import 'dart:async';
import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/Mangayomi/http/m_client.dart';
import '../../main.dart';

class MangaWebView extends ConsumerStatefulWidget {
  final String url;
  final String title;

  const MangaWebView({super.key, required this.url, required this.title});

  @override
  ConsumerState<MangaWebView> createState() => _MangaWebViewState();
}

class _MangaWebViewState extends ConsumerState<MangaWebView> {
  late final MyInAppBrowser browser;
  double _progress = 0;
  bool isNotWebviewWindow = false;

  @override
  void initState() {
    if (Platform.isLinux || Platform.isWindows) {
      _runWebViewDesktop();
    } else {
      setState(() {
        isNotWebviewWindow = true;
      });
    }
    super.initState();
  }

  Webview? _desktopWebview;

  _runWebViewDesktop() async {
    if (Platform.isLinux) {
      _desktopWebview = await WebviewWindow.create();

      final timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        try {
          final cookies =
              await _desktopWebview!.evaluateJavaScript('document.cookie') ??
                  "";
          final cookieList = cookies.toString().split('; ').map((cookie) {
            final parts = cookie.split('=');
            return {'name': parts[0], 'value': parts.sublist(1).join('=')};
          }).toList();
          final ua = await _desktopWebview!
                  .evaluateJavaScript("navigator.userAgent") ??
              "";
          final cookieString =
              cookieList.map((e) => "${e['name']}=${e['value']}").join(";");
          await MClient.setCookie(_url, ua, null, cookie: cookieString);
        } catch (_) {}
      });
      _desktopWebview!
        ..setBrightness(Brightness.dark)
        ..launch(widget.url)
        ..onClose.whenComplete(() {
          timer.cancel();
          if (mounted) Navigator.pop(context);
        });
    } else {
      browser = MyInAppBrowser(
        context: context,
        controller: (controller) {
          _webViewController = controller;
        },
        onProgress: (progress) async {
          final canGoback = await _webViewController?.canGoBack();
          final canGoForward = await _webViewController?.canGoForward();
          final title = await _webViewController?.getTitle();
          final url = await _webViewController?.getUrl();
          if (mounted) {
            setState(() {
              _progress = progress / 100;
              _url = url.toString();
              _title = title!;
              _canGoback = canGoback ?? false;
              _canGoForward = canGoForward ?? false;
            });
          }
        },
      );
      await browser.openUrlRequest(
        urlRequest: URLRequest(url: WebUri(widget.url)),
        settings: InAppBrowserClassSettings(
          browserSettings: InAppBrowserSettings(
              presentationStyle: ModalPresentationStyle.POPOVER),
          webViewSettings: InAppWebViewSettings(
              isInspectable: kDebugMode, useShouldOverrideUrlLoading: true),
        ),
      );
    }
  }

  InAppWebViewController? _webViewController;
  late String _url = widget.url;
  late String _title = widget.title;
  bool _canGoback = false;
  bool _canGoForward = false;

  @override
  Widget build(BuildContext context) {
    return (!isNotWebviewWindow && Platform.isLinux)
        ? Scaffold(
            appBar: AppBar(
              title: Text(
                _title,
                style: const TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                  onPressed: () {
                    _desktopWebview!.close();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close)),
            ),
          )
        : Material(
            child: SafeArea(
              child: WillPopScope(
                onWillPop: () async {
                  final canGoback = await _webViewController?.canGoBack();
                  if (canGoback ?? false) {
                    _webViewController?.goBack();
                  } else if (context.mounted) {
                    Navigator.pop(context);
                  }
                  return false;
                },
                child: Column(
                  children: [
                    SizedBox(
                      height: AppBar().preferredSize.height,
                      child: Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              dense: true,
                              subtitle: Text(
                                _url,
                                style: const TextStyle(
                                    fontSize: 10,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              title: Text(
                                _title,
                                style: const TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontWeight: FontWeight.bold),
                              ),
                              leading: IconButton(
                                  onPressed: () {
                                    if (Platform.isWindows) {
                                      if (browser.isOpened()) {
                                        browser.close();
                                        browser.dispose();
                                      }
                                    }
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.close)),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_back,
                                color: _canGoback ? null : Colors.grey),
                            onPressed: _canGoback
                                ? () {
                                    _webViewController?.goBack();
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_forward,
                                color: _canGoForward ? null : Colors.grey),
                            onPressed: _canGoForward
                                ? () {
                                    _webViewController?.goForward();
                                  }
                                : null,
                          ),
                          PopupMenuButton(itemBuilder: (context) {
                            return [
                              PopupMenuItem<int>(
                                  value: 0, child: Text("Refresh")),
                              PopupMenuItem<int>(
                                  value: 1, child: Text("Share")),
                              PopupMenuItem<int>(
                                  value: 2, child: Text("Open in browser")),
                              PopupMenuItem<int>(
                                  value: 3, child: Text("Clear Cookie")),
                            ];
                          }, onSelected: (value) async {
                            if (value == 0) {
                              _webViewController?.reload();
                            } else if (value == 1) {
                              Share.share(_url);
                            } else if (value == 2) {
                              await InAppBrowser.openWithSystemBrowser(
                                  url: WebUri(_url));
                            } else if (value == 3) {
                              CookieManager.instance().deleteAllCookies();
                              MClient.deleteAllCookies(_url);
                            }
                          }),
                        ],
                      ),
                    ),
                    _progress < 1.0
                        ? LinearProgressIndicator(value: _progress)
                        : Container(),
                    if (!Platform.isWindows)
                      Expanded(
                        child: InAppWebView(
                          webViewEnvironment: webViewEnvironment,
                          onWebViewCreated: (controller) async {
                            _webViewController = controller;
                          },
                          onLoadStart: (controller, url) async {
                            setState(() {
                              _url = url.toString();
                            });
                          },
                          shouldOverrideUrlLoading:
                              (controller, navigationAction) async {
                            var uri = navigationAction.request.url!;
                            if (![
                              "http",
                              "https",
                              "file",
                              "chrome",
                              "data",
                              "javascript",
                              "about"
                            ].contains(uri.scheme)) {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                                return NavigationActionPolicy.CANCEL;
                              }
                            }
                            return NavigationActionPolicy.ALLOW;
                          },
                          onLoadStop: (controller, url) async {
                            if (mounted) {
                              setState(() {
                                _url = url.toString();
                              });
                            }
                          },
                          onProgressChanged: (controller, progress) async {
                            if (mounted) {
                              setState(() {
                                _progress = progress / 100;
                              });
                            }
                          },
                          onUpdateVisitedHistory:
                              (controller, url, isReload) async {
                            final ua = await controller.evaluateJavascript(
                                    source: "navigator.userAgent") ??
                                "";
                            await MClient.setCookie(
                                url.toString(), ua, controller);
                            final canGoback = await controller.canGoBack();
                            final canGoForward =
                                await controller.canGoForward();
                            final title = await controller.getTitle();
                            if (mounted) {
                              setState(() {
                                _url = url.toString();
                                _title = title!;
                                _canGoback = canGoback;
                                _canGoForward = canGoForward;
                              });
                            }
                          },
                          initialUrlRequest:
                              URLRequest(url: WebUri(widget.url)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
  }
}

class MyInAppBrowser extends InAppBrowser {
  BuildContext context;
  void Function(InAppWebViewController) controller;
  void Function(int) onProgress;

  MyInAppBrowser(
      {required this.context,
      required this.controller,
      required this.onProgress})
      : super(webViewEnvironment: webViewEnvironment);

  @override
  Future onBrowserCreated() async {
    controller.call(webViewController!);
  }

  @override
  void onProgressChanged(progress) {
    onProgress.call(progress);
  }

  @override
  void onExit() {
    Navigator.pop(context);
  }

  @override
  void onLoadStop(url) async {
    if (webViewController != null) {
      final ua = await webViewController!
              .evaluateJavascript(source: "navigator.userAgent") ??
          "";
      await MClient.setCookie(url.toString(), ua, webViewController);
    }
  }

  @override
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      navigationAction) async {
    var uri = navigationAction.request.url!;
    if (!["http", "https", "file", "chrome", "data", "javascript", "about"]
        .contains(uri.scheme)) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return NavigationActionPolicy.CANCEL;
      }
    }
    return NavigationActionPolicy.ALLOW;
  }
}
