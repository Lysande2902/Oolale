import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/constants.dart';
import '../../models/post.dart';
import 'package:intl/intl.dart';
import '../events/events_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/public_profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _StreamView(onTabChange: (i) => setState(() => _currentIndex = i)),
      const UserSearchScreen(), 
      const EventsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: screens),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0)],
          stops: const [0.5, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppConstants.primaryColor.withOpacity(0.1), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarIcon(Icons.home_filled, 0, _currentIndex, (i) => setState(() => _currentIndex = i)),
              _NavBarIcon(Icons.search, 1, _currentIndex, (i) => setState(() => _currentIndex = i)),
              _AppLogoButton(onTap: () => setState(() => _currentIndex = 2)),
              _NavBarIcon(Icons.airplane_ticket_outlined, 2, _currentIndex, (i) => setState(() => _currentIndex = i)),
              _NavBarIcon(Icons.person_outline, 3, _currentIndex, (i) => setState(() => _currentIndex = i)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppLogoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AppLogoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: AppConstants.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.black, size: 24),
      ),
    );
  }
}

class _NavBarIcon extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NavBarIcon(this.icon, this.index, this.currentIndex, this.onTap);

  @override
  Widget build(BuildContext context) {
    if (index == 2) return const SizedBox.shrink();
    final isSelected = index == currentIndex;
    return IconButton(
      icon: Icon(icon, color: isSelected ? AppConstants.primaryColor : Colors.grey[700]),
      onPressed: () => onTap(index),
    );
  }
}

class _StreamView extends StatefulWidget {
  final Function(int) onTabChange;
  const _StreamView({required this.onTabChange});

  @override
  State<_StreamView> createState() => _StreamViewState();
}

class _StreamViewState extends State<_StreamView> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _trendingGigs = []; // Se usa como fallback o para gigs urgentes
  List<Post> _posts = [];
  bool _isLoading = true;
  final TextEditingController _postController = TextEditingController();
  bool _isPosting = false;
  StreamSubscription? _postSubscription;
  String? _artisticName;
  String? _profileAvatar;
  
  // Rotación
  Timer? _featuredGigTimer;
  int _currentFeaturedIndex = 0;

  List<dynamic> _urgentGigs = [];
  List<dynamic> _headliners = [];
  bool _showHeadliner = false; // Toggle to show headliner vs gig

  Future<void> _loadStreamData() async {
    final userId = _supabase.auth.currentUser?.id;
    try {
      // 1. Cargar perfil propio
      // 1. Cargar perfil propio
      if (userId != null) {
        debugPrint('HOME: Cargando perfil para $userId');
        final profile = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
        debugPrint('HOME: Perfil cargado: $profile');
        
        if (profile != null && mounted) {
          setState(() {
            _artisticName = profile['nombre_artistico'];
            // Fallback robusto
            if (_artisticName == null || _artisticName!.trim().isEmpty) {
               _artisticName = profile['nombre_completo'];
            }
            _profileAvatar = profile['avatar_url'];
          });
        }
      }

      final today = DateTime.now().toIso8601String().split('T')[0];
      final threeDaysLater = DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0];

      // 2. Gigs Urgentes (Próximos 7 días)
      final urgentGigsResponse = await _supabase.from('gigs')
          .select()
          .gte('fecha_gig', today)
          .lte('fecha_gig', threeDaysLater)
          .limit(10);
      
      // 3. Headliners (Artistas Destacados)
      final headlinersResponse = await _supabase.from('profiles')
          .select()
          .eq('estatus_headliner', true)
          .limit(10);

      // 4. Últimos Posts
      final postsData = await _supabase
          .from('posts')
          .select('*, author:profiles!posts_author_id_fkey(nombre_artistico, avatar_url)')
          .order('created_at', ascending: false)
          .limit(10); // Traemos más para que se vea lleno

      if (mounted) {
        setState(() {
          // Mezclar un poco para que sea dinámico
          _urgentGigs = List.from(urgentGigsResponse)..shuffle();
          _headliners = List.from(headlinersResponse)..shuffle();
          
          // Fallback si no hay urgentes, usar cualquiera futuro
          if (_urgentGigs.isEmpty) {
             _loadBackupGigs();
          } else {
             _trendingGigs = _urgentGigs;
          }

          _posts = (postsData as List).map((p) => Post.fromJson(p)).toList();
          _isLoading = false;
        });
        
        _startFeaturedRotation();
      }
    } catch (e) {
      debugPrint('Error loading stream: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBackupGigs() async {
    // Cargar cualquier evento futuro si no hay urgentes
    final today = DateTime.now().toIso8601String().split('T')[0];
    final response = await _supabase.from('gigs')
        .select()
        .gte('fecha_gig', today)
        .order('fecha_gig', ascending: true)
        .limit(5);
    
    if (mounted) {
      if (response.isNotEmpty) {
          setState(() {
            _trendingGigs = response; // Sin shuffle para que sean los más próximos
          });
      } else {
         // Si de plano no hay nada, no mostramos nada o mostramos pasados (no ideal)
         setState(() => _trendingGigs = []);
      }
    }
  }

  void _startFeaturedRotation() {
    _featuredGigTimer?.cancel();
    _featuredGigTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          // Rotar entre Gigs y Headliners si hay ambos
          if (_urgentGigs.isNotEmpty && _headliners.isNotEmpty) {
             _showHeadliner = !_showHeadliner; 
          } else if (_headliners.isNotEmpty) {
             _showHeadliner = true;
          } else {
             _showHeadliner = false;
          }

          // Rotar índice del carrusel específico
          if (!_showHeadliner && _urgentGigs.isNotEmpty) {
             _currentFeaturedIndex = (_currentFeaturedIndex + 1) % _urgentGigs.length;
          } else if (_showHeadliner && _headliners.isNotEmpty) {
             _currentFeaturedIndex = (_currentFeaturedIndex + 1) % _headliners.length;
          }
        });
      }
    });
  }
  Future<void> _createPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isPosting = true);
    try {
      await _supabase.from('posts').insert({
        'author_id': userId,
        'content': content,
      });
      _postController.clear();
      _loadStreamData();
    } catch (e) {
      debugPrint('Error creating post: $e');
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    // Usar el índice rotativo para mostrar diferentes eventos
    final featuredGig = _trendingGigs.isNotEmpty ? _trendingGigs[_currentFeaturedIndex] : null;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadStreamData,
        color: AppConstants.primaryColor,
        backgroundColor: Theme.of(context).cardColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hola,', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
                        Text(
                          (_artisticName ?? user?.name ?? 'ARTISTA').toUpperCase(),
                          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Row(
                    children: [
                      // Notificaciones
                      GestureDetector(
                        onTap: () => context.push('/notifications'),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                          ),
                          child: Icon(Icons.notifications_outlined, color: AppConstants.primaryColor, size: 22),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Mensajes
                      GestureDetector(
                        onTap: () => context.push('/messages'),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                          ),
                          child: Icon(Icons.chat_bubble_outline, color: AppConstants.primaryColor, size: 22),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Avatar
                      GestureDetector(
                        onTap: () => widget.onTabChange(3),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppConstants.primaryColor, width: 2),
                          ),
                           child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Theme.of(context).cardColor,
                            backgroundImage: _profileAvatar != null ? NetworkImage(_profileAvatar!) : null,
                            child: _profileAvatar == null 
                              ? Text(
                                  (_artisticName ?? user?.name ?? 'A').substring(0, 1).toUpperCase(),
                                  style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
                                )
                              : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 30),

              // PRÓXIMO EVENTO (DESTACADO CON ROTACIÓN)
              // LOGICA DE DESTACADO MIXTO (EVENTO URGENTE vs ARTISTA VIP)
              Builder(
                builder: (context) {
                  dynamic featuredItem;
                  bool isGig = true;

                  if (_showHeadliner && _headliners.isNotEmpty) {
                    featuredItem = _headliners[_currentFeaturedIndex % _headliners.length];
                    isGig = false;
                  } else if (_urgentGigs.isNotEmpty) {
                    featuredItem = _urgentGigs[_currentFeaturedIndex % _urgentGigs.length];
                    isGig = true;
                  } else if (_trendingGigs.isNotEmpty) {
                    featuredItem = _trendingGigs[_currentFeaturedIndex % _trendingGigs.length];
                    isGig = true;
                  }

                  if (featuredItem == null) {
                    return Container(
                      height: 120,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_outlined, color: Colors.grey[800], size: 40),
                          const SizedBox(height: 10),
                          Text('No hay eventos destacados', style: GoogleFonts.outfit(color: Colors.grey[700])),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isGig ? 'Evento Urgente' : 'Artista Destacado', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                          // Indicador simple
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppConstants.timeAgoColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(isGig ? 'HOY/MAÑANA' : 'VIP', 
                              style: GoogleFonts.outfit(color: AppConstants.timeAgoColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: () {
                           if (isGig) {
                             context.push('/gig/${featuredItem['id']}');
                           } else {
                             context.push('/portfolio/${featuredItem['id']}');
                           }
                        },
                        child: Container(
                          height: 280,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Theme.of(context).cardColor,
                            border: Border.all(color: isGig ? AppConstants.primaryColor.withOpacity(0.3) : Colors.purpleAccent.withOpacity(0.3), width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                // Background Image
                                if (!isGig && featuredItem['banner_url'] != null)
                                   Image.network(featuredItem['banner_url'], width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                                if (isGig && featuredItem['flyer_url'] != null)
                                   Image.network(featuredItem['flyer_url'], width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                                
                                // Overlay Gradient
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.8),
                                        Colors.black,
                                      ],
                                      stops: const [0.0, 0.6, 1.0],
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isGig ? AppConstants.primaryColor : Colors.purpleAccent,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(isGig ? 'PRÓXIMO' : 'HEADLINER', style: GoogleFonts.outfit(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        isGig ? (featuredItem['titulo_bolo'] ?? 'Evento') : (featuredItem['nombre_artistico'] ?? 'Artista'),
                                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(isGig ? Icons.location_on_outlined : Icons.music_note, color: isGig ? AppConstants.primaryColor : Colors.purpleAccent, size: 16),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              isGig ? (featuredItem['lugar_nombre'] ?? 'Ubicación') : (featuredItem['rol_principal'] ?? 'Músico'),
                                              style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              ),

              const SizedBox(height: 30),
              _buildPostInput(),
              const SizedBox(height: 30),
              _buildFeedHeader(),
              const SizedBox(height: 15),
              _buildPostList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _postController,
                  maxLines: 2,
                  style: GoogleFonts.outfit(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '¿Qué estás tocando hoy?',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[700]),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _isPosting ? null : _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 0,
                ),
                child: _isPosting 
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text('POSTEAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Muro de Artistas', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        Icon(Icons.auto_awesome, color: AppConstants.primaryColor, size: 18),
      ],
    );
  }

  Widget _buildPostList() {
    if (_posts.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.feed_outlined, color: Colors.grey[800], size: 40),
              const SizedBox(height: 10),
              Text('Aún no hay publicaciones.', style: GoogleFonts.outfit(color: Colors.grey[700])),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _posts.map((post) => _PostCard(post: post)).toList(),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              final myId = Supabase.instance.client.auth.currentUser?.id;
              if (post.authorId != myId) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: post.authorId)),
                );
              }
            },
            child: Row(
              children: [
                CircleAvatar(
                radius: 18,
                backgroundImage: post.authorAvatar != null ? NetworkImage(post.authorAvatar!) : null,
                child: post.authorAvatar == null ? const Icon(Icons.person, size: 18) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      DateFormat('dd MMM, HH:mm').format(post.createdAt),
                      style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: GoogleFonts.outfit(fontSize: 14, height: 1.4, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
