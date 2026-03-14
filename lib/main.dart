import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'homepage.dart';
import 'variable.dart';
import 'settings.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool darkMode = ref.watch(darkModeProvider);

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: darkMode ? Brightness.dark : Brightness.light,
        primaryColor: CupertinoColors.systemBlue,
      ),
      home: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.settings),
              label: "Settings",
            ),
          ],
        ),
        tabBuilder: (context, index) {
          if (index == 0) {
            return const Homepage();
          } else {
            return const Settings();
          }
        },
      ),
    );
  }
}