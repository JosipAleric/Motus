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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _authService.registerUser(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
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
        message: "Došlo je do greške prilikom registracije. Provjerite svoje podatke ili pokušajte ponovo.",
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String icon,
    bool obscure = false,
    required String? Function(String?) validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 5,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        style: TextStyle(fontSize: 14),
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              margin: EdgeInsets.all(8),
              child: IconifyIcon(
                icon: icon,
                size: 10,
                color: AppColors.textFieldSuffixIcon,
              ),
            ),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 17, horizontal: 10),
          labelText: label,
          labelStyle: TextStyle(
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
        ),
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
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Container(
        alignment: Alignment.center,
        color: AppColors.primary,
        child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Gornji logo
                        Container(
                          margin: const EdgeInsets.only(bottom: 50, top: 50),
                          child: Column(
                            children: [
                              const SizedBox(height: 50),
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
                            ],
                          ),
                        ),

                        // Donji dio
                        Expanded(
                          child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(80),
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(35, 30, 35, 30),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Registracija',
                                      style: TextStyle(
                                        fontFamily: 'MPlus1',
                                        fontSize: 27,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.7,
                                        color: Color(0xFF373737),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    buildTextField(
                                      controller: _firstNameController,
                                      label: 'Ime',
                                      icon: 'solar:user-broken',
                                      validator: (v) =>
                                          v!.isEmpty ? 'Unesite ime' : null,
                                    ),
                                    buildTextField(
                                      controller: _lastNameController,
                                      label: 'Prezime',
                                      icon: 'fluent:rename-a-20-regular',
                                      validator: (v) =>
                                          v!.isEmpty ? 'Unesite prezime' : null,
                                    ),
                                    buildTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      icon: 'mdi-light:email',
                                      validator: (v) =>
                                          v!.isEmpty ? 'Unesite email' : null,
                                    ),
                                    buildTextField(
                                      controller: _passwordController,
                                      label: 'Lozinka',
                                      icon: 'solar:lock-password-unlocked-broken',
                                      obscure: true,
                                      validator: (v) =>
                                          v!.isEmpty ? 'Unesite lozinku' : null,
                                    ),
                                    Transform.translate(
                                      offset: Offset(0, -15),
                                      child: Column(
                                        children: [
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child:     TextButton(
                                              onPressed: () =>
                                                  GoRouter.of(context).go('/login',),
                                              child: const Text(
                                                'Već imate račun? Prijavite se!',
                                                style: TextStyle(
                                                  color: Color(0xFF737373),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                          ),

                                          CustomButton(
                                            text: 'Registriraj se',
                                            onPressed: _register,
                                            icon: 'mdi:register',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            iconSize: 25,
                                            letterSpacing: 4,
                                            padding: EdgeInsets.symmetric(vertical: 15),
                                            isLoading: _loading,
                                            fontFamily: "MPlus1",
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),

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
    );
  }
}
