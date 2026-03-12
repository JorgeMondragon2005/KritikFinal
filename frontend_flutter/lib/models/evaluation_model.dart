class Evaluation {
  final String? projectId;
  final String? evaluatorId;
  final String? rubricId;
  final Map<String, int>? scores;
  final Map<String, int>? detailedScores;
  final String? feedback;
  final String? evidencePhotoBase64;
  final String? signatureBase64;

  Evaluation({
    this.projectId,
    this.evaluatorId,
    this.rubricId,
    this.scores,
    this.detailedScores,
    this.feedback,
    this.evidencePhotoBase64,
    this.signatureBase64,
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) => Evaluation(
    projectId: json['projectId'],
    evaluatorId: json['evaluatorId'],
    rubricId: json['rubricId'],
    scores: (json['scores'] as Map?)?.cast<String, int>(),
    detailedScores: (json['detailedScores'] as Map?)?.cast<String, int>(),
    feedback: json['feedback'],
    evidencePhotoBase64: json['evidencePhotoBase64'],
    signatureBase64: json['signatureBase64'],
  );

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'evaluatorId': evaluatorId,
    'rubricId': rubricId,
    'scores': scores,
    'detailedScores': detailedScores,
    'feedback': feedback,
    'evidencePhotoBase64': evidencePhotoBase64,
    'signatureBase64': signatureBase64,
  };
}
