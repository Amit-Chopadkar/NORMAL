import 'package:vibration/vibration.dart';

class NotificationService {
  // Vibrate with pattern based on alert type
  static Future<void> vibrate(int pattern) async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) return;

    switch (pattern) {
      case 3: // Danger - 3 strong pulses
        await Vibration.vibrate(
          pattern: [0, 500, 200, 500, 200, 500],
          intensities: [0, 255, 0, 255, 0, 255],
        );
        break;
      case 2: // Caution - 2 medium pulses
        await Vibration.vibrate(
          pattern: [0, 300, 200, 300],
          intensities: [0, 200, 0, 200],
        );
        break;
      case 1: // Safe or approaching - 1 light pulse
        await Vibration.vibrate(
          duration: 200,
          amplitude: 128,
        );
        break;
      default:
        await Vibration.vibrate(duration: 200);
    }
  }

  // Cancel any ongoing vibration
  static Future<void> cancel() async {
    await Vibration.cancel();
  }
}
