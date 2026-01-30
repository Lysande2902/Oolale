import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/constants.dart';
import '../../config/theme_colors.dart';
import '../profile/public_profile_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _artists = [];
  List<dynamic> _featured = [];
  List<dynamic> _verified = [];
  List<dynamic> _nearby = [];
  bool _isLoading = false;
  bool _showSearch = false;
  bool _showFilters = false;
  
  // Filtros
  String? _selectedRole;
  String? _selectedInstrument;
  String? _selectedLocation;
  double? _minRating;
  bool _onlyOpenToWork = false;
  bool _onlyVerified = false;
  String _sortBy = 'recent'; // recent, rating, connections

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      final myId = _supabase.auth.currentUser?.id;
      
      // Obtener lista de usuarios bloqueados
      List<String> blockedIds = [];
      if (myId != null) {
        final blockedUsers = await _supabase
            .from('usuarios_bloqueados')
            .select('bloqueado_id')
            .eq('usuario_id', myId)
            .eq('activo', true);
        blockedIds = blockedUsers.map((b) => b['bloqueado_id'] as String).toList();
      }
      
      // 1. Destacados (Premium o verificados con más actividad)
      var featuredQuery = _supabase.from('profiles').select();
      if (myId != null) featuredQuery = featuredQuery.neq('id', myId);
      
      final featuredData = await featuredQuery
          .or('ranking_tipo.eq.premium,verificado.eq.true')
          .order('rating_promedio', ascending: false)
          .limit(10);
      
      // 2. Verificados
      var verifiedQuery = _supabase.from('profiles').select();
      if (myId != null) verifiedQuery = verifiedQuery.neq('id', myId);
      
      final verifiedData = await verifiedQuery
          .eq('verificado', true)
          .order('created_at', ascending: false)
          .limit(10);
      
      // 3. Variados (mezcla de nuevos y antiguos)
      var mixedQuery = _supabase.from('profiles').select();
      if (myId != null) mixedQuery = mixedQuery.neq('id', myId);
      
      final mixedData = await mixedQuery
          .order('created_at', ascending: false)
          .limit(20);
      
      // Mezclar para variedad
      final List<dynamic> varied = List.from(mixedData)..shuffle();
      
      if (mounted) {
        setState(() {
          // Filtrar usuarios bloqueados
          _featured = featuredData.where((u) => !blockedIds.contains(u['id'])).toList();
          _verified = verifiedData.where((u) => !blockedIds.contains(u['id'])).toList();
          _artists = varied.where((u) => !blockedIds.contains(u['id'])).take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _artists = List.from(_featured)..shuffle();
        _artists = _artists.take(10).toList();
        _showSearch = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showSearch = true;
    });
    
    try {
      final myId = _supabase.auth.currentUser?.id;
      
      // Obtener lista de usuarios bloqueados
      List<String> blockedIds = [];
      if (myId != null) {
        final blockedUsers = await _supabase
            .from('usuarios_bloqueados')
            .select('bloqueado_id')
            .eq('usuario_id', myId)
            .eq('activo', true);
        blockedIds = blockedUsers.map((b) => b['bloqueado_id'] as String).toList();
      }
      
      // Buscar en múltiples campos
      var queryBuilder = _supabase.from('profiles').select('''
        *,
        perfil_gear(gear_catalog(nombre, categoria))
      ''');
      
      // Búsqueda amplia
      queryBuilder = queryBuilder.or(
        'nombre_artistico.ilike.%$query%,'
        'ubicacion_base.ilike.%$query%,'
        'instrumento_principal.ilike.%$query%'
      );
      
      if (myId != null) {
        queryBuilder = queryBuilder.neq('id', myId);
      }
      
      // Aplicar filtros
      if (_selectedRole != null) {
        queryBuilder = queryBuilder.eq('rol_principal', _selectedRole!);
      }
      if (_selectedInstrument != null && _selectedInstrument!.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('instrumento_principal', '%$_selectedInstrument%');
      }
      if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('ubicacion_base', '%$_selectedLocation%');
      }
      if (_minRating != null) {
        queryBuilder = queryBuilder.gte('rating_promedio', _minRating!);
      }
      if (_onlyOpenToWork) {
        queryBuilder = queryBuilder.eq('open_to_work', true);
      }
      if (_onlyVerified) {
        queryBuilder = queryBuilder.eq('verificado', true);
      }

      // Aplicar límite y ordenar resultados
      final data = await (() {
        switch (_sortBy) {
          case 'rating':
            return queryBuilder.order('rating_promedio', ascending: false).limit(60);
          case 'connections':
            return queryBuilder.order('total_conexiones', ascending: false).limit(60);
          case 'recent':
          default:
            return queryBuilder.order('created_at', ascending: false).limit(60);
        }
      })();
      
      if (mounted) {
        setState(() {
          // Filtrar usuarios bloqueados
          _artists = data.where((u) => !blockedIds.contains(u['id'])).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error en búsqueda: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedRole = null;
      _selectedInstrument = null;
      _selectedLocation = null;
      _minRating = null;
      _onlyOpenToWork = false;
      _onlyVerified = false;
      _sortBy = 'recent';
    });
    _performSearch(_searchController.text);
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
            if (_showFilters) _buildFilters(),
            Expanded(
              child: _isLoading && _artists.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                : _buildContent(),
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
                  'Explorar',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.primaryText(context),
                  ),
                ),
                Text(
                  _showSearch ? '${_artists.length} resultados' : 'Descubre artistas',
                  style: GoogleFonts.outfit(
                    color: ThemeColors.secondaryText(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showFilters ? AppConstants.primaryColor : ThemeColors.iconSecondary(context),
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
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
                    hintText: 'Nombre, instrumento, ubicación...',
                    hintStyle: GoogleFonts.outfit(color: ThemeColors.hintText(context), fontSize: 15),
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
                'Filtros',
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
          
          // Rol
          Text('Tipo', style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Músico', _selectedRole == 'musico', () {
                setState(() => _selectedRole = _selectedRole == 'musico' ? null : 'musico');
                _performSearch(_searchController.text);
              }),
              _buildFilterChip('Banda', _selectedRole == 'banda', () {
                setState(() => _selectedRole = _selectedRole == 'banda' ? null : 'banda');
                _performSearch(_searchController.text);
              }),
              _buildFilterChip('Venue', _selectedRole == 'venue', () {
                setState(() => _selectedRole = _selectedRole == 'venue' ? null : 'venue');
                _performSearch(_searchController.text);
              }),
            ],
          ),
          const SizedBox(height: 16),
          
          // Instrumento
          Text('Instrumento', style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() => _selectedInstrument = value.isEmpty ? null : value);
                _performSearch(_searchController.text);
              },
              style: GoogleFonts.outfit(color: ThemeColors.primaryText(context), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ej: Guitarra, Batería...',
                hintStyle: GoogleFonts.outfit(color: ThemeColors.hintText(context), fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Ubicación
          Text('Ubicación', style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() => _selectedLocation = value.isEmpty ? null : value);
                _performSearch(_searchController.text);
              },
              style: GoogleFonts.outfit(color: ThemeColors.primaryText(context), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ej: Ciudad, País...',
                hintStyle: GoogleFonts.outfit(color: ThemeColors.hintText(context), fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Calificación mínima
          Text('Calificación mínima', style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('4+ ⭐', _minRating == 4.0, () {
                setState(() => _minRating = _minRating == 4.0 ? null : 4.0);
                _performSearch(_searchController.text);
              }),
              _buildFilterChip('4.5+ ⭐', _minRating == 4.5, () {
                setState(() => _minRating = _minRating == 4.5 ? null : 4.5);
                _performSearch(_searchController.text);
              }),
            ],
          ),
          const SizedBox(height: 16),
          
          // Otros filtros
          Text('Otros', style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Disponible', _onlyOpenToWork, () {
                setState(() => _onlyOpenToWork = !_onlyOpenToWork);
                _performSearch(_searchController.text);
              }),
              _buildFilterChip('Verificado', _onlyVerified, () {
                setState(() => _onlyVerified = !_onlyVerified);
                _performSearch(_searchController.text);
              }),
            ],
          ),
          const SizedBox(height: 16),
          
          // Ordenar por
          Text('Ordenar por', style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('Recientes', _sortBy == 'recent', () {
                setState(() => _sortBy = 'recent');
                _performSearch(_searchController.text);
              }),
              _buildFilterChip('Mejor calificados', _sortBy == 'rating', () {
                setState(() => _sortBy = 'rating');
                _performSearch(_searchController.text);
              }),
              _buildFilterChip('Más conexiones', _sortBy == 'connections', () {
                setState(() => _sortBy = 'connections');
                _performSearch(_searchController.text);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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

  Widget _buildContent() {
    if (_showSearch) {
      return _buildSearchResults();
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_featured.isNotEmpty) ...[
            _buildSectionTitle('Destacados'),
            _buildHorizontalList(_featured),
            const SizedBox(height: 20),
          ],
          if (_verified.isNotEmpty) ...[
            _buildSectionTitle('Verificados'),
            _buildHorizontalList(_verified),
            const SizedBox(height: 20),
          ],
          _buildSectionTitle('Descubre'),
          _buildVerticalList(_artists),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: ThemeColors.primaryText(context),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<dynamic> artists) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        itemBuilder: (context, index) {
          return _buildHorizontalCard(artists[index]);
        },
      ),
    );
  }

  Widget _buildHorizontalCard(dynamic artist) {
    final rating = (artist['rating_promedio'] ?? 0.0).toDouble();
    final hasRating = rating > 0;
    
    return GestureDetector(
      onTap: () {
        if (!mounted) return;
        context.push('/profile/${artist['id']}');
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeColors.divider(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto con overlay de rating
            Stack(
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    color: Theme.of(context).scaffoldBackgroundColor,
                    image: artist['foto_perfil'] != null
                        ? DecorationImage(
                            image: NetworkImage(artist['foto_perfil']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: artist['foto_perfil'] == null
                      ? Center(
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: AppConstants.primaryColor.withOpacity(0.3),
                          ),
                        )
                      : null,
                ),
                // Rating badge
                if (hasRating)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: AppConstants.primaryColor, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Verificado badge
                if (artist['verificado'] == true)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified, color: Colors.black, size: 14),
                    ),
                  ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      artist['nombre_artistico'] ?? 'Artista',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.primaryText(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (artist['instrumento_principal'] != null)
                      Text(
                        artist['instrumento_principal'],
                        style: GoogleFonts.outfit(
                          color: ThemeColors.secondaryText(context),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_artists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: ThemeColors.iconSecondary(context)),
            const SizedBox(height: 20),
            Text('Sin resultados', style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 16)),
          ],
        ),
      );
    }

    return _buildVerticalList(_artists);
  }

  Widget _buildVerticalList(List<dynamic> artists) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          duration: const Duration(milliseconds: 250),
          delay: Duration(milliseconds: index * 20),
          child: _ArtistCard(
            artist: artists[index],
            onTap: () {
              if (!mounted) return;
              context.push('/profile/${artists[index]['id']}');
            },
          ),
        );
      },
    );
  }
}

class _ArtistCard extends StatelessWidget {
  final dynamic artist;
  final VoidCallback onTap;

  const _ArtistCard({required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rating = (artist['rating_promedio'] ?? 0.0).toDouble();
    final hasRating = rating > 0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeColors.divider(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Foto con rating overlay
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(context).scaffoldBackgroundColor,
                    image: artist['foto_perfil'] != null
                        ? DecorationImage(
                            image: NetworkImage(artist['foto_perfil']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: artist['foto_perfil'] == null
                      ? Center(
                          child: Icon(
                            Icons.person,
                            size: 35,
                            color: AppConstants.primaryColor.withOpacity(0.3),
                          ),
                        )
                      : null,
                ),
                // Rating badge
                if (hasRating)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: AppConstants.primaryColor, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre y verificado
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          artist['nombre_artistico'] ?? 'Artista',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.primaryText(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (artist['verificado'] == true) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified, color: AppConstants.primaryColor, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Instrumento
                  if (artist['instrumento_principal'] != null)
                    Text(
                      artist['instrumento_principal'],
                      style: GoogleFonts.outfit(
                        color: ThemeColors.secondaryText(context),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  // Rol y ubicación
                  Row(
                    children: [
                      if (artist['ubicacion_base'] != null) ...[
                        Icon(Icons.location_on, color: ThemeColors.iconSecondary(context), size: 12),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            artist['ubicacion_base'],
                            style: GoogleFonts.outfit(
                              color: ThemeColors.secondaryText(context),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: ThemeColors.iconSecondary(context), size: 22),
          ],
        ),
      ),
    );
  }
}
