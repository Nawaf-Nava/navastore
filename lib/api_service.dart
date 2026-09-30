import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<List<dynamic>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('فشل في جلب المنتجات');
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  static Future<bool> toggleFavorite(int productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/toggle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'product_id': productId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
