/// A web view for SYSTEM_UrlFrame and SYSTEM_HtmlFrame where this platform has one (SCOPE: webviews are gated per
/// platform). The gate is the registered implementation itself: WKWebView on macOS, an iframe on the web, nothing on
/// Linux, Windows or in the test runner, where the pages show their text fallbacks instead.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

bool get hasWebView => WebViewPlatform.instance != null;

/// Behind the view: the iframe on the web is transparent, so unstyled skill HTML would be black text on black.
const _paper = Colors.white;

class WebFrame extends StatefulWidget {
  const WebFrame.url(String this.url, {super.key}) : html = null;

  const WebFrame.html(String this.html, {super.key}) : url = null;

  final String? url;
  final String? html;

  @override
  State<WebFrame> createState() => _WebFrameState();
}

class _WebFrameState extends State<WebFrame> {
  late final WebViewController _controller = _create();

  /// Only loadRequest and loadHtmlString exist on the web, and WKWebView on macOS has no background setter, so the
  /// page background behind the view is the only colour set.
  WebViewController _create() {
    final controller = WebViewController();
    if (!kIsWeb) controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    final url = widget.url;
    if (url != null) {
      controller.loadRequest(Uri.parse(url));
    } else {
      controller.loadHtmlString(widget.html!);
    }
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: _paper,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
