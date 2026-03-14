import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final bool isEvaluated;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.isEvaluated = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get a thumbnail/cover image
    String? coverUrl = project.coverImageUrl;
    if (coverUrl != null && coverUrl.startsWith('/')) {
      coverUrl = 'https://kritikfinal.onrender.com$coverUrl';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cover Image / Video Thumbnail
            Stack(
              children: [
                Hero(
                  tag: 'project_cover_${project.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: coverUrl != null 
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SkeletonLoader(height: 200),
                          errorWidget: (context, url, error) => _buildPlaceholderCover(isDark),
                        )
                      : _buildPlaceholderCover(isDark),
                  ),
                ),
                // Video Icon Overlay if has promo video
                if (project.promoVideoUrl != null && project.promoVideoUrl!.isNotEmpty)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
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
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black05),
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
    );
  }

  Widget _buildPlaceholderCover(bool isDark) {
    return Container(
      height: 200,
      width: double.infinity,
      color: isDark ? Colors.white05 : Colors.black05,
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
