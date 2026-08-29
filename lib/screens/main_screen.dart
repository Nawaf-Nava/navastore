import 'package:flutter/material.dart';
import 'products_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Key _productsKey = UniqueKey();

  void _refreshProductsTab() {
    setState(() {
      _productsKey = UniqueKey(); // لإجبار شاشة المنتجات على التحديث
    });
  }

  @override
  Widget build(BuildContext context) {
    // استخدام IndexedStack يحافظ على حالة الصفحات ويمنع إعادة بنائها عند التنقل
    final List<Widget> pages = [
      ProductsScreen(key: _productsKey),
      const Scaffold(
        backgroundColor: Color(0xFFF4F6FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 70, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'قائمة المفضلة فارغة حالياً', 
                style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      ProfileScreen(onProductAdded: _refreshProductsTab),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF4A00E0),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: 'المنتجات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'المفضلة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}