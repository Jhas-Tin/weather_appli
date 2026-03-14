import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'variable.dart';

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
  });

  String _getWeatherGif(String condition) {
    switch (condition) {
      case "Rain": return "assets/animations/rainy2.jpg";
      case "Thunderstorm": return "assets/animations/thunder.jpg";
      case "Snow": return "assets/animations/snow.jpg";
      case "Clear": return "assets/animations/sunny.jpg";
      case "Mist":
      case "Fog":
      case "Haze": return "assets/animations/mist.jpg";
      case "Clouds":
      default: return "assets/animations/cloudy2.jpg";
    }
  }

  @override
  Widget build(BuildContext context) {
    String getDayLabel(DateTime date) {
      const labels = ["Mon", "Tue", "Wed", "Thu", "Fri"];
      return labels[date.weekday - 1];
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(_getWeatherGif(condition), fit: BoxFit.cover, gaplessPlayback: true),
        ),
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: (weatherBackgrounds[condition] ?? [const Color(0xFF3A8DFF), const Color(0xFF4FACFE)])
                    .map((c) => c.withOpacity(0.55))
                    .toList(),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Icon(weatherIcon, size: 80, color: CupertinoColors.white),
              const SizedBox(height: 8),
              Text(city, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
              const SizedBox(height: 4),
              Text(condition, style: const TextStyle(fontSize: 18, color: CupertinoColors.white)),
              const SizedBox(height: 4),
              Text(temp, style: const TextStyle(fontSize: 96, fontWeight: FontWeight.w200, color: CupertinoColors.white)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.drop_fill, size: 18, color: CupertinoColors.white),
                      const SizedBox(width: 6),
                      Text("Humidity: $humidity%", style: const TextStyle(color: CupertinoColors.white)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.wind, size: 18, color: CupertinoColors.white),
                      const SizedBox(width: 6),
                      Text("Wind: $windSpeed km/h", style: const TextStyle(color: CupertinoColors.white)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(50, 15, 45, 55),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Icon(CupertinoIcons.calendar, color: CupertinoColors.white, size: 18),
                          SizedBox(width: 8),
                          Text("Weather Forecast", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: weeklyForecast.length,
                          itemBuilder: (context, index) {
                            final day = weeklyForecast[index];
                            final dayName = getDayLabel(day.date);
                            final min = isCelsius ? "${day.minTemp.toStringAsFixed(0)}°" : "${(day.minTemp * 9 ~/ 5 + 32)}°";
                            final max = isCelsius ? "${day.maxTemp.toStringAsFixed(0)}°" : "${(day.maxTemp * 9 ~/ 5 + 32)}°";

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  SizedBox(width: 100, child: Text(dayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: CupertinoColors.white))),
                                  Icon(day.icon, color: CupertinoColors.white),
                                  const SizedBox(width: 10),
                                  Text(min, style: const TextStyle(color: CupertinoColors.white)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: const LinearGradient(colors: [CupertinoColors.systemYellow, CupertinoColors.systemRed]),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(max, style: const TextStyle(color: CupertinoColors.white)),
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

  final Map<String, IconData> weatherIconsMap = {
    "Clouds": CupertinoIcons.cloud,
    "Rain": CupertinoIcons.cloud_rain,
    "Thunderstorm": CupertinoIcons.cloud_bolt,
    "Clear": CupertinoIcons.sun_max,
    "Snow": CupertinoIcons.snow,
    "Drizzle": CupertinoIcons.cloud_drizzle,
    "Mist": CupertinoIcons.cloud_fog,
  };

  final Map<String, List<Color>> weatherBackgrounds = {
    "Clear": [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
    "Clouds": [const Color(0xFF757F9A), const Color(0xFFD7DDE8)],
    "Rain": [const Color(0xFF4E54C8), const Color(0xFF8F94FB)],
    "Thunderstorm": [const Color(0xFF373B44), const Color(0xFF4286f4)],
    "Snow": [const Color(0xFF83a4d4), const Color(0xFFb6fbff)],
    "Drizzle": [const Color(0xFF89F7FE), const Color(0xFF66A6FF)],
    "Mist": [const Color(0xFF606C88), const Color(0xFF3F4C6B)],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchWeather();
      ref.listen<String>(cityProvider, (prev, next) {
        if (!mounted) return;
        fetchWeather();
      });
    });
  }

  Future<void> fetchWeather() async {
    final city = ref.read(cityProvider);
    ref.read(isLoadingProvider.notifier).state = true;
    setState(() => hasError = false);

    final link =
        'https://api.openweathermap.org/data/2.5/weather?q=${Uri.encodeComponent(city)}&appid=9ec82ba0bb50795ef03a62858246ad4c&units=metric';

    try {
      final response = await http.get(Uri.parse(link));
      if (response.statusCode != 200) throw Exception("Failed: ${response.body}");

      final data = jsonDecode(response.body);
      setState(() {
        temp = (data["main"]["temp"] as num).toStringAsFixed(0);
        weatherCondition = data["weather"][0]["main"];
        humidity = (data["main"]["humidity"] as num).toString();
        double windSpeedMps = (data["wind"]["speed"] as num).toDouble();
        windSpeed = (windSpeedMps * 3.6).toStringAsFixed(1);
        weatherIcon = weatherIconsMap[weatherCondition] ?? CupertinoIcons.cloud;
      });

      final lat = data["coord"]["lat"];
      final lon = data["coord"]["lon"];
      await fetchWeeklyForecast(lat, lon);
      ref.read(isLoadingProvider.notifier).state = false;
    } catch (e) {
      print("Weather fetch failed: $e");
      ref.read(isLoadingProvider.notifier).state = false;
      setState(() => hasError = true);
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
      DateTime startDate = DateTime(today.year, today.month, today.day).add(const Duration(days: 1));

      for (var item in list) {
        DateTime date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
        DateTime dayOnly = DateTime(date.year, date.month, date.day);
        if (dayOnly.isBefore(startDate) || date.weekday > DateTime.friday) continue;
        String key = "${date.year}-${date.month}-${date.day}";
        if (!dailyMap.containsKey(key)) {
          String condition = item['weather'][0]['main'];
          dailyMap[key] = DailyForecast(
            date: date,
            minTemp: (item['main']['temp_min'] as num).toDouble(),
            maxTemp: (item['main']['temp_max'] as num).toDouble(),
            condition: condition,
            icon: weatherIconsMap[condition] ?? CupertinoIcons.cloud,
          );
        }
      }

      setState(() {
        weeklyForecast = dailyMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
      });
    } catch (e) {
      print("Failed to load weekly forecast: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    final city = ref.watch(cityProvider);
    final isCelsius = ref.watch(isCelsiusProvider);

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
              child: const Text("Retry"),
              onPressed: fetchWeather,
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
      ),
    );
  }
}