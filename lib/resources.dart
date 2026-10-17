/// Images named in session data, on a same-host display (SCOPE: no middle layer). A value is a `data:` URI, an
/// http(s) URL, or a file path; paths are read directly, since they come from skills over the GUI socket, the same
/// trust boundary ovos-visage's seen-image registry drew. Only image suffixes are loaded.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const imageSuffixes = {'.svg', '.png', '.jpg', '.jpeg', '.gif', '.webp'};
const _fileScheme = 'file://';
final cacheRoot = Directory('${Platform.environment['HOME']}/.cache/ovos_gui');

/// Path of the ovos-gui cache file for a `/res/...` URL (what the Python middle layer would have served).
File cacheFile(String resUrl) => File('${cacheRoot.path}/${resUrl.substring('/res/'.length)}');

/// A widget for the image, or null when the value is not something this display can load. [broken] is shown in
/// place of a network or file image that fails to decode.
Widget? imageFor(String? value, {BoxFit fit = BoxFit.contain, Widget? broken}) {
  final src = (value ?? '').trim();
  if (src.isEmpty) return null;
  Widget onError(BuildContext context, Object error, StackTrace? stack) => broken ?? const SizedBox.shrink();
  if (src.startsWith('data:image/')) return _dataImage(src, fit);
  if (src.startsWith('http://') || src.startsWith('https://')) return Image.network(src, fit: fit, errorBuilder: onError);
  final path = src.startsWith('/res/') ? cacheFile(src).path : src.replaceFirst(_fileScheme, '');
  if (!path.startsWith('/')) return null;
  final file = File(path);
  final dot = path.lastIndexOf('.');
  final suffix = dot < 0 ? '' : path.substring(dot).toLowerCase();
  if (!imageSuffixes.contains(suffix) || !file.existsSync()) return null;
  return suffix == '.svg' ? SvgPicture.file(file, fit: fit) : Image.file(file, fit: fit, errorBuilder: onError);
}

Widget? _dataImage(String src, BoxFit fit) {
  final comma = src.indexOf(',');
  if (comma < 0) return null;
  final header = src.substring(0, comma);
  final payload = src.substring(comma + 1);
  final bytes = header.endsWith(';base64') ? base64.decode(payload) : utf8.encode(Uri.decodeComponent(payload));
  if (header.startsWith('data:image/svg+xml')) return SvgPicture.string(utf8.decode(bytes), fit: fit);
  return Image.memory(bytes, fit: fit);
}

/// A bundled icon from assets/icons (the ovos-visage icon set with its CSS animation stripped; motion is a widget).
Widget icon(String name, {double size = 64}) => SvgPicture.asset('assets/icons/$name.svg', width: size, height: size);
