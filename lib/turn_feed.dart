/// Feeds the core bus events of a voice turn to the models that follow it (captions, outcome). Read from the core bus
/// rather than ovos-gui's forwarded events, since ovos-gui does not forward every one of them.
library;

import 'protocol/core_bus.dart';

typedef TurnSink = void Function(String event, Json data);

/// Subscribes once per event type and hands each message to every sink that asked for it.
void bindTurnFeed(CoreBus bus, Map<TurnSink, List<String>> sinks) {
  final byEvent = <String, List<TurnSink>>{};
  sinks.forEach((sink, events) {
    for (final event in events) {
      byEvent.putIfAbsent(event, () => []).add(sink);
    }
  });
  byEvent.forEach((event, targets) {
    bus.on(event, (message) {
      final data = (message['data'] ?? <String, dynamic>{}) as Json;
      for (final sink in targets) {
        sink(event, data);
      }
    });
  });
}
