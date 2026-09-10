class PublicUserName {
  final String displayName;

  const PublicUserName({required this.displayName});

  factory PublicUserName.fromJson(Map<String, dynamic> json) {
    return PublicUserName(
      displayName: json['displayName'] as String? ?? '',
    );
  }
}
