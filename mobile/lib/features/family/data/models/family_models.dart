class FamilyMemberModel {
  final String id;
  final String name;
  final String relationship;

  FamilyMemberModel({
    required this.id,
    required this.name,
    required this.relationship,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id'],
      name: json['name'],
      relationship: json['relationship'],
    );
  }
}
