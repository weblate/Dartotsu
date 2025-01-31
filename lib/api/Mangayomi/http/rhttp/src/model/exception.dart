import 'dart:typed_data';

import 'package:dantotsu/api/Mangayomi/http/src/rust/api/rhttp/error.dart'
    as rust;
import 'package:dantotsu/api/Mangayomi/http/src/rust/api/rhttp/http.dart'
    as rust_http;

import 'request.dart';

/// The base class for all exceptions thrown by the `rhttp` library
/// or by interceptors.
///
/// This class is not sealed to allow for custom exceptions.
class RhttpException {
  /// The associated request when the exception was thrown.
  final HttpRequest request;

  const RhttpException(this.request);
}

/// An exception thrown when a request is canceled.
class RhttpCancelException extends RhttpException {
  const RhttpCancelException(super.request);

  @override
  String toString() =>
      '[$runtimeType] Request was canceled. URL: ${request.url}';
}

/// An exception thrown when a request times out.
class RhttpTimeoutException extends RhttpException {
  const RhttpTimeoutException(super.request);

  @override
  String toString() => '[$runtimeType] Request timed out. URL: ${request.url}';
}

/// An exception thrown when there are issues related to redirects.
class RhttpRedirectException extends RhttpException {
  const RhttpRedirectException(super.request);

  @override
  String toString() => '[$runtimeType] Redirect error. URL: ${request.url}';
}

/// An exception thrown on a 4xx or 5xx status code.
class RhttpStatusCodeException extends RhttpException {
  /// The status code of the response.
  final int statusCode;

  /// Response headers.
  final List<(String, String)> headers;

  Map<String, String> get headerMap => {
        for (final entry in headers) entry.$1: entry.$2,
      };

  /// The response body. For simplicity, we don't differentiate between
  /// text or bytes. Streams are always null.
  /// Can be [String], [Uint8List], or null.
  final Object? body;

  const RhttpStatusCodeException({
    required HttpRequest request,
    required this.statusCode,
    required this.headers,
    required this.body,
  }) : super(request);

  @override
  String toString() =>
      '[$runtimeType] Status code: $statusCode. URL: ${request.url}';
}

/// An exception thrown when the server's certificate is invalid.
class RhttpInvalidCertificateException extends RhttpException {
  /// The more detailed error message.
  final String message;

  const RhttpInvalidCertificateException({
    required HttpRequest request,
    required this.message,
  }) : super(request);

  @override
  String toString() =>
      '[$runtimeType] Invalid certificate. $message URL: ${request.url}';
}

/// An exception thrown when a connection error occurs.
/// For example, when the server is unreachable or internet is not available.
class RhttpConnectionException extends RhttpException {
  final String message;

  const RhttpConnectionException(super.request, this.message);

  @override
  String toString() =>
      '[$runtimeType] Connection error. URL: ${request.url} ($message)';
}

/// An exception thrown a request is made with an invalid client.
class RhttpClientDisposedException extends RhttpException {
  const RhttpClientDisposedException(super.request);

  @override
  String toString() =>
      '[$runtimeType] Client is already disposed. URL: ${request.url}';
}

/// An exception thrown by an interceptor.
/// Interceptors should only throw exceptions of type [RhttpException].
class RhttpInterceptorException extends RhttpException {
  final Object error;

  RhttpInterceptorException(super.request, this.error);

  @override
  String toString() => '[$runtimeType] $error. URL: ${request.url}';
}

/// An exception thrown when an unknown error occurs.
class RhttpUnknownException extends RhttpException {
  /// The error message
  final String message;

  const RhttpUnknownException(super.request, this.message);

  @override
  String toString() => '[$runtimeType] $message';
}

RhttpException parseError(HttpRequest request, rust.RhttpError error) {
  return error.when(
    rhttpCancelError: () => RhttpCancelException(request),
    rhttpTimeoutError: () => RhttpTimeoutException(request),
    rhttpRedirectError: () => RhttpRedirectException(request),
    rhttpStatusCodeError: (code, headers, body) => RhttpStatusCodeException(
      request: request,
      statusCode: code,
      headers: headers,
      body: switch (body) {
        rust_http.HttpResponseBody_Text() => body.field0,
        rust_http.HttpResponseBody_Bytes() => body.field0,
        rust_http.HttpResponseBody_Stream() => null,
      },
    ),
    rhttpInvalidCertificateError: (message) =>
        RhttpInvalidCertificateException(request: request, message: message),
    rhttpConnectionError: (message) =>
        RhttpConnectionException(request, message),
    rhttpUnknownError: (message) => RhttpUnknownException(request, message),
  );
}
