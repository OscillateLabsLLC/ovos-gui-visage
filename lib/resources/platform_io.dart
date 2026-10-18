import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../faults.dart';
import 'data_image.dart';
import 'locate.dart';

final cacheRoot = Directory('${Platform.environment['HOME']}/.cache/ovos_gui');

File? fileFor(Resource resource) => switch (resource.kind) {
  ResourceKind.cache => File('${cacheRoot.path}/${resource.value}'),
  ResourceKind.absolute => File(resource.value),
  _ => null,
};

Widget? imageFor(String? value, {BoxFit fit = BoxFit.contain, Widget? broken}) {
  final resource = locate(value);
  Widget onError(BuildContext context, Object error, StackTrace? stack) {
    reportFault('decoding image $value', error, stack);
    return broken ?? const SizedBox.shrink();
  }

  switch (resource.kind) {
    case ResourceKind.none:
      return null;
    case ResourceKind.data:
      return resource.isImage ? dataImage(resource.value, fit) : null;
    case ResourceKind.http:
      return Image.network(resource.value, fit: fit, errorBuilder: onError);
    case ResourceKind.cache:
    case ResourceKind.absolute:
      final file = fileFor(resource)!;
      if (!resource.isImage) return null;
      if (!file.existsSync()) {
        reportFault('image $value', StateError('no such file ${file.path}'));
        return null;
      }
      return resource.suffix == '.svg' ? SvgPicture.file(file, fit: fit) : Image.file(file, fit: fit, errorBuilder: onError);
  }
}

Future<Uint8List> readResource(String value) {
  final file = fileFor(locate(value));
  if (file == null) throw ArgumentError.value(value, 'value', 'not a cache or host path');
  return file.readAsBytes();
}
