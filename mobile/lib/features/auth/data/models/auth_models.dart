class LoginRequest {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String? username;
  final String password;
  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.username,
    required this.password,
  });
  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    if (username != null && username!.isNotEmpty) 'username': username,
    'password': password,
  };
}

class UserModel {
  final String id;
  final String email;
  final String? username;
  final String firstName;
  final String lastName;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.isActive = true,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      username: json['username'],
      firstName: json['firstName'] ?? json['first_name'] ?? '',
      lastName: json['lastName'] ?? json['last_name'] ?? '',
      role: json['role'] ?? 'USER',
      isActive: json['active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    if (username != null) 'username': username,
    'firstName': firstName,
    'lastName': lastName,
    'role': role,
    'isActive': isActive,
  };
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel? user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    return AuthResponse(
      accessToken: data['accessToken'] ?? '',
      refreshToken: data['refreshToken'] ?? '',
      user: data['user'] != null ? UserModel.fromJson(data['user']) : null,
    );
  }
}
