class AdminUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String role;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.role,
    required this.isActive,
    required this.isEmailVerified,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'],
      role: json['role'] ?? 'USER',
      isActive: json['active'] ?? json['isActive'] ?? true,
      isEmailVerified: json['emailVerified'] ?? json['isEmailVerified'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumber': phoneNumber,
    'role': role,
    'isActive': isActive,
    'isEmailVerified': isEmailVerified,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

class AdminPaginatedUsers {
  final List<AdminUser> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  AdminPaginatedUsers({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory AdminPaginatedUsers.fromJson(Map<String, dynamic> json) {
    final list = (json['content'] as List<dynamic>?)
            ?.map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return AdminPaginatedUsers(
      content: list,
      page: json['page'] ?? 0,
      size: json['size'] ?? 10,
      totalElements: json['totalElements'] ?? list.length,
      totalPages: json['totalPages'] ?? 1,
      last: json['last'] ?? true,
    );
  }
}

class AdminUserHealthcareOverview {
  final String userId;
  final int familyMembersCount;
  final int activeMedicinesCount;
  final int upcomingAppointmentsCount;
  final int totalDocumentsCount;

  AdminUserHealthcareOverview({
    required this.userId,
    required this.familyMembersCount,
    required this.activeMedicinesCount,
    required this.upcomingAppointmentsCount,
    required this.totalDocumentsCount,
  });

  factory AdminUserHealthcareOverview.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    return AdminUserHealthcareOverview(
      userId: data['userId']?.toString() ?? '',
      familyMembersCount: (data['familyMembersCount'] as num?)?.toInt() ?? 0,
      activeMedicinesCount: (data['activeMedicinesCount'] as num?)?.toInt() ?? 0,
      upcomingAppointmentsCount: (data['upcomingAppointmentsCount'] as num?)?.toInt() ?? 0,
      totalDocumentsCount: (data['totalDocumentsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminCreateUserRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? phoneNumber;
  final String role;

  AdminCreateUserRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.role = 'USER',
  });

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'password': password,
    if (phoneNumber != null && phoneNumber!.isNotEmpty) 'phoneNumber': phoneNumber,
    'role': role,
  };
}
