import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final bool isEvaluated;

  final String? userRole;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.isEvaluated = false,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get a thumbnail/cover image
    String? coverUrl = project.coverImageUrl;
    if (coverUrl != null && coverUrl.startsWith('/')) {
      coverUrl = 'https://kritikfinal.onrender.com$coverUrl';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primaryYellow.withOpacity(0.1),
          highlightColor: AppColors.primaryYellow.withOpacity(0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 1. Cover Image / Video Thumbnail
            Stack(
              children: [
                _buildMediaInterface(isDark),
                
                // Evaluation Badge
                if (isEvaluated)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'EVALUADO',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            
            // 2. Project Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Team Icon/Thumbnail
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.psychology, color: AppColors.primaryYellow),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.title ?? 'Sin título',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${project.teamName ?? "Equipo S/N"} • ${project.category ?? "General"}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Technologies chips
                  if (project.technologies.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: project.technologies.map((tech) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.techChipBgDark : AppColors.techChipBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                          ),
                          child: Text(
                            tech,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Short Description
                  Text(
                    project.description ?? 'Sin descripción disponible.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildMediaInterface(bool isDark) {
    String? coverUrl = project.coverImageUrl;
    if (coverUrl != null && coverUrl.startsWith('/')) {
      coverUrl = 'https://kritikfinal.onrender.com$coverUrl';
    }

    final hasVideo = project.promoVideoUrl != null && project.promoVideoUrl!.isNotEmpty;
    // Direct playback only if teacher/evaluator for "premium" review feel, or let anyone play?
    // User said: "vista desde el usuario del profe"
    final canPlayDirectly = (userRole?.toLowerCase() == 'teacher' || userRole?.toLowerCase() == 'evaluator') && hasVideo;

    return Hero(
      tag: 'project_cover_${project.id}',
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          width: double.infinity,
          color: isDark ? Colors.black26 : Colors.black12,
          child: canPlayDirectly 
            ? _VideoPreviewWidget(url: project.promoVideoUrl!, isDark: isDark)
            : SizedBox(height: 200, child: _buildThumbnail(coverUrl, hasVideo, isDark)),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? coverUrl, bool hasVideo, bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        coverUrl != null 
          ? CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const SkeletonLoader(height: 200),
              errorWidget: (context, url, error) => _buildPlaceholderCover(isDark),
            )
          : _buildPlaceholderCover(isDark),
        if (hasVideo)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderCover(bool isDark) {
    return Container(
      height: 200,
      width: double.infinity,
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }
}

// Internal widget for lightweight preview
class _VideoPreviewWidget extends StatefulWidget {
  final String url;
  final bool isDark;
  const _VideoPreviewWidget({required this.url, required this.isDark});

  @override
  State<_VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<_VideoPreviewWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    String finalUrl = widget.url;
    if (finalUrl.startsWith('/')) {
      finalUrl = 'https://kritikfinal.onrender.com$finalUrl';
    }
    _controller = VideoPlayerController.networkUrl(Uri.parse(finalUrl))
      ..initialize().then((_) {
        _controller!.setVolume(0.0); // Muted by default for autoplay feeds
        _controller!.setLooping(true);
        _controller!.play();
        if (mounted) setState(() => _isInitialized = true);
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
            });
          },
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white.withOpacity(0.7),
                size: 50,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
