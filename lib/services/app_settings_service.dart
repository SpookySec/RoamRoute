import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool darkMode;
  final bool notificationsEnabled;
  final bool autoBackupEnabled;
  final bool offlineMapsEnabled;
  final String distanceUnit;
  final bool seenHomeOnboarding;

  const AppSettings({
    required this.darkMode,
    required this.notificationsEnabled,
    required this.autoBackupEnabled,
    required this.offlineMapsEnabled,
    required this.distanceUnit,
    required this.seenHomeOnboarding,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      darkMode: false,
      notificationsEnabled: true,
      autoBackupEnabled: true,
      offlineMapsEnabled: false,
      distanceUnit: 'Kilometers',
      seenHomeOnboarding: false,
    );
  }

  AppSettings copyWith({
    bool? darkMode,
    bool? notificationsEnabled,
    bool? autoBackupEnabled,
    bool? offlineMapsEnabled,
    String? distanceUnit,
    bool? seenHomeOnboarding,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      offlineMapsEnabled: offlineMapsEnabled ?? this.offlineMapsEnabled,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      seenHomeOnboarding: seenHomeOnboarding ?? this.seenHomeOnboarding,
    );
  }
}

class AppSettingsService {
  static const _kDarkMode = 'settings.darkMode';
  static const _kNotifications = 'settings.notifications';
  static const _kAutoBackup = 'settings.autoBackup';
  static const _kOfflineMaps = 'settings.offlineMaps';
  static const _kDistanceUnit = 'settings.distanceUnit';
  static const _kSeenOnboarding = 'settings.seenOnboarding';

  static Future<AppSettings> load() async {
    final defaults = AppSettings.defaults();

    try {
      final prefs = await SharedPreferences.getInstance();
      return AppSettings(
        darkMode: prefs.getBool(_kDarkMode) ?? defaults.darkMode,
        notificationsEnabled:
            prefs.getBool(_kNotifications) ?? defaults.notificationsEnabled,
        autoBackupEnabled:
            prefs.getBool(_kAutoBackup) ?? defaults.autoBackupEnabled,
        offlineMapsEnabled:
            prefs.getBool(_kOfflineMaps) ?? defaults.offlineMapsEnabled,
        distanceUnit: prefs.getString(_kDistanceUnit) ?? defaults.distanceUnit,
        seenHomeOnboarding:
            prefs.getBool(_kSeenOnboarding) ?? defaults.seenHomeOnboarding,
      );
    } on PlatformException catch (error) {
      debugPrint('SharedPreferences unavailable during load: $error');
      return defaults;
    } on MissingPluginException catch (error) {
      debugPrint('SharedPreferences plugin missing during load: $error');
      return defaults;
    }
  }

  static Future<void> save(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDarkMode, settings.darkMode);
      await prefs.setBool(_kNotifications, settings.notificationsEnabled);
      await prefs.setBool(_kAutoBackup, settings.autoBackupEnabled);
      await prefs.setBool(_kOfflineMaps, settings.offlineMapsEnabled);
      await prefs.setString(_kDistanceUnit, settings.distanceUnit);
      await prefs.setBool(_kSeenOnboarding, settings.seenHomeOnboarding);
    } on PlatformException catch (error) {
      debugPrint('SharedPreferences unavailable during save: $error');
    } on MissingPluginException catch (error) {
      debugPrint('SharedPreferences plugin missing during save: $error');
    }
  }
}
