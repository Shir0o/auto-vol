import 'package:flutter_volume_controller/flutter_volume_controller.dart';

class VolumeService {
  Future<void> setVolume(double volume) async {
    await FlutterVolumeController.setVolume(volume);
  }

  Future<double?> getVolume() async {
    return await FlutterVolumeController.getVolume();
  }
}
