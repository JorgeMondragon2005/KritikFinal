class Evaluation {
  final String? id;
  final String? projectId;
  final String? evaluatorId;
  final String? rubricId;
  final Map<String, int>? scores;
  final Map<String, int>? detailedScores;
  final String? feedback;
  final String? evidencePhotoBase64;
  final String? signatureBase64;
  final String? badgeEarned;

  Evaluation({
    this.id,
    this.projectId,
    this.evaluatorId,
    this.rubricId,
    this.scores,
    this.detailedScores,
    this.feedback,
    this.evidencePhotoBase64,
    this.signatureBase64,
    this.badgeEarned,
  });

  double? get generalScore {
    if (detailedScores == null || detailedScores!.isEmpty) return null;
    return detailedScores!.values.fold(0, (sum, score) => sum + score).toDouble();
  }

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    // Backend can return scores as an object with a 'values' field (RubricScores)
    Map<String, int>? parsedScores;
    if (json['scores'] != null && json['scores'] is Map) {
      if (json['scores']['values'] != null && json['scores']['values'] is Map) {
        parsedScores = (json['scores']['values'] as Map).cast<String, int>();
      } else {
        try {
          parsedScores = (json['scores'] as Map).cast<String, int>();
        } catch (_) {
          // If cast fails, maybe it's not the flat map we expected
        }
      }
    }

    return Evaluation(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? json['_id']?.toString(),
      projectId: json['projectId']?.toString() ?? json['ProjectId']?.toString(),
      evaluatorId: json['evaluatorId']?.toString() ?? json['EvaluatorId']?.toString(),
      rubricId: json['rubricId']?.toString() ?? json['RubricId']?.toString(),
      scores: parsedScores,
      detailedScores: (json['detailedScores'] as Map?)?.cast<String, int>() ?? 
                      (json['DetailedScores'] as Map?)?.cast<String, int>(),
      feedback: json['feedback']?.toString() ?? json['Feedback']?.toString(),
      evidencePhotoBase64: json['evidencePhotoBase64']?.toString(),
      signatureBase64: json['signatureBase64']?.toString(),
      badgeEarned: json['badgeEarned']?.toString() ?? json['BadgeEarned']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'evaluatorId': evaluatorId,
    'rubricId': rubricId,
    'scores': scores,
    'detailedScores': detailedScores,
    'feedback': feedback,
    'evidencePhotoBase64': evidencePhotoBase64,
    'signatureBase64': signatureBase64,
    if (badgeEarned != null) 'badgeEarned': badgeEarned,
  };
}
