import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:do_not_disturb/do_not_disturb.dart';
import 'dart:io';

enum VolumeStream { media, ringer, notification }

class VolumeService {
  final _dndPlugin = DoNotDisturbPlugin();

  Future<void> setVolume(
    double volume, {
    VolumeStream stream = VolumeStream.media,
  }) async {
    final audioStream = _mapStream(stream);
    await FlutterVolumeController.setVolume(volume, stream: audioStream);
  }

  Future<double?> getVolume({VolumeStream stream = VolumeStream.media}) async {
    final audioStream = _mapStream(stream);
    return await FlutterVolumeController.getVolume(stream: audioStream);
  }

  Future<void> setDndMode(bool enabled) async {
    if (!Platform.isAndroid) return;

    if (enabled) {
      await _dndPlugin.setInterruptionFilter(InterruptionFilter.none);
    } else {
      await _dndPlugin.setInterruptionFilter(InterruptionFilter.all);
    }
  }

  Future<bool> isDndEnabled() async {
    if (!Platform.isAndroid) return false;
    final filter = await _dndPlugin.getDNDStatus();
    return filter != InterruptionFilter.all &&
        filter != InterruptionFilter.unknown;
  }

  AudioStream _mapStream(VolumeStream stream) {
    switch (stream) {
      case VolumeStream.media:
        return AudioStream.music;
      case VolumeStream.ringer:
        return AudioStream.ring;
      case VolumeStream.notification:
        return AudioStream.notification;
    }
  }
}
