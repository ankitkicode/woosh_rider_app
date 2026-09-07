import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'socket_service.dart';

/// Called in the foreground service isolate — must be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_LocationTaskHandler());
}

class _LocationTaskHandler extends TaskHandler {
  String? _riderId;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _riderId = await FlutterForegroundTask.getData<String>(key: 'riderId');
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (_riderId != null) {
        SocketService().emitLocationUpdate(
          _riderId!,
          position.latitude,
          position.longitude,
        );
      }
    } catch (_) {
      // GPS temporarily unavailable — skip this interval
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Public API used by driver_home_view.dart
class LocationForegroundService {
  LocationForegroundService._();

  /// Call once at app startup (e.g. in main.dart or initState).
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'woosh_location_channel',
        channelName: 'Woosh Queens — Location Tracking',
        channelDescription:
            'Shows while you are online and receiving ride requests.',
        // DEFAULT importance ensures the notification is visible in the
        // status bar and not silently hidden like LOW can be on some devices.
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
        // Show notification icon in the status bar
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(10000), // every 10 seconds
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  /// Request location + notification permissions and start the foreground service.
  /// Returns false if a required permission is denied.
  static Future<bool> start(String riderId) async {
    // 1. Request POST_NOTIFICATIONS (Android 13+) — flutter_foreground_task
    //    handles this via its own permission helper on v9.
    final notifPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notifPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
      // Re-check after request
      final result = await FlutterForegroundTask.checkNotificationPermission();
      if (result != NotificationPermission.granted) {
        // Notification denied — we can still run but notification won't show.
        // Don't block going online; just continue.
      }
    }

    // 2. Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    // 3. Check location service enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    // 4. Pass riderId into the task isolate
    await FlutterForegroundTask.saveData(key: 'riderId', value: riderId);

    // 5. Start or restart the foreground service
    final isRunning = await FlutterForegroundTask.isRunningService;
    final result = isRunning
        ? await FlutterForegroundTask.restartService()
        : await FlutterForegroundTask.startService(
            serviceId: 1001,
            notificationTitle: 'Woosh Queens',
            notificationText: 'You are online — looking for ride requests',
            callback: startCallback,
          );

    return result is ServiceRequestSuccess;
  }

  /// Stop the foreground service.
  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }

  /// Whether the foreground service is currently running.
  static Future<bool> get isRunning => FlutterForegroundTask.isRunningService;
}
