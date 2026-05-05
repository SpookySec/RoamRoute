import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/trips_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_settings_service.dart';
import 'theme/duo_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const TravelPlannerApp());
}

class TravelPlannerApp extends StatefulWidget {
  const TravelPlannerApp({Key? key}) : super(key: key);

  @override
  State<TravelPlannerApp> createState() => _TravelPlannerAppState();
}

class _TravelPlannerAppState extends State<TravelPlannerApp> {
  AppSettings _settings = AppSettings.defaults();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AppSettingsService.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _ready = true;
    });
  }

  Future<void> _updateSettings(AppSettings nextSettings) async {
    setState(() {
      _settings = nextSettings;
    });
    await AppSettingsService.save(nextSettings);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        title: 'Roam Route',
        debugShowCheckedModeBanner: false,
        theme: DuoTheme.lightTheme,
        home: const Scaffold(body: Center(child: CircularProgressIndicator(color: DuoColors.duoGreen))),
      );
    }

    return MaterialApp(
      title: 'Roam Route',
      theme: DuoTheme.lightTheme,
      darkTheme: DuoTheme.darkTheme,
      themeMode: _settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: AppShell(settings: _settings, onSettingsChanged: _updateSettings),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  const AppShell({
    Key? key,
    required this.settings,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const ProfileScreen(),
      TripsListScreen(
        showOnboardingTip: !widget.settings.seenHomeOnboarding,
        onOnboardingDismissed: () {
          widget.onSettingsChanged(
            widget.settings.copyWith(seenHomeOnboarding: true),
          );
        },
      ),
      SettingsScreen(
        settings: widget.settings,
        onSettingsChanged: widget.onSettingsChanged,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? DuoColors.duoCardBorderDark 
                  : DuoColors.duoCardBorder,
              width: 2,
            ),
          ),
        ),
        child: NavigationBar(
          height: 70,
          elevation: 0,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'PROFILE',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'HOME',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}
