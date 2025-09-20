import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
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

      // Policies - use mock data
      _policies = _getMockPoliciesData('', 'en');

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

    // Create mock policies using comprehensive data
    _policies = _getMockPoliciesData('', 'en');

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
  Future<void> fetchPolicies({String query = '', String language = 'en'}) async {
    _policiesLoading = true;
    notifyListeners();

    try {
      // Use mock data instead of API call
      _policies = _getMockPoliciesData(query, language);
    } catch (e) {
      debugPrint('Policies fetch error: $e');
    } finally {
      _policiesLoading = false;
      notifyListeners();
    }
  }

  List<Policy> _getMockPoliciesData(String query, String language) {
    // Create comprehensive mock policies data
    final allPolicies = [
      Policy(
        policyId: 'p1',
        title: 'PM Kisan Samman Nidhi',
        description: 'Direct income support scheme providing ₹6,000 per year to all landholding farmer families across the country.',
        eligibility: 'All landholding farmer families with cultivable land',
        requiredDocs: [
          'Aadhaar Card',
          'Land Records',
          'Bank Account Details',
          'Mobile Number'
        ],
        states: ['All States', 'Union Territories'],
        tags: ['Income Support', 'Direct Benefit Transfer', 'Annual Payment'],
        applicationDeadline: 'Ongoing',
        benefits: '₹6,000 per year in 3 installments',
        contactInfo: '1800-180-1551',
        website: 'https://pmkisan.gov.in',
        status: 'Active',
      ),
      Policy(
        policyId: 'p2',
        title: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
        description: 'Crop insurance scheme providing financial support to farmers in case of crop failure due to natural calamities.',
        eligibility: 'All farmers growing notified crops in notified areas',
        requiredDocs: [
          'Land Records',
          'Crop Details',
          'Bank Account Details',
          'Aadhaar Card'
        ],
        states: ['All States', 'Union Territories'],
        tags: ['Crop Insurance', 'Natural Calamities', 'Premium Subsidy'],
        applicationDeadline: 'Before sowing season',
        benefits: 'Up to 100% premium subsidy for small farmers',
        contactInfo: '1800-180-1551',
        website: 'https://pmfby.gov.in',
        status: 'Active',
      ),
      Policy(
        policyId: 'p3',
        title: 'Soil Health Card Scheme',
        description: 'Scheme to provide soil health cards to farmers with recommendations for appropriate use of fertilizers.',
        eligibility: 'All farmers with agricultural land',
        requiredDocs: [
          'Land Records',
          'Aadhaar Card',
          'Mobile Number'
        ],
        states: ['All States', 'Union Territories'],
        tags: ['Soil Testing', 'Fertilizer Recommendation', 'Sustainable Farming'],
        applicationDeadline: 'Ongoing',
        benefits: 'Free soil testing and recommendations',
        contactInfo: '1800-180-1551',
        website: 'https://soilhealth.dac.gov.in',
        status: 'Active',
      ),
      Policy(
        policyId: 'p4',
        title: 'Kisan Credit Card (KCC)',
        description: 'Credit card scheme for farmers to meet their short-term credit requirements for cultivation.',
        eligibility: 'All farmers including tenant farmers and oral lessees',
        requiredDocs: [
          'Land Records',
          'Aadhaar Card',
          'Bank Account Details',
          'Income Certificate'
        ],
        states: ['All States', 'Union Territories'],
        tags: ['Credit Card', 'Short-term Credit', 'Low Interest'],
        applicationDeadline: 'Ongoing',
        benefits: 'Up to ₹3 lakh credit at 4% interest',
        contactInfo: 'Contact nearest bank branch',
        website: 'https://www.rbi.org.in',
        status: 'Active',
      ),
      Policy(
        policyId: 'p5',
        title: 'Pradhan Mantri Kisan Sampada Yojana',
        description: 'Scheme for creation of modern infrastructure for food processing sector.',
        eligibility: 'Food processing units, entrepreneurs, and farmers',
        requiredDocs: [
          'Project Proposal',
          'Land Documents',
          'Financial Statements',
          'Technical Details'
        ],
        states: ['All States', 'Union Territories'],
        tags: ['Food Processing', 'Infrastructure', 'Modernization'],
        applicationDeadline: 'As per notification',
        benefits: 'Up to 50% subsidy on project cost',
        contactInfo: '1800-180-1551',
        website: 'https://mofpi.nic.in',
        status: 'Active',
      ),
      Policy(
        policyId: 'p6',
        title: 'National Mission for Sustainable Agriculture',
        description: 'Mission to promote sustainable agriculture through climate change adaptation and mitigation measures.',
        eligibility: 'Farmers practicing sustainable agriculture',
        requiredDocs: [
          'Land Records',
          'Crop Details',
          'Sustainability Practices Documentation'
        ],
        states: ['All States', 'Union Territories'],
        tags: ['Sustainable Agriculture', 'Climate Change', 'Environment'],
        applicationDeadline: 'Ongoing',
        benefits: 'Financial assistance for sustainable practices',
        contactInfo: '1800-180-1551',
        website: 'https://nmsa.dac.gov.in',
        status: 'Active',
      ),
    ];

    // Filter policies based on query if provided
    if (query.isNotEmpty) {
      return allPolicies.where((policy) {
        return policy.title.toLowerCase().contains(query.toLowerCase()) ||
               policy.description.toLowerCase().contains(query.toLowerCase()) ||
               policy.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
      }).toList();
    }

    return allPolicies;
  }

  // Leaderboard methods
  Future<void> fetchLeaderboard({String scope = 'village'}) async {
    _leaderboardLoading = true;
    notifyListeners();

    try {
      // Use mock data instead of backend call
      _leaderboard = _getMockLeaderboardData(scope);
    } catch (e) {
      debugPrint('Leaderboard fetch error: $e');
    } finally {
      _leaderboardLoading = false;
      notifyListeners();
    }
  }

  List<LeaderboardEntry> _getMockLeaderboardData(String scope) {
    // Mock leaderboard data based on scope
    final mockData = {
      'village': [
        LeaderboardEntry(
          userId: 'u1', name: 'Ravi Kumar', points: 1250, rank: 1, level: 'Expert', 
          badge: 'Gold', village: 'Ludhiana Village', state: 'Punjab', 
          tasksCompleted: 45, streak: 12,
        ),
        LeaderboardEntry(
          userId: 'u2', name: 'Lakshmi Devi', points: 1180, rank: 2, level: 'Expert', 
          badge: 'Gold', village: 'Ludhiana Village', state: 'Punjab', 
          tasksCompleted: 42, streak: 8,
        ),
        LeaderboardEntry(
          userId: 'u3', name: 'Aman Singh', points: 1095, rank: 3, level: 'Advanced', 
          badge: 'Silver', village: 'Ludhiana Village', state: 'Punjab', 
          tasksCompleted: 38, streak: 15,
        ),
        LeaderboardEntry(
          userId: 'u4', name: 'Priya Sharma', points: 1020, rank: 4, level: 'Advanced', 
          badge: 'Silver', village: 'Ludhiana Village', state: 'Punjab', 
          tasksCompleted: 35, streak: 6,
        ),
        LeaderboardEntry(
          userId: 'u5', name: 'Rajesh Patel', points: 980, rank: 5, level: 'Intermediate', 
          badge: 'Bronze', village: 'Ludhiana Village', state: 'Punjab', 
          tasksCompleted: 32, streak: 4,
        ),
      ],
      'district': [
        LeaderboardEntry(
          userId: 'd1', name: 'Ravi Kumar', points: 1250, rank: 1, level: 'Expert', 
          badge: 'Gold', village: 'Ludhiana Village', state: 'Punjab', 
          tasksCompleted: 45, streak: 12,
        ),
        LeaderboardEntry(
          userId: 'd2', name: 'Lakshmi Devi', points: 1180, rank: 2, level: 'Expert', 
          badge: 'Gold', village: 'Ludhiana Village', state: 'Punjab', 
          tasksCompleted: 42, streak: 8,
        ),
        LeaderboardEntry(
          userId: 'd3', name: 'Aman Singh', points: 1095, rank: 3, level: 'Advanced', 
          badge: 'Silver', village: 'Ludhiana Village', state: 'Punjab', 
          tasksCompleted: 38, streak: 15,
        ),
      ],
      'state': [
        LeaderboardEntry(
          userId: 's1', name: 'Ravi Kumar', points: 1250, rank: 1, level: 'Expert', 
          badge: 'Gold', village: 'Ludhiana Village', state: 'Punjab', 
          tasksCompleted: 45, streak: 12,
        ),
        LeaderboardEntry(
          userId: 's2', name: 'Lakshmi Devi', points: 1180, rank: 2, level: 'Expert', 
          badge: 'Gold', village: 'Ludhiana Village', state: 'Punjab', 
          tasksCompleted: 42, streak: 8,
        ),
      ],
    };

    return mockData[scope] ?? mockData['village']!;
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
