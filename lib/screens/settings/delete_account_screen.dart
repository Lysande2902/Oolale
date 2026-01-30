import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme_colors.dart';
import '../../providers/auth_provider.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _supabase = Supabase.instance.client;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _agreedToTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Debes aceptar los términos para continuar');
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu contraseña para confirmar');
      return;
    }

    if (_confirmController.text != 'ELIMINAR') {
      setState(() => _errorMessage = 'Debes escribir "ELIMINAR" para confirmar');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final userId = _supabase.auth.currentUser?.id;
      final email = _supabase.auth.currentUser?.email;

      if (userId == null || email == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar contraseña
      try {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: _passwordController.text,
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Contraseña incorrecta';
          _isLoading = false;
        });
        return;
      }

      // Marcar cuenta como eliminada (soft delete)
      await _supabase
          .from('profiles')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'is_active': false,
          })
          .eq('id', userId);

      // Cerrar sesión
      await _supabase.auth.signOut();

      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).logout();
        
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Tu cuenta ha sido eliminada exitosamente'),
            backgroundColor: AppConstants.primaryColor,
            duration: Duration(seconds: 3),
          ),
        );

        context.go('/login');
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al eliminar cuenta. Intenta de nuevo.';
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
        title: Text('ELIMINAR CUENTA', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWarningCard(),
            const SizedBox(height: 30),
            
            _buildSection('¿QUÉ SUCEDERÁ?'),
            _buildInfoItem(Icons.delete_forever_rounded, 'Se eliminará tu perfil y toda tu información personal'),
            _buildInfoItem(Icons.photo_library_rounded, 'Se eliminarán todas tus fotos, videos y archivos de audio'),
            _buildInfoItem(Icons.message_rounded, 'Se eliminarán todos tus mensajes y conversaciones'),
            _buildInfoItem(Icons.event_rounded, 'Se cancelarán tus eventos y se eliminarán tus invitaciones'),
            _buildInfoItem(Icons.link_off_rounded, 'Se eliminarán todas tus conexiones'),
            _buildInfoItem(Icons.star_rounded, 'Se eliminarán tus calificaciones y referencias'),
            
            const SizedBox(height: 30),
            _buildSection('CONFIRMACIÓN'),
            
            // Campo de contraseña
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
                  labelText: 'Contraseña',
                  hintText: 'Ingresa tu contraseña',
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

            // Campo de confirmación
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ThemeColors.divider(context)),
              ),
              child: TextField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: 'Escribe "ELIMINAR" para confirmar',
                  hintText: 'ELIMINAR',
                  prefixIcon: Icon(Icons.warning_rounded),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            // Checkbox de aceptación
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ThemeColors.divider(context)),
              ),
              child: CheckboxListTile(
                value: _agreedToTerms,
                onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                title: Text(
                  'Entiendo que esta acción es permanente y no se puede deshacer',
                  style: GoogleFonts.outfit(fontSize: 14),
                ),
                activeColor: AppConstants.errorColor,
              ),
            ),

            // Mensaje de error
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

            // Botón de eliminar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text('ELIMINAR MI CUENTA', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 16),

            // Botón de cancelar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeColors.primaryText(context),
                  side: BorderSide(color: ThemeColors.divider(context)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('CANCELAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.errorColor, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_rounded, color: AppConstants.errorColor, size: 48),
          const SizedBox(height: 12),
          Text(
            '¡ADVERTENCIA!',
            style: GoogleFonts.outfit(
              color: AppConstants.errorColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta acción es permanente y no se puede deshacer. Toda tu información será eliminada de forma definitiva.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: ThemeColors.secondaryText(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
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

  Widget _buildInfoItem(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeColors.divider(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.errorColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: ThemeColors.secondaryText(context),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
