import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

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
        ],
      ),
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
}