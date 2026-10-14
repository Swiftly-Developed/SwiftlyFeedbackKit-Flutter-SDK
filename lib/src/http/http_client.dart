import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../client/feedbackkit_config.dart';
import '../errors/feedbackkit_error.dart';

/// HTTP client for making API requests.
class FeedbackKitHttpClient {
  final FeedbackKitConfig _config;
  final http.Client _client;
  /// The current user ID, sent as `X-User-Id`.
  String? userId;

  FeedbackKitHttpClient({
    required FeedbackKitConfig config,
    http.Client? client,
  })  : _config = config,
        _client = client ?? http.Client(),
        userId = config.userId {
    FeedbackKitConfig.assertSecureBaseUrl(config.baseUrl);
  }

  /// Gets the base URL.
  String get baseUrl => _config.baseUrl;

  /// Makes a GET request.
  Future<T> get<T>(
    String path, {
    Map<String, String?>? params,
    T Function(dynamic)? decoder,
  }) async {
    return _request<T>(
      method: 'GET',
      path: path,
      params: params,
      decoder: decoder,
    );
  }

  /// Makes a POST request.
  Future<T> post<T>(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String?>? params,
    T Function(dynamic)? decoder,
  }) async {
    return _request<T>(
      method: 'POST',
      path: path,
      body: body,
      params: params,
      decoder: decoder,
    );
  }

  /// Makes a DELETE request.
  ///
  /// [body] is encoded as JSON. The vote-removal route reads its user id from
  /// the body, so a DELETE with only query parameters does not reach it.
  Future<T> delete<T>(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String?>? params,
    T Function(dynamic)? decoder,
  }) async {
    return _request<T>(
      method: 'DELETE',
      path: path,
      body: body,
      params: params,
      decoder: decoder,
    );
  }

  /// Makes an HTTP request.
  Future<T> _request<T>({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String?>? params,
    T Function(dynamic)? decoder,
  }) async {
    final uri = _buildUri(path, params);
    final headers = _buildHeaders();

    try {
      final response = await _executeRequest(
        method: method,
        uri: uri,
        headers: headers,
        body: body,
      ).timeout(
        Duration(milliseconds: _config.timeout),
        onTimeout: () {
          throw const NetworkError(
            message: 'Request timed out',
            isTimeout: true,
          );
        },
      );

      return _handleResponse<T>(response, decoder);
    } on FeedbackKitError {
      rethrow;
    } on SocketException catch (e) {
      throw NetworkError(message: 'Network error: ${e.message}');
    } on TimeoutException {
      throw const NetworkError(
        message: 'Request timed out',
        isTimeout: true,
      );
    } catch (e) {
      throw NetworkError(message: 'Unexpected error: $e');
    }
  }

  Uri _buildUri(String path, Map<String, String?>? params) {
    final baseUri = Uri.parse(_config.baseUrl);
    final fullPath = '${baseUri.path}$path';

    // Filter out null values from params
    final filteredParams = <String, String>{};
    if (params != null) {
      for (final entry in params.entries) {
        if (entry.value != null) {
          filteredParams[entry.key] = entry.value!;
        }
      }
    }

    return baseUri.replace(
      path: fullPath,
      queryParameters: filteredParams.isEmpty ? null : filteredParams,
    );
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-API-Key': _config.apiKey,
    };

    if (userId != null) {
      headers['X-User-Id'] = userId!;
    }

    return headers;
  }

  Future<http.Response> _executeRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers);
      case 'POST':
        return _client.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        if (body == null) {
          return _client.delete(uri, headers: headers);
        }
        final request = http.Request('DELETE', uri);
        request.headers.addAll(headers);
        request.body = jsonEncode(body);
        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  T _handleResponse<T>(http.Response response, T Function(dynamic)? decoder) {
    final contentType = response.headers['content-type'] ?? '';
    dynamic data;

    if (contentType.contains('application/json') && response.body.isNotEmpty) {
      data = jsonDecode(response.body);
    } else {
      data = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoder != null) {
        return decoder(data);
      }
      return data as T;
    }

    // Extract the error, from either of the two body shapes the server sends.
    //
    // Branch on the JSON type of `error`, never on the status code: a 403
    // arrives in BOTH shapes — the detailed envelope for a measure rejection,
    // the middleware envelope for a role or project denial — so a status-code
    // branch cannot tell them apart.
    //
    // Until this was fixed the detailed shape crashed here: `error` is an
    // object, and casting it to String? threw a TypeError that _request caught
    // and reported as a generic NetworkError, losing the server's message and
    // its machine-readable code entirely.
    String message;
    String? code;
    String? field;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        // Detailed envelope: {error: {code, message, field?}, timestamp}.
        code = error['code'] as String?;
        field = error['field'] as String?;
        message = error['message'] as String? ?? 'HTTP ${response.statusCode}';
      } else {
        // Middleware envelope: {error: true, reason}. No code is sent, and the
        // SDK must not invent one.
        message = data['reason'] as String? ??
            (error is String ? error : null) ??
            data['message'] as String? ??
            'Unknown error';
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    } else {
      message = 'HTTP ${response.statusCode}';
    }

    throw createErrorFromResponse(
      response.statusCode,
      message,
      code: code,
      field: field,
      retryAfterSeconds: _parseRetryAfterSeconds(response.headers),
    );
  }

  /// Reads `Retry-After` when it is sent in the integer-seconds form.
  ///
  /// The HTTP-date form is not parsed; it yields null rather than a guess.
  static int? _parseRetryAfterSeconds(Map<String, String> headers) {
    final raw = headers['retry-after'];
    if (raw == null) return null;
    return int.tryParse(raw.trim());
  }

  /// Closes the HTTP client.
  void close() {
    _client.close();
  }
}
