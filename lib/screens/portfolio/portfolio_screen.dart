import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oolale_mobile/models/portfolio_media.dart';
import 'package:oolale_mobile/config/constants.dart';
import 'upload_media_screen.dart';
import 'media_detail_screen.dart';

class PortfolioScreen extends StatefulWidget {
  final String userId;
  const PortfolioScreen({super.key, required this.userId});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _supabase = Supabase.instance.client;
  List<PortfolioMedia> _mediaList = [];
  bool _isLoading = true;
  String _selectedFilter = 'todos';

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    try {
      setState(() => _isLoading = true);
      final response = await _supabase
          .from('portfolio_media')
          .select()
          .eq('profile_id', widget.userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _mediaList = List<PortfolioMedia>.from(response.map((x) => PortfolioMedia.fromJson(x)));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PortfolioMedia> get _filteredMedia {
    if (_selectedFilter == 'todos') return _mediaList;
    return _mediaList.where((m) => m.tipo.toLowerCase() == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final myId = _supabase.auth.currentUser?.id;
    final isMe = widget.userId == myId;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppConstants.bgDarkPanel,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isMe ? 'Mi Galería' : 'Galería', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (isMe)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppConstants.primaryColor),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UploadMediaScreen(userId: widget.userId, onUploadComplete: _loadMedia),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                : _filteredMedia.isEmpty
                    ? _buildEmptyState()
                    : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: ['todos', 'imagen', 'video', 'audio'].map((filter) {
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppConstants.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppConstants.primaryColor : Colors.grey[800]!),
              ),
              child: Center(
                child: Text(
                  filter.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.black : Colors.grey[400],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrid() {
    return MasonryGridView.count(
      crossAxisCount: 2,
      itemCount: _filteredMedia.length,
      padding: const EdgeInsets.all(12),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemBuilder: (context, index) {
        final media = _filteredMedia[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MediaDetailScreen(media: media)),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppConstants.bgDarkPanel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: media.tipo == 'imagen' ? 0.8 : 1.2,
                    child: media.tipo == 'imagen' 
                        ? Image.network(media.url, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFF1E1E1E),
                            child: Icon(
                              media.tipo == 'video' ? Icons.play_circle_outline : Icons.music_note,
                              color: AppConstants.primaryColor,
                              size: 40,
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      media.titulo,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.collections_outlined, size: 60, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text('Sin archivos', style: GoogleFonts.outfit(color: Colors.grey[700])),
        ],
      ),
    );
  }
}
