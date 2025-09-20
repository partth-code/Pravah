class WeatherData {
  final double lat;
  final double lng;
  final WeatherCurrent current;
  final List<WeatherForecast> forecast;

  WeatherData({
    required this.lat,
    required this.lng,
    required this.current,
    required this.forecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      current: WeatherCurrent.fromJson(json['current'] ?? {}),
      forecast: (json['forecast'] as List?)
          ?.map((e) => WeatherForecast.fromJson(e))
          .toList() ?? [],
    );
  }
}

class WeatherCurrent {
  final double tempC;
  final String condition;
  final String advice;

  WeatherCurrent({
    required this.tempC,
    required this.condition,
    required this.advice,
  });

  factory WeatherCurrent.fromJson(Map<String, dynamic> json) {
    return WeatherCurrent(
      tempC: (json['tempC'] ?? 0.0).toDouble(),
      condition: json['condition'] ?? '',
      advice: json['advice'] ?? '',
    );
  }
}

class WeatherForecast {
  final String day;
  final double tempC;
  final String condition;

  WeatherForecast({
    required this.day,
    required this.tempC,
    required this.condition,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      day: json['day'] ?? '',
      tempC: (json['tempC'] ?? 0.0).toDouble(),
      condition: json['condition'] ?? '',
    );
  }
}

class Policy {
  final String policyId;
  final String title;
  final String description;
  final String eligibility;
  final List<String> requiredDocs;
  final List<String> states;
  final List<String> tags;
  final String? applicationDeadline;
  final String? benefits;
  final String? contactInfo;
  final String? website;
  final String? status;

  Policy({
    required this.policyId,
    required this.title,
    required this.description,
    required this.eligibility,
    required this.requiredDocs,
    required this.states,
    required this.tags,
    this.applicationDeadline,
    this.benefits,
    this.contactInfo,
    this.website,
    this.status,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      policyId: json['policyId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      eligibility: json['eligibility']?.toString() ?? '',
      requiredDocs: (json['requiredDocs'] as List?)?.map((e) => e.toString()).toList() ?? [],
      states: (json['states'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      applicationDeadline: json['applicationDeadline']?.toString(),
      benefits: json['benefits']?.toString(),
      contactInfo: json['contactInfo']?.toString(),
      website: json['website']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class Task {
  final String taskId;
  final String farmId;
  final DateTime date;
  final String title;
  final String status;
  final int points;
  final String priority;

  Task({
    required this.taskId,
    required this.farmId,
    required this.date,
    required this.title,
    required this.status,
    required this.points,
    required this.priority,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['taskId'] ?? '',
      farmId: json['farmId'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      title: json['title'] ?? '',
      status: json['status'] ?? 'pending',
      points: json['points'] ?? 0,
      priority: json['priority'] ?? 'medium',
    );
  }
}

class DiseaseDetection {
  final List<DiseaseLabel> labels;
  final List<DiseaseRemedy> remedies;

  DiseaseDetection({
    required this.labels,
    required this.remedies,
  });

  factory DiseaseDetection.fromJson(Map<String, dynamic> json) {
    try {
      return DiseaseDetection(
        labels: (json['labels'] as List?)
            ?.map((e) => DiseaseLabel.fromJson(e as Map<String, dynamic>))
            .toList() ?? [],
        remedies: (json['remedies'] as List?)
            ?.map((e) => DiseaseRemedy.fromJson(e as Map<String, dynamic>))
            .toList() ?? [],
      );
    } catch (e) {
      print('Error parsing DiseaseDetection from JSON: $e');
      return DiseaseDetection(labels: [], remedies: []);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'labels': labels.map((e) => e.toJson()).toList(),
      'remedies': remedies.map((e) => e.toJson()).toList(),
    };
  }
}

class DiseaseLabel {
  final String tag;
  final double confidence;

  DiseaseLabel({
    required this.tag,
    required this.confidence,
  });

  factory DiseaseLabel.fromJson(Map<String, dynamic> json) {
    try {
      return DiseaseLabel(
        tag: json['tag']?.toString() ?? '',
        confidence: double.tryParse(json['confidence']?.toString() ?? '0.0') ?? 0.0,
      );
    } catch (e) {
      print('Error parsing DiseaseLabel from JSON: $e');
      return DiseaseLabel(tag: 'unknown', confidence: 0.0);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'confidence': confidence,
    };
  }
}

class DiseaseRemedy {
  final String type;
  final List<String> steps;
  final String dosage;

  DiseaseRemedy({
    required this.type,
    required this.steps,
    required this.dosage,
  });

  factory DiseaseRemedy.fromJson(Map<String, dynamic> json) {
    try {
      return DiseaseRemedy(
        type: json['type']?.toString() ?? '',
        steps: (json['steps'] as List?)?.map((e) => e.toString()).toList() ?? [],
        dosage: json['dosage']?.toString() ?? '',
      );
    } catch (e) {
      print('Error parsing DiseaseRemedy from JSON: $e');
      return DiseaseRemedy(type: 'unknown', steps: [], dosage: '');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'steps': steps,
      'dosage': dosage,
    };
  }
}

class LeaderboardEntry {
  final String userId;
  final String name;
  final int points;
  final int rank;
  final String level;
  final String badge;
  final String village;
  final String state;
  final int tasksCompleted;
  final int streak;

  LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.points,
    required this.rank,
    required this.level,
    required this.badge,
    required this.village,
    required this.state,
    required this.tasksCompleted,
    required this.streak,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      points: json['points'] ?? 0,
      rank: json['rank'] ?? 0,
      level: json['level'] ?? '',
      badge: json['badge'] ?? '',
      village: json['village'] ?? '',
      state: json['state'] ?? '',
      tasksCompleted: json['tasksCompleted'] ?? 0,
      streak: json['streak'] ?? 0,
    );
  }
}

class UserProfile {
  final String userId;
  final String name;
  final String phone;
  final String language;
  final String farmProfileId;
  final String aadhaarHash;
  final String uniqueFarmId;
  final String uniqueFarmerId;

  UserProfile({
    required this.userId,
    required this.name,
    required this.phone,
    required this.language,
    required this.farmProfileId,
    required this.aadhaarHash,
    required this.uniqueFarmId,
    required this.uniqueFarmerId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      language: json['language'] ?? 'en',
      farmProfileId: json['farmProfileId'] ?? '',
      aadhaarHash: json['aadhaarHash'] ?? '',
      uniqueFarmId: json['uniqueFarmId'] ?? '',
      uniqueFarmerId: json['uniqueFarmerId'] ?? '',
    );
  }
}

class FarmProfile {
  final String farmId;
  final String userId;
  final String state;
  final String district;
  final double lat;
  final double lng;
  final String soilType;
  final double area;
  final String waterLevel;
  final String primaryCrop;

  FarmProfile({
    required this.farmId,
    required this.userId,
    required this.state,
    required this.district,
    required this.lat,
    required this.lng,
    required this.soilType,
    required this.area,
    required this.waterLevel,
    required this.primaryCrop,
  });

  factory FarmProfile.fromJson(Map<String, dynamic> json) {
    return FarmProfile(
      farmId: json['farmId'] ?? '',
      userId: json['userId'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      soilType: json['soilType'] ?? '',
      area: (json['area'] ?? 0.0).toDouble(),
      waterLevel: json['waterLevel'] ?? '',
      primaryCrop: json['primaryCrop'] ?? '',
    );
  }
}
