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
  String _displayName = "";
  final MapController _mapController = MapController();
  String _previousCity = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCityCoordinates();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentCity = ref.watch(cityProvider);

    if (currentCity != _previousCity) {
      _previousCity = currentCity;
      if (currentCity.isNotEmpty) {
        _getCityCoordinates();
      }
    }
  }

  Future<void> _getCityCoordinates() async {
    final city = ref.read(cityProvider);
    if (city.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _city = city;
      _isLoading = true;
    });

    try {
      // Using OpenStreetMap Nominatim API for geocoding
      final geocodeUrl = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(city)}&format=json&limit=1';
      final response = await http.get(
        Uri.parse(geocodeUrl),
        headers: {
          'User-Agent': 'WeatherApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _lat = double.parse(data[0]['lat']);
            _lon = double.parse(data[0]['lon']);
            _displayName = data[0]['display_name'] ?? city;
            _isLoading = false;
          });

          // Move map to the new location
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _mapController.move(LatLng(_lat!, _lon!), 12.0);
            }
          });
        } else {
          setState(() {
            _isLoading = false;
          });

          // Show error dialog if city not found
          if (mounted) {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text("Location Not Found"),
                content: Text("Could not find location for: $city"),
                actions: [
                  CupertinoDialogAction(
                    child: const Text("OK"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }
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

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text("Error"),
            content: Text("Failed to load map: $e"),
            actions: [
              CupertinoDialogAction(
                child: const Text("OK"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool darkMode = ref.watch(darkModeProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.map, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _city.isEmpty ? "Map View" : _city,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
              const Icon(
                CupertinoIcons.location_slash,
                size: 60,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(height: 16),
              const Text(
                "No Location Selected",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please enter a city name in the home screen",
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        )
            : Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_lat!, _lon!),
                initialZoom: 12.0,
                maxZoom: 18.0,
                minZoom: 3.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // Standard OpenStreetMap tile layer
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.weather_app',
                  maxNativeZoom: 18,
                ),

                // Location marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_lat!, _lon!),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () {
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: Text(_city),
                              content: Text(_displayName),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text("OK"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed.withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CupertinoColors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.location_solid,
                            color: CupertinoColors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // OpenStreetMap attribution
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                      onTap: () {
                        // You could open a browser with the OpenStreetMap copyright page
                      },
                    ),
                  ],
                ),
              ],
            ),

            // Location info card at the bottom
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: darkMode
                      ? CupertinoColors.darkBackgroundGray.withOpacity(0.9)
                      : CupertinoColors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.location_fill,
                        color: CupertinoColors.activeBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _city,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_displayName.isNotEmpty && _displayName != _city)
                            Text(
                              _displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: darkMode
                                    ? CupertinoColors.white.withOpacity(0.7)
                                    : CupertinoColors.black.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}