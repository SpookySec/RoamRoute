import 'package:flutter/services.dart';

class DuoSoundService {
  static Future<void> playClick() async {
    // Using system click sounds as a baseline for "tactile" feedback without extra assets
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.lightImpact();
  }

  static Future<void> playSuccess() async {
    await HapticFeedback.mediumImpact();
    // In a real app with assets, we'd play a "tada" sound here
  }
}
