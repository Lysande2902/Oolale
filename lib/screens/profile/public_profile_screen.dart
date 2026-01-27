import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';
import 'package:share_plus/share_plus.dart';
import '../portfolio/portfolio_screen.dart';
import '../messages/chat_screen.dart';
import 'profile_detail_lists.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  int _eventosCount = 0;
  int _seguidoresCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();

      // Cargar contadores
      final eventosData = await _supabase
          .from('gig_lineup')
          .select()
          .eq('perfil_id', widget.userId);

      final seguidoresData = await _supabase
          .from('crews')
          .select()
          .eq('target_id', widget.userId);

      if (mounted) {
        setState(() {
          _profile = data;
          _eventosCount = (eventosData as List).length;
          _seguidoresCount = (seguidoresData as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareProfile() {
    if (_profile == null) return;
    Share.share('¡Checa este perfil en Óolale! ${_profile!['nombre_artistico']} - https://oolale.app/${_profile!['slug_url'] ?? "u/${widget.userId}"}');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: Theme.of(context).iconTheme),
        body: const Center(child: Text('Usuario no encontrado', style: TextStyle(color: Colors.grey))),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 30),
                  _buildActionButtons(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Bio'),
                  _buildBioCard(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Instrumento'),
                  _buildBadge(_profile!['instrumento_principal'] ?? 'No especificado'),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppConstants.primaryColor.withOpacity(0.2), Colors.black],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _shareProfile,
                  ),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppConstants.primaryColor, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppConstants.bgDarkAlt,
                      backgroundImage: _profile!['avatar_url'] != null ? NetworkImage(_profile!['avatar_url']) : null,
                      child: _profile!['avatar_url'] == null 
                        ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _profile!['nombre_artistico'] ?? 'Artista',
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildBadge((_profile!['rol_principal'] ?? 'musico').toString().toUpperCase()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStat(
          _eventosCount.toString(), 'Eventos',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileEventsScreen(userId: widget.userId))),
        ),
        Container(width: 1, height: 40, color: Colors.grey[900]),
        _buildStat(
          _seguidoresCount.toString(), 'Seguidores',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileFollowersScreen(userId: widget.userId))),
        ),
        Container(width: 1, height: 40, color: Colors.grey[900]),
        _buildStat(
          '0', 'Música', // Que es perfil_gear en realidad
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileGearScreen(userId: widget.userId))),
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (widget.userId == myId) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _shareProfile(),
          icon: const Icon(Icons.share_outlined),
          label: const Text('Compartir mi perfil'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: AppConstants.primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
  
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  userId: widget.userId,
                  userName: _profile!['nombre_artistico'] ?? 'Artista',
                ),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Mensaje'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PortfolioScreen(userId: widget.userId),
              ),
            ),
            icon: const Icon(Icons.collections_outlined),
            label: const Text('Galería'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppConstants.bgDarkAlt),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBioCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Text(
        _profile!['bio_rider'] ?? 'Sin biografía.',
        style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 15, height: 1.6),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: GoogleFonts.outfit(color: AppConstants.primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
