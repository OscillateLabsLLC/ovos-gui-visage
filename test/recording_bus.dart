import 'package:ovos_gui_visage/protocol/core_bus.dart';

/// A bus that records what is emitted and lets a test deliver messages to the handlers, without a socket.
class RecordingBus extends CoreBus {
  final Map<String, BusHandler> handlers = {};

  /// [type, data] pairs; lists so the matchers compare them structurally (records would compare maps by identity).
  final List<List<Object?>> emitted = [];

  List<String> get types => [for (final e in emitted) e[0] as String];

  Json? data(int index) => emitted[index][1] as Json?;

  @override
  void on(String type, BusHandler handler) => handlers[type] = handler;

  /// The extra context of each [emitWithContext] call, in order.
  final List<Json> contexts = [];

  @override
  bool emit(String type, [Json? data]) {
    emitted.add([type, data]);
    return true;
  }

  @override
  bool emitWithContext(String type, Json data, Json context) {
    contexts.add(context);
    return emit(type, data);
  }

  void send(String type, [Json? data]) => handlers[type]!({'type': type, 'data': data ?? {}});
}
