import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<void> requestInitialPermissions() async {
    await [
      Permission.location,
      Permission.notification,
    ].request();
  }
}
