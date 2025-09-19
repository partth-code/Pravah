import 'dart:io';
import 'package:dio/dio.dart';
import '../models/api_models.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:4000/api/v1';
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  // Profile
  Future<(UserProfile, FarmProfile)> getProfile() async {
    try {
      final response = await _dio.get('/profile');
      final user = UserProfile.fromJson(response.data['user'] ?? {});
      final farm = FarmProfile.fromJson(response.data['farm'] ?? {});
      return (user, farm);
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  // Tasks
  Future<List<Task>> getTasks() async {
    try {
      final response = await _dio.get('/tasks');
      final results = response.data['results'] as List? ?? [];
      return results.map((e) => Task.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  // Weather API
  Future<WeatherData> getWeather({required double lat, required double lng}) async {
    try {
      final response = await _dio.get('/weather', queryParameters: {
        'lat': lat,
        'lng': lng,
      });
      return WeatherData.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch weather: $e');
    }
  }

  // Policies API
  Future<List<Policy>> getPolicies({
    String query = '',
    String state = '',
    String crop = '',
  }) async {
    try {
      final response = await _dio.get('/policies', queryParameters: {
        'query': query,
        'state': state,
        'crop': crop,
      });
      final results = response.data['results'] as List? ?? [];
      return results.map((e) => Policy.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch policies: $e');
    }
  }

  // Tasks API
  Future<Map<String, dynamic>> markTask({
    required String taskId,
    required String status,
  }) async {
    try {
      final response = await _dio.post('/tasks/mark', data: {
        'taskId': taskId,
        'status': status,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to mark task: $e');
    }
  }

  // Disease Detection API
  Future<DiseaseDetection> detectDisease(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'disease_image.jpg',
        ),
      });

      final response = await _dio.post('/detect-disease', data: formData);
      return DiseaseDetection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to detect disease: $e');
    }
  }

  // Leaderboard API
  Future<List<LeaderboardEntry>> getLeaderboard({
    String scope = 'village',
    String id = 'default',
  }) async {
    try {
      final response = await _dio.get('/leaderboard', queryParameters: {
        'scope': scope,
        'id': id,
      });
      final entries = response.data['entries'] as List? ?? [];
      return entries.map((e) => LeaderboardEntry.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch leaderboard: $e');
    }
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
