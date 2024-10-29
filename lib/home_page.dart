import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert'; // For loading GeoJSON

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Marker> _markers = [];

  // Add controllers for reporting outages
  final TextEditingController suburbController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController outageTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGeoJsonData();
  }

  void _loadGeoJsonData() async {
    // Load GeoJSON data
    final plannedGeoJsonData = await DefaultAssetBundle.of(context)
        .loadString('assets/energex_po_current_planned.geojson');
    final unplannedGeoJsonData = await DefaultAssetBundle.of(context)
        .loadString('assets/energex_po_current_unplanned.geojson');
    final futurePlannedGeoJsonData = await DefaultAssetBundle.of(context)
        .loadString('assets/energex_po_future_planned.geojson');

    final plannedData = json.decode(plannedGeoJsonData);
    final unplannedData = json.decode(unplannedGeoJsonData);
    final futurePlannedData = json.decode(futurePlannedGeoJsonData);

    setState(() {
      // Combine all markers
      _markers = [
        ..._createMarkersFromGeoJson(plannedData['features'], 'PLANNED'),
        ..._createMarkersFromGeoJson(unplannedData['features'], 'UNPLANNED'),
        ..._createMarkersFromGeoJson(
            futurePlannedData['features'], 'FUTURE PLANNED'),
      ];
    });
  }

  List<Marker> _createMarkersFromGeoJson(List features, String outageType) {
    return features.map((feature) {
      final geometry = feature['geometry']['coordinates'];
      final properties = feature['properties'];

      final lat = geometry[1];
      final lng = geometry[0];

      // Set marker color based on outage type
      Color markerColor;
      if (outageType == 'PLANNED') {
        markerColor = Colors.green;
      } else if (outageType == 'UNPLANNED') {
        markerColor = Colors.red;
      } else if (outageType == 'FUTURE PLANNED') {
        markerColor = Colors.blue;
      } else {
        markerColor = Colors.black;
      }

      return Marker(
        point: LatLng(lat, lng),
        builder: (ctx) => GestureDetector(
          onTap: () {
            _showOutageDetails(properties); // Show existing outage details
          },
          child: Icon(
            Icons.location_on,
            color: markerColor,
            size: 30,
          ),
        ),
      );
    }).toList();
  }

  void _showOutageDetails(Map<String, dynamic> properties) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Outage Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${properties['TYPE']}'),
              Text('Customers Affected: ${properties['CUSTOMERS_AFFECTED']}'),
              Text('Reason: ${properties['REASON']}'),
              Text('Status: ${properties['STATUS']}'),
              Text('Start: ${properties['START']}'),
              Text('Estimated Fix Time: ${properties['EST_FIX_TIME']}'),
              Text('Streets: ${properties['STREETS']}'),
              Text('Suburbs: ${properties['SUBURBS']}'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showReportOutageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Report Outage'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Suburb'),
                controller: suburbController,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Street'),
                controller: streetController,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Outage Type'),
                controller: outageTypeController,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                _reportOutage(suburbController.text, streetController.text,
                    outageTypeController.text);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _reportOutage(String suburb, String street, String outageType) async {
    if (suburb.isNotEmpty && street.isNotEmpty && outageType.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> reportedOutages =
          prefs.getStringList('reportedOutages') ?? [];

      String outageDetails =
          'Suburb: $suburb, Street: $street, Type: $outageType';
      reportedOutages.add(outageDetails);

      await prefs.setStringList('reportedOutages', reportedOutages);

      // Optionally show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Outage reported successfully!')));
    }
  }

  @override
  void dispose() {
    // Dispose of the controllers
    suburbController.dispose();
    streetController.dispose();
    outageTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          center:
              LatLng(-27.4698, 153.0251), // Example coordinates for Brisbane
          zoom: 10.0,
          maxZoom: 18.0,
          interactiveFlags: InteractiveFlag.all, // Enable zoom/pinch
        ),
        children: [
          TileLayer(
            urlTemplate:
                "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png", // Grayscale tile URL from CartoDB
            subdomains: ['a', 'b', 'c'], // Tile subdomains
          ),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 120,
              size: Size(40, 40),
              fitBoundsOptions: FitBoundsOptions(
                padding: EdgeInsets.all(50),
              ),
              markers: _markers,
              polygonOptions: PolygonOptions(
                borderColor: Colors.blueAccent,
                color: Colors.black12,
                borderStrokeWidth: 3,
              ),
              builder: (context, markers) {
                return FloatingActionButton(
                  child: Text(markers.length.toString()),
                  onPressed: null,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.info, size: 24.0),
              onPressed: () {
                Navigator.pushNamed(context, '/info');
              },
            ),
            IconButton(
              icon: Icon(Icons.home, size: 24.0),
              onPressed: () {
                // Already on the home page, do nothing
              },
            ),
            IconButton(
              icon: Icon(Icons.report, size: 24.0), // Add report button
              onPressed: () {
                _showReportOutageDialog(); // Show report outage dialog
              },
            ),
            IconButton(
              icon: Icon(Icons.person, size: 24.0),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}
