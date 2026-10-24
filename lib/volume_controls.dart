/// What Visage sends to change the volume: only the scale-free requests both volume plugins handle, with no data, so
/// each plugin steps by its own interval (ALSA 10 %, Mac `volume_change_interval`). `mycroft.volume.set` is left out:
/// the ALSA plugin, the volume skill and ovos-shell send `percent` as a fraction, ovos-phal-plugin-mac reads it as a
/// whole percent, so one value cannot be right on both.
library;

import 'faults.dart';
import 'protocol/core_bus.dart';
import 'timers.dart';
import 'volume.dart';
import 'window/peek.dart';

const volumeGetEvent = 'mycroft.volume.get';
const volumeHold = 'volume';

enum VolumeAction {
  up('mycroft.volume.increase'),
  down('mycroft.volume.decrease'),
  toggleMute('mycroft.volume.mute.toggle');

  const VolumeAction(this.event);

  final String event;
}

class VolumeControls {
  VolumeControls(this.bus);

  final CoreBus bus;

  void act(VolumeAction action) {
    if (!bus.emit(action.event)) {
      reportFault('volume ${action.name}', StateError('could not send ${action.event}: the core bus is not connected'));
    }
  }

  bool askLevel() => bus.emit(volumeGetEvent);
}

/// The app's volume: the model the frame and the menu read, the controls the menu and the keys act through, and a
/// peeking widget kept open while a change shows.
class ScreenVolume {
  ScreenVolume({required CoreBus bus, required PeekController peek, OneShot? timer}) : controls = VolumeControls(bus) {
    model = VolumeModel(ask: controls.askLevel, timer: timer)..addListener(() => peek.hold(model.showing, by: volumeHold));
  }

  final VolumeControls controls;
  late final VolumeModel model;

  void dispose() => model.dispose();
}
