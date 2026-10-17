/// Lottie helpers that read the animation JSON (port of lottie.js liveSegment). Pure.
library;

/// End of a one-shot segment: the last frame with a live layer. OVOS's status-fail.json runs five frames past its
/// layers (op 45, every layer op 40), an empty outro for looping that would otherwise be the frame we hold.
({double start, double end}) liveSegment(Map<String, dynamic> data) {
  final ip = (data['ip'] as num).toDouble();
  final op = (data['op'] as num).toDouble();
  var layerEnd = ip;
  for (final layer in (data['layers'] as List? ?? const [])) {
    final layerOp = ((layer as Map)['op'] as num?)?.toDouble() ?? op;
    if (layerOp > layerEnd) layerEnd = layerOp;
  }
  return (start: ip, end: op < layerEnd ? op : layerEnd);
}
