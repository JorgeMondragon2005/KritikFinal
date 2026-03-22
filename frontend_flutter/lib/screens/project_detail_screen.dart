import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'native_media_viewer.dart';
import '../widgets/native_doc_viewer.dart';
import 'evaluation_screen.dart';
import '../models/evaluation_model.dart';
import '../services/api_service.dart';
import '../widgets/embedded_video_player.dart';
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
  final TextEditingController _commentController = TextEditingController();

  void _toggleUpvote() {
    if (widget.userId == null) return;
    setState(() {
      if (widget.project.upvotedBy.contains(widget.userId)) {
        widget.project.upvotedBy.remove(widget.userId);
      } else {
        widget.project.upvotedBy.add(widget.userId!);
      }
    });
    _apiService.toggleUpvote(widget.project.id!, widget.userId!);
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || widget.userId == null) return;

    final newComment = ProjectComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.userId,
      userName: 'Visitante',
      text: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      widget.project.comments.add(newComment);
      _commentController.clear();
    });

    await _apiService.addProjectComment(widget.project.id!, newComment);
  }

  bool _isDeleting = false;

  Future<void> _undoEvaluation() async {
    if (_existingEvaluation == null || _existingEvaluation!.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deshacer Evaluación'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta evaluación? El proyecto regresará a estado PENDIENTE para ti y podrás volver a evaluarlo desde cero.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sí, Eliminar',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    final success = await _apiService.deleteEvaluation(
      _existingEvaluation!.id!,
    );
    setState(() => _isDeleting = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evaluación borrada. Puedes volver a evaluar.'),
          ),
        );
        setState(() => _existingEvaluation = null);
      }
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al borrar evaluación.')),
        );
    }
  }

  Future<void> _undoProject() async {
    if (widget.project.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deshacer Entrega de Proyecto'),
        content: const Text(
          '¿Estás SEGURO de que quieres borrar tu proyecto? Esto eliminará todos los archivos, videos, upvotes y comentarios de forma PERMANENTE. Tendrás que volver a crearlo si la fecha límite no ha pasado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sí, Borrar Proyecto',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    final success = await _apiService.deleteProject(widget.project.id!);
    setState(() => _isDeleting = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proyecto borrado con éxito.')),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al borrar proyecto.')),
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchEvaluation();
  }

  Future<void> _fetchEvaluation() async {
    if (widget.project.id == null) return;
    try {
      final eval = await _apiService.getEvaluationByProjectId(
        widget.project.id!,
      );
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
    final bool canEvaluate =
        (widget.userRole?.toLowerCase() == 'evaluator' ||
        widget.userRole?.toLowerCase() == 'teacher' ||
        widget.userRole?.toLowerCase() == 'profesor');

    Widget? fab;
    if (canEvaluate && !_isLoadingEval) {
      fab = FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EvaluationScreen(
                projectId: widget.project.id ?? '',
                projectName: widget.project.title ?? 'Proyecto',
                evaluatorId: widget.userId,
              ),
            ),
          ).then((acted) {
            if (acted == true) _fetchEvaluation();
          });
        },
        icon: Icon(isEvaluated ? Icons.edit : Icons.star, color: Colors.white),
        label: Text(
          isEvaluated ? 'Editar Evaluación' : 'Evaluar Proyecto',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
      );
    } else if (isEvaluated &&
        !_isLoadingEval &&
        widget.userRole?.toLowerCase() == 'student') {
      fab = FloatingActionButton.extended(
        onPressed: () => PdfService.generateAndShowCertificate(
          project: widget.project,
          evaluation: _existingEvaluation!,
        ),
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: const Text(
          'Certificado PDF',
          style: TextStyle(color: Colors.white),
        ),
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
            actions: [
              IconButton(
                icon: Icon(
                  widget.project.upvotedBy.contains(widget.userId)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: widget.project.upvotedBy.contains(widget.userId)
                      ? Colors.red
                      : null,
                ),
                onPressed: widget.userId != null ? _toggleUpvote : null,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    '${widget.project.upvotedBy.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
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
                    : Container(
                        color: AppColors.primaryYellow.withOpacity(0.1),
                      ),
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
                    style: Theme.of(
                      context,
                    ).textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.project.category} • ${widget.project.teamName}',
                    style: const TextStyle(
                      color: AppColors.primaryYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Demo Video Section (Moved to the absolute top)
                  if (widget.project.promoVideoUrl != null &&
                      widget.project.promoVideoUrl!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Video Demo Principal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        String finalUrl = widget.project.promoVideoUrl!;
                        if (finalUrl.startsWith('/')) {
                          finalUrl =
                              'https://kritikfinal.onrender.com$finalUrl';
                        }
                        return EmbeddedVideoPlayer(url: finalUrl);
                      },
                    ),
                  ],

                  if (_existingEvaluation?.badgeEarned != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.military_tech,
                            color: Colors.amber,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _existingEvaluation!.badgeEarned!,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Technologies
                  if (widget.project.technologies.isNotEmpty) ...[
                    const Text(
                      'Tecnologías',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.project.technologies
                          .map(
                            (tech) => Chip(
                              label: Text(tech),
                              backgroundColor: isDark
                                  ? AppColors.techChipBgDark
                                  : AppColors.techChipBg,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  if (widget.project.members != null &&
                      widget.project.members!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Integrantes del Equipo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.project.members!
                          .map(
                            (member) => Chip(
                              avatar: CircleAvatar(
                                backgroundColor: AppColors.primaryYellow,
                                child: Text(
                                  member.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              label: Text(member),
                              backgroundColor: isDark
                                  ? AppColors.techChipBgDark
                                  : AppColors.techChipBg,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Sobre el proyecto',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.project.description ?? 'Sin descripción.',
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Pitch Video Section (At the bottom, replacing the old Promocional)
                  if (widget.project.pitchVideoUrl != null &&
                      widget.project.pitchVideoUrl!.isNotEmpty) ...[
                    const Text(
                      'Video Pitch',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        String finalUrl = widget.project.pitchVideoUrl!;
                        if (finalUrl.startsWith('/')) {
                          finalUrl =
                              'https://kritikfinal.onrender.com$finalUrl';
                        }
                        return EmbeddedVideoPlayer(url: finalUrl);
                      },
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Deliverables
                  const Text(
                    'Documentación y Archivos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  ...widget.project.videos.map(
                    (v) => _buildFileItem(
                      context,
                      v.title,
                      v.url,
                      Icons.video_file,
                      isVideo: true,
                    ),
                  ),
                  ...widget.project.documents.map(
                    (d) => _buildFileItem(
                      context,
                      d.title,
                      d.url,
                      Icons.description,
                      isImage: _isImage(d.type),
                    ),
                  ),

                  // Evaluation Feedback
                  if (_existingEvaluation?.feedback != null &&
                      _existingEvaluation!.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Feedback del Evaluador',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Text(
                        _existingEvaluation!.feedback!,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],

                  if (widget.userId != null &&
                      widget.userRole != null &&
                      widget.userId == widget.project.studentId) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isDeleting ? null : _undoProject,
                        icon: const Icon(Icons.warning, color: Colors.white),
                        label: const Text(
                          'DESHACER ENTREGA (BORRAR PROYECTO)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],

                  if (isEvaluated && canEvaluate) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isDeleting ? null : _undoEvaluation,
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'DESHACER EVALUACIÓN',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],

                  // Comentarios
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Foro de Comentarios',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  ...widget.project.comments.map(
                    (c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: const Icon(
                          Icons.person,
                          color: Colors.blueAccent,
                        ),
                      ),
                      title: Text(
                        c.userName ?? 'Anónimo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(c.text ?? ''),
                      trailing: Text(
                        '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  if (widget.project.comments.isEmpty)
                    const Text(
                      'Sé el primero en felicitar a este equipo.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),

                  const SizedBox(height: 16),
                  if (widget.userId != null)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Añadir un comentario...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: AppColors.primaryYellow,
                          ),
                          onPressed: _submitComment,
                        ),
                      ],
                    ),

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

  Widget _buildFileItem(
    BuildContext context,
    String title,
    String url,
    IconData icon, {
    bool isVideo = false,
    bool isImage = false,
  }) {
    String finalUrl = url;
    if (finalUrl.startsWith('/')) {
      finalUrl = 'https://kritikfinal.onrender.com$finalUrl';
    }

    return ListTile(
      leading: Icon(icon, color: AppColors.primaryYellow),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => NativeDocViewer.show(
        context,
        finalUrl,
        title,
        isVideo: isVideo,
        isImage: isImage,
      ),
    );
  }
}
