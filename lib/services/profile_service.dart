import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing user profiles with enhanced features
class ProfileService {
  final SupabaseClient _supabase;

  ProfileService(this._supabase);

  /// Save musical genres for a user
  Future<void> saveGenres(String userId, List<String> genres) async {
    try {
      // Delete existing genres
      await _supabase
          .from('profile_genres')
          .delete()
          .eq('profile_id', userId);

      // Insert new genres
      if (genres.isNotEmpty) {
        final genreRecords = genres.map((genre) => {
          'profile_id': userId,
          'genre': genre,
        }).toList();

        await _supabase.from('profile_genres').insert(genreRecords);
      }

      debugPrint('✅ Genres saved: ${genres.length}');
    } catch (e) {
      debugPrint('❌ Error saving genres: $e');
      rethrow;
    }
  }

  /// Get available genres from database
  Future<List<String>> getAvailableGenres() async {
    try {
      final data = await _supabase
          .from('genres')
          .select('name')
          .order('name', ascending: true);

      return data.map((g) => g['name'] as String).toList();
    } catch (e) {
      debugPrint('❌ Error getting available genres: $e');
      // Return default genres if database query fails
      return [
        'Rock',
        'Pop',
        'Jazz',
        'Blues',
        'Metal',
        'Reggae',
        'Salsa',
        'Cumbia',
        'Electrónica',
        'Hip Hop',
        'R&B',
        'Country',
        'Folk',
        'Clásica',
        'Latina',
      ];
    }
  }

  /// Get user's selected genres
  Future<List<String>> getUserGenres(String userId) async {
    try {
      final data = await _supabase
          .from('profile_genres')
          .select('genre')
          .eq('profile_id', userId);

      return data.map((g) => g['genre'] as String).toList();
    } catch (e) {
      debugPrint('❌ Error getting user genres: $e');
      return [];
    }
  }

  /// Save experience and availability
  Future<void> saveExperienceAndAvailability(
    String userId,
    int yearsExperience,
    Map<String, dynamic> availability,
  ) async {
    try {
      await _supabase.from('profiles').update({
        'years_experience': yearsExperience,
        'availability': availability,
      }).eq('id', userId);

      debugPrint('✅ Experience and availability saved');
    } catch (e) {
      debugPrint('❌ Error saving experience and availability: $e');
      rethrow;
    }
  }

  /// Save base rate with currency
  Future<void> saveBaseRate(String userId, double amount, String currency) async {
    try {
      await _supabase.from('profiles').update({
        'base_rate': amount,
        'currency': currency,
      }).eq('id', userId);

      debugPrint('✅ Base rate saved: $amount $currency');
    } catch (e) {
      debugPrint('❌ Error saving base rate: $e');
      rethrow;
    }
  }

  /// Save social links
  Future<void> saveSocialLinks(String userId, Map<String, String> links) async {
    try {
      // Filter out empty links
      final filteredLinks = Map<String, String>.from(links)
        ..removeWhere((key, value) => value.trim().isEmpty);

      await _supabase.from('profiles').update({
        'social_links': filteredLinks,
      }).eq('id', userId);

      debugPrint('✅ Social links saved: ${filteredLinks.length}');
    } catch (e) {
      debugPrint('❌ Error saving social links: $e');
      rethrow;
    }
  }

  /// Calculate profile completion percentage
  /// Based on 11 required fields
  int calculateProfileCompletion(Map<String, dynamic> profile) {
    int completedFields = 0;
    const int totalFields = 11;

    // Required fields
    if (profile['nombre_artistico'] != null && profile['nombre_artistico'].toString().isNotEmpty) completedFields++;
    if (profile['foto_perfil'] != null && profile['foto_perfil'].toString().isNotEmpty) completedFields++;
    if (profile['bio'] != null && profile['bio'].toString().isNotEmpty) completedFields++;
    if (profile['instrumento_principal'] != null && profile['instrumento_principal'].toString().isNotEmpty) completedFields++;
    if (profile['ubicacion'] != null && profile['ubicacion'].toString().isNotEmpty) completedFields++;
    
    // New optional fields
    if (profile['years_experience'] != null && profile['years_experience'] > 0) completedFields++;
    if (profile['availability'] != null && (profile['availability'] as Map).isNotEmpty) completedFields++;
    if (profile['base_rate'] != null && profile['base_rate'] > 0) completedFields++;
    if (profile['social_links'] != null && (profile['social_links'] as Map).isNotEmpty) completedFields++;
    
    // Check if has genres
    // This would need a separate query in practice
    completedFields++; // Assume genres exist for now
    
    // Check if has portfolio items
    completedFields++; // Assume portfolio exists for now

    return ((completedFields / totalFields) * 100).round();
  }

  /// Get list of missing fields for profile completion
  List<String> getMissingFields(Map<String, dynamic> profile) {
    final List<String> missing = [];

    if (profile['nombre_artistico'] == null || profile['nombre_artistico'].toString().isEmpty) {
      missing.add('Nombre artístico');
    }
    if (profile['foto_perfil'] == null || profile['foto_perfil'].toString().isEmpty) {
      missing.add('Foto de perfil');
    }
    if (profile['bio'] == null || profile['bio'].toString().isEmpty) {
      missing.add('Biografía');
    }
    if (profile['instrumento_principal'] == null || profile['instrumento_principal'].toString().isEmpty) {
      missing.add('Instrumento principal');
    }
    if (profile['ubicacion'] == null || profile['ubicacion'].toString().isEmpty) {
      missing.add('Ubicación');
    }
    if (profile['years_experience'] == null || profile['years_experience'] == 0) {
      missing.add('Años de experiencia');
    }
    if (profile['availability'] == null || (profile['availability'] as Map?)?.isEmpty != false) {
      missing.add('Disponibilidad');
    }
    if (profile['base_rate'] == null || profile['base_rate'] == 0) {
      missing.add('Tarifa base');
    }
    if (profile['social_links'] == null || (profile['social_links'] as Map?)?.isEmpty != false) {
      missing.add('Redes sociales');
    }

    return missing;
  }

  /// Validate URL format
  bool isValidUrl(String url) {
    if (url.trim().isEmpty) return true; // Empty is valid (optional)
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Validate social media URL for specific platform
  bool isValidSocialUrl(String platform, String url) {
    if (url.trim().isEmpty) return true;
    
    if (!isValidUrl(url)) return false;

    final lowerUrl = url.toLowerCase();
    switch (platform.toLowerCase()) {
      case 'instagram':
        return lowerUrl.contains('instagram.com');
      case 'youtube':
        return lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be');
      case 'spotify':
        return lowerUrl.contains('spotify.com');
      case 'soundcloud':
        return lowerUrl.contains('soundcloud.com');
      default:
        return true;
    }
  }

  /// Update profile completion in database
  Future<void> updateProfileCompletion(String userId) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final completion = calculateProfileCompletion(profile);

      await _supabase
          .from('profiles')
          .update({'profile_completion': completion})
          .eq('id', userId);

      debugPrint('✅ Profile completion updated: $completion%');
    } catch (e) {
      debugPrint('❌ Error updating profile completion: $e');
      rethrow;
    }
  }
}
