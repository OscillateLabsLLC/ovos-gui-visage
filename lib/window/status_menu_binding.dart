import 'package:flutter/foundation.dart';

import '../face/face.dart';
import '../face/face_remote.dart';
import '../volume.dart';
import '../volume_controls.dart';
import 'status_menu.dart';
import 'window_remote.dart';

/// The status menu over the app's state: it reads the window, the face and the volume, rebuilds whenever one changes,
/// and acts through the same remotes the bus uses, so the menu and `visage.*` messages always agree.
StatusMenuController bindStatusMenu({
  required FaceRemote face,
  required FaceController faceController,
  required WindowRemote window,
  required VolumeModel volume,
  required VolumeControls volumeControls,
  required void Function(List<MenuEntry> items) show,
  required VoidCallback typeCommand,
  required VoidCallback quit,
}) => StatusMenuController(
  changes: Listenable.merge([faceController, window, volume]),
  read: () => StatusMenuState(
    mode: window.config.mode,
    peek: window.config.peek,
    visible: window.visible,
    face: face.spec,
    volume: volume.level,
    muted: volume.muted,
  ),
  show: show,
  actions: StatusMenuActions(
    typeCommand: typeCommand,
    toggleVisible: () => window.setVisible(!window.visible),
    togglePeek: () => window.setPeek(!window.config.peek),
    setMode: window.setMode,
    toggleKiosk: window.toggleKiosk,
    applyPreset: (name) => face.apply(face.spec.merge({'preset': name})),
    applyColours: (name) => face.apply(face.spec.merge({'colours': name})),
    openPicker: face.openPicker,
    volume: volumeControls.act,
    quit: quit,
  ),
);
