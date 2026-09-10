class FamilyMemberModel {
  final String id;
  final String name;
  final String relationship;
  final String? dateOfBirth;

  FamilyMemberModel({
    required this.id,
    required this.name,
    required this.relationship,
    this.dateOfBirth,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? 'Family Member',
      dateOfBirth: json['dateOfBirth'],
    );
  }
}
