import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

String hostName = 'http://192.168.43.138:5000';

Future<dynamic> makePostRequest(
    Map<String, dynamic> postData, String endpoint) async {
  String url = '$hostName/api/android$endpoint';

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: await _getRequestHeaders(),
      body: jsonEncode(postData),
    );

    if (response.statusCode == 200) {
      dynamic jsonResponse = jsonDecode(response.body);
      if (endpoint == '/login') {
        if (jsonResponse['responseType'] == "success") {
          String setCookieHeader = response.headers['set-cookie']!;
          String accessToken = setCookieHeader.split('=')[1].split(';')[0];
          saveAccessTokenInMemory('accessToken', accessToken);
          saveAccessTokenInMemory('username', postData['username']);
        }
      }
      return jsonResponse;
    } else {
      throw Exception('Failed to post data: ${response.statusCode}');
    }
  } catch (error) {
    throw Exception('Failed to post data: $error');
  }
}

Future<dynamic> makeGETRequest(String endpoint) async {
  String url = '$hostName/api/android$endpoint';

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: await _getRequestHeaders(),
    );

    if (response.statusCode == 200) {
      dynamic jsonResponse = jsonDecode(response.body);
      if (endpoint == '/new_chat') {
        if (jsonResponse['responseType'] == "success") {
          String setCookieHeader = response.headers['set-cookie']!;
          String session = setCookieHeader.split('=')[1].split(';')[0];
          saveAccessTokenInMemory('session', session);
        }
      }
      return jsonResponse;
    } else {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }
  } catch (error) {
    throw Exception('Failed to fetch data: $error');
  }
}

Future<Map<String, String>> _getRequestHeaders() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('accessToken');
  String? session = prefs.getString('session');

  Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  if (accessToken != null) {
    headers['Cookie'] = 'accessToken=$accessToken';
  }

  if (session != null) {
    // Append the session to the existing Cookie header
    headers['Cookie'] = '${headers['Cookie'] ?? ''}; session=$session';
  }

  return headers;
}

void saveAccessTokenInMemory(String key, String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<String?> getAccessTokenFromMemory(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}
