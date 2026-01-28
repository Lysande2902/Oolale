import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../config/constants.dart';
import '../../config/theme_colors.dart';
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
  
  List<Evento> _allEvents = [];
  List<Evento> _todayEvents = [];
  List<Evento> _thisWeekEvents = [];
  List<Evento> _thisMonthEvents = [];
  List<Evento> _upcomingEvents = [];
  List<Evento> _pastEvents = [];
  
  bool _isLoading = true;
  bool _showFilters = false;
  String _selectedView = 'upcoming'; // upcoming, past, today, week, month
  String _sortBy = 'date'; // date, proximity, popularity
  
  // Filtros
  String? _selectedType;
  String? _selectedCity;
  DateTime? _startDate;
  DateTime? _endDate;
  
  int _page = 0;
  bool _hasMore = true;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadGigs();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasMore && _selectedView == 'upcoming') {
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
      
      // Búsqueda amplia
      final query = _searchController.text;
      if (query.isNotEmpty) {
        queryBuilder = queryBuilder.or(
          'titulo_bolo.ilike.%$query%,'
          'lugar_nombre.ilike.%$query%,'
          'lugar_ciudad.ilike.%$query%,'
          'tipo.ilike.%$query%'
        );
      }
      
      // Filtros
      if (_selectedType != null) {
        queryBuilder = queryBuilder.eq('tipo', _selectedType!);
      }
      if (_selectedCity != null) {
        queryBuilder = queryBuilder.ilike('lugar_ciudad', '%$_selectedCity%');
      }
      if (_startDate != null) {
        queryBuilder = queryBuilder.gte('fecha_gig', _startDate!.toIso8601String().split('T')[0]);
      }
      if (_endDate != null) {
        queryBuilder = queryBuilder.lte('fecha_gig', _endDate!.toIso8601String().split('T')[0]);
      }

      // Ordenamiento y paginación
      final from = _page * _limit;
      final to = from + _limit - 1;
      
      final List<dynamic> data;
      if (_sortBy == 'date') {
        data = await queryBuilder.order('fecha_gig', ascending: true).range(from, to);
      } else if (_sortBy == 'popularity') {
        data = await queryBuilder.order('created_at', ascending: false).range(from, to);
      } else {
        data = await queryBuilder.order('fecha_gig', ascending: true).range(from, to);
      }
          
      if (mounted) {
        final newEvents = data.map((e) => Evento.fromJson(e)).toList();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekEnd = today.add(const Duration(days: 7));
        final monthEnd = DateTime(now.year, now.month + 1, now.day);
        
        if (isLoadMore) {
          _allEvents.addAll(newEvents);
        } else {
          _allEvents = newEvents;
        }
        
        // Categorizar eventos
        _todayEvents = _allEvents.where((e) {
          final eventDate = DateTime(e.fecha.year, e.fecha.month, e.fecha.day);
          return eventDate.isAtSameMomentAs(today);
        }).toList();
        
        _thisWeekEvents = _allEvents.where((e) {
          final eventDate = DateTime(e.fecha.year, e.fecha.month, e.fecha.day);
          return eventDate.isAfter(today) && eventDate.isBefore(weekEnd);
        }).toList();
        
        _thisMonthEvents = _allEvents.where((e) {
          final eventDate = DateTime(e.fecha.year, e.fecha.month, e.fecha.day);
          return eventDate.isAfter(weekEnd) && eventDate.isBefore(monthEnd);
        }).toList();
        
        _upcomingEvents = _allEvents.where((e) => 
          e.fecha.isAfter(now) || 
          DateTime(e.fecha.year, e.fecha.month, e.fecha.day).isAtSameMomentAs(today)
        ).toList();
        
        _pastEvents = _allEvents.where((e) {
          final eventDate = DateTime(e.fecha.year, e.fecha.month, e.fecha.day);
          return eventDate.isBefore(today);
        }).toList();
        
        if (newEvents.length < _limit) {
          _hasMore = false;
        }
        
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error cargando gigs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _performSearch(String query) {
    _page = 0;
    _hasMore = true;
    _loadGigs();
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedCity = null;
      _startDate = null;
      _endDate = null;
    });
    _loadGigs();
  }

  List<Evento> _getCurrentEvents() {
    switch (_selectedView) {
      case 'today':
        return _todayEvents;
      case 'week':
        return _thisWeekEvents;
      case 'month':
        return _thisMonthEvents;
      case 'past':
        return _pastEvents;
      default:
        return _upcomingEvents;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayEvents = _getCurrentEvents();
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryChips(),
            if (_showFilters) _buildFilters(),
            Expanded(
              child: _isLoading && _allEvents.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                  : displayEvents.isEmpty
                      ? _buildEmptyState()
                      : _buildEventList(displayEvents),
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
                    color: ThemeColors.primaryText(context),
                  ),
                ),
                Text(
                  _getSubtitle(),
                  style: GoogleFonts.outfit(
                    color: ThemeColors.secondaryText(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: _showFilters ? AppConstants.primaryColor : ThemeColors.iconSecondary(context),
                ),
                onPressed: () => setState(() => _showFilters = !_showFilters),
              ),
              IconButton(
                icon: Icon(
                  _sortBy == 'date' ? Icons.calendar_today : 
                  _sortBy == 'proximity' ? Icons.location_on : Icons.trending_up,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                onPressed: _showSortMenu,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSubtitle() {
    switch (_selectedView) {
      case 'today':
        return '${_todayEvents.length} eventos hoy';
      case 'week':
        return '${_thisWeekEvents.length} esta semana';
      case 'month':
        return '${_thisMonthEvents.length} este mes';
      case 'past':
        return '${_pastEvents.length} pasados';
      default:
        return '${_upcomingEvents.length} próximos';
    }
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ordenar por',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeColors.primaryText(context),
              ),
            ),
            const SizedBox(height: 20),
            _buildSortOption('Fecha', 'date', Icons.calendar_today),
            _buildSortOption('Proximidad', 'proximity', Icons.location_on),
            _buildSortOption('Popularidad', 'popularity', Icons.trending_up),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppConstants.primaryColor : ThemeColors.iconSecondary(context)),
      title: Text(
        label,
        style: GoogleFonts.outfit(
          color: isSelected ? AppConstants.primaryColor : ThemeColors.primaryText(context),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: AppConstants.primaryColor) : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
        _loadGigs();
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppConstants.primaryColor.withOpacity(0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.search, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _performSearch,
                  style: GoogleFonts.outfit(color: ThemeColors.primaryText(context), fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Buscar eventos, lugares, ciudades...',
                    hintStyle: GoogleFonts.outfit(color: ThemeColors.hintText(context), fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: ThemeColors.iconSecondary(context), size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          if (_todayEvents.isNotEmpty)
            _buildCategoryChip('Hoy', 'today', _todayEvents.length),
          if (_todayEvents.isNotEmpty) const SizedBox(width: 8),
          _buildCategoryChip('Esta Semana', 'week', _thisWeekEvents.length),
          const SizedBox(width: 8),
          _buildCategoryChip('Este Mes', 'month', _thisMonthEvents.length),
          const SizedBox(width: 8),
          _buildCategoryChip('Próximos', 'upcoming', _upcomingEvents.length),
          const SizedBox(width: 8),
          _buildCategoryChip('Pasados', 'past', _pastEvents.length),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateEventScreen()),
              );
              if (result == true) _loadGigs();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Colors.black, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value, int count) {
    final isSelected = _selectedView == value;
    final isToday = value == 'today';
    
    return GestureDetector(
      onTap: () => setState(() => _selectedView = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
            ? (isToday ? Colors.red.withOpacity(0.2) : AppConstants.primaryColor.withOpacity(0.2))
            : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? (isToday ? Colors.red : AppConstants.primaryColor)
              : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            if (isToday && isSelected)
              Icon(Icons.today, color: Colors.red, size: 16),
            if (isToday && isSelected) const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: GoogleFonts.outfit(
                color: isSelected 
                  ? (isToday ? Colors.red : AppConstants.primaryColor)
                  : Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros Avanzados',
                style: GoogleFonts.outfit(
                  color: ThemeColors.primaryText(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Limpiar',
                  style: GoogleFonts.outfit(
                    color: AppConstants.primaryColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tipo de Evento',
            style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Concierto', 'concierto'),
              _buildFilterChip('Jam Session', 'jam_session'),
              _buildFilterChip('Festival', 'festival'),
              _buildFilterChip('Ensayo', 'ensayo'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Rango de Fechas',
            style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                      _loadGigs();
                    }
                  },
                  icon: Icon(Icons.calendar_today, size: 16, color: ThemeColors.secondaryText(context)),
                  label: Text(
                    _startDate != null 
                      ? DateFormat('dd/MM/yy').format(_startDate!)
                      : 'Desde',
                    style: GoogleFonts.outfit(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ThemeColors.primaryText(context),
                    side: BorderSide(color: ThemeColors.divider(context)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                      _loadGigs();
                    }
                  },
                  icon: Icon(Icons.calendar_today, size: 16, color: ThemeColors.secondaryText(context)),
                  label: Text(
                    _endDate != null 
                      ? DateFormat('dd/MM/yy').format(_endDate!)
                      : 'Hasta',
                    style: GoogleFonts.outfit(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ThemeColors.primaryText(context),
                    side: BorderSide(color: ThemeColors.divider(context)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = isSelected ? null : value);
        _loadGigs();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? AppConstants.primaryColor : ThemeColors.secondaryText(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEventList(List<Evento> events) {
    return RefreshIndicator(
      onRefresh: () async {
        _page = 0;
        _hasMore = true;
        await _loadGigs();
      },
      color: AppConstants.primaryColor,
      backgroundColor: Theme.of(context).cardColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: events.length + (_hasMore && _selectedView == 'upcoming' ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == events.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppConstants.primaryColor),
              ),
            );
          }
          return FadeInUp(
            duration: const Duration(milliseconds: 250),
            delay: Duration(milliseconds: index * 20),
            child: _EventCard(
              event: events[index],
              isPast: _selectedView == 'past',
              isToday: _selectedView == 'today',
            ),
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
          Icon(
            _selectedView == 'past' ? Icons.history : Icons.event_available,
            size: 80,
            color: ThemeColors.iconSecondary(context),
          ),
          const SizedBox(height: 20),
          Text(
            _getEmptyMessage(),
            style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 16),
          ),
          if (_selectedView == 'upcoming' && _searchController.text.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Toca + para crear uno',
              style: GoogleFonts.outfit(color: ThemeColors.hintText(context), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_selectedView) {
      case 'today':
        return 'No hay eventos hoy';
      case 'week':
        return 'No hay eventos esta semana';
      case 'month':
        return 'No hay eventos este mes';
      case 'past':
        return 'No hay eventos pasados';
      default:
        return 'No hay eventos próximos';
    }
  }
}

class _EventCard extends StatelessWidget {
  final Evento event;
  final bool isPast;
  final bool isToday;

  const _EventCard({
    required this.event,
    this.isPast = false,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final day = event.fecha.day.toString();
    final month = DateFormat.MMM('es_ES').format(event.fecha).toUpperCase();
    final hasImage = event.flyerUrl != null && event.flyerUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push('/gig/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isToday
              ? Colors.red.withOpacity(0.3)
              : isPast 
                ? Colors.grey.withOpacity(0.1) 
                : AppConstants.primaryColor.withOpacity(0.15),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Imagen o fecha
              if (hasImage)
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 120,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(event.flyerUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Overlay con fecha
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isToday
                            ? Colors.red
                            : isPast 
                              ? Colors.grey[800]
                              : AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              day,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                height: 1,
                              ),
                            ),
                            Text(
                              month,
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      width: 100,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Theme.of(context).cardColor.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: 80,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isToday
                      ? Colors.red.withOpacity(0.1)
                      : isPast 
                        ? Colors.grey.withOpacity(0.1)
                        : AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isToday
                            ? Colors.red
                            : isPast 
                              ? Colors.grey[500] 
                              : AppConstants.primaryColor,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        month,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isToday
                            ? Colors.red
                            : isPast 
                              ? Colors.grey[600] 
                              : AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.titulo,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ThemeColors.primaryText(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isToday
                            ? Colors.red.withOpacity(0.2)
                            : isPast 
                              ? Colors.grey.withOpacity(0.2)
                              : AppConstants.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.tipo.replaceAll('_', ' ').toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: isToday
                              ? Colors.red
                              : isPast 
                                ? Colors.grey[500] 
                                : AppConstants.primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on, 
                            color: isToday
                              ? Colors.red
                              : isPast 
                                ? Colors.grey[600] 
                                : AppConstants.primaryColor, 
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.ubicacion,
                              style: GoogleFonts.outfit(
                                color: ThemeColors.secondaryText(context),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: ThemeColors.iconSecondary(context), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            event.hora,
                            style: GoogleFonts.outfit(
                              color: ThemeColors.hintText(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right, color: ThemeColors.iconSecondary(context), size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
