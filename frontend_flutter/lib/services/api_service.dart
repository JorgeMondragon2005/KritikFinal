// lib/services/api_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/user_model.dart';
import '../models/assignment_model.dart';
import '../models/project_model.dart';
import '../models/rubric_model.dart';
import '../models/evaluation_model.dart';
import '../models/criterion_model.dart';
import '../models/classroom_model.dart';
import '../models/enrollment_model.dart';
import '../models/notification_model.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class ApiService {
  final Dio _dio;

  static String get _baseUrl {
    // URL de producción en Render
    return 'https://kritikfinal.onrender.com';
  }

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: '$_baseUrl/api/',
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

  Future<User?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        'auth/login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Login error caught: $e');
      if (e is DioException) {
          debugPrint('DioException details: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<String?> register(User user, String password) async {
    try {
      final data = user.toJson();
      data['passwordHash'] = password; // Backend expects plain password in register for hashing
      
      final response = await _dio.post('auth/register', data: data);
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Register error: $e');
      if (e is DioException) {
        return e.response?.data.toString() ?? 'Error en el servidor';
      }
      return 'Error de conexión';
    }
  }

  Future<bool> uploadProfileBannerImage(String userId, File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/users/$userId/banner'),
      );
      request.files.add(await http.MultipartFile.fromPath('banner', imageFile.path));
      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error ApiService uploadProfileBannerImage: $e');
      return false;
    }
  }

  // --- RECOVERY SECTION ---
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Error recuperacion: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error ApiService forgotPassword: $e');
      return false;
    }
  }

  Future<bool> resetPassword(String email, String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Error al restablecer contraseña: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error ApiService resetPassword: $e');
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    try {
      final response = await _dio.post('auth/verify', data: {
        'email': email,
        'code': code,
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Verify error: $e');
      return false;
    }
  }

  Future<List<Project>> getProjects({String? studentId, String? teacherId, String? assignmentId, String? search}) async {
    try {
      final response = await _dio.get('projects', queryParameters: {
        if (studentId != null) 'studentId': studentId,
        if (teacherId != null) 'teacherId': teacherId,
        if (assignmentId != null) 'assignmentId': assignmentId,
        if (search != null) 'search': search,
      });
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        List<Project> projects = [];
        for (var item in data) {
          try {
            if (item is Map<String, dynamic>) {
              projects.add(Project.fromJson(item));
            }
          } catch (e) {
            debugPrint('Error parsing project item: $e');
          }
        }
        return projects;
      }
      return <Project>[];
    } catch (e) {
      debugPrint('Get projects error: $e');
      return <Project>[];
    }
  }

  Future<List<Project>> getAllProjects() async {
    try {
      final response = await _dio.get('projects');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((x) => Project.fromJson(x)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting all projects: $e');
      return [];
    }
  }

  Future<Project?> getProjectById(String id) async {
    try {
      final response = await _dio.get('projects/$id');
      if (response.statusCode == 200) {
        return Project.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting project $id: $e');
      return null;
    }
  }

  Future<List<Evaluation>> getProjectEvaluations(String projectId) async {
    try {
      final response = await _dio.get('evaluations/project/$projectId');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((x) => Evaluation.fromJson(x)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching evaluations for project $projectId: $e');
      return [];
    }
  }

  Future<Rubric?> getRubricById(String id) async {
    try {
      final response = await _dio.get('rubrics/$id');
      if (response.statusCode == 200) {
        return Rubric.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Get rubric by id error: $e');
      return null;
    }
  }

  Future<Evaluation?> getEvaluationByProjectId(String projectId, {String? evaluatorId}) async {
    try {
      final response = await _dio.get('evaluations/project/$projectId');
      if (response.statusCode == 200 && response.data is List) {
        final evals = (response.data as List).map((x) => Evaluation.fromJson(x)).toList();
        if (evals.isEmpty) return null;
        if (evaluatorId != null) {
          try {
            return evals.firstWhere((e) => e.evaluatorId == evaluatorId);
          } catch (_) {
            return null; // Evaluator hasn't evaluated yet
          }
        }
        return evals.first; // Legacy fallback
      }
      return null;
    } catch (e) {
      debugPrint('Get evaluation error: $e');
      return null;
    }
  }

  Future<bool> assignTeacher(String projectId, String teacherId) async {
    try {
      final response = await _dio.post('projects/$projectId/assign/$teacherId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Assign teacher error: $e');
      return false;
    }
  }

  Future<List<Rubric>> getRubrics({String? creatorId}) async {
    try {
      final response = await _dio.get('rubrics', queryParameters: {
        if (creatorId != null) 'creatorId': creatorId,
      });
      if (response.statusCode == 200) {
        return (response.data as List).map((x) => Rubric.fromJson(x)).toList();
      }
      return <Rubric>[];
    } catch (e) {
      debugPrint('Get rubrics error: $e');
      return <Rubric>[];
    }
  }

  Future<bool> createRubric(Map<String, dynamic> rubric) async {
    try {
      final response = await _dio.post('rubrics', data: rubric);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Create rubric error: $e');
      return false;
    }
  }

  Future<List<User>> getUsers() async {
    try {
      final response = await _dio.get('users');
      if (response.statusCode == 200) {
         final list = response.data as List;
         return list.map((e) => User.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      final response = await _dio.put('users/$userId/role', data: {'role': newRole});
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error updating user role: $e');
      return false;
    }
  }

  Future<bool> updateRubric(String id, Map<String, dynamic> rubric) async {
    try {
      final response = await _dio.put('rubrics/$id', data: rubric);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Update rubric error: $e');
      return false;
    }
  }

  Future<bool> deleteRubric(String id) async {
    try {
      final response = await _dio.delete('rubrics/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Delete rubric error: $e');
      return false;
    }
  }

  Future<bool> createProjectsBatch(List<Project> projects) async {
    try {
      final response = await _dio.post(
        'projects/batch',
        data: projects.map((p) => p.toJson()).toList(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Batch create error: $e');
      return false;
    }
  }

  Future<List<Criterion>> getCriteria() async {
    try {
      final response = await _dio.get('criteria');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Criterion.fromJson(json)).toList();
      }
      return <Criterion>[];
    } catch (e) {
      debugPrint('Get criteria error: $e');
      return <Criterion>[];
    }
  }

  Future<bool> submitEvaluation(Evaluation data) async {
    try {
      final response = await _dio.post('evaluations', data: data.toJson());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException) {
          throw Exception('Backend Error: ${e.response?.statusCode} - ${e.response?.data}');
      }
      throw Exception(e.toString());
    }
  }

  Future<List<Evaluation>> getEvaluationsByEvaluator(String evaluatorId) async {
    try {
      final response = await _dio.get('evaluations');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        List<Evaluation> evals = [];
        for (var item in data) {
          try {
            evals.add(Evaluation.fromJson(item));
          } catch (e) {
            debugPrint('Error parsing an evaluation: $e');
          }
        }
        return evals.where((e) => e.evaluatorId == evaluatorId).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get evaluations by evaluator error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRankings() async {
    try {
      final response = await _dio.get('projects/rankings');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('Get rankings error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<String?> uploadFile(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post('Upload', data: formData);
      if (response.statusCode == 200) {
        return response.data['url'];
      }
      return null;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // Assignments
  Future<List<Assignment>> getAssignments({String? teacherId, String? studentId, String? evaluatorId}) async {
    try {
      debugPrint('DEBUG: Calling getAssignments with teacherId: $teacherId, studentId: $studentId, evaluatorId: $evaluatorId');
      final response = await _dio.get('Assignments', queryParameters: {
        if (teacherId != null) 'teacherId': teacherId,
        if (studentId != null) 'studentId': studentId,
        if (evaluatorId != null) 'evaluatorId': evaluatorId,
      });
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        debugPrint('DEBUG: getAssignments returned ${data.length} items');
        List<Assignment> assignments = [];
        for (var item in data) {
          try {
            if (item is Map<String, dynamic>) {
              assignments.add(Assignment.fromJson(item));
            }
          } catch (e) {
            debugPrint('Error parsing assignment item: $e');
          }
        }
        return assignments;
      }
      return <Assignment>[];
    } catch (e) {
      debugPrint('Get assignments error: $e');
      return <Assignment>[];
    }
  }

  Future<List<Assignment>> getAssignmentsByClassroom(String classroomId) async {
    try {
      debugPrint('DEBUG: Fetching assignments for classroom: "$classroomId"');
      final response = await _dio.get('Assignments/classroom/$classroomId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        debugPrint('DEBUG: Found ${data.length} assignments for classroom $classroomId');
        return data.map((json) => Assignment.fromJson(json)).toList();
      }
      return <Assignment>[];
    } catch (e) {
      debugPrint('DEBUG: Error in getAssignmentsByClassroom: $e');
      return <Assignment>[];
    }
  }

  Future<Assignment?> getAssignmentById(String id) async {
    try {
      final response = await _dio.get('Assignments/$id');
      if (response.statusCode == 200) {
        return Assignment.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Get assignment by id error: $e');
      return null;
    }
  }

  Future<Assignment?> getAssignmentByCode(String code) async {
    try {
      final response = await _dio.get('Assignments/code/$code');
      if (response.statusCode == 200) {
        return Assignment.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Get assignment by code error: $e');
      return null;
    }
  }

  Future<bool> createAssignment(Assignment assignment) async {
    try {
      final response = await _dio.post('Assignments', data: assignment.toJson());
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Create assignment error: $e');
      return false;
    }
  }

  Future<bool> updateAssignment(Assignment assignment) async {
    try {
      final response = await _dio.put('Assignments/${assignment.id}', data: assignment.toJson());
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Update assignment error: $e');
      return false;
    }
  }

  Future<bool> updateProject(Project project) async {
    try {
      final response = await _dio.put('Projects/${project.id}', data: project.toJson());
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Update project error: $e');
      return false;
    }
  }

  Future<bool> updateEvaluation(Evaluation evaluation) async {
    try {
      final response = await _dio.put('Evaluations/${evaluation.id}', data: evaluation.toJson());
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Update evaluation error: $e');
      return false;
    }
  }

  Future<bool> deleteAssignment(String id) async {
    try {
      final response = await _dio.delete('Assignments/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Delete assignment error: $e');
      return false;
    }
  }

  Future<bool> deleteProject(String id) async {
    try {
      final response = await _dio.delete('Projects/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Delete project error: $e');
      return false;
    }
  }

  // User Profile
  Future<User?> getUserProfile(String id) async {
    try {
      final response = await _dio.get('Users/$id');
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile(User user) async {
    try {
      final response = await _dio.put('Users/${user.id}', data: user.toJson());
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {
          throw Exception('Backend Error: ${e.response?.statusCode} - ${e.response?.data}');
      }
      throw Exception(e.toString());
    }
  }

  Future<List<User>> getEvaluators() async {
    try {
      final response = await _dio.get('Users/evaluators');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((x) => User.fromJson(x)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting evaluators: $e');
      return [];
    }
  }

  // --- NOTIFICATIONS ---
  Future<List<AppNotification>> getUserNotifications(String userId) async {
    try {
      final response = await _dio.get('Notifications/user/$userId');
      if (response.statusCode == 200) {
        return (response.data as List).map((x) => AppNotification.fromJson(x)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error ApiService getUserNotifications: $e');
      return [];
    }
  }

  Future<bool> createNotification(AppNotification notification) async {
    try {
      final response = await _dio.post('Notifications', data: notification.toJson());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      return false;
    }
  }

  Future<bool> markNotificationAsRead(String id) async {
    try {
      final response = await _dio.put('Notifications/$id/read');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead(String userId) async {
    try {
      final response = await _dio.put('Notifications/user/$userId/read');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  Future<Classroom?> getClassroomById(String id) async {
    try {
      final response = await _dio.get('Classrooms/$id');
      if (response.statusCode == 200) {
        return Classroom.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Get classroom by id error: $e');
      return null;
    }
  }

  // Classrooms
  Future<List<Classroom>> getClassrooms({String? teacherId, String? studentId}) async {
    try {
      final response = await _dio.get('Classrooms', queryParameters: {
        if (teacherId != null) 'teacherId': teacherId,
        if (studentId != null) 'studentId': studentId,
      });
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        List<Classroom> classrooms = [];
        for (var item in data) {
          try {
            if (item is Map<String, dynamic>) {
              classrooms.add(Classroom.fromJson(item));
            }
          } catch (e) {
            debugPrint('Error parsing classroom item: $e');
          }
        }
        return classrooms;
      }
      return <Classroom>[];
    } catch (e) {
      debugPrint('Get classrooms error: $e');
      return <Classroom>[];
    }
  }

  Future<Classroom?> getClassroomByCode(String code) async {
    try {
      final response = await _dio.get('Classrooms/code/$code');
      if (response.statusCode == 200) {
        return Classroom.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Get classroom by code error: $e');
      return null;
    }
  }

  Future<dynamic> createClassroom(Classroom classroom) async {
    try {
      final response = await _dio.post('Classrooms', data: classroom.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Classroom.fromJson(response.data);
      }
      return 'Error ${response.statusCode}: ${response.statusMessage}';
    } catch (e) {
      debugPrint('Create classroom error: $e');
      if (e is DioException) {
        debugPrint('Dio Error Response: ${e.response?.data}');
        if (e.response?.statusCode == 404) {
          return 'Error 404: El servidor no reconoce la ruta /api/Classrooms. Asegúrate de que el backend esté desplegado correctamente.';
        }
        return 'Error ${e.response?.statusCode ?? 'Conexión'}: ${e.response?.data ?? e.message}';
      }
      return e.toString();
    }
  }

  Future<dynamic> updateClassroom(Classroom classroom) async {
    try {
      final response = await _dio.put('Classrooms/${classroom.id}', data: classroom.toJson());
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Update classroom error (ID: ${classroom.id}): $e');
      if (e is DioException) {
        return 'Error ${e.response?.statusCode ?? 'Conexión'} al actualizar ID ${classroom.id}: ${e.response?.data ?? e.message}';
      }
      return 'Error al actualizar ID ${classroom.id}: $e';
    }
  }

  Future<dynamic> deleteClassroom(String id) async {
    try {
      final response = await _dio.delete('Classrooms/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Delete classroom error (ID: $id): $e');
      if (e is DioException) {
        return 'Error ${e.response?.statusCode ?? 'Conexión'} al eliminar ID $id: ${e.response?.data ?? e.message}';
      }
      return 'Error al eliminar ID $id: $e';
    }
  }

  Future<dynamic> enrollInClass(ClassEnrollment enrollment) async {
    try {
      final response = await _dio.post('Classrooms/enroll', data: enrollment.toJson());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException) {
        final errorData = e.response?.data;
        debugPrint('Enroll error detailed: ${e.message}');
        debugPrint('Enroll error response body: $errorData');
        return errorData?.toString() ?? e.message;
      }
      debugPrint('Enroll error unknown: $e');
      return e.toString();
    }
  }

  Future<List<ClassEnrollment>> getClassMembers(String classroomId) async {
    try {
      final response = await _dio.get('Classrooms/$classroomId/members');
      if (response.statusCode == 200) {
        return (response.data as List).map((x) => ClassEnrollment.fromJson(x)).toList();
      }
      return <ClassEnrollment>[];
    } catch (e) {
      debugPrint('Get class members error: $e');
      return <ClassEnrollment>[];
    }
  }

  Future<bool> updateEnrollmentStatus(String enrollmentId, String status) async {
    try {
      final response = await _dio.patch('Classrooms/enroll/$enrollmentId/status', queryParameters: {'status': status});
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Update enrollment status error: $e');
      return false;
    }
  }

  Future<bool> leaveClassroom(String studentId, String classroomId) async {
    try {
      final response = await _dio.delete('Classrooms/enroll/$studentId/$classroomId');
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Leave classroom error: $e');
      return false;
    }
  }


  /// Descarga un archivo y lo abre usando la aplicación nativa correspondiente
  Future<void> downloadAndOpenFile(String url, String fileName) async {
    try {
      final finalUrl = url.startsWith('/') ? 'https://kritikfinal.onrender.com$url' : url;
      
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      
      await _dio.download(finalUrl, filePath);
      
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception('No se encontró una aplicación para abrir este archivo.');
      }
    } catch (e) {
      debugPrint('Download/Open error: $e');
      rethrow;
    }
  }

  // --- AI INTEGRATION EXPERIMENTAL ---
  Future<String?> getProjectMentorReview(Project project) async {
    try {
      final response = await _dio.post('AI/mentor/review', data: project.toJson());
      if (response.statusCode == 200) {
        return response.data['suggestion'];
      }
      return null;
    } catch (e) {
      debugPrint('AI Mentor error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> suggestEvaluationResultsWithAI(Project project, Rubric rubric) async {
    try {
      final response = await _dio.post('AI/evaluation/suggest', data: {
        'project': project.toJson(),
        'rubric': rubric.toJson(),
      });
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('AI Evaluator error: $e');
      return null;
    }
  }

  Future<List<String>> getMatchmakingRecommendations(String userId, String userRole, List<Project> projects) async {
    try {
      final response = await _dio.post('AI/matchmaking', data: {
        'userId': userId,
        'userRole': userRole,
        'projects': projects.map((p) => p.toJson()).toList(),
      });
      if (response.statusCode == 200) {
        final List<dynamic> ids = response.data;
        return ids.map((id) => id.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('AI Matchmaking error: $e');
      return [];
    }
  }
}

