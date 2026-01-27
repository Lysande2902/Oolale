import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/user.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final sb.SupabaseClient _supabase = sb.Supabase.instance.client;
  
  AuthStatus _status = AuthStatus.checking;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Verificar sesión actual al inicio
    final session = _supabase.auth.currentSession;
    _updateUserFromSession(session);
    
    // Escuchar cambios
    _supabase.auth.onAuthStateChange.listen((data) {
      final sb.AuthChangeEvent event = data.event;
      final sb.Session? session = data.session;
      
      debugPrint('AUTH_PROVIDER: Evento recibido: $event');
      _updateUserFromSession(session);
    });
  }

  void _updateUserFromSession(sb.Session? session) {
    if (session != null) {
      _user = User(
        id: session.user.id,
        email: session.user.email ?? '',
        name: session.user.userMetadata?['full_name'] ?? 'Usuario',
        isAdmin: session.user.userMetadata?['is_admin'] ?? false,
      );
      _status = AuthStatus.authenticated;
      debugPrint('AUTH_PROVIDER: Estado -> AUTHENTICATED (${_user!.email})');
    } else {
      _user = null;
      _status = AuthStatus.unauthenticated;
      debugPrint('AUTH_PROVIDER: Estado -> UNAUTHENTICATED');
    }
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final session = _supabase.auth.currentSession;
    _updateUserFromSession(session);
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('AUTH_PROVIDER: Intentando login con $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        debugPrint('AUTH_PROVIDER: Login exitoso para ${response.user!.id}');
        // Forzamos actualización inmediata para que la UI reaccione rápido
        _updateUserFromSession(response.session);
        return true;
      }
      return false;
    } on sb.AuthException catch (e) {
      debugPrint('AUTH_PROVIDER: Error AuthException: ${e.message}');
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('AUTH_PROVIDER: Error general: $e');
      _errorMessage = 'Ocurrió un error inesperado: $e';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name, String rol) async {
    _status = AuthStatus.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('AUTH_PROVIDER: Registrando $email');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'rol_principal': rol,
        },
      );
      
      if (response.user != null) {
        debugPrint('AUTH_PROVIDER: Registro exitoso');
        _updateUserFromSession(response.session);
        return true;
      }
      return false;
    } on sb.AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ocurrió un error inesperado';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _status = AuthStatus.unauthenticated;
    _user = null;
    notifyListeners();
  }
}
