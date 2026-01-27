import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  
  List<Map<String, dynamic>> _connections = [];
  List<Map<String, dynamic>> _pending = [];
  bool _isLoading = true;
  final int _pageSize = 20;
  int _activePage = 0;
  int _pendingPage = 0;
  bool _hasMoreActive = true;
  bool _hasMorePending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConnections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    setState(() => _isLoading = true);

    try {
      final activeData = await _supabase
          .from('crews')
          .select('*, target:profiles!target_id(id, nombre_artistico, avatar_url, instrumento_principal)')
          .eq('perfil_id', myId)
          .eq('estatus', 'activo')
          .order('id', ascending: false)
          .range(0, _pageSize - 1);

      final pendingData = await _supabase
          .from('crews')
          .select('*, requester:profiles!perfil_id(id, nombre_artistico, avatar_url, instrumento_principal)')
          .eq('target_id', myId)
          .eq('estatus', 'pendiente')
          .order('id', ascending: false)
          .range(0, _pageSize - 1);

      if (mounted) {
        setState(() {
          _connections = List<Map<String, dynamic>>.from(activeData);
          _pending = List<Map<String, dynamic>>.from(pendingData);
          _isLoading = false;
          _activePage = 0;
          _pendingPage = 0;
          _hasMoreActive = _connections.length == _pageSize;
          _hasMorePending = _pending.length == _pageSize;
        });
      }
    } catch (e) {
      debugPrint('Error loading connections: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadMoreActive() async {
    if (!_hasMoreActive || _isLoading) return;
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;
    setState(() => _isLoading = true);
    try {
      final nextPage = _activePage + 1;
      final start = nextPage * _pageSize;
      final end = start + _pageSize - 1;
      final data = await _supabase
          .from('crews')
          .select('*, target:profiles!target_id(id, nombre_artistico, avatar_url, instrumento_principal)')
          .eq('perfil_id', myId)
          .eq('estatus', 'activo')
          .order('id', ascending: false)
          .range(start, end);
      if (!mounted) return;
      setState(() {
        _activePage = nextPage;
        _connections = [..._connections, ...List<Map<String, dynamic>>.from(data)];
        _hasMoreActive = data.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadMorePending() async {
    if (!_hasMorePending || _isLoading) return;
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;
    setState(() => _isLoading = true);
    try {
      final nextPage = _pendingPage + 1;
      final start = nextPage * _pageSize;
      final end = start + _pageSize - 1;
      final data = await _supabase
          .from('crews')
          .select('*, requester:profiles!perfil_id(id, nombre_artistico, avatar_url, instrumento_principal)')
          .eq('target_id', myId)
          .eq('estatus', 'pendiente')
          .order('id', ascending: false)
          .range(start, end);
      if (!mounted) return;
      setState(() {
        _pendingPage = nextPage;
        _pending = [..._pending, ...List<Map<String, dynamic>>.from(data)];
        _hasMorePending = data.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _respondToRequest(int crewId, String action) async {
    try {
      if (action == 'accept') {
        await _supabase
            .from('crews')
            .update({'estatus': 'activo'})
            .eq('id', crewId);
      } else {
        await _supabase
            .from('crews')
            .delete()
            .eq('id', crewId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'accept' ? '¡Conexión aceptada!' : 'Solicitud rechazada'),
            backgroundColor: action == 'accept' ? AppConstants.primaryColor : Colors.grey,
          ),
        );
        _loadConnections();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar solicitud')),
        );
      }
    }
  }

  Future<void> _removeConnection(int crewId) async {
    try {
      await _supabase.from('crews').delete().eq('id', crewId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conexión eliminada')),
        );
        _loadConnections();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar conexión')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text('CONEXIONES', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryColor,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: 'Conexiones (${_connections.length})'),
            Tab(text: 'Solicitudes (${_pending.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConnectionsList(),
                _buildPendingList(),
              ],
            ),
    );
  }

  Widget _buildConnectionsList() {
    if (_connections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.white10),
            const SizedBox(height: 20),
            Text(
              'Aún no tienes conexiones',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Usa Discovery para encontrar músicos',
              style: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _connections.length + (_hasMoreActive ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _connections.length) {
          return Center(
            child: SizedBox(
              height: 36,
              width: 140,
              child: OutlinedButton(
                onPressed: _loadMoreActive,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: AppConstants.primaryColor.withOpacity(0.6)),
                ),
                child: Text('Cargar más', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              ),
            ),
          );
        }
        final crew = _connections[index];
        final target = crew['target'] as Map<String, dynamic>?;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: AppConstants.primaryColor,
              child: Text(
                (target?['nombre_artistico'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            title: Text(
              target?['nombre_artistico'] ?? 'Usuario',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              target?['instrumento_principal'] ?? 'Músico',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              color: AppConstants.cardColor,
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Ver Perfil', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    final id = target?['id']?.toString() ?? '';
                    if (id.isNotEmpty) {
                      GoRouter.of(context).go('/portfolio/$id');
                    }
                  },
                ),
                PopupMenuItem(
                  child: const Text('Enviar Mensaje', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    final id = target?['id']?.toString() ?? '';
                    final name = target?['nombre_artistico']?.toString() ?? 'Artist';
                    if (id.isNotEmpty) {
                      GoRouter.of(context).go('/messages/$id', extra: name);
                    }
                  },
                ),
                PopupMenuItem(
                  child: const Text('Eliminar Conexión', style: TextStyle(color: Colors.redAccent)),
                  onTap: () => _removeConnection(crew['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingList() {
    if (_pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.white10),
            const SizedBox(height: 20),
            Text(
              'No hay solicitudes pendientes',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pending.length + (_hasMorePending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _pending.length) {
          return Center(
            child: SizedBox(
              height: 36,
              width: 140,
              child: OutlinedButton(
                onPressed: _loadMorePending,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: AppConstants.primaryColor.withOpacity(0.6)),
                ),
                child: Text('Cargar más', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              ),
            ),
          );
        }
        final crew = _pending[index];
        final requester = crew['requester'] as Map<String, dynamic>?;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppConstants.accentColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppConstants.accentColor,
                  child: Text(
                    (requester?['nombre_artistico'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                title: Text(
                  requester?['nombre_artistico'] ?? 'Usuario',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Quiere conectar contigo',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _respondToRequest(crew['id'], 'reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white60,
                          side: BorderSide(color: AppConstants.primaryColor.withOpacity(0.3), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Rechazar', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _respondToRequest(crew['id'], 'accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Aceptar', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
