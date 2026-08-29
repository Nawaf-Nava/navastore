import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const NavastorApp());
}

class NavastorApp extends StatelessWidget {
  const NavastorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Navastor',
      theme: ThemeData(
        primaryColor: const Color(0xFF4A00E0),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // استخدام ودجت للتحقق من الجلسة عند فتح التطبيق
      home: const AuthCheckWrapper(),
    );
  }
}

// ودجت للتحقق من هل المستخدم مسجل دخول أم لا
class AuthCheckWrapper extends StatefulWidget {
  const AuthCheckWrapper({super.key});

  @override
  State<AuthCheckWrapper> createState() => _AuthCheckWrapperState();
}

class _AuthCheckWrapperState extends State<AuthCheckWrapper> {
  late Future<Map<String, String>?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = ApiService.getUserSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        // أثناء التحقق من الـ SharedPreferences
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F6FA),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF4A00E0)),
            ),
          );
        }

        // إذا وجدت جلسة محفوظة (المستخدم مسجل دخول)
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        } 
        
        // إذا لم توجد جلسة (يرجى تسجيل الدخول)
        return const LoginScreen();
      },
    );
  }
}