import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart' as win;
import 'package:webview_flutter/webview_flutter.dart' as mobile;

/// A cross-platform webview widget that handles
/// - webview_windows for Windows
/// - webview_flutter for Android/iOS
class PlatformWebview extends StatefulWidget {
  final String htmlContent;

  const PlatformWebview({super.key, required this.htmlContent});

  @override
  State<PlatformWebview> createState() => _PlatformWebviewState();
}

class _PlatformWebviewState extends State<PlatformWebview> {
  // Windows Controller
  final _windowsController = win.WebviewController();
  bool _isWindowsInitialized = false;

  // Mobile Controller
  late final mobile.WebViewController _mobileController;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      _initWindows();
    } else {
      _initMobile();
    }
  }

  Future<void> _initWindows() async {
    try {
      await _windowsController.initialize();
      if (mounted) {
        setState(() {
          _isWindowsInitialized = true;
        });
        _windowsController.loadStringContent(widget.htmlContent);
      }
    } catch (e) {
      print("Windows Webview Init Error: $e");
    }
  }

  void _initMobile() {
    // Basic setup for webview_flutter 4.x
    _mobileController = mobile.WebViewController()
      ..setJavaScriptMode(mobile.JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        mobile.NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (mobile.WebResourceError error) {},
        ),
      )
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  void didUpdateWidget(covariant PlatformWebview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      if (Platform.isWindows && _isWindowsInitialized) {
        _windowsController.loadStringContent(widget.htmlContent);
      } else if (!Platform.isWindows) {
        _mobileController.loadHtmlString(widget.htmlContent);
      }
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      _windowsController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      if (!_isWindowsInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
      return win.Webview(_windowsController);
    } else {
      // Mobile (Android / iOS)
      return mobile.WebViewWidget(controller: _mobileController);
    }
  }
}
