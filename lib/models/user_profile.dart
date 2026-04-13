class UserProfile {
  final int birthYear;
  final String gender;
  final double weightKg;
  final List<String> medications;
  final List<String> conditions;
  final String dietPattern;
  final List<String> goals;
  final bool isPregnant;

  int get age => DateTime.now().year - birthYear;

  const UserProfile({
    required this.birthYear,
    required this.gender,
    required this.weightKg,
    this.medications = const [],
    this.conditions = const [],
    this.dietPattern = 'standard',
    this.goals = const [],
    this.isPregnant = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      birthYear: json['birthYear'] as int,
      gender: json['gender'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
      medications: (json['medications'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      conditions: (json['conditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dietPattern: json['dietPattern'] as String? ?? 'standard',
      goals: (json['goals'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isPregnant: json['isPregnant'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'birthYear': birthYear,
      'gender': gender,
      'weightKg': weightKg,
      'medications': medications,
      'conditions': conditions,
      'dietPattern': dietPattern,
      'goals': goals,
      'isPregnant': isPregnant,
    };
  }

  UserProfile copyWith({
    int? birthYear,
    String? gender,
    double? weightKg,
    List<String>? medications,
    List<String>? conditions,
    String? dietPattern,
    List<String>? goals,
    bool? isPregnant,
  }) {
    return UserProfile(
      birthYear: birthYear ?? this.birthYear,
      gender: gender ?? this.gender,
      weightKg: weightKg ?? this.weightKg,
      medications: medications ?? this.medications,
      conditions: conditions ?? this.conditions,
      dietPattern: dietPattern ?? this.dietPattern,
      goals: goals ?? this.goals,
      isPregnant: isPregnant ?? this.isPregnant,
    );
  }
}
