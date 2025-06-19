import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class ViewMapPage extends StatefulWidget {
  const ViewMapPage({Key? key}) : super(key: key);

  @override
  _ViewMapPageState createState() => _ViewMapPageState();
}

class _ViewMapPageState extends State<ViewMapPage> {
  int _selectedIndex = -1;
  bool? _permissionGranted;
  late AuthService auth;
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(14.5613, 121.0215);
  Set<Marker> _hospitalMarkers = {};
  bool _isLoadingHospitals = false;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    auth = Provider.of<AuthService>(context, listen: false);
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      context.go('/chat');
    } else if (index == 1) {
      context.go('/home');
    } else if (index == 2) {
      context.go('/profile/${auth.user!.uid}');
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Map",
      selectedIndex: _selectedIndex == -1 ? 0 : _selectedIndex,
      onItemTapped: _onItemTapped,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            myLocationEnabled: _permissionGranted ?? false,
            myLocationButtonEnabled: false, // We'll use our own button
            zoomControlsEnabled: false,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _hospitalMarkers,
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF5BF0D7),
              child: const Icon(Icons.my_location, color: Colors.white),
              onPressed: _checkAndRequestLocationService,
            ),
          ),
          // Hospital button (bottom left)
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              child: const Icon(Icons.local_hospital, color: Colors.black),
              onPressed: _showNearbyHospitals,
              tooltip: 'Show Nearby Hospitals',
            ),
          ),
          if (_isLoadingHospitals)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  //asks for location permission then asks to turn on gps(once "locate me" button is pressed)
  Future<void> _checkAndRequestLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show a dialog before redirecting to device settings
      bool? result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable GPS'),
          content: const Text('Your device\'s GPS is turned off. Would you like to turn it on?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (result == true) {
        await Geolocator.openLocationSettings();
      }
      return;
    }
    Position position = await Geolocator.getCurrentPosition();
    mapController.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  //dialog box for user location permission
  Future<void> _requestPermission() async {
    final status = await Permission.location.request();

    if (!mounted) return;

    setState(() {
      _permissionGranted = status.isGranted;
    });
  }

  // Fetch hospitals from Overpass API (OpenStreetMap)
  Future<void> _showNearbyHospitals() async {
    setState(() {
      _isLoadingHospitals = true;
    });

    Position position = await Geolocator.getCurrentPosition();
    final double lat = position.latitude;
    final double lng = position.longitude;
    const double radius = 10000; // 5km radius

    // Calculate bounding box for Overpass API (approximate)
    double latDiff = radius / 111320; // meters per degree latitude
    double lonDiff = radius / (111320 * (cos(lat * pi / 180)));

    double south = lat - latDiff;
    double north = lat + latDiff;
    double west = lng - lonDiff;
    double east = lng + lonDiff;

    final query = '''
      [out:json];
      (
        node["amenity"="hospital"]($south,$west,$north,$east);
        way["amenity"="hospital"]($south,$west,$north,$east);
        relation["amenity"="hospital"]($south,$west,$north,$east);
      );
      out center;
    ''';

    print('Querying Overpass with: center=($lat, $lng), bbox=($south, $west, $north, $east)');
    final url = Uri.parse('https://overpass-api.de/api/interpreter');
    final response = await http.post(url, body: {'data': query});

    setState(() {
      _isLoadingHospitals = false;
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data);
      if (data['elements'] != null && data['elements'].isNotEmpty) {
        Set<Marker> markers = {};
        for (var element in data['elements']) {
          double? lat, lon;
          if (element['lat'] != null && element['lon'] != null) {
            lat = element['lat'];
            lon = element['lon'];
          } else if (element['center'] != null) {
            lat = element['center']['lat'];
            lon = element['center']['lon'];
          }
          if (lat != null && lon != null) {
            markers.add(
              Marker(
                markerId: MarkerId(element['id'].toString()),
                position: LatLng(lat, lon),
                infoWindow: InfoWindow(
                  title: element['tags']?['name'] ?? 'Hospital',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            );
          }
        }
        setState(() {
          _hospitalMarkers = markers;
        });
        // Zoom to fit all markers (same as before)
        if (markers.isNotEmpty && mapController != null) {
          final lats = markers.map((m) => m.position.latitude);
          final lngs = markers.map((m) => m.position.longitude);
          final sw = LatLng(lats.reduce(min), lngs.reduce(min));
          final ne = LatLng(lats.reduce(max), lngs.reduce(max));
          mapController.animateCamera(
            CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 80),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hospitals found nearby.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch hospitals (HTTP ${response.statusCode})')),
      );
    }
  }
}