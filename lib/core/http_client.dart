import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:gestion_cafeteria/core/failure.dart';

import 'token_storage.dart';

class ApiClient {
  final http.Client _httpClient;
  final Uri _baseUrl;
  final Duration _timeout;
  final TokenStorage? _tokens;

  ApiClient({
    http.Client? client,
    String? baseUrl,
    TokenStorage? tokens,
    this._timeout = const Duration(seconds: 10),
  }) : _httpClient = client ?? http.Client(),
       _tokens = tokens,
       _baseUrl = _validarUrl(
         baseUrl ??
             const String.fromEnvironment(
               'API_URL',
               defaultValue: 'http://10.0.2.2:8000',
             ),
       );

  static const _hostLocales = {
    'localhost',
    '127.0.0.1',
    '10.0.0.2',
    '10.0.3.2',
  };

  // Validar si la url tiene o no https
  static Uri _validarUrl(String url) {
    final uri = Uri.parse(url);

    if (uri.scheme == 'https') return uri;
    if (uri.scheme == 'http' && _hostLocales.contains(uri.host)) return uri;

    throw ArgumentError('Conexión rechazadaL URL no segura: $url');
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) => _send('GET', path, queryParameters: queryParameters, headers: headers);

  Future<dynamic> post(
    String path,
    Object? body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) => _send(
    'POST',
    path,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
  );

  Future<dynamic> patch(
    String path,
    Object? body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) => _send(
    'PATCH',
    path,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
  );

  Future<void> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) =>
      _send('DELETE', path, queryParameters: queryParameters, headers: headers);

  void close() {
    _httpClient.close();
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final token = await _tokens?.readToken();

    final request = http.Request(method, uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        ...?headers,
      });

    if (body != null) {
      request.body = body is String ? body : jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await _httpClient
          .send(request)
          .then(http.Response.fromStream)
          .timeout(_timeout);
    } on http.ClientException {
      throw const NetworkFailure();
    } on TimeoutException {
      throw const NetworkFailure();
    } catch (e) {
      if (e is Failure) rethrow;
      throw const NetworkFailure();
    }

    final json = _tryDecode(response);
    final code = response.statusCode;

    if (code >= 200 && code < 300) {
      return json;
    }

    throw _mapHttpError(code, json);
  }

  Failure mapHttpError(int statusCode, dynamic json) =>
      _mapHttpError(statusCode, json);

  Failure _mapHttpError(int statusCode, dynamic json) {
    switch (statusCode) {
      case 404:
        return const NotFoundFailure();
      case 409:
        final message = (json is Map && json['detail'] is String)
            ? json['detail'] as String
            : 'Conflicto en la operación';
        return ConflictFailure(message);
      case 422:
        return UnprocessableEntityFailure(_fieldsFrom(json));
      case >= 500 && < 600:
        return ServerFailure(statusCode);
      default:
        final message = (json is Map && json['detail'] is String)
            ? json['detail'] as String
            : 'Error inesperado del servidor';
        return UnexpectedFailure(statusCode, message);
    }
  }

  Uri _buildUri(String path, Map<String, dynamic>? queryParameters) {
    final uri = _baseUrl.resolve(path);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    final mergedQuery = Map<String, dynamic>.from(uri.queryParameters)
      ..addAll(
        queryParameters.map((key, value) => MapEntry(key, value.toString())),
      );
    return uri.replace(queryParameters: mergedQuery);
  }

  dynamic _tryDecode(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  Map<String, String> _fieldsFrom(Object? json) {
    final fields = <String, String>{};
    if (json is Map && json['detail'] is List) {
      for (final error in json['detail']) {
        if (error is Map && error['loc'] is List && error['msg'] is String) {
          final loc = error['loc'] as List;
          if (loc.isNotEmpty) {
            fields[loc.last.toString()] = error['msg'] as String;
          }
        }
      }
    }
    return fields;
  }
}
