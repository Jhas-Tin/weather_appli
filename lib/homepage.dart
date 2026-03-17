import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'variable.dart';
import 'weather_map.dart';

class DailyForecast {
  final DateTime date;
  final String condition;
  final double minTemp;
  final double maxTemp;
  final IconData icon;

  DailyForecast({
    required this.date,
    required this.condition,
    required this.minTemp,
    required this.maxTemp,
    required this.icon,
  });
}

class WeatherHome extends StatelessWidget {
  final String city;
  final String temp;
  final String condition;
  final String humidity;
  final String windSpeed;
  final IconData weatherIcon;
  final bool isCelsius;
  final List<DailyForecast> weeklyForecast;
  final Map<String, List<Color>> weatherBackgrounds;
  final double? lat;
  final double? lon;

  const WeatherHome({
    super.key,
    required this.city,
    required this.temp,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.weatherIcon,
    required this.isCelsius,
    required this.weeklyForecast,
    required this.weatherBackgrounds,
    this.lat,
    this.lon,
  });

  String _getWeatherGif(String condition) {
    final lowerCondition = condition.toLowerCase();

    if (lowerCondition.contains("rain") ||
        lowerCondition.contains("drizzle") ||
        lowerCondition.contains("shower")) {
      return "assets/animations/rainy2.jpg";
    } else if (lowerCondition.contains("thunder")) {
      return "assets/animations/thunder.jpg";
    } else if (lowerCondition.contains("snow")) {
      return "assets/animations/snow.jpg";
    } else if (lowerCondition.contains("clear") ||
        lowerCondition.contains("sun")) {
      return "assets/animations/sunny.jpg";
    } else if (lowerCondition.contains("mist") ||
        lowerCondition.contains("fog") ||
        lowerCondition.contains("haze")) {
      return "assets/animations/mist.jpg";
    } else {
      return "assets/animations/cloudy2.jpg";
    }
  }

  @override
  Widget build(BuildContext context) {
    String getDayLabel(DateTime date) {
      const labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      return labels[date.weekday - 1];
    }

    String cleanCity = city.split(',').first.trim();

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            _getWeatherGif(condition),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF2F80ED),
              );
            },
          ),
        ),
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: (weatherBackgrounds[condition] ??
                    [const Color(0xFF3A8DFF), const Color(0xFF4FACFE)])
                    .map((c) => c.withValues(alpha: 0.55))
                    .toList(),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cleanCity,
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.white)),
                        const SizedBox(height: 4),
                        Text(condition,
                            style: const TextStyle(
                                fontSize: 18, color: CupertinoColors.white)),
                        const SizedBox(height: 10),
                        Text(temp,
                            style: const TextStyle(
                                fontSize: 96,
                                fontWeight: FontWeight.w200,
                                color: CupertinoColors.white)),
                      ],
                    ),
                    Row(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => const WeatherMap(),
                              ),
                            );
                          },
                          child: const Icon(
                            CupertinoIcons.map,
                            color: CupertinoColors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(weatherIcon,
                            size: 70, color: CupertinoColors.white),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.drop_fill,
                          size: 18, color: CupertinoColors.white),
                      const SizedBox(width: 6),
                      Text("Humidity: $humidity%",
                          style:
                          const TextStyle(color: CupertinoColors.white)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.wind,
                          size: 18, color: CupertinoColors.white),
                      const SizedBox(width: 6),
                      Text("Wind: $windSpeed km/h",
                          style:
                          const TextStyle(color: CupertinoColors.white)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (lat != null && lon != null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const WeatherMap(),
                      ),
                    );
                  },
                  child: Container(
                    height: 150,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: CupertinoColors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(lat!, lon!),
                              initialZoom: 8.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                userAgentPackageName: 'com.example.weather_app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(lat!, lon!),
                                    width: 30,
                                    height: 30,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemRed
                                            .withOpacity(0.9),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: CupertinoColors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.location_solid,
                                        color: CupertinoColors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: CupertinoColors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.map,
                                      color: CupertinoColors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    "Tap to open",
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(50, 15, 45, 55),
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.calendar,
                                color: CupertinoColors.white, size: 18),
                            SizedBox(width: 8),
                            Text("Weather Forecast",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.white)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: weeklyForecast.length,
                          itemBuilder: (context, index) {
                            final day = weeklyForecast[index];
                            final dayName = getDayLabel(day.date);
                            final min = isCelsius
                                ? "${day.minTemp.toStringAsFixed(0)}°"
                                : "${(day.minTemp * 9 ~/ 5 + 32)}°";
                            final max = isCelsius
                                ? "${day.maxTemp.toStringAsFixed(0)}°"
                                : "${(day.maxTemp * 9 ~/ 5 + 32)}°";

                            return Container(
                              width: 90,
                              margin:
                              const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(40, 255, 255, 255),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(dayName,
                                      style: const TextStyle(
                                          color: CupertinoColors.white)),
                                  const SizedBox(height: 6),
                                  Icon(day.icon,
                                      color: CupertinoColors.white, size: 28),
                                  const SizedBox(height: 6),
                                  Text("$min / $max",
                                      style: const TextStyle(
                                          color: CupertinoColors.white)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Homepage extends ConsumerStatefulWidget {
  const Homepage({super.key});

  @override
  ConsumerState<Homepage> createState() => _HomepageState();
}

class _HomepageState extends ConsumerState<Homepage> {
  bool hasError = false;
  String temp = "";
  String weatherCondition = "";
  String humidity = "";
  String windSpeed = "";
  IconData weatherIcon = CupertinoIcons.cloud_bolt;
  List<DailyForecast> weeklyForecast = [];
  double? lat;
  double? lon;

  final Map<String, IconData> weatherIconsMap = {
    "Clouds": CupertinoIcons.cloud,
    "Rain": CupertinoIcons.cloud_rain,
    "Thunderstorm": CupertinoIcons.cloud_bolt,
    "Clear": CupertinoIcons.sun_max,
    "Snow": CupertinoIcons.snow,
    "Drizzle": CupertinoIcons.cloud_drizzle,
    "Mist": CupertinoIcons.cloud_fog,
    "Smoke": CupertinoIcons.cloud_fog,
    "Haze": CupertinoIcons.cloud_fog,
    "Dust": CupertinoIcons.cloud_fog,
    "Fog": CupertinoIcons.cloud_fog,
    "Sand": CupertinoIcons.cloud_fog,
    "Ash": CupertinoIcons.cloud_fog,
    "Squall": CupertinoIcons.cloud_bolt,
    "Tornado": CupertinoIcons.cloud_bolt,
    "Shower": CupertinoIcons.cloud_rain,
    "Light Rain": CupertinoIcons.cloud_drizzle,
    "Heavy Rain": CupertinoIcons.cloud_rain,
    "Moderate Rain": CupertinoIcons.cloud_rain,
    "Patchy Rain": CupertinoIcons.cloud_drizzle,
    "Partly Cloudy": CupertinoIcons.cloud,
    "Overcast": CupertinoIcons.cloud,
    "Sunny": CupertinoIcons.sun_max,
  };

  final Map<String, List<Color>> weatherBackgrounds = {
    "Clear": [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
    "Clouds": [const Color(0xFF757F9A), const Color(0xFFD7DDE8)],
    "Rain": [const Color(0xFF4E54C8), const Color(0xFF8F94FB)],
    "Thunderstorm": [const Color(0xFF373B44), const Color(0xFF4286f4)],
    "Snow": [const Color(0xFF83a4d4), const Color(0xFFb6fbff)],
    "Drizzle": [const Color(0xFF89F7FE), const Color(0xFF66A6FF)],
    "Mist": [const Color(0xFF606C88), const Color(0xFF3F4C6B)],
    "Smoke": [const Color(0xFF606C88), const Color(0xFF3F4C6B)],
    "Haze": [const Color(0xFF606C88), const Color(0xFF3F4C6B)],
    "Fog": [const Color(0xFF606C88), const Color(0xFF3F4C6B)],
    "Dust": [const Color(0xFFB8860B), const Color(0xFF8B4513)],
    "Sand": [const Color(0xFFB8860B), const Color(0xFF8B4513)],
    "Ash": [const Color(0xFF2C3E50), const Color(0xFF34495E)],
    "Squall": [const Color(0xFF1A2980), const Color(0xFF26D0CE)],
    "Tornado": [const Color(0xFF0F2027), const Color(0xFF203A43)],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeWeather();
      }
    });
  }

  void _initializeWeather() {
    if (ref.read(useCurrentLocationProvider)) {
      getCurrentLocationCity();
    } else {
      fetchWeather();
    }
  }

  Future<void> getCurrentLocationCity() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        String city = placemarks.first.locality ?? "";
        if (city.isNotEmpty && mounted) {
          ref.read(cityProvider.notifier).state = city;
        }
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  String determineWeatherCondition(String mainCondition, String description, Map<String, dynamic> data) {
    String lowerDescription = description.toLowerCase();

    bool hasRain = false;
    bool hasSnow = false;

    if (data["rain"] != null) {
      if (data["rain"] is Map) {
        hasRain = (data["rain"]["1h"] != null || data["rain"]["3h"] != null);
      } else {
        hasRain = true;
      }
    }

    if (data["snow"] != null) {
      if (data["snow"] is Map) {
        hasSnow = (data["snow"]["1h"] != null || data["snow"]["3h"] != null);
      } else {
        hasSnow = true;
      }
    }

    if (hasRain || lowerDescription.contains('thunder') || mainCondition == "Thunderstorm") {
      if (lowerDescription.contains('thunder') || mainCondition == "Thunderstorm") {
        return "Thunderstorm";
      }
      return "Rain";
    } else if (hasSnow || lowerDescription.contains('snow') || lowerDescription.contains('sleet')) {
      return "Snow";
    } else if (lowerDescription.contains('drizzle')) {
      return "Drizzle";
    } else if (lowerDescription.contains('mist') ||
        lowerDescription.contains('fog') ||
        lowerDescription.contains('haze')) {
      return "Mist";
    } else if (lowerDescription.contains('clear') || lowerDescription.contains('sun')) {
      return "Clear";
    } else if (lowerDescription.contains('cloud') || mainCondition == "Clouds") {
      return "Clouds";
    }

    return mainCondition;
  }

  Future<void> fetchWeather() async {
    if (!mounted) return;

    final city = ref.read(cityProvider);
    ref.read(isLoadingProvider.notifier).state = true;
    setState(() => hasError = false);

    String cleanCityForApi = city.split(',').first.trim();

    final link =
        'https://api.openweathermap.org/data/2.5/weather?q=${Uri.encodeComponent(cleanCityForApi)}&appid=9ec82ba0bb50795ef03a62858246ad4c&units=metric';

    try {
      final response = await http.get(Uri.parse(link));
      if (response.statusCode != 200) throw Exception("Failed: ${response.body}");

      final data = jsonDecode(response.body);

      String mainCondition = data["weather"][0]["main"];
      String description = data["weather"][0]["description"];

      String finalCondition = determineWeatherCondition(mainCondition, description, data);

      if (mounted) {
        setState(() {
          temp = (data["main"]["temp"] as num).toStringAsFixed(0);
          weatherCondition = finalCondition;
          humidity = (data["main"]["humidity"] as num).toString();
          double windSpeedMps = (data["wind"]["speed"] as num).toDouble();
          windSpeed = (windSpeedMps * 3.6).toStringAsFixed(1);
          weatherIcon = weatherIconsMap[weatherCondition] ??
              weatherIconsMap[mainCondition] ??
              CupertinoIcons.cloud;
          lat = data["coord"]["lat"].toDouble();
          lon = data["coord"]["lon"].toDouble();
        });

        await fetchWeeklyForecast(lat!, lon!);
      }

      ref.read(isLoadingProvider.notifier).state = false;
    } catch (e) {
      debugPrint("Weather fetch failed: $e");
      if (mounted) {
        setState(() => hasError = true);
      }
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> fetchWeeklyForecast(double lat, double lon) async {
    final link =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&appid=9ec82ba0bb50795ef03a62858246ad4c';
    try {
      final response = await http.get(Uri.parse(link));
      if (response.statusCode != 200) throw Exception("Failed: ${response.body}");

      final data = jsonDecode(response.body);
      final List list = data['list'];
      Map<String, DailyForecast> dailyMap = {};
      DateTime today = DateTime.now();
      DateTime startDate = DateTime(today.year, today.month, today.day)
          .add(const Duration(days: 1));

      for (var item in list) {
        DateTime date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
        DateTime dayOnly = DateTime(date.year, date.month, date.day);
        if (dayOnly.isBefore(startDate)) {
          continue;
        }

        String key = "${date.year}-${date.month}-${date.day}";
        if (!dailyMap.containsKey(key)) {
          String condition = item['weather'][0]['main'];
          String description = item['weather'][0]['description'].toString().toLowerCase();

          String finalCondition = condition;
          if (description.contains('rain') || description.contains('drizzle') ||
              description.contains('shower') || description.contains('storm')) {
            finalCondition = "Rain";
          } else if (description.contains('snow') || description.contains('sleet')) {
            finalCondition = "Snow";
          } else if (description.contains('thunder')) {
            finalCondition = "Thunderstorm";
          } else if (description.contains('clear')) {
            finalCondition = "Clear";
          } else if (description.contains('cloud')) {
            finalCondition = "Clouds";
          }

          dailyMap[key] = DailyForecast(
            date: date,
            minTemp: (item['main']['temp_min'] as num).toDouble(),
            maxTemp: (item['main']['temp_max'] as num).toDouble(),
            condition: finalCondition,
            icon: weatherIconsMap[finalCondition] ?? CupertinoIcons.cloud,
          );
        }
      }

      if (mounted) {
        setState(() {
          weeklyForecast = dailyMap.values.toList()
            ..sort((a, b) => a.date.compareTo(b.date));
          if (weeklyForecast.length > 5) {
            weeklyForecast = weeklyForecast.sublist(0, 5);
          }
        });
      }
    } catch (e) {
      debugPrint("Failed to load weekly forecast: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(cityProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final isCelsius = ref.watch(isCelsiusProvider);

    ref.listen<String>(cityProvider, (previous, next) {
      if (next.isNotEmpty && mounted) {
        fetchWeather();
      }
    });

    return CupertinoPageScaffold(
      child: isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 20))
          : hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Failed to load weather data",
              style: TextStyle(color: CupertinoColors.white),
            ),
            const SizedBox(height: 12),
            CupertinoButton.filled(
              onPressed: fetchWeather,
              child: const Text("Retry"),
            ),
          ],
        ),
      )
          : WeatherHome(
        city: city,
        temp: isCelsius
            ? "$temp°"
            : "${((int.tryParse(temp) ?? 0) * 9 ~/ 5 + 32)}°",
        condition: weatherCondition,
        humidity: humidity,
        windSpeed: windSpeed,
        weatherIcon: weatherIcon,
        isCelsius: isCelsius,
        weeklyForecast: weeklyForecast,
        weatherBackgrounds: weatherBackgrounds,
        lat: lat,
        lon: lon,
      ),
    );
  }
}