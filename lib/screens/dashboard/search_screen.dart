import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/constants.dart';
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
  bool _isLoading = false;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _loadFeatured();
  }

  Future<void> _loadFeatured() async {
    try {
      final myId = _supabase.auth.currentUser?.id;
      var queryBuilder = _supabase.from('profiles').select();
      
      if (myId != null) {
        queryBuilder = queryBuilder.neq('id', myId);
      }

      final data = await queryBuilder
          .order('created_at', ascending: false)
          .limit(10);
      
      if (mounted) {
        setState(() {
          _featured = data;
          _artists = data;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _artists = _featured;
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
      var queryBuilder = _supabase.from('profiles').select();
      
      queryBuilder = queryBuilder.ilike('nombre_artistico', '%$query%');
      
      if (myId != null) {
        queryBuilder = queryBuilder.neq('id', myId);
      }

      final data = await queryBuilder.limit(20);
      
      if (mounted) {
        setState(() {
          _artists = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _isLoading 
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
                  ),
                ),
                Text(
                  _showSearch ? 'Resultados' : 'Artistas',
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
        height: 55,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConstants.primaryColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search, color: AppConstants.primaryColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _performSearch,
                style: GoogleFonts.outfit(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Músicos, bandas o instrumentos...',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[700]),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600]),
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

  Widget _buildContent() {
    if (_artists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[800]),
            const SizedBox(height: 20),
            Text('Sin resultados', style: GoogleFonts.outfit(color: Colors.grey[700])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 30),
          child: _ArtistCard(
            artist: _artists[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: _artists[index]['id'])),
            ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            // Avatar con gradiente
            Container(
              width: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryColor.withOpacity(0.3),
                    AppConstants.primaryColor.withOpacity(0.05),
                  ],
                ),
                image: artist['avatar_url'] != null 
                    ? DecorationImage(image: NetworkImage(artist['avatar_url']), fit: BoxFit.cover) 
                    : null,
              ),
              child: artist['avatar_url'] == null 
                  ? Center(child: Icon(Icons.person, size: 40, color: Colors.white.withOpacity(0.3)))
                  : null,
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            artist['nombre_artistico'] ?? 'Artista',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (artist['verificado'] == true)
                          Icon(Icons.verified, color: AppConstants.primaryColor, size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (artist['rol_principal'] ?? 'musico').toString().toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: AppConstants.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (artist['ubicacion_base'] != null) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.location_on_outlined, color: Colors.grey[700], size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              artist['ubicacion_base'],
                              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12),
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
            ),
            // Arrow
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
