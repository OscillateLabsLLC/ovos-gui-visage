/// The face over the bus: anyone on the OVOS messagebus can read and change it, which is how the picker page and a
/// voice skill drive it without touching the display. Client-only message names; nothing in OVOS sends them.
///
/// - `visage.face.set` with any of `preset`, `eyes`, `mouth`, `mouthSize`, `backdrop` changes those parts.
/// - `visage.face.get` asks for the state.
/// - `visage.face.state` is the answer to both and to every change: the spec, its preset name if it has one, and the
///   names available for each part.
library;

import 'dart:async';

import '../faults.dart';
import '../protocol/core_bus.dart';
import 'face.dart';
import 'face_spec.dart';
import 'styles.dart';

const faceSetMessage = 'visage.face.set';
const faceGetMessage = 'visage.face.get';
const faceStateMessage = 'visage.face.state';

typedef FacePersist = Future<void> Function(FaceSpec spec);

class FaceRemote {
  FaceRemote(this.bus, this.controller, {required FaceSpec initial, required this.persist, this.log}) : _spec = initial {
    bus.on(faceSetMessage, _onSet);
    bus.on(faceGetMessage, (_) => announce());
    unawaited(bus.whenConnected.then((_) => announce()));
  }

  final CoreBus bus;
  final FaceController controller;
  final FacePersist persist;
  final void Function(String)? log;
  FaceSpec _spec;

  FaceSpec get spec => _spec;

  void _onSet(Json message) {
    final data = message['data'];
    if (data is! Map) {
      reportFault('$faceSetMessage without an object payload', FormatException('$message'));
      return;
    }
    apply(_spec.merge(data));
  }

  /// Shows [next], remembers it for the next start, and tells the bus.
  void apply(FaceSpec next) {
    _spec = next;
    controller.theme = next.theme();
    log?.call('face is now $next');
    persist(next).catchError((Object err, StackTrace stack) => reportFault('saving the face to the config file', err, stack));
    announce();
  }

  void announce() => bus.emit(faceStateMessage, state());

  Json state() => {
    ..._spec.toJson(),
    'preset': _spec.presetName,
    'available': {
      'eyes': eyeStyles.keys.toList(),
      'mouth': mouthStyles.keys.toList(),
      'mouthSize': mouthSizes.keys.toList(),
      'backdrop': backdrops.keys.toList(),
      'preset': facePresets.keys.toList(),
    },
  };
}
