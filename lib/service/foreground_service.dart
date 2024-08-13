// // @dart = 2.9

// import 'dart:async';
// import 'dart:isolate';

// import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// class ForegroundTaskService {
//   static init() {
//     FlutterForegroundTask.init(
//       androidNotificationOptions: AndroidNotificationOptions(
//         channelId: 'foreground_service',
//         channelName: 'Foreground Service Notification',
//         channelDescription:
//             'This notification appears when the foreground service is running.',
//         channelImportance: NotificationChannelImportance.LOW,
//         priority: NotificationPriority.LOW,
//         iconData: const NotificationIconData(
//           resType: ResourceType.mipmap,
//           resPrefix: ResourcePrefix.ic,
//           name: 'launcher',
//         ),
//       ),
//       iosNotificationOptions: const IOSNotificationOptions(
//         showNotification: true,
//         playSound: false,
//       ),
//       foregroundTaskOptions: const ForegroundTaskOptions(
//         isOnceEvent: true,
//       ),
//     );
//   }
// }

// @pragma(
//     'vm:entry-point') // This decorator means that this function calls native code
// void startCallback() {
//   FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
// }

// class FirstTaskHandler extends TaskHandler {
//   SendPort sendPortResult;
//   Timer _timer;
//   int _eventCount = 0;

//   @override
//   Future<void> onDestroy(DateTime timestamp, SendPort sendPort) {
//     _timer.cancel();
//     FlutterForegroundTask.stopService();
//   }

//   @override
//   Future<void> onEvent(DateTime timestamp, SendPort sendPort) {
//     // FlutterForegroundTask.updateService(
//     //   notificationTitle: 'MyTaskHandler',
//     //   notificationText: 'eventCount: $_eventCount',
//     // );

//     // // Send data to the main isolate.
//     // sendPort?.send(_eventCount);

//     // _eventCount++;
//     sendPort.send("startTask");
//   }

//   @override
//   Future<void> onStart(DateTime timestamp, SendPort sendPort) {
//     sendPortResult =
//         sendPort; // This is used for communicating between our service and our app
//     sendPort.send("startTask");
//   }

//   @override
//   void onButtonPressed(String id) {
//     sendPortResult.send("killTask");
//   }

//   @override
//   void onNotificationPressed() {
//     _timer?.cancel();
//     sendPortResult.send('onNotificationPressed');
//     FlutterForegroundTask.stopService();
//   }
// }

// // class FirstTaskHandler extends TaskHandler {
// //   SendPort? _sendPort;
  
// //   // Called when the task is started.
// //   @override
// //   void onStart(DateTime timestamp, SendPort? sendPort) async {
// //     _sendPort = sendPort; // This is used for communicating between our service and our app
// //    sendPort?.send("startTask");
// //   }

// //   // Called every [interval] milliseconds in [ForegroundTaskOptions].
// //   @override
// //   void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
// //     // Send data to the main isolate.

// //   }

// //   // Called when the notification button on the Android platform is pressed.
// //   @override
// //   void onDestroy(DateTime timestamp, SendPort? sendPort) async {
// //     _timer?.cancel();
// //     FlutterForegroundTask.stopService();
// //   }

// //   // Called when the notification button on the Android platform is pressed.
// //   @override
// //   void onNotificationButtonPressed(String id) {
// //     _sendPort?.send("killTask");  
// // }

// //   // Called when the notification itself on the Android platform is pressed.
// //   //
// //   // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
// //   // this function to be called.
// //   @override
// //   void onNotificationPressed() {
// //     _timer?.cancel();
// //     _sendPort?.send('onNotificationPressed');
// //     FlutterForegroundTask.stopService();
// //   }
// // }