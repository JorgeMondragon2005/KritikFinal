import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';
import '../models/evaluation_model.dart';
import '../theme/app_theme.dart';
import '../widgets/project_card_widget.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _rankedProjects = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final projects = await _apiService.getAllProjects();
      
      // For each project, we need its evaluations to calculate total score
      List<Map<String, dynamic>> rankings = [];
      
      for (var p in projects) {
        final evals = await _apiService.getProjectEvaluations(p.id ?? '');
        double totalScore = 0;
        if (evals.isNotEmpty) {
          // Average of evaluations or sum? Let's use average for fairness
          double sum = 0;
          for (var e in evals) {
            if (e.scores != null) {
              sum += e.scores!.values.values.fold(0.0, (prev, element) => prev + element);
            }
          }
          totalScore = sum / evals.length;
        }
        
        rankings.add({
          'project': p,
          'score': totalScore,
          'evalCount': evals.length,
        });
      }

      // Sort by score descending
      rankings.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      setState(() {
        _rankedProjects = rankings;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking en Vivo'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLeaderboard,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonList()
          : RefreshIndicator(
              onRefresh: _fetchLeaderboard,
              child: _rankedProjects.isEmpty
                  ? const Center(child: Text('Aún no hay proyectos evaluados'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rankedProjects.length,
                      itemBuilder: (context, index) {
                        final item = _rankedProjects[index];
                        final project = item['project'] as Project;
                        final score = item['score'] as double;
                        final rank = index + 1;

                        return _buildRankItem(context, project, score, rank, isDark);
                      },
                    ),
            ),
    );
  }

  Widget _buildRankItem(BuildContext context, Project project, double score, int rank, bool isDark) {
    Color medalColor = Colors.grey;
    if (rank == 1) medalColor = const Color(0xFFFFD700); // Gold
    if (rank == 2) medalColor = const Color(0xFFC0C0C0); // Silver
    if (rank == 3) medalColor = const Color(0xFFCD7F32); // Bronze

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: rank <= 3 ? Border.all(color: medalColor.withOpacity(0.5), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Number / Medal
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3 ? medalColor.withOpacity(0.2) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: rank <= 3 ? medalColor : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Project Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title ?? 'Sin título',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  project.teamName ?? 'Equipo S/N',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Text('PUNTOS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: SkeletonLoader(height: 80, borderRadius: 16),
      ),
    );
  }
}
