import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'variable.dart';

class Settings extends ConsumerWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);
    final city = ref.watch(cityProvider);
    final isCelsius = ref.watch(isCelsiusProvider);
    final useCurrentLocation = ref.watch(useCurrentLocationProvider);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  leading: _iconBox(CupertinoIcons.moon_fill, CupertinoColors.systemBlue),
                  title: Text("Dark Mode"),
                  trailing: CupertinoSwitch(
                    value: darkMode,
                    onChanged: (value) {
                      ref.read(darkModeProvider.notifier).state = value;
                    },
                  ),
                ),
                CupertinoListTile(
                  leading: _iconBox(CupertinoIcons.location_fill, CupertinoColors.systemGreen),
                  title: Text("Location"),
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Row(
                      children: [
                        Text(city),
                        Icon(CupertinoIcons.chevron_forward, size: 18),
                      ],
                    ),
                    onPressed: () {
                      final controller = TextEditingController(text: city);
                      showCupertinoDialog(
                        context: context,
                        builder: (context) {
                          return CupertinoAlertDialog(
                            title: Text("City"),
                            content: CupertinoTextField(
                              controller: controller,
                              placeholder: "Enter city",
                            ),
                            actions: [
                              CupertinoDialogAction(
                                child: Text("Save"),
                                onPressed: () {
                                  final newCity = controller.text.trim();
                                  if (newCity.isEmpty) return;

                                  // Update Riverpod provider
                                  ref.read(cityProvider.notifier).state = newCity;

                                  Navigator.pop(context);
                                },
                              ),
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                child: Text("Cancel"),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                // Metrics
                CupertinoListTile(
                  leading: _iconBox(CupertinoIcons.thermometer, CupertinoColors.systemPurple),
                  title: Text("Metrics"),
                  trailing: CupertinoSegmentedControl<bool>(
                    groupValue: isCelsius,
                    children: {
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
                  leading: _iconBox(CupertinoIcons.bell, CupertinoColors.systemMint),
                  title: Text("Notifications"),
                  trailing: Text(
                    useCurrentLocation ? "Current Location" : city,
                    style: TextStyle(color: CupertinoColors.systemBlue),
                  ),
                  onTap: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) {
                        return CupertinoAlertDialog(
                          title: Text("Notification"),
                          content: Text(
                            "Weather will send you a notification when the weather changes.",
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: Text("Use Current Location"),
                              onPressed: () {
                                ref.read(useCurrentLocationProvider.notifier).state = true;
                                Navigator.pop(context);
                              },
                            ),
                            CupertinoDialogAction(
                              child: Text("Turn Off"),
                              onPressed: () {
                                ref.read(useCurrentLocationProvider.notifier).state = false;
                                Navigator.pop(context);
                              },
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: Text("Cancel"),
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
    padding: EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Icon(icon, size: 16, color: CupertinoColors.white),
  );
}