import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'native_media_viewer.dart';
import '../widgets/native_doc_viewer.dart';
import 'evaluation_screen.dart';
import '../models/evaluation_model.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  final String? userRole;
  final String? userId;
  
  const ProjectDetailScreen({
    super.key, 
    required this.project,
    this.userRole,
    this.userId,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ApiService _apiService = ApiService();
  Evaluation? _existingEvaluation;
  bool _isLoadingEval = true;

  @override
  void initState() {
    super.initState();
    _fetchEvaluation();
  }

  Future<void> _fetchEvaluation() async {
    if (widget.project.id == null) return;
    try {
      final eval = await _apiService.getEvaluationByProjectId(widget.project.id!);
      if (mounted) {
        setState(() {
          _existingEvaluation = eval;
          _isLoadingEval = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEval = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bool isEvaluated = _existingEvaluation != null;
    final bool canEvaluate = (widget.userRole?.toLowerCase() == 'evaluator' || widget.userRole?.toLowerCase() == 'teacher');

    Widget? fab;
    if (canEvaluate && !_isLoadingEval) {
      fab = FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EvaluationScreen(
              projectId: widget.project.id ?? '',
              projectName: widget.project.title ?? 'Proyecto',
              evaluatorId: widget.userId,
            )),
          ).then((acted) { if (acted == true) _fetchEvaluation(); });
        },
        icon: Icon(isEvaluated ? Icons.edit : Icons.star, color: Colors.white),
        label: Text(isEvaluated ? 'Editar Evaluación' : 'Evaluar Proyecto', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
      );
    } else if (isEvaluated && !_isLoadingEval && widget.userRole?.toLowerCase() == 'student') {
      fab = FloatingActionButton.extended(
        onPressed: () => PdfService.generateAndShowCertificate(
          project: widget.project, 
          evaluation: _existingEvaluation!
        ),
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: const Text('Certificado PDF', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade600,
      );
    }

    return Scaffold(
      floatingActionButton: fab,
      body: CustomScrollView(
        slivers: [
          // 1. Animated Header with Hero
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'project_cover_${widget.project.id}',
                child: widget.project.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.project.coverImageUrl!.startsWith('/') 
                            ? 'https://kritikfinal.onrender.com${widget.project.coverImageUrl}'
                            : widget.project.coverImageUrl!,
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
                    widget.project.title ?? 'Sin título',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.project.category} • ${widget.project.teamName}',
                    style: const TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.bold),
                  ),
                  
                  if (_existingEvaluation?.badgeEarned != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.military_tech, color: Colors.amber, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            _existingEvaluation!.badgeEarned!,
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Technologies
                  if (widget.project.technologies.isNotEmpty) ...[
                    const Text('Tecnologías', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.project.technologies.map((tech) => Chip(
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
                    widget.project.description ?? 'Sin descripción.',
                    style: TextStyle(height: 1.6, color: isDark ? Colors.white70 : Colors.black87),
                  ),

                  const SizedBox(height: 32),

                  // Demo Video Section
                  if (widget.project.promoVideoUrl != null && widget.project.promoVideoUrl!.isNotEmpty) ...[
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
                            onPressed: () {
                              String finalUrl = widget.project.promoVideoUrl!;
                              if (finalUrl.startsWith('/')) {
                                finalUrl = 'https://kritikfinal.onrender.com$finalUrl';
                              }
                              NativeDocViewer.show(context, finalUrl, 'Video Demo', isVideo: true);
                            },
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
                  ...widget.project.videos.map((v) => _buildFileItem(context, v.title, v.url, Icons.video_file, isVideo: true)),
                  ...widget.project.documents.map((d) => _buildFileItem(context, d.title, d.url, Icons.description, isImage: _isImage(d.type))),
                  
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
    String finalUrl = url;
    if (finalUrl.startsWith('/')) {
        finalUrl = 'https://kritikfinal.onrender.com$finalUrl';
    }

    return ListTile(
      leading: Icon(icon, color: AppColors.primaryYellow),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => NativeDocViewer.show(context, finalUrl, title, isVideo: isVideo, isImage: isImage),
    );
  }
}
