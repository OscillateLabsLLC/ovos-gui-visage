import 'dart:typed_data';

import 'package:flutter/material.dart';

Widget? imageFor(String? value, {BoxFit fit = BoxFit.contain, Widget? broken}) =>
    throw UnsupportedError('no resource layer for this platform');

Future<Uint8List> readResource(String value) => throw UnsupportedError('no resource layer for this platform');
