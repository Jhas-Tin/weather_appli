import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'variable.dart';

class WeatherMap extends ConsumerStatefulWidget {
  const WeatherMap({super.key});

  @override
  ConsumerState<WeatherMap> createState() => _WeatherMapState();
}

class _WeatherMapState extends ConsumerState<WeatherMap> {
  bool _isLoading = true;
  double? _lat;
  double? _lon;
  String _city = "";
  final MapController _mapController = MapController();

  final List<Map<String, dynamic>> _mapStyles = [
    {
      'name': 'Satellite',
      'url': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      'description': 'High-resolution satellite imagery',
    },
    {
      'name': 'Street',
      'url': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
      'description': 'Detailed street map',
    },
    {
      'name': 'Topographic',
      'url': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
      'description': 'Topographic map with elevation',
    },
  ];

  int _selectedMapIndex = 0;

  @override
  void initState() {
    super.initState();
    _getCityCoordinates();
  }

  Future<void> _getCityCoordinates() async {
    final city = ref.read(cityProvider);
    setState(() {
      _city = city;
      _isLoading = true;
    });

    try {
      final geocodeUrl = 'http://api.openweathermap.org/geo/1.0/direct?q=${Uri.encodeComponent(city)}&limit=1&appid=9ec82ba0bb50795ef03a62858246ad4c';
      final response = await http.get(Uri.parse(geocodeUrl));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _lat = data[0]['lat'];
            _lon = data[0]['lon'];
            _isLoading = false;
          });

          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _mapController.move(LatLng(_lat!, _lon!), 10.0);
            }
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error getting coordinates: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_city.isEmpty ? "Weather Map" : _city),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _getCityCoordinates,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 20))
            : _lat == null || _lon == null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle, size: 50),
              const SizedBox(height: 16),
              const Text("Could not find location"),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: _getCityCoordinates,
                child: const Text("Retry"),
              ),
            ],
          ),
        )
            : Column(
          children: [
            Container(
              height: 50,
              color: CupertinoColors.systemGrey6,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mapStyles.length,
                itemBuilder: (context, index) {
                  final style = _mapStyles[index];
                  final isSelected = index == _selectedMapIndex;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMapIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          style['name'],
                          style: TextStyle(
                            color: isSelected ? CupertinoColors.white : CupertinoColors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(_lat!, _lon!),
                  initialZoom: 10.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: _mapStyles[_selectedMapIndex]['url'],
                    userAgentPackageName: 'com.example.weather_app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_lat!, _lon!),
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CupertinoColors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.location_solid,
                            color: CupertinoColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.info, size: 16, color: CupertinoColors.systemGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _mapStyles[_selectedMapIndex]['description'],
                      style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}