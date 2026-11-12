import 'package:permission_handler/permission_handler.dart';

class MicrophonePermission {
  static Future<bool> request() async {
    return (await Permission.microphone.request()).isGranted;
  }
}
