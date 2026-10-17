/// SYSTEM_Face (SPEC 8.2): the concept face at its true place on the frame; eyes closed while `sleeping` is true.
library;

import 'package:flutter/material.dart';

import '../face/face.dart';
import '../face/face_theme.dart';
import '../json.dart';
import 'page.dart';

class SystemFacePage extends StatefulWidget {
  const SystemFacePage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => SystemFacePage(data: data);

  final Json data;

  @override
  State<SystemFacePage> createState() => _SystemFacePageState();
}

class _SystemFacePageState extends State<SystemFacePage> {
  final controller = FaceController();

  @override
  void initState() {
    super.initState();
    controller.setSleeping(truthy(widget.data['sleeping']));
  }

  @override
  void didUpdateWidget(SystemFacePage old) {
    super.didUpdateWidget(old);
    controller.setSleeping(truthy(widget.data['sleeping']));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The page sits inside the shell's padding; undo it so the face lands at its frame coordinates.
    return OverflowBox(
      maxWidth: frameWidth,
      maxHeight: frameHeight,
      child: Face(controller: controller),
    );
  }
}
