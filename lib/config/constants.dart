import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Óolale';
  static const String appTagline = 'El latido de tu música';
  
  // Supabase Configuration
  static const String supabaseUrl = 'https://lwrlunndqzepwsbmofki.supabase.co';
  static const String supabaseKey = 'sb_publishable_nF-kOiwfnggVy5hrAxpvYw_bsPk5p7C';
  
  // Legado API (para rutas personalizadas)
  static const String baseUrl = '$supabaseUrl/rest/v1';

  // Official Branding Palette (Óolale - Official)
  // PRIMARY COLOR (Brand Signature)
  static const Color primaryColor = Color(0xFF009688); // Teal/Verde-Azulado Principal
  static const Color primaryDark = Color(0xFF00796B); // Teal Oscuro (Hover/Active)
  static const Color primaryLight = Color(0xFF4DB6AC); // Teal Claro (Fondos suaves)
  
  // STATE COLORS (Semantic)
  static const Color successColor = Color(0xFF4CAF50); // Verde Éxito
  static const Color warningColor = Color(0xFFFF9800); // Naranja Advertencia
  static const Color errorColor = Color(0xFFF44336); // Rojo Error/Peligro
  static const Color infoColor = Color(0xFF2196F3); // Azul Información
  
  // DARK BACKGROUNDS
  static const Color backgroundColor = Color(0xFF0A0A0A); // Fondo Body Oscuro
  static const Color cardColor = Color(0xFF121212); // Fondo Tarjetas
  static const Color bgDarkSecondary = Color(0xFF1A1A1A); // Fondo Secundario
  static const Color bgDarkTertiary = Color(0xFF2A2A2A); // Hover/Terciario
  static const Color bgDarkPanel = Color(0xFF0F0F0F); // Paneles oscuros
  static const Color bgDarkAlt = Color(0xFF1E1E1E); // Alternativo oscuro
  
  // TEXT COLORS (Dark Theme)
  static const Color textPrimary = Colors.white; // #FFFFFF
  static const Color textSecondary = Color(0xFFB0B0B0); // Texto Secundario
  static const Color textMuted = Color(0xFF808080); // Texto Apagado
  
  // BORDERS
  static const Color borderColor = Color(0xFF333333); // Borde Oscuro
  static const Color borderGlow = Color(0xFF009688); // Borde con Glow Principal
  
  // LEGACY (para compatibilidad)
  static const Color aquamarineColor = Color(0xFF06B6D4); // Cyan Alternativo
  static const Color accentColor = Color(0xFFFFC107); // Gold (aún usado)
  
  static const double defaultPadding = 24.0;
  static const double borderRadius = 20.0;
  
  // Typography - Using system fonts (no internet required)
  static const String fontFamily = 'Roboto';
  
  // Text styles using system fonts
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.grey,
  );
}
