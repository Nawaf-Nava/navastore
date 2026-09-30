import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'product_details_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<dynamic>> _productsFuture;
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  final Set<dynamic> _favoriteProductIds = {};

  final List<String> _categories = ['الكل', 'الكترونيات', 'أجهزة', 'موضة', 'عروض'];

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = ApiService.getProducts().then((data) {
        _allProducts = data;
        _applyFilters();
        return data;
      });
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final name = p['name']?.toString().toLowerCase() ?? '';
        final productCategory = p['category']?.toString() ?? '';

        final matchesSearch = name.contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == 'الكل' || productCategory == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  String _fixImageUrl(String url) {
    if (url.startsWith('http')) {
      try {
        final uri = Uri.parse(url);
        final baseUri = Uri.parse(ApiService.baseUrl);
        final fixedUri = uri.replace(
          host: baseUri.host,
          port: baseUri.port,
        );
        return fixedUri.toString();
      } catch (_) {}
    }
    return url;
  }

  void _showAddProductBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategory = 'الكترونيات';
    File? selectedImage;
    final picker = ImagePicker();
    
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إضافة منتج جديد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A00E0))),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'اسم المنتج',
                        prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF4A00E0)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'السعر (\$)',
                        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF4A00E0)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'التصنيف',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['الكترونيات', 'أجهزة', 'موضة', 'عروض'].map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setModalState(() => selectedImage = File(pickedFile.path));
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF8E2DE2).withValues(alpha: 0.3)),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(selectedImage!, fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: Color(0xFF4A00E0), size: 30),
                                  SizedBox(height: 6),
                                  Text('اضغط لاختيار صورة المنتج', style: TextStyle(color: Color(0xFF4A00E0), fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A00E0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (nameController.text.isEmpty || priceController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('الرجاء إدخال الاسم والسعر')),
                            );
                            return;
                          }
                          double? price = double.tryParse(priceController.text);
                          if (price == null) return;

                          Navigator.pop(context);

                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(content: Text('جاري إضافة المنتج وترفيع الصورة...')),
                          );

                          bool success = await ApiService.addProduct(
                            nameController.text,
                            price,
                            selectedImage,
                            category: selectedCategory,
                          );

                          if (!mounted) return;

                          if (success) {
                            _refreshProducts();
                            if (!mounted) return;
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تمت إضافة المنتج بنجاح!')),
                            );
                          } else {
                            if (!mounted) return;
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('فشل إضافة المنتج، حاول مجدداً')),
                            );
                          }
                        },
                        child: const Text('حفظ ونشر المنتج', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: Colors.purple.shade50,
        child: const Icon(Icons.shopping_bag, size: 50, color: Color(0xFF8E2DE2)),
      );
    }

    final correctedUrl = _fixImageUrl(imagePath);

    if (correctedUrl.startsWith('http://') || correctedUrl.startsWith('https://')) {
      return Image.network(
        correctedUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: Colors.purple.shade50,
          child: const Icon(Icons.shopping_bag, size: 50, color: Color(0xFF8E2DE2)),
        ),
      );
    } else {
      return Image.file(
        File(imagePath),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: Colors.purple.shade50,
          child: const Icon(Icons.shopping_bag, size: 50, color: Color(0xFF8E2DE2)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductBottomSheet(context),
        backgroundColor: const Color(0xFF4A00E0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة منتج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refreshProducts(),
          color: const Color(0xFF4A00E0),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('مرحباً بك 👋', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              SizedBox(height: 4),
                              Text('متجر Navastor', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('لا توجد إشعارات جديدة حالياً')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن أفضل المنتجات والعروض...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF4A00E0)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedCategory == _categories[index];
                      return GestureDetector(
                        onTap: () => _onCategorySelected(_categories[index]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)])
                                : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(color: const Color(0xFF8E2DE2).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _categories[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              FutureBuilder<List<dynamic>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0))),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 50, color: Colors.red),
                            const SizedBox(height: 12),
                            const Text('حدث خطأ أثناء تحميل المنتجات', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _refreshProducts,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A00E0)),
                              child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (_filteredProducts.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text('لا توجد منتجات مطابقة للبحث', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final p = _filteredProducts[index];
                          final productId = p['id'] ?? index;
                          final isFavorite = _favoriteProductIds.contains(productId);

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailsScreen(product: p),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                          child: _buildProductImage(p['image_url']?.toString()),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () async {
                                              bool success = await ApiService.toggleFavorite(productId);
                                              if (success) {
                                                setState(() {
                                                  if (isFavorite) {
                                                    _favoriteProductIds.remove(productId);
                                                  } else {
                                                    _favoriteProductIds.add(productId);
                                                  }
                                                });
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                                color: isFavorite ? Colors.red : Colors.grey,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['name']?.toString() ?? 'منتج بدون اسم',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 16),
                                            const SizedBox(width: 4),
                                            Text('${p['rating'] ?? 4.8}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '\$${p['price'] ?? 0}',
                                              style: const TextStyle(
                                                color: Color(0xFF4A00E0),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('تمت إضافة "${p['name']}" إلى السلة')),
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _filteredProducts.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}