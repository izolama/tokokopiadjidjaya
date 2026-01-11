class CoffeeProfile {
  const CoffeeProfile({
    required this.tastePreference,
    required this.drinkTime,
    required this.brewStyle,
    required this.purpose,
    required this.personaLabel,
  });

  final String tastePreference;
  final String drinkTime;
  final String brewStyle;
  final String purpose;
  final String personaLabel;

  Map<String, dynamic> toMap() {
    return {
      'tastePreference': tastePreference,
      'drinkTime': drinkTime,
      'brewStyle': brewStyle,
      'purpose': purpose,
      'personaLabel': personaLabel,
    };
  }

  factory CoffeeProfile.fromMap(Map<String, dynamic> data) {
    return CoffeeProfile(
      tastePreference: data['tastePreference'] as String? ?? 'balanced',
      drinkTime: data['drinkTime'] as String? ?? 'morning',
      brewStyle: data['brewStyle'] as String? ?? 'manual',
      purpose: data['purpose'] as String? ?? 'relax',
      personaLabel: data['personaLabel'] as String? ?? 'Balanced Explorer',
    );
  }
}
