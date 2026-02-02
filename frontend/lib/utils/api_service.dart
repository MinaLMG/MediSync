import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'config.dart'; // Blocked by gitignore, using fallback

class ApiService {
  // Fallback if Config is not accessible
  static const String baseUrl = 'http://localhost:5000/api';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> postRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw data['message'] ?? 'Request failed';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<dynamic> getRequest(
    String endpoint, [
    Map<String, dynamic>? queryParams,
  ]) async {
    return _authenticatedRequest(endpoint, 'GET', queryParams: queryParams);
  }

  static Future<dynamic> putRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return _authenticatedRequest(endpoint, 'PUT', body: body);
  }

  static Future<dynamic> deleteRequest(String endpoint) async {
    return _authenticatedRequest(endpoint, 'DELETE');
  }

  static Future<dynamic> _authenticatedRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse(
      '$baseUrl$endpoint',
    ).replace(queryParameters: queryParams);

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      http.Response response;
      if (method == 'POST') {
        response = await http.post(
          uri,
          headers: headers,
          body: json.encode(body),
        );
      } else if (method == 'PUT') {
        response = await http.put(
          uri,
          headers: headers,
          body: json.encode(body),
        );
      } else if (method == 'DELETE') {
        response = await http.delete(uri, headers: headers);
      } else {
        response = await http.get(uri, headers: headers);
      }

      final data = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw data['message'] ?? 'Request failed';
      }
    } catch (e) {
      throw e.toString();
    }
  }
}
