import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../faults.dart';
import 'data_image.dart';
import 'locate.dart';

/// The sidecar's routes, relative to the page so the app can live under any prefix.
const cacheRoute = 'res/';
const hostRoute = 'res-abs';

String? routeFor(Resource resource) => switch (resource.kind) {
  ResourceKind.cache => '$cacheRoute${resource.value}',
  ResourceKind.absolute => '$hostRoute${resource.value}',
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
      if (!resource.isImage) return null;
      final url = Uri.base.resolve(routeFor(resource)!).toString();
      return resource.suffix == '.svg' ? SvgPicture.network(url, fit: fit) : Image.network(url, fit: fit, errorBuilder: onError);
  }
}

Future<Uint8List> readResource(String value) async {
  final route = routeFor(locate(value));
  if (route == null) throw ArgumentError.value(value, 'value', 'not a cache or host path');
  final response = await http.get(Uri.base.resolve(route));
  if (response.statusCode != 200) throw StateError('$route: HTTP ${response.statusCode}');
  return response.bodyBytes;
}
