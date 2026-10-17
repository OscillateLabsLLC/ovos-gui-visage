// Spike: negotiate the GUI socket against a live ovos-gui and print what arrives for a few seconds.
// dart run tool/connect_spike.dart [seconds]
import 'dart:async';
import 'dart:io';

import 'package:ovos_gui_visage/protocol/core_bus.dart';
import 'package:ovos_gui_visage/protocol/gui_client.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

Future<void> main(List<String> args) async {
  final seconds = args.isEmpty ? 6 : int.parse(args.first);
  final state = GuiState();
  final bus = CoreBus(log: (line) => stderr.writeln('[bus] $line'));
  var pages = 0;
  late GuiClient gui;
  gui = GuiClient(
    bus: bus,
    guiId: 'visage-spike-${DateTime.now().millisecondsSinceEpoch % 100000}',
    log: (line) => stderr.writeln('[gui] $line'),
    onStatus: (up) {
      stderr.writeln('[gui] ${up ? "connected" : "disconnected"}; clearing state');
      state.reset();
    },
    onMessage: (message) {
      if (!state.apply(message)) stderr.writeln('[gui] unknown/malformed: $message');
      if (message['type'] == 'mycroft.gui.list.insert') {
        pages++;
        stdout.writeln('page insert ns=${message['namespace']} data=${message['data']}');
        final target = state.current();
        if (target != null) gui.send(focusMessage(target.namespace, target.index));
      }
    },
  );
  bus.start();
  gui.start();
  await Future.delayed(Duration(seconds: seconds));
  stdout.writeln('current=${state.current()} active=${state.active} pageInserts=$pages');
  await gui.stop();
  await bus.stop();
  exit(0);
}
