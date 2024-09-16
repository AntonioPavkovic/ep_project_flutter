import 'dart:async';
import 'dart:convert'; // For decoding JSON

import 'package:flutter/material.dart';
import 'package:fun_drive/consts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _locationController = new Location();

  final Completer<GoogleMapController> _mapController =
  Completer<GoogleMapController>();
  final CustomInfoWindowController _customInfoWindowController =
  CustomInfoWindowController();

  LatLng? _currentP = null;
  Map<PolylineId, Polyline> polylines = {};
  Set<Marker> _markers = {}; // Store all the markers

  @override
  void initState() {
    super.initState();
    getLocationUpdates().then(
          (_) {
        getMarkersFromApi(); // Fetch markers when map is initialized
        getPolylinePoints().then((coordinates) {
          generatePolyLineFromPoints(coordinates);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentP == null
          ? const Center(
        child: Text("Loading..."),
      )
          : Stack(
        children: [
          GoogleMap(
            onTap: (position) {
              _customInfoWindowController.hideInfoWindow!();
            },
            onCameraMove: (position) {
              _customInfoWindowController.onCameraMove!();
            },
            onMapCreated: (GoogleMapController controller) async {
              _customInfoWindowController.googleMapController = controller;
              _mapController.complete(controller); // Ensure map controller is set
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(43.34583290192481, 17.7967256308148),
              zoom: 13,
            ),
            markers: _markers, // Use the markers set
            polylines: Set<Polyline>.of(polylines.values),
          ),
          CustomInfoWindow(
            controller: _customInfoWindowController,
            height: 300,
            width: 340,
            offset: 50,
          ),
        ],
      ),
    );
  }

  Future<void> getMarkersFromApi() async {
    try {

      final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/markers'));


      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('Markers fetched: $data'); // Debugging: Check if data is fetched
        Set<Marker> markersFromApi = {};

        for (var item in data) {
          // Check for valid latitude and longitude
          if (item['latitude'] != null && item['longitude'] != null) {
            LatLng position = LatLng(item['latitude'], item['longitude']);

            markersFromApi.add(
              Marker(
                markerId: MarkerId(item['id'].toString()),
                position: position,
                infoWindow: InfoWindow(
                  title: item['name'],
                  snippet: item['description'],
                ),
                onTap: () {
                  _customInfoWindowController.addInfoWindow!(
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.network(
                            item['imgURL'] != null && item['imgURL'].isNotEmpty
                                ? item['imgURL']
                                : 'https://via.placeholder.com/150', // Fallback image if URL is empty
                            fit: BoxFit.cover,
                          ),
                          Text(
                            item['name'],
                            style: TextStyle(fontSize: 28),
                          ),
                          Text(
                            item['description'],
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    position,
                  );
                },
              ),
            );
          } else {
            print("Invalid LatLng for marker: ${item['name']}"); // Debugging
          }
        }

        setState(() {
          _markers = markersFromApi;
          print('Markers added: $_markers'); // Debugging: Check if markers are added
        });
      } else {
        print('Error: Failed to load markers. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching markers: $e"); // Debugging
    }
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(
      target: pos,
      zoom: 13,
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_newCameraPosition),
    );
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    _locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentP = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _cameraToPosition(_currentP!);
        });
      }
    });
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: GOOGLE_MAPS_API_KEY,
      request: PolylineRequest(
        origin: PointLatLng(43.34583290192481, 17.7967256308148),
        destination: PointLatLng(43.11654170482214, 17.7064743399809),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      print('Error: ${result.errorMessage}');
    }
    return polylineCoordinates;
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.black,
      points: polylineCoordinates,
      width: 8,
    );
    setState(() {
      polylines[id] = polyline;
    });
  }
}
