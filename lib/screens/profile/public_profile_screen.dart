import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';
import '../../config/theme_colors.dart';
import 'package:share_plus/share_plus.dart';
import '../portfolio/portfolio_screen.dart';
import '../messages/chat_screen.dart';
import '../ratings/view_ratings_screen.dart';
import 'profile_detail_lists.dart';

// Importar LeaveRatingScreen
import '../ratings/leave_rating_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  List<dynamic> _instrumentos = [];
  int _eventosCount = 0;
  int _seguidoresCount = 0;
  int _musicCount = 0;
  bool _isLoading = true;
  String? _connectionStatus; // null, 'pending', 'accepted', 'rejected'
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final myId = _supabase.auth.currentUser?.id;
      
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();

      final gear = await _supabase
          .from('perfil_gear')
          .select('gear_catalog(nombre)')
          .eq('perfil_id', widget.userId);

      // Cargar contadores
      final eventosData = await _supabase
          .from('gig_lineup')
          .select()
          .eq('perfil_id', widget.userId);

      final seguidoresData = await _supabase
          .from('crews')
          .select()
          .eq('target_id', widget.userId);

      final musicData = await _supabase
          .from('perfil_gear')
          .select()
          .eq('perfil_id', widget.userId);

      // Verificar estado de conexión
      String? connectionStatus;
      bool isBlocked = false;
      
      if (myId != null && myId != widget.userId) {
        // Verificar si hay conexión
        final connectionData = await _supabase
            .from('connections')
            .select()
            .or('and(usuario_id.eq.$myId,conectado_id.eq.${widget.userId}),and(usuario_id.eq.${widget.userId},conectado_id.eq.$myId)')
            .maybeSingle();
        
        if (connectionData != null) {
          connectionStatus = connectionData['estatus']; // 'pending', 'accepted', 'rejected'
        }
        
        // Verificar si está bloqueado
        final blockData = await _supabase
            .from('bloqueos')
            .select()
            .eq('bloqueador_id', myId)
            .eq('bloqueado_id', widget.userId)
            .maybeSingle();
        
        isBlocked = blockData != null;
      }

      if (mounted) {
        setState(() {
          _profile = data;
          _instrumentos = gear;
          _eventosCount = (eventosData as List).length;
          _seguidoresCount = (seguidoresData as List).length;
          _musicCount = (musicData as List).length;
          _connectionStatus = connectionStatus;
          _isBlocked = isBlocked;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando perfil público: $e');
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
        appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: IconThemeData(color: ThemeColors.icon(context))),
        body: Center(child: Text('Usuario no encontrado', style: TextStyle(color: ThemeColors.secondaryText(context)))),
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
                  // Instrumento Principal
                  if (_profile?['instrumento_principal'] != null) ...[
                    _buildInstrumentCard(),
                    const SizedBox(height: 30),
                  ],
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
          colors: [AppConstants.primaryColor.withOpacity(0.2), Colors.black],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: ThemeColors.icon(context)),
                onPressed: () => Navigator.pop(context),
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
                      backgroundImage: _profile!['foto_perfil'] != null ? NetworkImage(_profile!['foto_perfil']) : null,
                      child: _profile!['foto_perfil'] == null 
                        ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _profile!['nombre_artistico'] ?? 'Artista',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_profile!['verificado'] == true) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.verified, color: AppConstants.primaryColor, size: 24),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Ubicación
                  if (_profile?['ubicacion'] != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: ThemeColors.secondaryText(context)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _profile!['ubicacion'],
                              style: GoogleFonts.outfit(
                                color: ThemeColors.secondaryText(context),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Calificación
                  if (_profile?['rating_promedio'] != null && _profile!['rating_promedio'] > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(5, (index) {
                          final rating = _profile!['rating_promedio'] ?? 0.0;
                          return Icon(
                            index < rating.floor() ? Icons.star : Icons.star_border,
                            color: AppConstants.primaryColor,
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          '${_profile!['rating_promedio'].toStringAsFixed(1)} (${_profile!['total_calificaciones'] ?? 0})',
                          style: GoogleFonts.outfit(
                            color: ThemeColors.secondaryText(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Badges
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_profile?['open_to_work'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.work_outline, size: 12, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Disponible',
                                style: GoogleFonts.outfit(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_profile?['ranking_tipo'] == 'premium') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber, Colors.orange],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.black),
                              const SizedBox(width: 4),
                              Text(
                                'PREMIUM',
                                style: GoogleFonts.outfit(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileEventsScreen(userId: widget.userId))),
        ),
        Container(width: 1, height: 40, color: ThemeColors.divider(context)),
        _buildStat(
          _seguidoresCount.toString(), 'Seguidores',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileFollowersScreen(userId: widget.userId))),
        ),
        Container(width: 1, height: 40, color: ThemeColors.divider(context)),
        _buildStat(
          (_profile?['total_calificaciones'] ?? 0).toString(), 'Ratings',
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViewRatingsScreen(
                userId: widget.userId,
                userName: _profile!['nombre_artistico'] ?? 'Artista',
              ),
            ),
          ),
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
            Text(label, style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 12)),
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
  
    if (_isBlocked) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              'Usuario bloqueado',
              style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
  
    return Column(
      children: [
        Row(
          children: [
            // Botón de Conectar/Mensaje
            Expanded(
              flex: 2,
              child: _buildConnectionButton(),
            ),
            const SizedBox(width: 12),
            // Botón de Galería
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PortfolioScreen(userId: widget.userId),
                  ),
                ),
                icon: const Icon(Icons.collections_outlined, size: 18),
                label: const Text('Galería', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppConstants.bgDarkAlt),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Botón de Calificar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeaveRatingScreen(
                    userId: widget.userId,
                    userName: _profile!['nombre_artistico'] ?? 'Artista',
                  ),
                ),
              );
              if (result == true) {
                _loadProfile(); // Recargar perfil para actualizar rating
              }
            },
            icon: const Icon(Icons.star_outline, size: 18),
            label: const Text('Dejar Calificación', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor.withOpacity(0.2),
              foregroundColor: AppConstants.primaryColor,
              side: BorderSide(color: AppConstants.primaryColor.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Botones de Reportar y Bloquear
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showReportDialog,
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Reportar', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: Colors.orange.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showBlockDialog,
                icon: const Icon(Icons.block_outlined, size: 18),
                label: const Text('Bloquear', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionButton() {
    if (_connectionStatus == 'accepted') {
      // Ya son conexiones - Puede mensajear
      return ElevatedButton.icon(
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
      );
    } else if (_connectionStatus == 'pending') {
      // Solicitud pendiente
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_empty, size: 18),
        label: const Text('Solicitud enviada'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey,
          side: const BorderSide(color: Colors.grey),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      // No hay conexión - Enviar solicitud
      return ElevatedButton.icon(
        onPressed: _sendConnectionRequest,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Conectar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _sendConnectionRequest() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      await _supabase.from('connections').insert({
        'usuario_id': myId,
        'conectado_id': widget.userId,
        'estatus': 'pending',
      });

      if (mounted) {
        setState(() => _connectionStatus = 'pending');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Solicitud enviada', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error enviando solicitud: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar solicitud', style: GoogleFonts.outfit()),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _showReportDialog() async {
    final reasons = [
      'Spam o contenido engañoso',
      'Acoso o intimidación',
      'Contenido inapropiado',
      'Suplantación de identidad',
      'Otro',
    ];

    String? selectedReason;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppConstants.cardColor,
          title: Text('Reportar usuario', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Por qué reportas a este usuario?',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...reasons.map((reason) => RadioListTile<String>(
                title: Text(reason, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
                value: reason,
                groupValue: selectedReason,
                activeColor: AppConstants.primaryColor,
                onChanged: (value) => setState(() => selectedReason = value),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: GoogleFonts.outfit(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: selectedReason == null ? null : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
              ),
              child: Text('Reportar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedReason != null) {
      await _submitReport(selectedReason!);
    }
  }

  Future<void> _submitReport(String reason) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      await _supabase.from('reportes').insert({
        'reportante_id': myId,
        'usuario_reportado_id': widget.userId,
        'contenido_tipo': 'usuario',
        'categoria': reason,
        'descripcion': reason,
        'estatus': 'pendiente',
        'urgencia': 'media',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Reporte enviado. Lo revisaremos pronto.', style: GoogleFonts.outfit()),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error enviando reporte: $e');
    }
  }

  Future<void> _showBlockDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: Text('Bloquear usuario', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro que quieres bloquear a ${_profile!['nombre_artistico']}? No podrás ver su contenido ni recibir mensajes.',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Bloquear', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _blockUser();
    }
  }

  Future<void> _blockUser() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      await _supabase.from('bloqueos').insert({
        'bloqueador_id': myId,
        'bloqueado_id': widget.userId,
      });

      if (mounted) {
        setState(() => _isBlocked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.block, color: Colors.white),
                const SizedBox(width: 12),
                Text('Usuario bloqueado', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error bloqueando usuario: $e');
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: ThemeColors.primaryText(context),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInstrumentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor.withOpacity(0.1),
            AppConstants.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.music_note,
              color: AppConstants.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instrumento Principal',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: ThemeColors.secondaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _profile!['instrumento_principal'],
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.primaryText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        _profile!['bio'] ?? 'Sin biografía.',
        style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 15, height: 1.6),
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
            'No ha agregado equipo',
            style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context)),
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
              color: ThemeColors.primaryText(context),
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
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
