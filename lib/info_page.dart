import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert'; // Import for JSON decoding
import 'package:latlong2/latlong.dart'; // Import for LatLng

class InfoPage extends StatefulWidget {
  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  String _selectedOption = 'ALL'; // Default to "ALL"
  List<Map<String, dynamic>> plannedFeatures = [];
  List<Map<String, dynamic>> unplannedFeatures = [];
  List<Map<String, dynamic>> futurePlannedFeatures =
      []; // For future planned outages
  List<Map<String, dynamic>> filteredFeatures = [];

  @override
  void initState() {
    super.initState();
    _loadGeoJsonData();
  }

  void _loadGeoJsonData() async {
    // Load and parse the current planned GeoJSON data
    final plannedGeoJsonData = await DefaultAssetBundle.of(context)
        .loadString('assets/energex_po_current_planned.geojson');
    final plannedData = json.decode(plannedGeoJsonData);

    // Load and parse the unplanned GeoJSON data
    final unplannedGeoJsonData = await DefaultAssetBundle.of(context)
        .loadString('assets/energex_po_current_unplanned.geojson');
    final unplannedData = json.decode(unplannedGeoJsonData);

    // Load and parse the future planned GeoJSON data
    final futurePlannedGeoJsonData = await DefaultAssetBundle.of(context)
        .loadString('assets/energex_po_future_planned.geojson');
    final futurePlannedData = json.decode(futurePlannedGeoJsonData);

    setState(() {
      plannedFeatures =
          List<Map<String, dynamic>>.from(plannedData['features']);
      unplannedFeatures =
          List<Map<String, dynamic>>.from(unplannedData['features']);
      futurePlannedFeatures =
          List<Map<String, dynamic>>.from(futurePlannedData['features']);

      // Initialize the filtered list with all features initially
      filteredFeatures = [
        ...plannedFeatures,
        ...unplannedFeatures,
        ...futurePlannedFeatures
      ];
    });
  }

  void _filterFeatures(String query) {
    List<Map<String, dynamic>> currentFeatures;

    if (_selectedOption == 'CURRENT') {
      currentFeatures = plannedFeatures;
    } else if (_selectedOption == 'UNPLANNED') {
      currentFeatures = unplannedFeatures;
    } else if (_selectedOption == 'FUTURE PLANNED') {
      currentFeatures = futurePlannedFeatures;
    } else {
      // For "ALL", combine all features
      currentFeatures = [
        ...plannedFeatures,
        ...unplannedFeatures,
        ...futurePlannedFeatures
      ];
    }

    if (query.isNotEmpty) {
      setState(() {
        String lowerCaseQuery = query.toLowerCase();

        filteredFeatures = currentFeatures.where((feature) {
          return feature['properties'].values.any((value) {
            if (value != null) {
              return value.toString().toLowerCase().contains(lowerCaseQuery);
            }
            return false;
          });
        }).toList();
      });
    } else {
      setState(() {
        filteredFeatures = currentFeatures;
      });
    }
  }

  Future<void> _launchURL() async {
    const url =
        'https://www.energex.com.au/outages/outage-finder/outage-finder-map/'; // Replace with actual URL
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _navigateToMap(LatLng coordinates) {
    // Navigate to the map and show the marker at the outage location
    Navigator.pushNamed(context, '/map', arguments: coordinates);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Info'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) {
                      _filterFeatures(value);
                    },
                  ),
                ),
                SizedBox(width: 10.0),
                DropdownButton<String>(
                  value: _selectedOption,
                  icon: Icon(Icons.arrow_drop_down),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedOption = newValue!;
                      if (_selectedOption == 'CURRENT') {
                        filteredFeatures = plannedFeatures;
                      } else if (_selectedOption == 'UNPLANNED') {
                        filteredFeatures = unplannedFeatures;
                      } else if (_selectedOption == 'FUTURE PLANNED') {
                        filteredFeatures = futurePlannedFeatures;
                      } else {
                        filteredFeatures = [
                          ...plannedFeatures,
                          ...unplannedFeatures,
                          ...futurePlannedFeatures
                        ];
                      }
                    });
                  },
                  items: <String>['ALL', 'CURRENT', 'UNPLANNED', 'SCHEDULED']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: filteredFeatures.length,
                itemBuilder: (context, index) {
                  final feature = filteredFeatures[index];
                  final properties = feature['properties'];
                  final coordinates = feature['geometry']['coordinates'];
                  final lat = coordinates[1];
                  final lng = coordinates[0];

                  return GestureDetector(
                    onTap: () {
                      _navigateToMap(
                          LatLng(lat, lng)); // Navigate to map with coordinates
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16.0),
                      padding: EdgeInsets.all(16.0),
                      color: Colors.grey[300],
                      child: Table(
                        border:
                            TableBorder.all(color: Colors.grey), // Add border
                        columnWidths: {
                          0: FlexColumnWidth(1), // Left column
                          1: FlexColumnWidth(2), // Right column
                        },
                        children: [
                          TableRow(
                            children: [
                              Center(
                                child: Text(
                                  'Suburb:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Center(child: Text('${properties['SUBURBS']}')),
                            ],
                          ),
                          TableRow(
                            children: [
                              Center(
                                child: Text(
                                  'Street:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Center(child: Text('${properties['STREETS']}')),
                            ],
                          ),
                          TableRow(
                            children: [
                              Center(
                                child: Text(
                                  'Type:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Center(child: Text('${properties['TYPE']}')),
                            ],
                          ),
                          TableRow(
                            children: [
                              Center(
                                child: Text(
                                  'Customers Affected:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Center(
                                  child: Text(
                                      '${properties['CUSTOMERS_AFFECTED']}')),
                            ],
                          ),
                          TableRow(
                            children: [
                              Center(
                                child: Text(
                                  'Reason:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Center(child: Text('${properties['REASON']}')),
                            ],
                          ),
                          TableRow(
                            children: [
                              Center(
                                child: Text(
                                  'Status:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Center(child: Text('${properties['STATUS']}')),
                            ],
                          ),
                          TableRow(
                            children: [
                              Center(
                                child: Text(
                                  'Start:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Center(child: Text('${properties['START']}')),
                            ],
                          ),
                          TableRow(
                            children: [
                              Center(
                                child: Text(
                                  'Est. Fix Time:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Center(
                                  child: Text('${properties['EST_FIX_TIME']}')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            TextButton(
              child: Text('Website View'),
              onPressed: _launchURL,
            ),
          ],
        ),
      ),
    );
  }
}
