import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';
import '../../widgets/customAlert.dart';
import '../../widgets/customButton.dart';
import '../../widgets/customSnackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _authService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        GoRouter.of(context).go('/');
      }
    } catch (e) {
      CustomSnackbar.show(
        context,
        type: AlertType.error,
        title: "Greška!",
        message:
            "Došlo je do greške prilikom prijave. Provjerite svoje podatke ili pokušajte ponovo.",
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required Widget suffixIcon,
  }) {
    return InputDecoration(
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 10),
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 14,
        color: Colors.grey,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.0),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildEmailField() {
    return _buildShadowedField(
      TextFormField(
        style: TextStyle(fontSize: 14),
        controller: _emailController,
        decoration: _inputDecoration(
          label: 'Email',
          suffixIcon: const Padding(
            padding: EdgeInsets.only(right: 15, left: 10),
            child: IconifyIcon(
              icon: 'mdi-light:email',
              size: 23,
              color: Color(0xffacacac),
            ),
          ),
        ),
        validator: (v) => v!.isEmpty ? 'Unesite email' : null,
      ),
    );
  }

  Widget _buildPasswordField() {
    return _buildShadowedField(
      TextFormField(
        style: TextStyle(fontSize: 14),
        controller: _passwordController,
        obscureText: true,
        decoration: _inputDecoration(
          label: 'Lozinka',
          suffixIcon: const Padding(
            padding: EdgeInsets.only(right: 15, left: 10),
            child: IconifyIcon(
              icon: 'solar:lock-password-unlocked-broken',
              size: 22,
              color: Color(0xffacacac),
            ),
          ),
        ),
        validator: (v) => v!.isEmpty ? 'Unesite lozinku' : null,
      ),
    );
  }

  Widget _buildShadowedField(Widget child) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 5,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSocialButton({required String label, required String icon}) {
    return Expanded(
      child: TextButton.icon(
        icon: IconifyIcon(
          icon: icon,
          size: 23.0,
          color: const Color(0xFF575757),
        ),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF575757),
          padding: const EdgeInsets.symmetric(vertical: 20),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'MPlus1',
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(color: Colors.black.withOpacity(0.1)),
          ),
        ),
        onPressed: _login,
        label: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Container(
          alignment: Alignment.center,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 80),
                        SvgPicture.asset(
                          'assets/images/logo.svg',
                          width: 35,
                          height: 35,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'MOTUS',
                          style: TextStyle(
                            fontFamily: 'Michroma',
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 50),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(80),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 35,
                              vertical: 40,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  Center(
                                    child: const Text(
                                      'Prijava',
                                      style: TextStyle(
                                        fontFamily: 'MPlus1',
                                        fontSize: 28,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  _buildEmailField(),
                                  const SizedBox(height: 20),
                                  _buildPasswordField(),
                                  const SizedBox(height: 15),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Zaboravljena lozinka?',
                                      style: TextStyle(
                                        color: const Color(0xFF8F8F8F),
                                        fontFamily: 'MPlus1',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  SizedBox(
                                    width: double.infinity,
                                    child: CustomButton(
                                      text: 'Prijavi se',
                                      onPressed: _login,
                                      icon: 'solar:login-bold',
                                      fontSize: 14,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                        horizontal: 30,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      borderRadius: 10.0,
                                      letterSpacing: 3,
                                      isLoading: _loading,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: const [
                                      Expanded(
                                        child: Divider(
                                          color: AppColors.divider,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20.0,
                                        ),
                                        child: Text(
                                          'ili',
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: AppColors.divider,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      _buildSocialButton(
                                        label: 'Google',
                                        icon: 'material-icon-theme:google',
                                      ),
                                      const SizedBox(width: 15),
                                      _buildSocialButton(
                                        label: 'Facebook',
                                        icon: 'logos:facebook',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: () =>
                                        GoRouter.of(context).go("/register"),
                                    child: const Text(
                                      'Nemate račun? Registrirajte se!',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
