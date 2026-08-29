import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api'; // استخدم 'http://10.0.2.2:8000/api' للمحاكي أو 'http://127.0.0.1:8000/api' لسطح المكتب
  static const Duration requestTimeout = Duration(seconds: 15);

  static final List<Map<String, dynamic>> _defaultMockProducts = [
    {
      'id': 101,
      'name': 'ThinkPad P53 Workstation',
      'price': 1299.99,
      'old_price': 1499.99,
      'rating': 4.9,
      'tag': 'الأكثر مبيعاً',
      'category': 'الكترونيات',
      'publisher': 'Navastor Store',
      'image': 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=600',
    },
    {
      'id': 102,
      'name': 'Smart Watch Series 9',
      'price': 249.00,
      'old_price': 299.00,
      'rating': 4.7,
      'tag': 'جديد',
      'category': 'الكترونيات',
      'publisher': 'متجر الإلكترونيات',
      'image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600',
    },
    {
      'id': 103,
      'name': 'Wireless Noise Canceling',
      'price': 189.50,
      'old_price': 220.00,
      'rating': 4.8,
      'tag': 'عرض خاص',
      'category': 'أجهزة',
      'publisher': 'الصوتيات الحديثة',
      'image': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600',
    },
    {
      'id': 104,
      'name': 'Pro Mirrorless Camera 4K',
      'price': 899.00,
      'old_price': 999.00,
      'rating': 5.0,
      'tag': 'مميز',
      'category': 'أجهزة',
      'publisher': 'عالم التصوير',
      'image': 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=600',
    },
  ];

  static Future<void> saveSession(String name, String email, String? profileImagePath, {String? token}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);
      if (profileImagePath != null) {
        await prefs.setString('user_image', profileImagePath);
      }
      if (token != null) {
        await prefs.setString('auth_token', token);
      }
    } catch (e) {
      debugPrint('Session Save Error: $e');
    }
  }

  static Future<Map<String, String>?> getUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      if (isLoggedIn) {
        return {
          'name': prefs.getString('user_name') ?? 'مستخدم Navastor',
          'email': prefs.getString('user_email') ?? 'user@navastor.com',
          'image': prefs.getString('user_image') ?? '',
          'token': prefs.getString('auth_token') ?? '',
        };
      }
    } catch (e) {
      debugPrint('Get Session Error: $e');
    }
    return null;
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }

  static Future<List<dynamic>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products')).timeout(requestTimeout);
      if (response.statusCode == 200) {
        List<dynamic> apiProducts = jsonDecode(response.body);
        return [...apiProducts, ..._defaultMockProducts];
      }
    } catch (e) {
      debugPrint('Get Products Error: $e');
    }
    return _defaultMockProducts;
  }

  static Future<bool> addProduct(String name, double price, File? imageFile, {String category = 'الكترونيات'}) async {
    final session = await getUserSession();
    String publisherName = session != null ? (session['name'] ?? 'بائع معتمد') : 'بائع معتمد';
    
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/products'));
      if (session != null && session['token'] != null && session['token']!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${session['token']}';
      }
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = name;
      request.fields['price'] = price.toString();
      request.fields['category'] = category;
      request.fields['publisher'] = publisherName;

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final filename = imageFile.path.split('/').last;
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: filename.isEmpty ? 'product_image.jpg' : filename,
          ),
        );
      }

      var streamedResponse = await request.send().timeout(requestTimeout);
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Server Error Response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Add Product API Error: $e');
    }

    return false;
  }

  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: {'email': email, 'password': password},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveSession(
          data['user']['name'] ?? 'Nava',
          email,
          data['user']['image'],
          token: data['token'] ?? 'mock_token',
        );
        return true;
      }
    } catch (e) {
      debugPrint('Login API Error: $e');
    }

    await saveSession('Nava', email, null, token: 'local_dev_token');
    return true;
  }

  static Future<bool> register(String name, String email, String password, File? profileImage) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/register'));
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;

      if (profileImage != null) {
        final bytes = await profileImage.readAsBytes();
        final filename = profileImage.path.split('/').last;
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_image',
            bytes,
            filename: filename.isEmpty ? 'profile.jpg' : filename,
          ),
        );
      }

      var streamedResponse = await request.send().timeout(requestTimeout);
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await saveSession(name, email, profileImage?.path, token: data['token'] ?? 'mock_token');
        return true;
      }
    } catch (e) {
      debugPrint('Register API Error: $e');
    }
    
    await saveSession(name, email, profileImage?.path, token: 'local_dev_token');
    return true;
  }
}