import 'package:flutter/material.dart';
import '../../models/portfolio_media.dart';
import '../../config/theme_colors.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';

class MediaDetailScreen extends StatefulWidget {
  final PortfolioMedia media;

  const MediaDetailScreen({super.key, required this.media});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    if (widget.media.tipo == 'video') {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.media.url))
        ..initialize().then((_) {
          setState(() {});
        });
    } else if (widget.media.tipo == 'audio') {
      _audioPlayer = AudioPlayer();
      _audioPlayer?.setUrl(widget.media.url);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.media.titulo),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.media.tipo == 'imagen') {
      return Image.network(widget.media.url);
    } else if (widget.media.tipo == 'video') {
      if (_videoController != null && _videoController!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              IconButton(
                icon: Icon(
                  _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: ThemeColors.icon(context),
                  size: 50,
                ),
                onPressed: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
              ),
            ],
          ),
        );
      } else {
        return const CircularProgressIndicator();
      }
    } else if (widget.media.tipo == 'audio') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note, size: 100, color: ThemeColors.icon(context)),
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: ThemeColors.icon(context),
              size: 64,
            ),
            onPressed: () {
              setState(() {
                if (_isPlaying) {
                  _audioPlayer?.pause();
                } else {
                  _audioPlayer?.play();
                }
                _isPlaying = !_isPlaying;
              });
            },
          ),
        ],
      );
    }
    return Text('Formato no soportado', style: TextStyle(color: ThemeColors.primaryText(context)));
  }
}
