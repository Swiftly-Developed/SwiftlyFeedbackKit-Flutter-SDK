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
  String? _userId;

  FeedbackKitHttpClient({
    required FeedbackKitConfig config,
    http.Client? client,
  })  : _config = config,
        _client = client ?? http.Client(),
        _userId = config.userId;

  /// Gets the current user ID.
  String? get userId => _userId;

  /// Sets the current user ID.
  set userId(String? value) => _userId = value;

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
  Future<T> delete<T>(
    String path, {
    Map<String, String?>? params,
    T Function(dynamic)? decoder,
  }) async {
    return _request<T>(
      method: 'DELETE',
      path: path,
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

    if (_userId != null) {
      headers['X-User-Id'] = _userId!;
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
        return _client.delete(uri, headers: headers);
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

    // Extract error message
    String message;
    if (data is Map<String, dynamic>) {
      message = data['reason'] as String? ??
          data['error'] as String? ??
          data['message'] as String? ??
          'Unknown error';
    } else if (data is String && data.isNotEmpty) {
      message = data;
    } else {
      message = 'HTTP ${response.statusCode}';
    }

    throw createErrorFromResponse(response.statusCode, message);
  }

  /// Closes the HTTP client.
  void close() {
    _client.close();
  }
}
