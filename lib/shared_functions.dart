import 'dart:convert';
import 'package:http/http.dart' as http;

String hostName = 'http://192.168.43.138:5000';

Future<dynamic> makePostRequest(Map<String, dynamic> postData, String endpoint) async {
  String url = '$hostName/api/android$endpoint';

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(postData),
    );

    if (response.statusCode == 200) {
      dynamic jsonResponse = jsonDecode(response.body);
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
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      dynamic jsonResponse = jsonDecode(response.body);
      return jsonResponse;
    } else {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }
  } catch (error) {
    throw Exception('Failed to fetch data: $error');
  }
}