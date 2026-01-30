import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../config/theme_colors.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'soporte@oolale.app',
      query: 'subject=Soporte Óolale',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Centro de Ayuda', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(context, 'PREGUNTAS FRECUENTES'),
          _buildFAQItem(
            context,
            '¿Cómo edito mi perfil?',
            'Ve a Configuración > Editar Perfil. Ahí podrás actualizar tu nombre artístico, bio, ubicación e instrumentos.',
          ),
          _buildFAQItem(
            context,
            '¿Cómo conecto con otros músicos?',
            'Busca músicos en la pestaña Descubrir y presiona "Conectar". Una vez aceptada la solicitud, podrán enviarse mensajes.',
          ),
          _buildFAQItem(
            context,
            '¿Qué es Open to Work?',
            'Es una opción que indica que estás disponible para trabajos. Aparecerás en búsquedas de contratación con un badge verde.',
          ),
          _buildFAQItem(
            context,
            '¿Cómo bloqueo a un usuario?',
            'Ve al perfil del usuario y presiona "Bloquear". No podrás ver su contenido ni recibir mensajes de esa persona.',
          ),
          _buildFAQItem(
            context,
            '¿Cómo subo contenido a mi galería?',
            'Ve a tu perfil y presiona "Mi Galería". Ahí podrás subir fotos, videos y audios de tus presentaciones.',
          ),
          
          const SizedBox(height: 30),
          _buildSection(context, 'CONTACTO'),
          _buildContactCard(
            context,
            'Email de Soporte',
            'soporte@oolale.app',
            Icons.email_rounded,
            onTap: _launchEmail,
          ),
          _buildContactCard(
            context,
            'Reportar un Problema',
            'Describe el problema que encontraste',
            Icons.bug_report_rounded,
            onTap: _launchEmail,
          ),
          
          const SizedBox(height: 30),
          _buildSection(context, 'RECURSOS'),
          _buildResourceCard(
            context,
            'Guía de Inicio',
            'Aprende a usar Óolale',
            Icons.school_rounded,
          ),
          _buildResourceCard(
            context,
            'Consejos de Seguridad',
            'Mantén tu cuenta segura',
            Icons.security_rounded,
          ),
          _buildResourceCard(
            context,
            'Comunidad',
            'Únete a nuestra comunidad',
            Icons.groups_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title) {
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

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeColors.divider(context)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          question,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: GoogleFonts.outfit(
                color: ThemeColors.secondaryText(context),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    {VoidCallback? onTap}
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeColors.divider(context)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppConstants.primaryColor, size: 22),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, 
          style: TextStyle(color: ThemeColors.hintText(context), fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded, 
          color: ThemeColors.divider(context)),
      ),
    );
  }

  Widget _buildResourceCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeColors.divider(context)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppConstants.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppConstants.accentColor, size: 22),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, 
          style: TextStyle(color: ThemeColors.hintText(context), fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded, 
          color: ThemeColors.divider(context)),
      ),
    );
  }
}
