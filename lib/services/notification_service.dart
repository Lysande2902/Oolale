import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final _supabase = Supabase.instance.client;

  // Inicializar servicio de notificaciones
  static Future<void> initialize() async {
    try {
      debugPrint('🔔 Inicializando NotificationService...');
      
      // Solicitar permisos
      await _requestPermissions();
      
      // Configurar notificaciones locales
      await _setupLocalNotifications();
      
      // Obtener y guardar token FCM
      await _saveDeviceToken();
      
      // Configurar listeners
      _setupMessageHandlers();
      
      debugPrint('✅ NotificationService inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando NotificationService: $e');
    }
  }

  // Solicitar permisos de notificaciones
  static Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('📱 Permisos de notificación: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('⚠️ Permisos de notificaciones denegados por el usuario');
      }
    } catch (e) {
      debugPrint('❌ Error solicitando permisos: $e');
    }
  }

  // Configurar notificaciones locales
  static Future<void> _setupLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Crear canal de notificaciones para Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notificaciones Importantes',
        description: 'Canal para notificaciones importantes de Óolale',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      
      debugPrint('✅ Notificaciones locales configuradas');
    } catch (e) {
      debugPrint('❌ Error configurando notificaciones locales: $e');
    }
  }

  // Guardar token del dispositivo en Supabase
  static Future<void> _saveDeviceToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      final userId = _supabase.auth.currentUser?.id;

      if (token != null && userId != null) {
        debugPrint('🔑 FCM Token: $token');
        
        final platform = Platform.isAndroid ? 'android' : 'ios';
        
        // Guardar token en la tabla device_tokens
        await _supabase.from('device_tokens').upsert({
          'user_id': userId,
          'token': token,
          'platform': platform,
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        debugPrint('✅ Token guardado en Supabase');
      } else {
        debugPrint('⚠️ No se pudo guardar token: token=$token, userId=$userId');
      }
    } catch (e) {
      debugPrint('❌ Error guardando token: $e');
    }

    // Listener para cuando el token se actualice
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          final platform = Platform.isAndroid ? 'android' : 'ios';
          
          await _supabase.from('device_tokens').upsert({
            'user_id': userId,
            'token': newToken,
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          });
          
          debugPrint('🔄 Token actualizado: $newToken');
        }
      } catch (e) {
        debugPrint('❌ Error actualizando token: $e');
      }
    });
  }

  // Configurar handlers de mensajes
  static void _setupMessageHandlers() {
    debugPrint('🔧 Configurando handlers de mensajes...');
    
    // Cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 ========================================');
      debugPrint('📨 MENSAJE RECIBIDO EN FOREGROUND!');
      debugPrint('📨 Message ID: ${message.messageId}');
      debugPrint('📨 Notification: ${message.notification}');
      debugPrint('📨 Title: ${message.notification?.title}');
      debugPrint('📨 Body: ${message.notification?.body}');
      debugPrint('📨 Data: ${message.data}');
      debugPrint('📨 ========================================');
      _showLocalNotification(message);
    }, onError: (error) {
      debugPrint('❌ Error en onMessage listener: $error');
    });

    // Cuando el usuario toca la notificación (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 Notificación tocada (background): ${message.data}');
      _handleNotificationTap(message.data);
    });

    // Verificar si la app se abrió desde una notificación
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🚀 App abierta desde notificación: ${message.data}');
        _handleNotificationTap(message.data);
      }
    });
    
    debugPrint('✅ Handlers de mensajes configurados');
  }

  // Mostrar notificación local
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      debugPrint('🔔 Intentando mostrar notificación local...');
      RemoteNotification? notification = message.notification;

      if (notification != null) {
        debugPrint('   Título: ${notification.title}');
        debugPrint('   Cuerpo: ${notification.body}');
        
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Notificaciones Importantes',
              channelDescription: 'Canal para notificaciones importantes de Óolale',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
        
        debugPrint('✅ Notificación local mostrada exitosamente');
      } else {
        debugPrint('⚠️ El mensaje no tiene notification payload');
      }
    } catch (e) {
      debugPrint('❌ Error mostrando notificación local: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    }
  }

  // Manejar tap en notificación local
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Notificación local tocada: ${response.payload}');
    // TODO: Implementar navegación desde payload
  }

  // Manejar tap en notificación (navegación)
  static void _handleNotificationTap(Map<String, dynamic> data) {
    try {
      final type = data['type'];
      
      debugPrint('🔀 Manejando navegación para tipo: $type');
      
      // TODO: Implementar navegación real con GoRouter
      switch (type) {
        case 'connection_request':
          debugPrint('→ Navegar a solicitudes de conexión');
          break;
        case 'connection_accepted':
          debugPrint('→ Navegar a conexiones');
          break;
        case 'new_message':
          final userId = data['user_id'];
          debugPrint('→ Navegar a chat con usuario: $userId');
          break;
        case 'new_rating':
          final userId = data['user_id'];
          debugPrint('→ Navegar a calificaciones de usuario: $userId');
          break;
        case 'event_invitation':
          final eventId = data['event_id'];
          debugPrint('→ Navegar a evento: $eventId');
          break;
        default:
          debugPrint('⚠️ Tipo de notificación desconocido: $type');
      }
    } catch (e) {
      debugPrint('❌ Error manejando tap de notificación: $e');
    }
  }

  // Obtener contador de notificaciones no leídas
  static Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      // Intentar con 'read' primero, si falla intentar con 'leido'
      final data = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('leido', false);
      return data.length;
    } catch (e) {
      debugPrint('❌ Error obteniendo contador: $e');
      return 0;
    }
  }

  // Marcar notificación como leída
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'leido': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
      
      debugPrint('✅ Notificación marcada como leída: $notificationId');
    } catch (e) {
      debugPrint('❌ Error marcando como leída: $e');
    }
  }

  // Marcar todas como leídas
  static Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'leido': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('leido', false);
      
      debugPrint('✅ Todas las notificaciones marcadas como leídas');
    } catch (e) {
      debugPrint('❌ Error marcando todas como leídas: $e');
    }
  }

  // Eliminar token al cerrar sesión
  static Future<void> deleteToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      final userId = _supabase.auth.currentUser?.id;

      if (token != null && userId != null) {
        await _supabase
            .from('device_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', token);
        
        debugPrint('✅ Token eliminado de Supabase');
      }
    } catch (e) {
      debugPrint('❌ Error eliminando token: $e');
    }
  }
}
