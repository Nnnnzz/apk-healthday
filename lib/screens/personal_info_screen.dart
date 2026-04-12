import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import '../constants/app_colors.dart';
import 'package:flutter/foundation.dart'; // สำหรับ kIsWeb และ Uint8List

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

  XFile? _pickedXFile; // ✅ เปลี่ยนจาก File เป็น XFile เพื่อเลี่ยงปัญหา Namespace
  String? _currentImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('users')
          .select()
          .eq('user_id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _firstNameController.text = data['first_name'] ?? '';
          _lastNameController.text = data['last_name'] ?? '';
          _weightController.text = data['weight_kg']?.toString() ?? '';
          _heightController.text = data['height_cm']?.toString() ?? '';
          _currentImageUrl = data['profile_image_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        setState(() {
          _pickedXFile = pickedFile; // ✅ เก็บข้อมูลในรูปแบบ XFile
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      String? finalImageUrl = _currentImageUrl;

      if (_pickedXFile != null) {
        // ✅ อ่านข้อมูลเป็น Bytes แทนการเข้าถึง Path โดยตรง (แก้ Namespace Error)
        final fileBytes = await _pickedXFile!.readAsBytes();
        final fileExt = p.extension(_pickedXFile!.path);
        final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}$fileExt';
        
        // ✅ อ้างอิง Path ตามนโยบาย "own folder" ในรูป (user_id/filename)
        final filePath = '${user.id}/$fileName'; 

        // ✅ ตรวจสอบชื่อ Bucket ให้ตรงกับในระบบ (จากรูปคือ PROFILE)
        await supabase.storage
            .from('profile') // <-- ตรวจสอบชื่อ Bucket ว่าตรงกับที่ตั้งไว้ใน Supabase หรือไม่
            .uploadBinary(
              filePath,
              fileBytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
                contentType: 'image/jpeg', 
              ),
            );

        finalImageUrl = supabase.storage
            .from('profile')
            .getPublicUrl(filePath);
      }

      await supabase
          .from('users')
          .update({
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'weight_kg': double.tryParse(_weightController.text),
            'height_cm': double.tryParse(_heightController.text),
            'profile_image_url': finalImageUrl,
          })
          .eq('user_id', user.id);

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

  // --- UI Methods ---

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

  Widget _buildProfileAvatar() {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _showPickImageOptions,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                image: _pickedXFile != null
                    ? DecorationImage(
                        // ✅ แสดงผลรูปที่เลือกโดยใช้ Bytes สำหรับ Web/Mobile
                        image: NetworkImage(_pickedXFile!.path), 
                        fit: BoxFit.cover,
                      )
                    : (_currentImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_currentImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null),
              ),
              child: (_pickedXFile == null && _currentImageUrl == null)
                  ? const Icon(Icons.person_outline, size: 55, color: Colors.white)
                  : null,
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: AppColors.darkText, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ... (ส่วน UI อื่นๆ เหมือนเดิมที่คุณทำไว้) ...
  // หมายเหตุ: อย่าลืมตรวจสอบชื่อ Bucket ในฟังก์ชัน _saveData() ให้ตรงกับ Supabase (PROFILE)

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.greyText),
                  SizedBox(width: 8),
                  Text("Back", style: TextStyle(color: AppColors.greyText, fontSize: 16)),
                ],
              ),
            ),
          ),
          const Text("Profile", style: TextStyle(color: AppColors.greyText, fontSize: 18)),
          const SizedBox(width: 80),
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

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
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
          height: 55, width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.primaryOrangeGradient,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  void _showPickImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Profile Picture", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionItem(icon: Icons.camera_alt_rounded, label: "Camera", onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
                _buildOptionItem(icon: Icons.photo_library_rounded, label: "Gallery", onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [Icon(icon, size: 30), const SizedBox(height: 8), Text(label)]),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        Positioned(top: -40, left: -60, child: Container(width: 180, height: 180, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryOrangeGradient))),
      ],
    );
  }
}