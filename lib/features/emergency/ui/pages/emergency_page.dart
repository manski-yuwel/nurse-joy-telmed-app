import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../main.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  _EmergencyPageState createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  //Colors
  static const color1 = Color(0xffB3261E);
  static const color2 = Color(0xffFF7C7C);
  static const color3 = Color(0xffFFE1E2);
  static const color4 = Color(0xffA02040);

  LatLng? _currentLocation;
  List<Marker> _hospitalMarkers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _hospitalsLoadingStatus = '';
  bool _isFetchingHospitals = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndGetLocation();
  }

  Future<void> _checkPermissionAndGetLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permission denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Location permission permanently denied, please enable in settings';
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _fetchHospitals();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error getting location: $e';
        print('Location error: $e');
      });
    }
  }

  Future<void> _fetchHospitals() async {
    if (_currentLocation == null) return;

    // Set loading states
    setState(() {
      _hospitalsLoadingStatus = 'Searching for nearby hospitals...';
      _isFetchingHospitals = true;
    });

    try {
      // Create a safer version of the API call
      final result = await _fetchHospitalsWithTimeout();

      if (result.isEmpty) {
        setState(() {
          _hospitalsLoadingStatus =
              'No medical facilities found. Using defaults.';
          _useDefaultHospitals();
        });
      } else {
        setState(() {
          _hospitalMarkers = result;
          _hospitalsLoadingStatus = 'Found ${result.length} medical facilities';
        });
      }
    } catch (e) {
      print('Error fetching hospitals: $e');
      setState(() {
        _hospitalsLoadingStatus = 'Service unavailable. Using defaults.';
        _useDefaultHospitals();
      });
    } finally {
      setState(() {
        _isFetchingHospitals = false;
      });
    }
  }

  Future<List<Marker>> _fetchHospitalsWithTimeout() async {
    // Use a completer to handle timeout properly
    final completer = Completer<List<Marker>>();

    // Set a timer to handle timeout
    final timer = Timer(const Duration(seconds: 8), () {
      if (!completer.isCompleted) {
        completer.complete([]);
        print('Hospital API request timed out');
      }
    });

    try {
      // Build a reasonable search query with lower radius first
      final overpassUrl = 'https://overpass-api.de/api/interpreter';
      final query = '''
        [out:json];
        (
          node["amenity"="hospital"](around:5000,${_currentLocation!.latitude},${_currentLocation!.longitude});
          node["amenity"="clinic"](around:5000,${_currentLocation!.latitude},${_currentLocation!.longitude});
          node["healthcare"="hospital"](around:5000,${_currentLocation!.latitude},${_currentLocation!.longitude});
        );
        out;
      ''';

      print('Sending request to Overpass API');
      final response = await http
          .post(
            Uri.parse(overpassUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'data=$query',
          )
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        print('Received ${elements.length} hospitals from API');

        if (elements.isNotEmpty) {
          final markers = elements.map<Marker>((element) {
            // Extract the name if available
            final String name = element['tags']?['name'] ?? 'Medical Facility';
            return Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(element['lat'], element['lon']),
              child: Column(
                children: [
                  Icon(Icons.local_hospital, color: Colors.red, size: 40),
                  Container(
                    padding: EdgeInsets.all(2),
                    color: Colors.white.withOpacity(0.7),
                    child: Text(
                      name,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList();

          if (!completer.isCompleted) {
            completer.complete(markers);
          }
        } else {
          if (!completer.isCompleted) {
            completer.complete([]);
          }
        }
      } else {
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      }
    } catch (e) {
      if (!completer.isCompleted) {
        print('Error in hospital API request: $e');
        completer.complete([]);
      }
    } finally {
      timer.cancel();
    }

    return completer.future;
  }

  void _useDefaultHospitals() {
    if (_currentLocation == null) return;

    // Create default hospital markers around the user's location
    _hospitalMarkers = [
      _createHospitalMarker(
          _offsetLocation(_currentLocation!, 0.01, 0), 'City General Hospital'),
      _createHospitalMarker(
          _offsetLocation(_currentLocation!, 0, 0.01), 'Medical Center'),
      _createHospitalMarker(_offsetLocation(_currentLocation!, -0.005, 0.008),
          'Community Clinic'),
    ];
  }

  Marker _createHospitalMarker(LatLng location, String name) {
    return Marker(
      width: 80.0,
      height: 80.0,
      point: location,
      child: Column(
        children: [
          Icon(Icons.local_hospital, color: Colors.red, size: 40),
          Container(
            padding: EdgeInsets.all(2),
            color: Colors.white.withOpacity(0.7),
            child: Text(
              name,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  LatLng _offsetLocation(LatLng start, double latOffset, double lonOffset) {
    return LatLng(
      start.latitude + latOffset,
      start.longitude + lonOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color1,
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back)),
        title: Text(
          'Emergency Mode',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(1, 1),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // AI Assistant Card
            displayCard(color: color2, children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xffB3261E),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(children: [
                  SizedBox(
                    width: 43,
                    height: 43,
                    child: buildCircleImage('assets/img/nursejoy.jpg', 0, 1.5),
                  ),
                  SizedBox(width: 20),
                  Text(
                    'How can I help?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]),
              ),
              SizedBox(height: 10),
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: color3,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Icon(Icons.mic, color: color4),
                    SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                      decoration: InputDecoration(
                        hintText: '...',
                        hintStyle: TextStyle(color: color1),
                      ),
                    )),
                    IconButton(
                        icon: Icon(Icons.send, color: color4),
                        onPressed: () {} //TODO: Add send functionality,
                        ),
                  ])),
            ]),

            // Map Card
            displayCard(color: color2, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nearest Hospital',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold)),
                  _isFetchingHospitals
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : IconButton(
                          onPressed: _checkPermissionAndGetLocation,
                          icon: Icon(Icons.refresh, color: Colors.white),
                        )
                ],
              ),
              Container(
                height: 300,
                child: _errorMessage.isNotEmpty
                    ? Center(
                        child: Text(_errorMessage,
                            style: TextStyle(color: Colors.white)))
                    : _isLoading || _currentLocation == null
                        ? Center(
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : FlutterMap(
                            options: MapOptions(
                              initialCenter: _currentLocation!,
                              initialZoom: 13.0,
                              onMapReady: () {
                                print('Map is ready!');
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                                tileProvider: NetworkTileProvider(),
                              ),
                              MarkerLayer(
                                markers: [
                                  // Always add a marker for current location to verify map is working
                                  Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: _currentLocation!,
                                    child: Column(
                                      children: [
                                        Icon(Icons.my_location,
                                            color: Colors.blue, size: 40),
                                        Container(
                                          padding: EdgeInsets.all(2),
                                          color: Colors.white.withOpacity(0.7),
                                          child: Text(
                                            'You are here',
                                            style: TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ..._hospitalMarkers,
                                ],
                              ),
                            ],
                          ),
              ),
              // Debug stuff
              Text(
                _currentLocation != null
                    ? 'Location: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}'
                    : 'No location data',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                _hospitalsLoadingStatus,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              // Add a refresh button
            ]),
          ],
        ),
      ),
    );
  }
}

// Card template
Widget displayCard({required List<Widget> children, required Color color}) {
  return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: color,
      child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children))
          ])));
}
