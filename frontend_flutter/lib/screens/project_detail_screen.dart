import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'native_media_viewer.dart';
import '../widgets/native_doc_viewer.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Animated Header with Hero
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'project_cover_${project.id}',
                child: project.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: project.coverImageUrl!.startsWith('/') 
                            ? 'https://kritikfinal.onrender.com${project.coverImageUrl}'
                            : project.coverImageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(color: AppColors.primaryYellow.withOpacity(0.1)),
              ),
            ),
          ),

          // 2. Info Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Category
                  Text(
                    project.title ?? 'Sin título',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${project.category} • ${project.teamName}',
                    style: TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 24),

                  // Technologies
                  if (project.technologies.isNotEmpty) ...[
                    const Text('Tecnologías', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: project.technologies.map((tech) => Chip(
                        label: Text(tech),
                        backgroundColor: isDark ? AppColors.techChipBgDark : AppColors.techChipBg,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  const Text('Sobre el proyecto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  Text(
                    project.description ?? 'Sin descripción.',
                    style: TextStyle(height: 1.6, color: isDark ? Colors.white70 : Colors.black87),
                  ),

                  const SizedBox(height: 32),

                  // Demo Video Section
                  if (project.promoVideoUrl != null && project.promoVideoUrl!.isNotEmpty) ...[
                    const Text('Video Promocional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.play_circle_filled, size: 48, color: AppColors.primaryYellow),
                          const SizedBox(height: 12),
                          const Text('Ver video demo oficial', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => NativeDocViewer.show(context, project.promoVideoUrl!, 'Video Demo', isVideo: true),
                            child: const Text('REPRODUCIR AHORA'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Deliverables
                  const Text('Documentación y Archivos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  ...project.videos.map((v) => _buildFileItem(context, v.title, v.url, Icons.video_file, isVideo: true)),
                  ...project.documents.map((d) => _buildFileItem(context, d.title, d.url, Icons.description, isImage: _isImage(d.type))),
                  
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isImage(String type) {
    return ['JPG', 'JPEG', 'PNG', 'WEBP'].contains(type.toUpperCase());
  }

  Widget _buildFileItem(BuildContext context, String title, String url, IconData icon, {bool isVideo = false, bool isImage = false}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryYellow),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => NativeDocViewer.show(context, url, title, isVideo: isVideo, isImage: isImage),
    );
  }
}
