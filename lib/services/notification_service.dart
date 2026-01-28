import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final _supabase = Supabase.instance.client;

  /// Crea una notificación de postulación a evento
  static Future<void> createGigPostulationNotification({
    required String organizerId,
    required int gigId,
    required String gigTitle,
    required String senderId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': organizerId,
        'tipo': 'gig_postulation',
        'titulo': 'Nuevo interesado',
        'mensaje': 'Alguien quiere unirse a "$gigTitle"',
        'leido': false,
        'data': {
          'gig_id': gigId,
          'sender_id': senderId,
        },
      });
      debugPrint('✅ Notificación de postulación creada');
    } catch (e) {
      debugPrint('❌ Error creando notificación: $e');
    }
  }

  /// Crea una notificación de solicitud de conexión
  static Future<void> createConnectionRequestNotification({
    required String targetUserId,
    required String senderUserId,
    required String senderName,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': targetUserId,
        'tipo': 'connection_request',
        'titulo': 'Nueva solicitud',
        'mensaje': '$senderName quiere conectar contigo',
        'leido': false,
        'data': {
          'sender_id': senderUserId,
        },
      });
      debugPrint('✅ Notificación de conexión creada');
    } catch (e) {
      debugPrint('❌ Error creando notificación: $e');
    }
  }

  /// Crea una notificación de mensaje nuevo
  static Future<void> createMessageNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required int conversationId,
    required String messagePreview,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': recipientId,
        'tipo': 'message',
        'titulo': 'Mensaje de $senderName',
        'mensaje': messagePreview,
        'leido': false,
        'data': {
          'sender_id': senderId,
          'conversation_id': conversationId,
        },
      });
      debugPrint('✅ Notificación de mensaje creada');
    } catch (e) {
      debugPrint('❌ Error creando notificación: $e');
    }
  }

  /// Crea una notificación de pago
  static Future<void> createPaymentNotification({
    required String userId,
    required String title,
    required String message,
    required Map<String, dynamic> paymentData,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'tipo': 'payment',
        'titulo': title,
        'mensaje': message,
        'leido': false,
        'data': paymentData,
      });
      debugPrint('✅ Notificación de pago creada');
    } catch (e) {
      debugPrint('❌ Error creando notificación: $e');
    }
  }

  /// Obtiene el conteo de notificaciones no leídas
  static Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('leido', false);
      
      return response.length;
    } catch (e) {
      debugPrint('❌ Error obteniendo conteo: $e');
      return 0;
    }
  }
}
