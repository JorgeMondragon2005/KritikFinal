import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../theme/app_theme.dart';

class NativeMediaViewer extends StatefulWidget {
  final String url;
  final bool isVideo;
  final bool isImage;

  const NativeMediaViewer({
    super.key, 
    required this.url, 
    this.isVideo = false,
    this.isImage = false,
  });

  @override
  State<NativeMediaViewer> createState() => _NativeMediaViewerState();
}

class _NativeMediaViewerState extends State<NativeMediaViewer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initializePlayer();
    }
  }

  bool _hasError = false;
  String _errorMessage = '';

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      
      // Add timeout to prevent infinite loading on bad networks
      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado al cargar el video');
        },
      );
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        autoInitialize: true,
        showControls: true,
        showOptions: false,
        fullScreenByDefault: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryYellow,
          handleColor: AppColors.primaryYellow,
          bufferedColor: Colors.white30,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage ?? 'Error desconocido', // Handle null errorMessage
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      
      // Initialize volume and wait for it
      await _videoPlayerController!.setVolume(1.0);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString().contains('Exception:') 
              ? e.toString().split('Exception: ')[1] 
              : 'El video no pudo ser reproducido o el enlace está dañado.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {}); // Trigger rebuild to stop loading indicator
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Visor Multimedia', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: widget.isVideo ? _buildVideoViewer() : _buildImageViewer(),
      ),
    );
  }

  Widget _buildVideoViewer() {
    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Error al reproducir video',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    } else {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Cargando video...', style: TextStyle(color: Colors.white)),
        ],
      );
    }
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      panEnabled: true,
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 4,
      child: Image.network(
        widget.url,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const CircularProgressIndicator(color: Colors.white);
        },
        errorBuilder: (context, error, stackTrace) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text('Error al cargar la imagen', style: TextStyle(color: Colors.white)),
            ],
          );
        },
      ),
    );
  }
}
