import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.statusCode,
    required this.payload,
  });

  final String message;
  final int statusCode;
  final Map<String, dynamic> payload;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  String? _sessionCookie;

  Future<void> login({required String email, required String password}) async {
    final request = http.MultipartRequest('POST', _buildUri('/api/auth/login'))
      ..fields['email'] = email
      ..fields['password'] = password
      ..followRedirects = false
      ..maxRedirects = 0;

    final streamedResponse = await _httpClient.send(request);
    final setCookieHeader = streamedResponse.headers['set-cookie'];

    if (streamedResponse.statusCode != 303 || setCookieHeader == null) {
      throw Exception('Logowanie nie powiodlo sie.');
    }

    _sessionCookie = setCookieHeader.split(';').first;
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _httpClient.get(_buildUri(path), headers: _buildHeaders());
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> payload) async {
    final response = await _httpClient.post(
      _buildUri(path),
      headers: {
        ..._buildHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> patchJson(String path, Map<String, dynamic> payload) async {
    final response = await _httpClient.patch(
      _buildUri(path),
      headers: {
        ..._buildHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> deleteJson(String path, [Map<String, dynamic>? payload]) async {
    final request = http.Request('DELETE', _buildUri(path))
      ..headers.addAll({
        ..._buildHeaders(),
        'Content-Type': 'application/json',
      });

    if (payload != null) {
      request.body = jsonEncode(payload);
    }

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required String filePath,
    String? fileName,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri(path))
      ..headers.addAll(_buildHeaders())
      ..fields.addAll(fields)
      ..files.add(await http.MultipartFile.fromPath(fileField, filePath, filename: fileName));

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    return _decodeJson(response);
  }

  Uri _buildUri(String path) {
    return Uri.parse('${ApiConfig.baseUrl}$path');
  }

  Map<String, String> _buildHeaders() {
    if (_sessionCookie == null) {
      return const {};
    }

    return {
      'Cookie': _sessionCookie!,
    };
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    final json = jsonDecode(body);

    if (json is! Map<String, dynamic>) {
      throw Exception('Odpowiedz API ma niepoprawny format.');
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        message: json['error']?.toString() ?? 'Operacja nie powiodla sie.',
        statusCode: response.statusCode,
        payload: json,
      );
    }

    return json;
  }
}