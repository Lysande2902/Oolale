import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Procesa un pago simulado y registra la transacción
  Future<bool> processPayment({
    required String userId,
    required double amount,
    required String concept,
    String gateway = 'Simulado',
  }) async {
    try {
      debugPrint('[PAYMENT] Inicio processPayment userId=$userId amount=$amount concept=$concept gateway=$gateway');
      // 1. Simular delay de procesamiento bancario
      await Future.delayed(const Duration(seconds: 2));

      // 2. Registrar la transacción en tickets_pagos
      final paymentData = {
        'comprador_id': userId,
        'monto_total': amount,
        'estatus': 'completado',
        'pasarela': '$gateway - $concept',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await _supabase.from('tickets_pagos').insert(paymentData);
      debugPrint('[PAYMENT] Insert en tickets_pagos OK');

      debugPrint('[PAYMENT] Verificación Premium pendiente de confirmación backend/webhook');

      return true;
    } catch (e) {
      debugPrint('[PAYMENT][ERROR] $e');
      return false;
    }
  }

  /// Inicia el flujo de pago con MercadoPago
  /// Retorna la URL de pago si es exitoso, o null si falla
  Future<String?> initiateMercadoPagoPayment({
    required String userId,
    required double amount,
    required String concept,
  }) async {
    try {
      debugPrint('[PAYMENT] Inicio initiateMercadoPagoPayment userId=$userId amount=$amount concept=$concept');
      // TODO: Llamar al backend real cuando esté disponible
      // final response = await ApiService().post('/ranking/upgrade', {
      //   'nivel': concept,
      //   'metodo_pago': 'mercadopago'
      // });
      // return response['url_pago'];

      // Por ahora, simulamos una URL de Sandbox o una URL de éxito directa para testing
      // En un flujo real, el backend crea la preferencia en MP y devuelve el init_point.
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulamos que el backend nos devolvió una URL válida
      // Usamos una URL de ejemplo de MP o una propia de éxito
      final url = 'https://www.mercadopago.com.mx/checkout/v1/redirect?pref_id=simulated_preference_id';
      debugPrint('[PAYMENT] URL MP generada $url');
      return url;
    } catch (e) {
      debugPrint('[PAYMENT][ERROR] initiateMercadoPagoPayment $e');
      return null;
    }
  }

  /// Abre la URL de pago en el navegador/app
  Future<bool> launchPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('[PAYMENT] URL abierta correctamente');
      return true;
    } else {
      debugPrint('[PAYMENT][ERROR] No se pudo abrir la URL: $url');
      return false;
    }
  }
}
