import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// EBM App API Service (adapted from Central)
class ApiService {
  String get baseUrl => AppConfig.baseUrl;

  String? token;

  void setToken(String newToken) => token = newToken;
  void clearToken() => token = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-EBM-Client': 'ebm-app-flutter',
        'X-Requested-With': 'XMLHttpRequest',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', statusCode: 0);
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', statusCode: 0);
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', statusCode: 0);
    }
  }

  Future<dynamic> patch(String endpoint, [Map<String, dynamic>? data]) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: data != null ? json.encode(data) : null,
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', statusCode: 0);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', statusCode: 0);
    }
  }

  Future<dynamic> postMultipart(
      String endpoint, Map<String, String> fields, List<http.MultipartFile> files) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll(_headers);
      request.headers.remove('Content-Type'); // Let http client set it with boundary
      request.fields.addAll(fields);
      request.files.addAll(files);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', statusCode: 0);
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;
      try {
        return json.decode(body);
      } catch (e) {
        debugPrint('❌ JSON Decode Error (Success Code but Invalid JSON):');
        debugPrint('Raw Body: $body');
        throw ApiException('Server returned invalid data format.', statusCode: statusCode);
      }
    }

    String message = 'Request failed ($statusCode)';
    try {
      if (body.isNotEmpty) {
        final decodedBody = json.decode(body);
        message = decodedBody['message'] ?? decodedBody['error'] ?? message;
      }
    } catch (_) {
      debugPrint('⚠️ Could not decode error response body as JSON. Status: $statusCode');
      if (body.contains('<html') || body.contains('<?php')) {
        debugPrint('Raw Error Body (HTML/PHP Detected): ${body.substring(0, body.length > 200 ? 200 : body.length)}...');
      }
    }

    if (statusCode == 401) throw ApiException('Unauthorized. Please log in again.', statusCode: 401);
    if (statusCode == 403) throw ApiException('Access denied: $message', statusCode: 403);
    if (statusCode == 422) throw ApiException('Validation error: $message', statusCode: 422);
    throw ApiException(message, statusCode: statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, {required this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}
