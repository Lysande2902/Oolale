import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Direct DB
import '../../config/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final _supabase = Supabase.instance.client; // Direct connection
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _results = [];
  bool _isLoading = false;
  String _activeFilter = 'todos'; 

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    
    try {
      var queryBuilder = _supabase.from('profiles').select();
      
      if (query.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('nombre_artistico', '%$query%');
      }

      // Aplicar filtro por tipo de rol
      if (_activeFilter == 'musicos') {
        queryBuilder = queryBuilder.eq('rol_principal', 'musico');
      } else if (_activeFilter == 'bandas') {
        queryBuilder = queryBuilder.eq('rol_principal', 'banda');
      } else if (_activeFilter == 'open_to_work') {
        queryBuilder = queryBuilder.eq('open_to_work', true);
      }

      // No mostrarse a uno mismo en búsquedas (¡autocuidado preventivo! jaja)
      final myId = _supabase.auth.currentUser?.id;
      if (myId != null) {
        queryBuilder = queryBuilder.neq('id', myId);
      }

      final response = await queryBuilder.limit(20);
      
      if (mounted) {
        setState(() {
          _results = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error Discovery: $e');
      if(mounted) {
        setState(() {
         _isLoading = false; 
         if (_results.isEmpty) _loadDummyDiscovery();
      });
      }
    }
  }

  void _loadDummyDiscovery() {
      _results = [
          {'id': '1', 'nombre_artistico': 'Leo Fender', 'ubicacion_base': 'CDMX', 'nivel_badge': 'pro', 'instrumento_principal': 'Guitarra'},
          {'id': '2', 'nombre_artistico': 'Ringo Starr', 'ubicacion_base': 'Liverpool', 'nivel_badge': 'maestro', 'instrumento_principal': 'Batería'},
          {'id': '3', 'nombre_artistico': 'Flea', 'ubicacion_base': 'LA', 'nivel_badge': 'pro', 'instrumento_principal': 'Bajo'},
          {'id': '4', 'nombre_artistico': 'Miles Davis', 'ubicacion_base': 'NY', 'nivel_badge': 'leyenda', 'instrumento_principal': 'Trompeta'},
      ];
  }

  Future<void> _sendConnectionRequest(String targetId) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión')),
      );
      return;
    }

    try {
      // Verificar si ya existe una conexión
      final existing = await _supabase
          .from('crews')
          .select()
          .eq('perfil_id', myId)
          .eq('target_id', targetId)
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ya tienes una conexión con este usuario')),
          );
        }
        return;
      }

      // Crear nueva solicitud
      await _supabase.from('crews').insert({
        'perfil_id': myId,
        'target_id': targetId,
        'estatus': 'pendiente',
        'es_colaboracion': false,
      });

      // Notificar al usuario objetivo
      await _supabase.from('notifications').insert({
        'user_id': targetId,
        'tipo': 'connection_request',
        'titulo': 'Nueva solicitud de conexión',
        'mensaje': 'Un músico quiere conectar contigo',
        'leido': false,
        'data': {'sender_id': myId},
        // 'created_at': DateTime.now().toIso8601String(), // Supabase usa default now()
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Solicitud enviada!'),
            backgroundColor: AppConstants.primaryColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending connection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar solicitud')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header & Search
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text('Explorar', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white12)
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      onSubmitted: _performSearch,
                      decoration: InputDecoration(
                        hintText: 'Músico, banda o instrumento...',
                        hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4)),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.filter_list, color: AppConstants.accentColor),
                          onPressed: () {
                             // TODO: Abrir modal de filtros avanzados
                          },
                        )
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Filters / Chips
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                children: [
                  _buildFilterChip('Todos', 'todos'),
                  _buildFilterChip('Músicos', 'musicos'),
                  _buildFilterChip('Bandas', 'bandas'),
                  _buildFilterChip('Open To Work', 'open_to_work'),
                ],
              ),
            ),

            // 3. Grid Results
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                : _results.isEmpty 
                  ? Center(child: Text('No se encontraron resultados', style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4))))
                  : GridView.builder(
                      padding: const EdgeInsets.all(15),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15
                      ),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        return _buildArtistCard(_results[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String id) {
    final bool isActive = _activeFilter == id;
    return GestureDetector(
      onTap: () {
        setState(() => _activeFilter = id);
        _performSearch(_searchController.text); // Trigger search with filter
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppConstants.primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label, 
          style: TextStyle(
            color: isActive ? Colors.black : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: 12
          )
        ),
      ),
    );
  }

  Widget _buildArtistCard(dynamic item, int index) {
    return FadeInUp(
      delay: Duration(milliseconds: index * 100),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    item['nivel_badge'] == 'pro' || item['nivel_badge'] == 'maestro' ? AppConstants.accentColor : Colors.transparent,
                    AppConstants.primaryColor
                  ]
                )
              ),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: Text(
                   (item['nombre_artistico'] ?? 'A')[0].toUpperCase(),
                   style: TextStyle(fontSize: 24, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)
                ),
                // backgroundImage: NetworkImage(item['foto_url']) // Si hubiera foto
              ),
            ),
            const SizedBox(height: 12),
            
            // Info
            Text(
              item['nombre_artistico'] ?? 'Artista',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              (item['instrumento_principal'] ?? 'Músico General').toUpperCase(),
              style: const TextStyle(color: AppConstants.primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text(item['ubicacion_base'] ?? 'Mundo', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4), fontSize: 12)),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // Action Button
            SizedBox(
              height: 36,
              width: 110,
              child: ElevatedButton(
                onPressed: () => _sendConnectionRequest(item['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: Text('Conectar', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
