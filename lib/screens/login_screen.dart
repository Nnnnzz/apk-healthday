import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import 'signup_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Animation สำหรับปุ่มเปลี่ยนหน้า (Sign Up)
  late AnimationController _signUpAnimationController;
  late Animation<double> _signUpScaleAnimation;

  @override
  void initState() {
    super.initState();
    _signUpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _signUpScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _signUpAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _signUpAnimationController.dispose();
    super.dispose();
  }

  // ==========================================
  // LOGIC
  // ==========================================
  void _onLoginPressed() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('กรุณากรอก Username และ Password', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String internalEmail = "$username@healthday.app"; 

      final response = await supabase.auth.signInWithPassword(
        email: internalEmail,
        password: password,
      );

      if (mounted && response.user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } on AuthException {
      _showSnackBar('Username หรือ Password ไม่ถูกต้อง', isError: true);
    } catch (error) {
      _showSnackBar('เกิดข้อผิดพลาด กรุณาลองใหม่', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToSignUp() {
    _signUpAnimationController.forward().then((_) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
      _signUpAnimationController.reverse();
    });
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      // เพื่อให้ Layout ปรับตามคีย์บอร์ดเมื่อเปิดขึ้นมา
      body: SafeArea(
        child: Column(
          children: [
            // ส่วนที่ 1: Header (ดันขึ้นไปด้านบนสุดด้วย Expanded)
            Expanded(
              child: _buildHeader(),
            ),
            
            // ส่วนที่ 2: ฟอร์ม Login (ติดขอบล่าง)
            _buildLoginForm(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // UI COMPONENTS
  // ==========================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'LOGIN',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Color(0xFF5C5454),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/Full_logo.png',
              width: 230,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.health_and_safety, size: 80, color: Color(0xFF2D7D9A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryBlueGradient.colors.first,
            AppColors.primaryBlueGradient.colors.first.withOpacity(0.4),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(25, 40, 25, 50),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ใช้พื้นที่เท่าที่เนื้อหาต้องการ
        children: [
          _buildTextField(controller: _usernameController, hint: 'username'),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _passwordController,
            hint: 'password',
            obscure: _obscurePassword,
            hasToggle: true,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 35),
          _buildLoginButton(),
          const SizedBox(height: 25),
          _buildSignUpLink(),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _onLoginPressed,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: AppColors.primaryOrangeGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins-Medium',
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account ? ",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.darkText.withOpacity(0.6),
            fontFamily: 'Poppins',
          ),
        ),
        ScaleTransition(
          scale: _signUpScaleAnimation,
          child: GestureDetector(
            onTap: _navigateToSignUp,
            child: Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlueGradient.colors.first,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    bool hasToggle = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: AppColors.darkText, fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Poppins'),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          suffixIcon: hasToggle
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: onToggle,
                )
              : null,
        ),
      ),
    );
  }
}