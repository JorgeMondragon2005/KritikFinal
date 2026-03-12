class Video {
  final String title;
  final String url;
  final String description;

  Video({required this.title, required this.url, required this.description});

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        title: json['title']?.toString() ?? json['Title']?.toString() ?? '',
        url: json['url']?.toString() ?? json['Url']?.toString() ?? '',
        description: json['description']?.toString() ?? json['Description']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'description': description,
      };
}

class Document {
  final String title;
  final String url;
  final String type;

  Document({required this.title, required this.url, required this.type});

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        title: json['title']?.toString() ?? json['Title']?.toString() ?? '',
        url: json['url']?.toString() ?? json['Url']?.toString() ?? '',
        type: json['type']?.toString() ?? json['Type']?.toString() ?? 'PDF',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'type': type,
      };
}

class Project {
  final String? id;
  final String? teamName;
  final String? title;
  final String? category;
  final String? description;
  final String? status;
  final List<String> technologies;
  final String? studentId;
  final String? assignedTeacherId;
  final String? coverImageUrl;
  final String? iconUrl;
  final String? assignmentId;
  final List<Video> videos;
  final List<Document> documents;

  Project({
    this.id, 
    this.teamName,
    this.title, 
    this.category,
    this.description,
    this.status, 
    this.technologies = const [],
    this.studentId,
    this.assignedTeacherId,
    this.coverImageUrl,
    this.iconUrl,
    this.assignmentId,
    this.videos = const [],
    this.documents = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id']?.toString() ?? json['Id']?.toString() ?? json['_id']?.toString(),
        teamName: json['teamName']?.toString() ?? json['TeamName']?.toString(),
        title: json['title']?.toString() ?? json['Title']?.toString() ?? (json['teamName']?.toString() ?? json['TeamName']?.toString()),
        category: json['category']?.toString() ?? json['Category']?.toString(),
        description: json['description']?.toString() ?? json['Description']?.toString(),
        status: json['status']?.toString() ?? json['Status']?.toString(),
        technologies: (json['technologies'] as List?)?.cast<String>().toList() ?? (json['Technologies'] as List?)?.cast<String>().toList() ?? [],
        studentId: json['studentId']?.toString() ?? json['StudentId']?.toString(),
        assignedTeacherId: json['assignedTeacherId']?.toString() ?? json['AssignedTeacherId']?.toString(),
        coverImageUrl: json['coverImageUrl']?.toString() ?? json['CoverImageUrl']?.toString(),
        iconUrl: json['iconUrl']?.toString() ?? json['IconUrl']?.toString(),
        assignmentId: json['assignmentId']?.toString() ?? json['AssignmentId']?.toString(),
        videos: (json['videos'] as List?)?.map((x) => Video.fromJson(x)).toList() ?? (json['Videos'] as List?)?.map((x) => Video.fromJson(x)).toList() ?? [],
        documents: (json['documents'] as List?)?.map((x) => Document.fromJson(x)).toList() ?? (json['Documents'] as List?)?.map((x) => Document.fromJson(x)).toList() ?? [],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamName': teamName,
    'title': title,
    'category': category,
    'description': description,
    'status': status,
    'technologies': technologies,
    'studentId': studentId,
    'assignedTeacherId': assignedTeacherId,
    'coverImageUrl': coverImageUrl,
    'iconUrl': iconUrl,
    'assignmentId': assignmentId,
    'videos': videos.map((v) => v.toJson()).toList(),
    'documents': documents.map((d) => d.toJson()).toList(),
  };
}
