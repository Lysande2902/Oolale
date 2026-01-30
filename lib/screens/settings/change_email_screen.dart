import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';
import '../../config/theme_colors.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _supabase = Supabase.instance.client;
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _passwordVisible = false;
  String? _errorMessage;
  String _currentEmail = '';

  @override
  void initState() {
    super.initState();
    _currentEmail = _supabase.auth.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _newEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _changeEmail() async {
    if (_newEmailController.text.isEmpty) {
      setState(() => _errorMessage = 'Ingresa el nuevo email');
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu contraseña para confirmar');
      return;
    }

    if (!_newEmailController.text.contains('@')) {
      setState(() => _errorMessage = 'Email inválido');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verificar contraseña primero
      await _supabase.auth.signInWithPassword(
        email: _currentEmail,
        password: _passwordController.text,
      );

      // Cambiar email
      await _supabase.auth.updateUser(
        UserAttributes(email: _newEmailController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email actualizado. Verifica tu nuevo email para confirmar el cambio.'),
            backgroundColor: AppConstants.primaryColor,
            duration: Duration(seconds: 5),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error changing email: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('Invalid login')
              ? 'Contraseña incorrecta'
              : 'Error al cambiar email. Intenta de nuevo.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('CAMBIAR EMAIL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('EMAIL ACTUAL'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ThemeColors.divider(context)),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_rounded, color: AppConstants.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    _currentEmail,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            _buildSection('NUEVO EMAIL'),
            
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ThemeColors.divider(context)),
              ),
              child: TextField(
                controller: _newEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Nuevo Email',
                  hintText: 'nuevo@email.com',
                  prefixIcon: Icon(Icons.email_rounded),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ThemeColors.divider(context)),
              ),
              child: TextField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: 'Contraseña Actual',
                  hintText: 'Confirma tu contraseña',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.errorColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppConstants.errorColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.outfit(color: AppConstants.errorColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changeEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : Text('CAMBIAR EMAIL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppConstants.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppConstants.primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Recibirás un email de confirmación en tu nueva dirección. Debes verificarlo para completar el cambio.',
              style: GoogleFonts.outfit(
                color: ThemeColors.secondaryText(context),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
