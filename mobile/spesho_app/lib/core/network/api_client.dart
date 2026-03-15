import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../../data/datasources/auth_local_datasource.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  final String _base = AppConstants.baseUrl;
  final AuthLocalDatasource _authLocal;

  // Persistent client — reuses TCP connections (HTTP keep-alive)
  final http.Client _client = http.Client();

  ApiClient(this._authLocal);

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await _authLocal.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
    final res = await _client.get(uri, headers: await _headers());
    return _handle(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final uri = Uri.parse('$_base$path');
    final res = await _client.post(uri,
        headers: await _headers(auth: auth), body: jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_base$path');
    final res = await _client.put(uri,
        headers: await _headers(), body: jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$_base$path');
    final res = await _client.delete(uri, headers: await _headers());
    return _handle(res);
  }

  Future<http.Response> getRaw(String path,
      {Map<String, String>? query}) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
    return _client.get(uri, headers: await _headers());
  }

  dynamic _handle(http.Response res) {
    final ct = res.headers['content-type'] ?? '';
    if (!ct.contains('application/json')) {
      if (res.statusCode == 503 || res.statusCode == 502) {
        throw ApiException('Server inaanza, subiri sekunde chache kisha jaribu tena.', statusCode: res.statusCode);
      }
      throw ApiException('Server haijajibu vizuri (status ${res.statusCode}). Jaribu tena.', statusCode: res.statusCode);
    }
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = body['error'] ?? body['message'] ?? 'Unknown error';
    throw ApiException(msg, statusCode: res.statusCode);
  }

  void dispose() => _client.close();
}
