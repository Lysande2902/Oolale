import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabase = Supabase.instance.client;
  
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _openToWork = false;
  bool _profilePublic = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await _supabase
          .from('profiles')
          .select('open_to_work')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _openToWork = data['open_to_work'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOpenToWork(bool value) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('profiles')
          .update({'open_to_work': value})
          .eq('id', userId);

      setState(() => _openToWork = value);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Ahora estás disponible para trabajos' : 'Ya no apareces como disponible'),
            backgroundColor: AppConstants.primaryColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating setting: $e');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro que quieres salir?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir', style: TextStyle(color: AppConstants.errorColor)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('CONFIGURACIÓN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSection('PERFIL'),
                _buildSettingTile(
                  'Editar Perfil',
                  'Actualiza tu información',
                  Icons.edit_rounded,
                  onTap: () => context.push('/edit-profile'),
                ),
                _buildSettingTile(
                  'Billetera',
                  'Gestiona tus pagos y saldo',
                  Icons.account_balance_wallet_rounded,
                  onTap: () => context.push('/settings/wallet'),
                ),
                
                const SizedBox(height: 30),
                _buildSection('DISPONIBILIDAD'),
                _buildSwitchTile(
                  'Open to Work',
                  'Aparece en búsquedas de contratación',
                  Icons.work_outline_rounded,
                  _openToWork,
                  (val) => _updateOpenToWork(val),
                ),
                _buildSwitchTile(
                  'Perfil Público',
                  'Permite que otros vean tu perfil completo',
                  Icons.public_rounded,
                  _profilePublic,
                  (val) => setState(() => _profilePublic = val),
                ),

                const SizedBox(height: 30),
                _buildSection('APARIENCIA'),
                _buildSwitchTile(
                  'Modo Oscuro',
                  'Alterna entre tema claro y oscuro',
                  Icons.dark_mode_rounded,
                  Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark,
                  (val) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(val),
                ),

                const SizedBox(height: 30),
                _buildSection('NOTIFICACIONES'),
                _buildSwitchTile(
                  'Notificaciones',
                  'Recibe alertas de la app',
                  Icons.notifications_rounded,
                  _notificationsEnabled,
                  (val) => setState(() => _notificationsEnabled = val),
                ),
                _buildSwitchTile(
                  'Email',
                  'Notificaciones por correo',
                  Icons.email_rounded,
                  _emailNotifications,
                  (val) => setState(() => _emailNotifications = val),
                ),
                _buildSwitchTile(
                  'Push',
                  'Notificaciones push',
                  Icons.phone_android_rounded,
                  _pushNotifications,
                  (val) => setState(() => _pushNotifications = val),
                ),

                const SizedBox(height: 30),
                _buildSection('CUENTA'),
                _buildSettingTile(
                  'Premium',
                  'Mejora tu experiencia',
                  Icons.star_rounded,
                  color: AppConstants.accentColor,
                  onTap: () => context.push('/premium'),
                ),
                _buildSettingTile(
                  'Privacidad',
                  'Controla tu información',
                  Icons.privacy_tip_rounded,
                  onTap: () {},
                ),
                _buildSettingTile(
                  'Ayuda y Soporte',
                  'Contacta al equipo',
                  Icons.help_outline_rounded,
                  onTap: () {},
                ),

                const SizedBox(height: 30),
                _buildDangerButton(),
                const SizedBox(height: 20),
                _buildVersionInfo(),
              ],
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

  Widget _buildSettingTile(String title, String subtitle, IconData icon, {VoidCallback? onTap, Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? AppConstants.primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color ?? AppConstants.primaryColor, size: 22),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppConstants.primaryColor, size: 22),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppConstants.primaryColor,
      ),
    );
  }

  Widget _buildDangerButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.errorColor,
          side: const BorderSide(color: AppConstants.errorColor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: Text('Cerrar Sesión', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Column(
        children: [
          Text(
            'Óolale Mobile',
            style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.3), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Versión 1.0.0 (Beta)',
            style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.15), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
