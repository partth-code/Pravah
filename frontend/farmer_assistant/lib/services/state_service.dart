import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/api_models.dart';
import 'api_service.dart';

class StateService extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // App Loading State
  bool _isAppLoading = true;

  // User and Farm Data
  UserProfile? _userProfile;
  FarmProfile? _farmProfile;
  
  // Weather Data
  WeatherData? _weatherData;
  bool _weatherLoading = false;

  // Tasks
  List<Task> _tasks = [];
  bool _tasksLoading = false;

  // Policies
  List<Policy> _policies = [];
  bool _policiesLoading = false;

  // Leaderboard
  List<LeaderboardEntry> _leaderboard = [];
  bool _leaderboardLoading = false;

  // Points and Gamification
  int _totalPoints = 0;
  int _weeklyStreak = 0;

  // Roadmap
  bool _hasRoadmap = false;
  String _roadmapPhase = '';
  List<String> _roadmapMilestones = const [];

  // Getters
  bool get isAppLoading => _isAppLoading;
  UserProfile? get userProfile => _userProfile;
  FarmProfile? get farmProfile => _farmProfile;
  WeatherData? get weatherData => _weatherData;
  bool get weatherLoading => _weatherLoading;
  List<Task> get tasks => _tasks;
  bool get tasksLoading => _tasksLoading;
  List<Policy> get policies => _policies;
  bool get policiesLoading => _policiesLoading;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  bool get leaderboardLoading => _leaderboardLoading;
  int get totalPoints => _totalPoints;
  int get weeklyStreak => _weeklyStreak;
  bool get hasRoadmap => _hasRoadmap;
  String get roadmapPhase => _roadmapPhase;
  List<String> get roadmapMilestones => _roadmapMilestones;

  // Bootstrap from backend
  Future<void> bootstrap() async {
    try {
      // Add a timeout to prevent infinite loading
      await Future.any([
        _performBootstrap(),
        Future.delayed(const Duration(seconds: 5)),
      ]);
    } catch (e) {
      debugPrint('Bootstrap error: $e');
    } finally {
      // Always stop loading screen after timeout or completion
      _isAppLoading = false;
      notifyListeners();
    }
  }

  Future<void> _performBootstrap() async {
    try {
      // Profile
      final (user, farm) = await _apiService.getProfile();
      _userProfile = user;
      _farmProfile = farm;

      // Tasks
      _tasksLoading = true;
      notifyListeners();
      _tasks = await _apiService.getTasks();
      _tasksLoading = false;

      // Derived values (example – these might come from backend later)
      _totalPoints = _tasks.fold<int>(0, (p, t) => p + t.points);
      _weeklyStreak = 5; // placeholder until backend provides streaks

      notifyListeners();

      // Weather
      await fetchWeather();

      // Policies
      await fetchPolicies();

      // Leaderboard
      await fetchLeaderboard();
      
      // App loading complete
      _isAppLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Bootstrap API error: $e');
      // Create mock data if API fails
      _createMockData();
      _isAppLoading = false;
      notifyListeners();
    }
  }

  void _createMockData() {
    // Create mock user and farm data
    _userProfile = UserProfile(
      userId: 'mock_user',
      name: 'Farmer Dev',
      phone: '+91 90000 00000',
      language: 'en',
      farmProfileId: 'mock_farm',
      aadhaarHash: 'XXXX-XXXX-XXXX',
      uniqueFarmId: 'FARM-123456',
      uniqueFarmerId: 'FRMR-654321',
    );
    
    _farmProfile = FarmProfile(
      farmId: 'mock_farm',
      userId: 'mock_user',
      state: 'Kerala',
      district: 'Ernakulam',
      lat: 9.9816,
      lng: 76.2999,
      soilType: 'Loamy',
      area: 2.5,
      waterLevel: 'Medium',
      primaryCrop: 'Rice',
    );

    // Create mock tasks
    _tasks = [
      Task(
        taskId: 'task_1',
        farmId: 'mock_farm',
        title: 'Irrigation Check',
        points: 10,
        status: 'pending',
        date: DateTime.now().add(const Duration(days: 1)),
        priority: 'high',
      ),
      Task(
        taskId: 'task_2',
        farmId: 'mock_farm',
        title: 'Soil Testing',
        points: 15,
        status: 'pending',
        date: DateTime.now().add(const Duration(days: 3)),
        priority: 'medium',
      ),
    ];

    // Create mock policies
    _policies = [
      Policy(
        policyId: 'p1',
        title: 'Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)',
        description: 'Direct income support of ₹6,000 per year to all landholding farmer families',
        eligibility: 'All landholding farmer families',
        requiredDocs: ['Aadhaar Card', 'Land Records', 'Bank Account Details', 'Mobile Number'],
        states: ['All States', 'All Union Territories'],
        tags: ['Income Support', 'Direct Benefit Transfer', 'Central Scheme'],
      ),
      Policy(
        policyId: 'p2',
        title: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
        description: 'Crop insurance scheme to provide financial support to farmers in case of crop failure',
        eligibility: 'All farmers growing notified crops',
        requiredDocs: ['Aadhaar Card', 'Land Records', 'Bank Account Details', 'Crop Details'],
        states: ['All States', 'All Union Territories'],
        tags: ['Crop Insurance', 'Risk Management', 'Central Scheme'],
      ),
      Policy(
        policyId: 'p3',
        title: 'Soil Health Card Scheme',
        description: 'Issue soil health cards to farmers every 2 years with crop-wise recommendations',
        eligibility: 'All farmers',
        requiredDocs: ['Aadhaar Card', 'Land Records', 'Soil Sample'],
        states: ['All States', 'All Union Territories'],
        tags: ['Soil Health', 'Scientific Farming', 'Central Scheme'],
      ),
    ];

    // Create mock leaderboard
    _leaderboard = [
      LeaderboardEntry(
        userId: 'u1',
        name: 'Ravi Kumar',
        points: 1250,
        rank: 1,
        level: 'Expert',
        badge: 'Gold',
        village: 'Ludhiana Village',
        state: 'Punjab',
        tasksCompleted: 45,
        streak: 12,
      ),
      LeaderboardEntry(
        userId: 'u2',
        name: 'Lakshmi Devi',
        points: 1180,
        rank: 2,
        level: 'Expert',
        badge: 'Gold',
        village: 'Ludhiana Village',
        state: 'Punjab',
        tasksCompleted: 42,
        streak: 8,
      ),
      LeaderboardEntry(
        userId: 'u3',
        name: 'Aman Singh',
        points: 1095,
        rank: 3,
        level: 'Advanced',
        badge: 'Silver',
        village: 'Ludhiana Village',
        state: 'Punjab',
        tasksCompleted: 38,
        streak: 15,
      ),
      LeaderboardEntry(
        userId: 'u4',
        name: 'Priya Sharma',
        points: 1020,
        rank: 4,
        level: 'Advanced',
        badge: 'Silver',
        village: 'Ludhiana Village',
        state: 'Punjab',
        tasksCompleted: 35,
        streak: 6,
      ),
      LeaderboardEntry(
        userId: 'u5',
        name: 'Rajesh Patel',
        points: 980,
        rank: 5,
        level: 'Intermediate',
        badge: 'Bronze',
        village: 'Ludhiana Village',
        state: 'Punjab',
        tasksCompleted: 32,
        streak: 4,
      ),
    ];

    _totalPoints = _tasks.fold<int>(0, (p, t) => p + t.points);
    _weeklyStreak = 5;
    
    debugPrint('Created mock data for offline mode');
  }

  // Weather methods
  Future<void> fetchWeather() async {
    if (_farmProfile == null) return;
    
    _weatherLoading = true;
    notifyListeners();

    try {
      _weatherData = await _apiService.getWeather(
        lat: _farmProfile!.lat,
        lng: _farmProfile!.lng,
      );
    } catch (e) {
      debugPrint('Weather fetch error: $e');
    } finally {
      _weatherLoading = false;
      notifyListeners();
    }
  }

  // Tasks methods
  Future<void> fetchTasks() async {
    _tasksLoading = true;
    notifyListeners();

    try {
      _tasks = await _apiService.getTasks();
    } catch (e) {
      debugPrint('Tasks fetch error: $e');
    } finally {
      _tasksLoading = false;
      notifyListeners();
    }
  }

  Future<void> markTaskComplete(String taskId) async {
    try {
      final result = await _apiService.markTask(
        taskId: taskId,
        status: 'done',
      );

      final pointsAwarded = (result['pointsAwarded'] ?? 0) as int;
      _totalPoints += pointsAwarded;

      // Update task status locally
      final taskIndex = _tasks.indexWhere((t) => t.taskId == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = Task(
          taskId: _tasks[taskIndex].taskId,
          farmId: _tasks[taskIndex].farmId,
          date: _tasks[taskIndex].date,
          title: _tasks[taskIndex].title,
          status: 'done',
          points: _tasks[taskIndex].points,
          priority: _tasks[taskIndex].priority,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Mark task error: $e');
    }
  }

  // Policies methods
  Future<void> fetchPolicies({String query = ''}) async {
    _policiesLoading = true;
    notifyListeners();

    try {
      _policies = await _apiService.getPolicies(
        query: query,
        state: _farmProfile?.state ?? '',
        crop: _farmProfile?.primaryCrop ?? '',
      );
    } catch (e) {
      debugPrint('Policies fetch error: $e');
    } finally {
      _policiesLoading = false;
      notifyListeners();
    }
  }

  // Leaderboard methods
  Future<void> fetchLeaderboard({String scope = 'village'}) async {
    _leaderboardLoading = true;
    notifyListeners();

    try {
      _leaderboard = await _apiService.getLeaderboard(
        scope: scope,
        id: _farmProfile?.district ?? 'default',
      );
    } catch (e) {
      debugPrint('Leaderboard fetch error: $e');
    } finally {
      _leaderboardLoading = false;
      notifyListeners();
    }
  }

  // Disease detection
  Future<DiseaseDetection> detectDisease(String imagePath) async {
    try {
      final file = File(imagePath);
      return await _apiService.detectDisease(file);
    } catch (e) {
      throw Exception('Disease detection failed: $e');
    }
  }

  // Health check
  Future<bool> checkApiHealth() async {
    return await _apiService.healthCheck();
  }

  // Roadmap methods (kept local for now)
  Future<void> generateRoadmap() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      _hasRoadmap = true;
      _roadmapPhase = 'Sowing Preparation';
      _roadmapMilestones = const [
        'Soil Testing',
        'Seed Selection',
        'Sowing',
        'Irrigation Schedule',
        'Fertilization',
        'Pest Control',
        'Harvest',
      ];
      notifyListeners();
    } catch (e) {
      debugPrint('Generate roadmap error: $e');
    }
  }

  void resetRoadmapForNewSeason() {
    _hasRoadmap = false;
    _roadmapPhase = '';
    _roadmapMilestones = const [];
    notifyListeners();
  }
}
