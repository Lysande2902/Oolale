import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../config/constants.dart';
import '../../models/event.dart';
import 'create_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<Evento> _events = [];
  bool _isLoading = true;
  int _page = 0;
  bool _hasMore = true;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadGigs();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (!_isLoading && _hasMore) {
          _loadGigs(isLoadMore: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGigs({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (!_hasMore) return;
      _page++;
    } else {
      _page = 0;
      _hasMore = true;
      setState(() => _isLoading = true);
    }

    try {
      var queryBuilder = _supabase.from('gigs').select();
      
      final query = _searchController.text;
      if (query.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('titulo_bolo', '%$query%'); // Buscar por título
      }

      final from = _page * _limit;
      final to = from + _limit - 1;
      
      final List<dynamic> data = await queryBuilder
          .order('fecha_gig', ascending: true)
          .range(from, to);
          
      if (mounted) {
        setState(() {
          final newEvents = data.map((e) => Evento.fromJson(e)).toList();
          if (isLoadMore) {
            _events.addAll(newEvents);
          } else {
            _events = newEvents;
          }
          
          if (newEvents.length < _limit) {
            _hasMore = false;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando gigs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _performSearch(String query) {
    // Debounce manual o simplemente recargar
    _loadGigs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCreateButton(),
            Expanded(
              child: _isLoading && _events.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                  : _events.isEmpty
                      ? _buildEmptyState()
                      : _buildEventList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eventos',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _searchController.text.isEmpty 
                    ? 'Todos' 
                    : '${_events.length}',
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConstants.primaryColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search, color: AppConstants.primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _performSearch,
                style: GoogleFonts.outfit(),
                decoration: InputDecoration(
                  hintText: 'Encuentra tu próximo evento...',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateEventScreen()),
            );
            if (result == true) _loadGigs();
          },
          icon: const Icon(Icons.add_circle_outline, size: 22),
          label: Text(
            'Crear',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildEventList() {
    return RefreshIndicator(
      onRefresh: () async {
        _page = 0;
        _hasMore = true;
        await _loadGigs();
      },
      color: AppConstants.primaryColor,
      backgroundColor: AppConstants.bgDarkPanel,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _events.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _events.length) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: AppConstants.primaryColor),
            ));
          }
          return FadeInUp(
            duration: const Duration(milliseconds: 300),
            delay: Duration(milliseconds: (index % 10) * 30), // Modulo to prevent long delays
            child: _GigCard(event: _events[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 60, color: Colors.grey[800]),
          const SizedBox(height: 20),
          Text(
            _searchController.text.isEmpty 
              ? 'No hay gigs programados' 
              : 'Sin resultados para "${_searchController.text}"',
            style: GoogleFonts.outfit(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _GigCard extends StatelessWidget {
  final Evento event;

  const _GigCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final day = event.fecha.day.toString().padLeft(2, '0');
    final month = DateFormat.MMM('es_ES').format(event.fecha).toUpperCase();
    final weekday = DateFormat.EEEE('es_ES').format(event.fecha);

    return GestureDetector(
      onTap: () => context.push('/gig/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            // Fecha lateral con gradiente
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppConstants.primaryColor.withOpacity(0.3),
                    AppConstants.primaryColor.withOpacity(0.1),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    month,
                    style: GoogleFonts.outfit(
                      color: AppConstants.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    weekday.substring(0, 3).toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Info del evento
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.tipo.replaceAll('_', ' ').toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: AppConstants.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.access_time_rounded, color: Colors.grey[600], size: 14),
                        const SizedBox(width: 4),
                        Text(
                          event.hora,
                          style: GoogleFonts.outfit(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.titulo,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: AppConstants.primaryColor, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.ubicacion,
                            style: GoogleFonts.outfit(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Arrow indicator
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[700], size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
