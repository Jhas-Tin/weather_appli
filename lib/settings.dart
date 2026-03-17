import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'variable.dart';

class Settings extends ConsumerWidget {
  const Settings({super.key});

  Future<void> _detectCity(WidgetRef ref) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        String city = placemarks.first.locality ?? "Unknown";
        String country = placemarks.first.country ?? "";
        String adminArea = placemarks.first.administrativeArea ?? "";

        String locationString;
        if (country.toLowerCase().contains('philippines') ||
            adminArea.toLowerCase().contains('pampanga') ||
            adminArea.toLowerCase().contains('central luzon')) {
          locationString = "$city, $adminArea, Philippines";
        } else {
          locationString = city;
        }

        ref.read(cityProvider.notifier).state = locationString;
      }
    } catch (e) {
      print("Location error: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);
    final city = ref.watch(cityProvider);
    final isCelsius = ref.watch(isCelsiusProvider);
    final useCurrentLocation = ref.watch(useCurrentLocationProvider);

    // Clean the city name for display - remove anything after comma if present
    String cleanCity = city.split(',').first.trim();

    if (useCurrentLocation) {
      Future.microtask(() => _detectCity(ref));
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Settings"),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              children: [

                CupertinoListTile(
                  leading: _iconBox(
                    CupertinoIcons.moon_fill,
                    CupertinoColors.systemBlue,
                  ),
                  title: const Text("Dark Mode"),
                  trailing: CupertinoSwitch(
                    value: darkMode,
                    onChanged: (value) {
                      ref.read(darkModeProvider.notifier).state = value;
                    },
                  ),
                ),

                CupertinoListTile(
                  leading: _iconBox(
                    CupertinoIcons.location_fill,
                    CupertinoColors.systemGreen,
                  ),
                  title: const Text("Location"),
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cleanCity),
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.chevron_forward,
                          size: 18,
                        ),
                      ],
                    ),
                    onPressed: () {
                      final controller = TextEditingController(text: cleanCity);

                      showCupertinoDialog(
                        context: context,
                        builder: (context) {
                          return CupertinoAlertDialog(
                            title: const Text("City"),
                            content: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: CupertinoTextField(
                                controller: controller,
                                placeholder: "Enter city",
                              ),
                            ),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text("Save"),
                                onPressed: () {
                                  final newCity = controller.text.trim();
                                  if (newCity.isEmpty) return;

                                  ref
                                      .read(cityProvider.notifier)
                                      .state = newCity;

                                  Navigator.pop(context);
                                },
                              ),
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                child: const Text("Cancel"),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),

                CupertinoListTile(
                  leading: _iconBox(
                    CupertinoIcons.thermometer,
                    CupertinoColors.systemPurple,
                  ),
                  title: const Text("Metrics"),
                  trailing: CupertinoSegmentedControl<bool>(
                    groupValue: isCelsius,
                    children: const {
                      true: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text("°C"),
                      ),
                      false: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text("°F"),
                      ),
                    },
                    onValueChanged: (value) {
                      ref.read(isCelsiusProvider.notifier).state = value;
                    },
                  ),
                ),

                CupertinoListTile(
                  leading: _iconBox(
                    CupertinoIcons.bell,
                    CupertinoColors.systemMint,
                  ),
                  title: const Text("Notifications"),
                  trailing: Text(
                    useCurrentLocation ? "Current Location" : cleanCity, // Using trimmed city name
                    style: const TextStyle(
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                  onTap: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) {
                        return CupertinoAlertDialog(
                          title: const Text("Notification"),
                          content: const Text(
                            "Weather will send you a notification when the weather changes.",
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text("Use Current Location"),
                              onPressed: () {
                                ref
                                    .read(
                                    useCurrentLocationProvider.notifier)
                                    .state = true;

                                Navigator.pop(context);
                              },
                            ),
                            CupertinoDialogAction(
                              child: const Text("Turn Off"),
                              onPressed: () {
                                ref
                                    .read(
                                    useCurrentLocationProvider.notifier)
                                    .state = false;

                                Navigator.pop(context);
                              },
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text("Cancel"),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _iconBox(IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Icon(
      icon,
      size: 16,
      color: CupertinoColors.white,
    ),
  );
}