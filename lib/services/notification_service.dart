import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import '../models/task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    await _requestPermissions();

    _isInitialized = true;
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Check if exact alarm permission is granted (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    
    // For Android 12 (API 31) and above, check scheduleExactAlarm permission
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }

  // Request exact alarm permission by opening app settings
  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    
    final status = await Permission.scheduleExactAlarm.status;
    
    if (status.isGranted) {
      return true;
    }
    
    // Open app settings to allow user to enable exact alarms
    return await openAppSettings();
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation based on payload
    final payload = response.payload;
    if (payload != null) {
      // Navigate to task details or relevant screen
      print('Notification tapped with payload: $payload');
    }
  }

  // Schedule a notification for a task due date
  Future<void> scheduleDueDateNotification(TaskModel task) async {
    if (!_isInitialized) await initialize();

    // Check if exact alarm permission is granted
    if (!await canScheduleExactAlarms()) {
      print('Exact alarms permission not granted. Please enable it in settings.');
      return;
    }

    final scheduledDate = tz.TZDateTime.from(task.dueDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'task_due_channel',
      'Task Due Notifications',
      channelDescription: 'Notifications for task due dates',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      task.id.hashCode, // Unique notification ID
      'Task Due: ${task.taskName}',
      task.description,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );
  }

  // Schedule a custom reminder notification
  Future<void> scheduleReminderNotification(TaskModel task) async {
    if (!_isInitialized) await initialize();
    if (task.reminderTime == null) return;

    // Check if exact alarm permission is granted
    if (!await canScheduleExactAlarms()) {
      print('Exact alarms permission not granted. Please enable it in settings.');
      return;
    }

    final scheduledDate = tz.TZDateTime.from(task.reminderTime!, tz.local);

    // Don't schedule if the reminder time has passed
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'task_reminder_channel',
      'Task Reminders',
      channelDescription: 'Custom reminder notifications for tasks',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      '${task.id}_reminder'.hashCode, // Unique notification ID for reminder
      'Reminder: ${task.taskName}',
      'Upcoming task: ${task.description}',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );
  }

  // Cancel a specific task notification
  Future<void> cancelTaskNotification(String taskId) async {
    await _notifications.cancel(taskId.hashCode);
    await _notifications.cancel('${taskId}_reminder'.hashCode);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Show an immediate notification
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'immediate_channel',
      'Immediate Notifications',
      channelDescription: 'Immediate task notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Reschedule all task notifications
  Future<void> rescheduleAllNotifications(List<TaskModel> tasks) async {
    await cancelAllNotifications();
    
    for (final task in tasks) {
      if (task.status != TaskStatus.done) {
        // Only schedule for incomplete tasks
        if (task.dueDate.isAfter(DateTime.now())) {
          await scheduleDueDateNotification(task);
        }
        
        if (task.reminderTime != null && task.reminderTime!.isAfter(DateTime.now())) {
          await scheduleReminderNotification(task);
        }
      }
    }
  }
}
