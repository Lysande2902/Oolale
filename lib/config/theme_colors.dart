import 'package:flutter/material.dart';

/// Helper class para obtener colores que se adaptan al tema actual
class ThemeColors {
  /// Texto principal (blanco en oscuro, negro en claro)
  static Color primaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1A1A1A);
  }

  /// Texto secundario (gris claro en oscuro, gris oscuro en claro)
  static Color secondaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[400]!
        : const Color(0xFF666666);
  }

  /// Texto terciario/hint (gris muy claro en oscuro, gris medio en claro)
  static Color hintText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[600]!
        : const Color(0xFF999999);
  }

  /// Texto deshabilitado
  static Color disabledText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[700]!
        : const Color(0xFFCCCCCC);
  }

  /// Fondo de tarjetas
  static Color cardBackground(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  /// Fondo de la pantalla
  static Color scaffoldBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  /// Color de divisores/bordes
  static Color divider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFFE0E0E0);
  }

  /// Fondo de inputs
  static Color inputBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
  }

  /// Iconos principales
  static Color icon(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1A1A1A);
  }

  /// Iconos secundarios
  static Color iconSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[600]!
        : const Color(0xFF999999);
  }

  /// Overlay oscuro (para imágenes, etc)
  static Color overlay(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withOpacity(0.5)
        : Colors.black.withOpacity(0.3);
  }

  /// Fondo alternativo (para secciones destacadas)
  static Color alternativeBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF0F0F0);
  }
}
