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
  final String password;
  RegisterRequest({required this.firstName, required this.lastName, required this.email, required this.password});
  Map<String, dynamic> toJson() => {'firstName': firstName, 'lastName': lastName, 'email': email, 'password': password};
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  AuthResponse({required this.accessToken, required this.refreshToken});
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['data']['accessToken'] ?? '',
      refreshToken: json['data']['refreshToken'] ?? '',
    );
  }
}
