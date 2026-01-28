import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/constants.dart';
import '../../config/theme_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    // Diseño Minimalista "Ultra Dark"
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  // --- LOGO MINIMALISTA ---
                  Center(
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppConstants.primaryColor,
                        ),
                        child: const Icon(
                          Icons.multitrack_audio_rounded,
                          size: 50,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // --- TEXTOS ---
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        Text(
                          'BIENVENIDO',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Inicia sesión para continuar',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: ThemeColors.secondaryText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),

                  // --- INPUTS ---
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        _buildMinimalInput(
                          controller: _emailController,
                          hint: 'Correo electrónico',
                          icon: Icons.alternate_email,
                        ),
                        const SizedBox(height: 20),
                        _buildMinimalInput(
                          controller: _passwordController,
                          hint: 'Contraseña',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // --- BOTÓN PRINCIPAL ---
                  FadeInUp(
                    delay: const Duration(milliseconds: 700),
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                      : ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'ENTRAR',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                  ),
                  
                  const Spacer(flex: 3),

                  // --- FOOTER ---
                  FadeIn(
                    delay: const Duration(milliseconds: 900),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes cuenta? ',
                          style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context)),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: Text(
                            'Regístrate',
                            style: GoogleFonts.outfit(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_showPassword,
        style: GoogleFonts.outfit(fontSize: 16),
        cursorColor: AppConstants.primaryColor,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Icon(icon, color: ThemeColors.secondaryText(context), size: 20),
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: ThemeColors.hintText(context)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: ThemeColors.secondaryText(context),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(email, password);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Credenciales incorrectas',
              style: GoogleFonts.outfit(color: ThemeColors.primaryText(context)),
            ),
            backgroundColor: Colors.red[900],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
