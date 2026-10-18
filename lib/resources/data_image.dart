import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The image in a `data:image/...` URI, base64 or percent-encoded.
Widget? dataImage(String src, BoxFit fit) {
  final comma = src.indexOf(',');
  if (comma < 0) return null;
  final header = src.substring(0, comma);
  final payload = src.substring(comma + 1);
  final bytes = header.endsWith(';base64') ? base64.decode(payload) : utf8.encode(Uri.decodeComponent(payload));
  if (header.startsWith('data:image/svg+xml')) return SvgPicture.string(utf8.decode(bytes), fit: fit);
  return Image.memory(bytes, fit: fit);
}
