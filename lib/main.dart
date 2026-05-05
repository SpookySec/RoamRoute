import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/trips_list_screen.dart';
import 'services/app_settings_service.dart';

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
        title: 'Travel Planner',
        debugShowCheckedModeBanner: false,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'Travel Planner',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 28, child: Icon(Icons.person, size: 28)),
                SizedBox(height: 12),
                Text(
                  'Traveler',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Build your next adventure route',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  const SettingsScreen({
    Key? key,
    required this.settings,
    required this.onSettingsChanged,
  }) : super(key: key);

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Travel Planner',
      applicationVersion: '1.0.0',
      applicationLegalese: 'School Project 2026',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use a darker appearance'),
                    value: settings.darkMode,
                    onChanged: (value) {
                      onSettingsChanged(settings.copyWith(darkMode: value));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Trip Notifications'),
                    subtitle: const Text(
                      'Receive reminders for upcoming trips',
                    ),
                    value: settings.notificationsEnabled,
                    onChanged: (value) {
                      onSettingsChanged(
                        settings.copyWith(notificationsEnabled: value),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Auto Backup'),
                    subtitle: const Text('Back up trips automatically'),
                    value: settings.autoBackupEnabled,
                    onChanged: (value) {
                      onSettingsChanged(
                        settings.copyWith(autoBackupEnabled: value),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Offline Maps Cache'),
                    subtitle: const Text('Save map tiles for recent trips'),
                    value: settings.offlineMapsEnabled,
                    onChanged: (value) {
                      onSettingsChanged(
                        settings.copyWith(offlineMapsEnabled: value),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Distance Unit'),
                    subtitle: Text(settings.distanceUnit),
                    trailing: DropdownButton<String>(
                      value: settings.distanceUnit,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: 'Kilometers',
                          child: Text('Kilometers'),
                        ),
                        DropdownMenuItem(value: 'Miles', child: Text('Miles')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        onSettingsChanged(
                          settings.copyWith(distanceUnit: value),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAbout(context),
                icon: const Icon(Icons.info_outline),
                label: const Text('About'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
