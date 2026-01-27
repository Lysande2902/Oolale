import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../config/constants.dart';
import '../../models/event.dart';

class GigDetailScreen extends StatefulWidget {
  final int gigId;
  const GigDetailScreen({super.key, required this.gigId});

  @override
  State<GigDetailScreen> createState() => _GigDetailScreenState();
}

class _GigDetailScreenState extends State<GigDetailScreen> {
  final _supabase = Supabase.instance.client;
  Evento? _gig;
  Map<String, dynamic>? _organizer;
  List<dynamic> _lineup = [];
  bool _isLoading = true;
  bool _isPostulating = false;
  bool _alreadyInLineup = false;

  @override
  void initState() {
    super.initState();
    _loadGigDetails();
  }

  Future<void> _loadGigDetails() async {
    final myId = _supabase.auth.currentUser?.id;
    try {
      debugPrint('Loading gig with ID: ${widget.gigId}');
      
      final gigData = await _supabase
          .from('gigs')
          .select()
          .eq('id', widget.gigId)
          .maybeSingle();

      if (gigData == null) {
        debugPrint('Gig not found with ID: ${widget.gigId}');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Load organizer separately
      final organizer = await _supabase
          .from('profiles')
          .select()
          .eq('id', gigData['organizador_id'] ?? '')
          .maybeSingle();

      final lineupData = await _supabase
          .from('gig_lineup')
          .select('*, profiles(id, nombre_artistico, avatar_url)')
          .eq('gig_id', widget.gigId);

      if (mounted) {
        setState(() {
          _gig = Evento.fromJson(gigData);
          _organizer = organizer;
          _lineup = lineupData;
          _alreadyInLineup = lineupData.any((l) => l['perfil_id'] == myId);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading gig details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postulate() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    setState(() => _isPostulating = true);
    try {
      await _supabase.from('gig_lineup').insert({
        'gig_id': widget.gigId,
        'perfil_id': myId,
        'rol_en_gig': 'Interesado',
        'asistencia_confirmada': false,
      });

        // Notificar al organizador
        if (_gig?.organizadorId != null) {
          await _supabase.from('notifications').insert({
            'user_id': _gig!.organizadorId,
            'tipo': 'gig_postulation',
            'titulo': 'Nuevo interesado',
            'mensaje': 'Alguien quiere unirse a "${_gig!.titulo}"',
            'leido': false,
            'data': {'gig_id': widget.gigId, 'sender_id': myId},
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Interés enviado correctamente'), backgroundColor: AppConstants.primaryColor),
          );
          _loadGigDetails();
        }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar interés'), backgroundColor: AppConstants.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isPostulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
      );
    }

    if (_gig == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.not_interested, color: Colors.grey, size: 64),
              const SizedBox(height: 16),
              const Text('Evento no encontrado', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildHeroImage(),
          _buildDetailContent(),
          _buildAppBar(),
          _buildStickyAction(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Positioned(
      top: 40,
      left: 10,
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeroImage() {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppConstants.primaryColor.withOpacity(0.3),
            Colors.black,
          ],
        ),
      ),
      child: Stack(
        children: [
          if (_gig!.flyerUrl != null)
            Image.network(_gig!.flyerUrl!, width: double.infinity, height: 400, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 350),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderInfo(),
                const SizedBox(height: 30),
                _buildOrganizerRow(),
                const SizedBox(height: 30),
                _buildSectionTitle('Detalles'),
                Text(
                  _gig!.descripcion,
                  style: GoogleFonts.outfit(color: Colors.grey[400], height: 1.6, fontSize: 16),
                ),
                const SizedBox(height: 30),
                _buildSectionTitle('Categoría'),
                _buildBadge(_gig!.tipo.toUpperCase()),
                const SizedBox(height: 30),
                // Requisitos técnicos si existen
                if (_gig!.tipo == 'concierto' || _gig!.tipo == 'ensayo') ...[
                  _buildSectionTitle('Requisitos'),
                  Text('Contacto con el organizador para más detalles.', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 30),
                ],
                _buildLineupSection(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _gig!.titulo,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.1),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildInfoChip(Icons.calendar_today_rounded, DateFormat('dd MMM, yyyy').format(_gig!.fecha)),
            const SizedBox(width: 15),
            _buildInfoChip(Icons.access_time_rounded, _gig!.hora),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Icon(Icons.location_on_rounded, color: AppConstants.primaryColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _gig!.ubicacion,
                style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppConstants.bgDarkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 14),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildOrganizerRow() {
    return GestureDetector(
      onTap: () => context.push('/portfolio/${_organizer?['id']}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.bgDarkPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppConstants.bgDarkAlt,
              backgroundImage: _organizer?['avatar_url'] != null ? NetworkImage(_organizer!['avatar_url']) : null,
              child: _organizer?['avatar_url'] == null 
                ? const Icon(Icons.person, color: Colors.grey, size: 20) : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Organizado por', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 11)),
                  Text(
                    _organizer?['nombre_artistico'] ?? 'Artista',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Icon(Icons.chat_bubble_outline, color: AppConstants.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLineupSection() {
    if (_lineup.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Confirmados'),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _lineup.length,
            itemBuilder: (context, index) {
              final artist = _lineup[index]['profiles'];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => context.push('/portfolio/${artist['id']}'),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppConstants.bgDarkAlt,
                    backgroundImage: artist['avatar_url'] != null ? NetworkImage(artist['avatar_url']) : null,
                    child: artist['avatar_url'] == null 
                      ? const Icon(Icons.person, color: Colors.grey) : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
      ),
      child: Text(text, style: GoogleFonts.outfit(color: AppConstants.primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStickyAction() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: SafeArea(
        child: ElevatedButton(
          onPressed: (_isPostulating || _alreadyInLineup) ? null : _postulate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isPostulating
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : Text(
                  _alreadyInLineup ? 'Interés Enviado' : 'Unirme',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
        ),
      ),
    );
  }
}
