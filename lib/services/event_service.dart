import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';

/// Service for managing events, invitations, and RSVPs
class EventService {
  final SupabaseClient _supabase;

  EventService(this._supabase);

  /// Get event history (past events) for a user
  /// Returns events ordered by date (most recent first)
  Future<List<Evento>> getEventHistory(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      // Get events where user is organizer or in lineup
      final data = await _supabase
          .from('gigs')
          .select()
          .or('organizador_id.eq.$userId,lineup.cs.{$userId}')
          .lt('fecha_gig', now)
          .order('fecha_gig', ascending: false);

      return data.map((json) => Evento.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting event history: $e');
      rethrow;
    }
  }

  /// Get upcoming events for a user
  /// Returns events ordered by date (soonest first)
  Future<List<Evento>> getUpcomingEvents(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      // Get events where user is organizer or in lineup
      final data = await _supabase
          .from('gigs')
          .select()
          .or('organizador_id.eq.$userId,lineup.cs.{$userId}')
          .gte('fecha_gig', now)
          .order('fecha_gig', ascending: true);

      return data.map((json) => Evento.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting upcoming events: $e');
      rethrow;
    }
  }

  /// Get events for a specific date
  Future<List<Evento>> getEventsForDate(DateTime date, String userId) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
      
      final data = await _supabase
          .from('gigs')
          .select()
          .or('organizador_id.eq.$userId,lineup.cs.{$userId}')
          .gte('fecha_gig', startOfDay)
          .lte('fecha_gig', endOfDay)
          .order('fecha_gig', ascending: true);

      return data.map((json) => Evento.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting events for date: $e');
      rethrow;
    }
  }

  /// Send invitations to musicians for an event
  /// Creates invitation records and sends notifications
  Future<void> sendInvitations(int eventId, List<String> musicianIds) async {
    try {
      final organizerId = _supabase.auth.currentUser?.id;
      if (organizerId == null) throw Exception('User not authenticated');

      // Get event details
      final event = await _supabase
          .from('gigs')
          .select()
          .eq('id', eventId)
          .single();

      // Create invitations
      final invitations = musicianIds.map((musicianId) => {
        'event_id': eventId,
        'musician_id': musicianId,
        'organizer_id': organizerId,
        'status': 'pending',
      }).toList();

      await _supabase.from('event_invitations').insert(invitations);

      // Get organizer profile
      final organizerProfile = await _supabase
          .from('profiles')
          .select('nombre_artistico')
          .eq('id', organizerId)
          .single();

      // Create notifications for each musician
      final notifications = musicianIds.map((musicianId) => {
        'user_id': musicianId,
        'tipo': 'event_invitation',
        'titulo': 'Invitación a evento',
        'mensaje': '${organizerProfile['nombre_artistico']} te invitó a ${event['titulo_bolo']}',
        'leido': false,
        'data': {
          'event_id': eventId,
          'organizer_id': organizerId,
        },
      }).toList();

      await _supabase.from('notifications').insert(notifications);

      debugPrint('✅ Invitations sent to ${musicianIds.length} musicians');
    } catch (e) {
      debugPrint('❌ Error sending invitations: $e');
      rethrow;
    }
  }

  /// Respond to an event invitation (accept or decline)
  /// Updates invitation status and modifies event lineup if accepted
  Future<void> respondToInvitation(int invitationId, String status) async {
    try {
      if (status != 'accepted' && status != 'declined') {
        throw Exception('Invalid status. Must be "accepted" or "declined"');
      }

      // Get invitation details
      final invitation = await _supabase
          .from('event_invitations')
          .select()
          .eq('id', invitationId)
          .single();

      // Update invitation status
      await _supabase
          .from('event_invitations')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invitationId);

      // If accepted, add musician to event lineup
      if (status == 'accepted') {
        final event = await _supabase
            .from('gigs')
            .select('lineup')
            .eq('id', invitation['event_id'])
            .single();

        List<String> lineup = [];
        if (event['lineup'] != null) {
          lineup = List<String>.from(event['lineup']);
        }

        if (!lineup.contains(invitation['musician_id'])) {
          lineup.add(invitation['musician_id']);
          
          await _supabase
              .from('gigs')
              .update({'lineup': lineup})
              .eq('id', invitation['event_id']);
        }
      }

      // Notify organizer of response
      final musicianProfile = await _supabase
          .from('profiles')
          .select('nombre_artistico')
          .eq('id', invitation['musician_id'])
          .single();

      final eventData = await _supabase
          .from('gigs')
          .select('titulo_bolo')
          .eq('id', invitation['event_id'])
          .single();

      await _supabase.from('notifications').insert({
        'user_id': invitation['organizer_id'],
        'tipo': 'invitation_response',
        'titulo': status == 'accepted' ? 'Invitación aceptada' : 'Invitación rechazada',
        'mensaje': '${musicianProfile['nombre_artistico']} ${status == 'accepted' ? 'aceptó' : 'rechazó'} tu invitación a ${eventData['titulo_bolo']}',
        'leido': false,
        'data': {
          'event_id': invitation['event_id'],
          'musician_id': invitation['musician_id'],
          'status': status,
        },
      });

      debugPrint('✅ Invitation $status');
    } catch (e) {
      debugPrint('❌ Error responding to invitation: $e');
      rethrow;
    }
  }

  /// Get pending invitations for a user
  Future<List<Map<String, dynamic>>> getPendingInvitations(String userId) async {
    try {
      final data = await _supabase
          .from('event_invitations')
          .select('*, gigs(*), profiles!event_invitations_organizer_id_fkey(*)')
          .eq('musician_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('❌ Error getting pending invitations: $e');
      rethrow;
    }
  }

  /// Check if user can rate an event
  /// User can rate if event is past and they participated
  Future<bool> canRateEvent(int eventId, String userId) async {
    try {
      final event = await _supabase
          .from('gigs')
          .select('fecha_gig, lineup, organizador_id')
          .eq('id', eventId)
          .single();

      // Check if event is in the past
      final eventDate = DateTime.parse(event['fecha_gig']);
      if (eventDate.isAfter(DateTime.now())) {
        return false;
      }

      // Check if user participated (in lineup or organizer)
      final lineup = event['lineup'] != null ? List<String>.from(event['lineup']) : [];
      final participated = lineup.contains(userId) || event['organizador_id'] == userId;

      return participated;
    } catch (e) {
      debugPrint('❌ Error checking if can rate event: $e');
      return false;
    }
  }

  /// Get list of participants to rate for an event
  /// Returns users who participated but haven't been rated yet by current user
  Future<List<Map<String, dynamic>>> getParticipantsToRate(int eventId, String userId) async {
    try {
      final event = await _supabase
          .from('gigs')
          .select('lineup, organizador_id')
          .eq('id', eventId)
          .single();

      // Get all participants
      final lineup = event['lineup'] != null ? List<String>.from(event['lineup']) : [];
      final allParticipants = [...lineup];
      
      // Add organizer if not current user
      if (event['organizador_id'] != userId) {
        allParticipants.add(event['organizador_id']);
      }

      // Remove current user
      allParticipants.remove(userId);

      if (allParticipants.isEmpty) return [];

      // Get existing ratings from current user for this event
      final existingRatings = await _supabase
          .from('referencias')
          .select('calificado_id')
          .eq('calificador_id', userId)
          .eq('event_id', eventId);

      final ratedUserIds = existingRatings.map((r) => r['calificado_id'].toString()).toSet();

      // Filter out already rated users
      final unratedUserIds = allParticipants.where((id) => !ratedUserIds.contains(id)).toList();

      if (unratedUserIds.isEmpty) return [];

      // Get profiles for unrated users
      final profiles = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', unratedUserIds);

      return List<Map<String, dynamic>>.from(profiles);
    } catch (e) {
      debugPrint('❌ Error getting participants to rate: $e');
      rethrow;
    }
  }

  /// Check if event is within 24 hours
  bool isEventWithin24Hours(DateTime eventDate) {
    final now = DateTime.now();
    final difference = eventDate.difference(now);
    return difference.inHours <= 24 && difference.inHours >= 0;
  }

  /// Get events within 24 hours for a user (for reminders)
  Future<List<Evento>> getEventsWithin24Hours(String userId) async {
    try {
      final now = DateTime.now();
      final in24Hours = now.add(const Duration(hours: 24)).toIso8601String();
      
      final data = await _supabase
          .from('gigs')
          .select()
          .or('organizador_id.eq.$userId,lineup.cs.{$userId}')
          .gte('fecha_gig', now.toIso8601String())
          .lte('fecha_gig', in24Hours)
          .order('fecha_gig', ascending: true);

      return data.map((json) => Evento.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting events within 24 hours: $e');
      rethrow;
    }
  }
}

