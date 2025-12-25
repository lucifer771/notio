import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:notio/services/storage_service.dart';
import 'package:notio/models/user_model.dart';

import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    // Android Emulator specific host
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }
    // iOS and others
    return 'http://localhost:3000/api';
  }

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    // Try to load token from storage immediately if available
    final token = StorageService().getAuthToken();
    if (token != null) {
      _authToken = token;
    }
  }

  String? _authToken;

  void setToken(String token) {
    _authToken = token;
    StorageService().saveAuthToken(token);
  }

  void clearToken() {
    _authToken = null;
    StorageService().clearAuthToken();
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['x-auth-token'] = _authToken!;
    }
    return headers;
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: _headers,
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<UserProfile?> fetchProfile() async {
    if (_authToken == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );
      final data = _handleResponse(response);
      return UserProfile.fromJson(data); // Needs to be updated in UserModel
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  dynamic _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw Exception(body['msg'] ?? 'Unknown Error');
    }
  }
}
