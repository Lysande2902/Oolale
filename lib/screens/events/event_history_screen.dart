import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';
import '../../config/theme_colors.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import 'package:intl/intl.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  final _supabase = Supabase.instance.client;
  late EventService _eventService;
  List<Evento> _pastEvents = [];
  bool _isLoading = true;
  Map<int, bool> _ratingStatus = {}; // eventId -> hasRated

  @override
  void initState() {
    super.initState();
    _eventService = EventService(_supabase);
    _loadPastEvents();
  }

  Future<void> _loadPastEvents() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final events = await _eventService.getEventHistory(userId);
      
      // Check rating status for each event
      for (final event in events) {
        final participants = await _eventService.getParticipantsToRate(event.id, userId);
        _ratingStatus[event.id] = participants.isEmpty; // true if all rated
      }

      if (mounted) {
        setState(() {
          _pastEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading past events: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar historial de eventos')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ThemeColors.icon(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Historial de Eventos',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : _pastEvents.isEmpty
              ? _buildEmptyState()
              : _buildEventList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: ThemeColors.iconSecondary(context),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin eventos pasados',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ThemeColors.primaryText(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aquí aparecerán los eventos en los que has participado',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: ThemeColors.secondaryText(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList() {
    return RefreshIndicator(
      onRefresh: _loadPastEvents,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _pastEvents.length,
        itemBuilder: (context, index) {
          final event = _pastEvents[index];
          final hasRated = _ratingStatus[event.id] ?? false;
          return _EventCard(
            event: event,
            hasRated: hasRated,
            onTap: () => _navigateToEventDetail(event.id),
            onRateTap: hasRated ? null : () => _navigateToRating(event.id),
          );
        },
      ),
    );
  }

  void _navigateToEventDetail(int eventId) {
    Navigator.pushNamed(context, '/gig-detail', arguments: eventId);
  }

  void _navigateToRating(int eventId) {
    Navigator.pushNamed(
      context,
      '/leave-rating',
      arguments: {'eventId': eventId},
    ).then((_) => _loadPastEvents()); // Refresh after rating
  }
}

class _EventCard extends StatelessWidget {
  final Evento event;
  final bool hasRated;
  final VoidCallback onTap;
  final VoidCallback? onRateTap;

  const _EventCard({
    required this.event,
    required this.hasRated,
    required this.onTap,
    this.onRateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeColors.divider(context)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.titulo,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ThemeColors.primaryText(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: ThemeColors.secondaryText(context),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm', 'es').format(event.fecha),
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: ThemeColors.secondaryText(context),
                                ),
                              ),
                            ],
                          ),
                          if (event.ubicacion.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: ThemeColors.secondaryText(context),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    event.ubicacion,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: ThemeColors.secondaryText(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildRatingBadge(context),
                  ],
                ),
                if (!hasRated && onRateTap != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star_outline,
                          size: 20,
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Califica a los participantes de este evento',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: ThemeColors.primaryText(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: onRateTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Calificar',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasRated
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasRated ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasRated ? Icons.check_circle : Icons.pending,
            size: 14,
            color: hasRated ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            hasRated ? 'Calificado' : 'Pendiente',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: hasRated ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}



