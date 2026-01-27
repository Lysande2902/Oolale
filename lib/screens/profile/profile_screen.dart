import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../config/constants.dart';
import 'edit_profile_screen.dart';
import 'public_profile_screen.dart';
import 'profile_detail_lists.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profileData;
  List<dynamic> _instrumentos = [];
  int _eventosCount = 0;
  int _seguidoresCount = 0;
  int _musicCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtistProfile();
  }

  Future<void> _loadArtistProfile() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        if (mounted) setState(() { _profileData = null; _isLoading = false; });
        return;
      }

      final gear = await _supabase
          .from('perfil_gear')
          .select('gear_catalog(nombre)')
          .eq('perfil_id', user.id);

      // Cargar contadores
      final eventosData = await _supabase
          .from('gig_lineup')
          .select()
          .eq('perfil_id', user.id);

      final seguidoresData = await _supabase
          .from('crews')
          .select()
          .eq('target_id', user.id);

      final musicData = await _supabase
          .from('perfil_gear')
          .select()
          .eq('perfil_id', user.id);

      if (mounted) {
        setState(() {
          _profileData = profile;
          _instrumentos = gear;
          _eventosCount = (eventosData as List).length;
          _seguidoresCount = (seguidoresData as List).length;
          _musicCount = (musicData as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando Perfil: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro que quieres salir?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir', style: TextStyle(color: AppConstants.errorColor)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
    }
  }

  void _shareProfile() {
    if (_profileData == null) return;
    final slug = _profileData!['slug_url'] ?? "u/${_profileData!['id']}";
    Share.share('¡Checa mi perfil en Óolale! ${_profileData!['nombre_artistico']} - https://oolale.app/$slug');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
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
                  const SizedBox(height: 10),
                  _buildBioCard(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Mi Equipo'),
                  const SizedBox(height: 10),
                  _buildGearSection(),
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
          colors: [
            AppConstants.primaryColor.withOpacity(0.2),
            Colors.black,
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Header Buttons
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                    onPressed: () => context.push('/settings'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white70),
                    onPressed: _shareProfile,
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                    onPressed: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
            // Profile content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInDown(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppConstants.primaryColor, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).cardColor,
                        backgroundImage: _profileData?['avatar_url'] != null 
                            ? NetworkImage(_profileData!['avatar_url']) 
                            : null,
                        child: _profileData?['avatar_url'] == null
                            ? Icon(Icons.person, size: 60, color: Colors.grey[700])
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _profileData?['nombre_artistico'] ?? 'Artista',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_profileData?['verificado'] == true) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.verified, color: AppConstants.primaryColor, size: 24),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      (_profileData?['rol_principal'] ?? 'musico').toString().toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: AppConstants.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileEventsScreen(userId: _profileData!['id']))),
        ),
        Container(width: 1, height: 40, color: Theme.of(context).dividerColor.withOpacity(0.1)),
        _buildStat(
          _seguidoresCount.toString(), 'Seguidores',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileFollowersScreen(userId: _profileData!['id']))),
        ),
        Container(width: 1, height: 40, color: Theme.of(context).dividerColor.withOpacity(0.1)),
        _buildStat(
          _musicCount.toString(), 'Música', // Que es perfil_gear en realidad
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileGearScreen(userId: _profileData!['id']))),
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
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
              _loadArtistProfile();
            },
            icon: const Icon(Icons.edit_outlined),
            label: Text('Editar Perfil', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
          ),
          child: IconButton(
            onPressed: () {
              final myId = Supabase.instance.client.auth.currentUser?.id;
              if (myId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: myId)),
                );
              }
            },
            icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.white),
            tooltip: 'Ver mi perfil público',
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: Theme.of(context).textTheme.titleLarge?.color,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
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
        _profileData?['bio_rider'] ?? 'Sin biografía. Cuéntale al mundo quién eres.',
        style: GoogleFonts.outfit(
          color: Colors.grey[400],
          fontSize: 15,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildGearSection() {
    if (_instrumentos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
        ),
        child: Center(
          child: Text(
            'No has agregado equipo aún',
            style: GoogleFonts.outfit(color: Colors.grey[700]),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _instrumentos.map((i) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
          ),
          child: Text(
            i['gear_catalog']['nombre'],
            style: GoogleFonts.outfit(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
    );
  }
}
