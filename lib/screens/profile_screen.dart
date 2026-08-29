import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onProductAdded;
  const ProfileScreen({super.key, required this.onProductAdded});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, String>? _userSession;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  
  File? _productImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _checkSession() async {
    final session = await ApiService.getUserSession();
    if (mounted) {
      setState(() => _userSession = session);
    }
  }

  // نافذة تعديل بيانات الحساب (الاسم والصورة الشخصية)
  Future<void> _editProfile() async {
    final nameEditingController = TextEditingController(text: _userSession?['name'] ?? '');
    File? newProfileImage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentImage = _userSession?['image'] ?? '';
            return AlertDialog(
              title: const Text('تعديل البيانات الشخصية', textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                        if (picked != null) {
                          setDialogState(() {
                            newProfileImage = File(picked.path);
                          });
                        }
                      },
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.purple.shade50,
                        backgroundImage: newProfileImage != null
                            ? FileImage(newProfileImage!)
                            : (currentImage.isNotEmpty
                                ? (currentImage.startsWith('http')
                                    ? NetworkImage(currentImage) as ImageProvider
                                    : FileImage(File(currentImage)))
                                : null),
                        child: (newProfileImage == null && currentImage.isEmpty)
                            ? const Icon(Icons.camera_alt, size: 30, color: Color(0xFF4A00E0))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameEditingController,
                      decoration: InputDecoration(
                        labelText: 'الاسم الجديد',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A00E0)),
                  onPressed: () async {
                    final updatedName = nameEditingController.text.trim();
                    if (updatedName.isNotEmpty) {
                      final email = _userSession?['email'] ?? '';
                      final token = _userSession?['token'] ?? '';
                      final finalImagePath = newProfileImage != null ? newProfileImage!.path : currentImage;

                      // حفظ التحديثات في الجلسة المحلية
                      await ApiService.saveSession(updatedName, email, finalImagePath, token: token);
                      _checkSession(); // إعادة تحميل بيانات الجلسة في الشاشة
                    }
                    // ignore: use_build_context_synchronously
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('حفظ', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickProductImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() => _productImage = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Product Image Pick Error: $e');
    }
  }

  void _publishProduct() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();

    if (name.isEmpty || priceText.isEmpty || _productImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة بيانات المنتج واختيار صورة له')),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال سعر صحيح للمنتج')),
      );
      return;
    }

    setState(() => _isUploading = true);
    
    try {
      bool success = await ApiService.addProduct(name, price, _productImage);

      if (mounted) {
        setState(() {
          _nameController.clear();
          _priceController.clear();
          _productImage = null;
          _isUploading = false;
        });

        if (success) {
          widget.onProductAdded();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم نشر منتجك باسم حسابك بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل نشر المنتج، يرجى المحاولة لاحقاً')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء النشر: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي وإدارة المنتجات'),
        centerTitle: true,
        actions: [
          if (_userSession != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF4A00E0)),
              onPressed: _editProfile,
              tooltip: 'تعديل الحساب',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_userSession != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32, 
                      backgroundColor: Colors.white, 
                      backgroundImage: _userSession!['image'] != null && _userSession!['image']!.isNotEmpty 
                          ? (_userSession!['image']!.startsWith('http')
                              ? NetworkImage(_userSession!['image']!) as ImageProvider
                              : FileImage(File(_userSession!['image']!)))
                          : null,
                      child: (_userSession!['image'] == null || _userSession!['image']!.isEmpty)
                          ? const Icon(Icons.person, color: Color(0xFF4A00E0), size: 35) 
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userSession!['name']!, 
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userSession!['email']!, 
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: _editProfile,
                      tooltip: 'تعديل البيانات',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerRight, 
                child: Text('نشر منتج جديد باسم حسابك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              
              GestureDetector(
                onTap: _pickProductImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    image: _productImage != null 
                        ? DecorationImage(image: FileImage(_productImage!), fit: BoxFit.cover) 
                        : null,
                  ),
                  child: _productImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('اضغط لاختيار صورة المنتج من جهازك', style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _nameController, 
                decoration: InputDecoration(
                  labelText: 'اسم المنتج', 
                  prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF4A00E0)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController, 
                keyboardType: TextInputType.number, 
                decoration: InputDecoration(
                  labelText: 'السعر (\$)', 
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF4A00E0)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _publishProduct,
                icon: _isUploading 
                    ? const SizedBox.shrink() 
                    : const Icon(Icons.cloud_upload, color: Colors.white),
                label: _isUploading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('نشر المنتج في المتجر', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  minimumSize: const Size.fromHeight(50), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await ApiService.logout();
                  _checkSession();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else ...[
              const SizedBox(height: 40),
              const Icon(Icons.account_circle, size: 90, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'قم بتسجيل الدخول لنشر منتجاتك وتخصيص تجربتك', 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                  _checkSession();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A00E0), 
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('تسجيل الدخول / حساب جديد', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}