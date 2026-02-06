import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'blocked_users_screen.dart';
import '../../utils/error_handler.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  bool _pushEnabled = true;
  bool _dataSaver = false;

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    setState(() => _isLoading = true);
    final userId = _supabase.auth.currentUser?.id;
    
    try {
      // 1. Cargar Notificaciones desde Supabase
      if (userId != null) {
        final pushData = await _supabase
            .from('configuracion_notificaciones')
            .select('push_enabled')
            .eq('user_id', userId)
            .maybeSingle();
        
        if (pushData != null) {
          _pushEnabled = pushData['push_enabled'] ?? true;
        }
      }

      // 2. Cargar Ahorro de Datos desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _dataSaver = prefs.getBool('data_saver_enabled') ?? false;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ErrorHandler.logError('SettingsScreen._loadAllSettings', e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePush(bool value) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _pushEnabled = value);

    try {
      await _supabase
          .from('configuracion_notificaciones')
          .update({'push_enabled': value})
          .eq('user_id', userId);
    } catch (e) {
      ErrorHandler.logError('SettingsScreen._togglePush', e);
      // Revertir si hay error
      setState(() => _pushEnabled = !value);
    }
  }

  Future<void> _toggleDataSaver(bool value) async {
    setState(() => _dataSaver = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('data_saver_enabled', value);
    } catch (e) {
      ErrorHandler.logError('SettingsScreen._toggleDataSaver', e);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cerrar Sesión', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro que quieres salir de tu cuenta?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Salir', style: GoogleFonts.outfit(color: AppConstants.errorColor, fontWeight: FontWeight.bold)),
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
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                _buildSection('CUENTA Y PRIVACIDAD'),
                _buildSettingTile(
                  'Ajustes de Cuenta',
                  'Email, contraseña y estado de perfil',
                  Icons.manage_accounts_rounded,
                  onTap: () => context.push('/settings/account-settings'),
                ),
                _buildSettingTile(
                  'Usuarios Bloqueados',
                  'Gestiona quién no puede contactarte',
                  Icons.block_rounded,
                  color: Colors.redAccent,
                  onTap: () => context.push('/blocked-users'),
                ),

                const SizedBox(height: 32),
                _buildSection('PERSONALIZACIÓN'),
                _buildSwitchTile(
                  'Modo Oscuro',
                  'Tema visual de la aplicación',
                  Icons.dark_mode_rounded,
                  Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark,
                  (val) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(val),
                ),
                _buildSettingTile(
                  'Tamaño de fuente',
                  'Mejora la legibilidad del texto',
                  Icons.text_fields_rounded,
                  onTap: () => context.push('/settings/font-size'),
                ),

                const SizedBox(height: 32),
                _buildSection('NOTIFICACIONES'),
                _buildSwitchTile(
                  'Notificaciones Push',
                  'Alertas de mensajes y eventos',
                  Icons.notifications_active_rounded,
                  _pushEnabled,
                  _togglePush,
                ),
                _buildSettingTile(
                  'Ajustes Detallados',
                  'Configura cada tipo de alerta',
                  Icons.tune_rounded,
                  onTap: () => context.push('/settings/notifications'),
                ),

                const SizedBox(height: 32),
                _buildSection('DATOS Y RENDIMIENTO'),
                _buildSwitchTile(
                  'Ahorro de Datos',
                  'Optimiza el consumo de red',
                  Icons.data_saver_off_rounded,
                  _dataSaver,
                  _toggleDataSaver,
                ),
                _buildSettingTile(
                  'Almacenamiento y Caché',
                  'Gestiona archivos temporales',
                  Icons.cleaning_services_rounded,
                  onTap: () => context.push('/settings/cache'),
                ),

                const SizedBox(height: 48),
                _buildDangerButton(),
                const SizedBox(height: 32),
                _buildVersionInfo(),
                const SizedBox(height: 40),
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
          fontSize: 11,
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
        border: Border.all(color: ThemeColors.divider(context).withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? AppConstants.primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color ?? AppConstants.primaryColor, size: 22),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: GoogleFonts.outfit(color: ThemeColors.hintText(context), fontSize: 11)),
        trailing: Icon(Icons.chevron_right_rounded, color: ThemeColors.hintText(context).withOpacity(0.5), size: 20),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeColors.divider(context).withOpacity(0.05)),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppConstants.primaryColor, size: 22),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: GoogleFonts.outfit(color: ThemeColors.hintText(context), fontSize: 11)),
        value: value,
        onChanged: onChanged,
        activeColor: AppConstants.primaryColor,
      ),
    );
  }

  Widget _buildDangerButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: OutlinedButton.icon(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.errorColor,
          side: BorderSide(color: AppConstants.errorColor.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text('CERRAR SESIÓN', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Column(
        children: [
          Text(
            'ÓOLALE CONNECT',
            style: GoogleFonts.poppins(
              color: AppConstants.primaryColor.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Versión 1.0.0 Stable',
            style: GoogleFonts.outfit(color: ThemeColors.hintText(context).withOpacity(0.3), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
