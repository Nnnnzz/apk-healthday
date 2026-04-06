import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // อย่าลืมเพิ่มใน pubspec.yaml
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import '../constants/app_colors.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  File? _imageFile; // เก็บไฟล์รูปที่เลือกใหม่
  String? _currentImageUrl; // URL รูปปัจจุบันจาก DB
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 1. ดึงข้อมูล User จาก Database
  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('users')
          .select()
          .eq('user_id', user.id)
          .single();

      setState(() {
        _firstNameController.text = data['first_name'] ?? '';
        _lastNameController.text = data['last_name'] ?? '';
        _weightController.text = data['weight_kg']?.toString() ?? '';
        _heightController.text = data['height_cm']?.toString() ?? '';
        _currentImageUrl = data['profile_image_url'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading user data: $e");
      setState(() => _isLoading = false);
    }
  }

  // 2. ฟังก์ชันเลือกรูปภาพ
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // ลดขนาดรูปเพื่อความเร็วในการอัปโหลด
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 3. ฟังก์ชันอัปโหลดรูปและบันทึกข้อมูล
  Future<void> _saveData() async {
    setState(() => _isSaving = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      String? finalImageUrl = _currentImageUrl;

      // --- อัปโหลดรูปภาพถ้ามีการเลือกใหม่ ---
      if (_imageFile != null) {
        final fileExt = p.extension(_imageFile!.path);
        final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}$fileExt';

        await supabase.storage.from('profiles').upload(
          fileName,
          _imageFile!,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        finalImageUrl = supabase.storage.from('profiles').getPublicUrl(fileName);
      }

      // --- อัปเดตข้อมูลลงตาราง users ---
      await supabase.from('users').update({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'weight_kg': double.tryParse(_weightController.text),
        'height_cm': double.tryParse(_heightController.text),
        'profile_image_url': finalImageUrl,
      }).eq('user_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully! 🎉")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error saving data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          _buildBackgroundDecorations(),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D7D9A)))
              : SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 20),
                        _buildGlassCard(),
                        const SizedBox(height: 30),
                        _isSaving 
                          ? const CircularProgressIndicator(color: Colors.orange) 
                          : _buildSaveButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(left: 10),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.greyText),
                  SizedBox(width: 5),
                  Text("Back", style: TextStyle(color: AppColors.greyText, fontFamily: 'Poppins-Medium', fontSize: 16)),
                ],
              ),
            ),
          ),
          const Text("Profile", style: TextStyle(color: AppColors.greyText, fontSize: 18, fontFamily: 'Poppins-Medium')),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildGlassCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.glassBorderColor, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: AppColors.glassColor,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Column(
                children: [
                  _buildProfileAvatar(),
                  const SizedBox(height: 35),
                  _buildTextField(_firstNameController, "First Name"),
                  const SizedBox(height: 15),
                  _buildTextField(_lastNameController, "Last Name"),
                  const SizedBox(height: 15),
                  _buildTextField(_weightController, "Weight (kg)", isNumber: true),
                  const SizedBox(height: 15),
                  _buildTextField(_heightController, "Height (cm)", isNumber: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                image: _imageFile != null
                    ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                    : (_currentImageUrl != null
                        ? DecorationImage(image: NetworkImage(_currentImageUrl!), fit: BoxFit.cover)
                        : null),
              ),
              child: (_imageFile == null && _currentImageUrl == null)
                  ? const Icon(Icons.person_outline, size: 55, color: Colors.white)
                  : null,
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: AppColors.darkText, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontFamily: 'Poppins-Medium', color: AppColors.darkText, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Poppins-Medium'),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: GestureDetector(
        onTap: _saveData,
        child: Container(
          height: 55,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.primaryOrangeGradient,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrangeGradient.colors.last.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Poppins-SemiBold')),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        Positioned(top: -40, left: -60, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryOrangeGradient.scale(0.7)))),
        Positioned(top: 100, right: -50, child: _orb(200, AppColors.primaryBlueGradient)),
        Positioned(bottom: 250, left: -50, child: _orb(250, AppColors.primaryBlueGradient)),
        Positioned(bottom: -50, right: -50, child: _orb(300, AppColors.primaryOrangeGradient)),
      ],
    );
  }

  Widget _orb(double size, LinearGradient gradient) {
    return Opacity(
      opacity: 0.4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
    );
  }
}