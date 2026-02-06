import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../config/constants.dart';
import '../config/theme_colors.dart';

/// Widget profesional para reproducir videos con controles completos
/// Incluye play/pause, barra de progreso, fullscreen, y controles de volumen
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? title;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.title,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _showControls = true;
  String? _error;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      
      await _controller.initialize();
      
      _controller.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller.value.isPlaying;
          });
          
          // Auto-pause when finished
          if (_controller.value.position >= _controller.value.duration) {
            _controller.pause();
            _controller.seekTo(Duration.zero);
          }
        }
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar video';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.title != null
            ? Text(
                widget.title!,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: AppConstants.primaryColor)
            : _error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: _toggleControls,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Video player
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                        
                        // Controls overlay
                        if (_showControls) ...[
                          // Dark overlay
                          Container(
                            color: Colors.black.withOpacity(0.3),
                          ),
                          
                          // Play/Pause button
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 50,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ),
                          
                          // Bottom controls
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Progress bar
                                  VideoProgressIndicator(
                                    _controller,
                                    allowScrubbing: true,
                                    colors: const VideoProgressColors(
                                      playedColor: AppConstants.primaryColor,
                                      bufferedColor: Colors.grey,
                                      backgroundColor: Colors.white24,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Time and volume controls
                                  Row(
                                    children: [
                                      // Current time / Duration
                                      Text(
                                        '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const Spacer(),
                                      
                                      // Volume control
                                      IconButton(
                                        icon: Icon(
                                          _volume == 0
                                              ? Icons.volume_off
                                              : _volume < 0.5
                                                  ? Icons.volume_down
                                                  : Icons.volume_up,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (_volume > 0) {
                                              _volume = 0;
                                            } else {
                                              _volume = 1.0;
                                            }
                                            _controller.setVolume(_volume);
                                          });
                                        },
                                      ),
                                      
                                      // Fullscreen button
                                      IconButton(
                                        icon: const Icon(
                                          Icons.fullscreen,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          // TODO: Implement fullscreen
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Fullscreen próximamente',
                                                style: GoogleFonts.outfit(),
                                              ),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}
