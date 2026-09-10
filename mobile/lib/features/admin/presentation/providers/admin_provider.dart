import 'package:caresync/core/network/dio_client.dart';
import 'package:caresync/features/admin/data/models/admin_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminState {
  final bool isLoading;
  final bool isActionLoading;
  final List<AdminUser> users;
  final int page;
  final int totalPages;
  final int totalElements;
  final String searchQuery;
  final String roleFilter; // 'ALL', 'ADMIN', 'USER'
  final String statusFilter; // 'ALL', 'ACTIVE', 'INACTIVE'
  final String? error;
  final Map<String, AdminUserHealthcareOverview> healthcareOverviews;
  final bool isOverviewLoading;

  const AdminState({
    this.isLoading = false,
    this.isActionLoading = false,
    this.users = const [],
    this.page = 0,
    this.totalPages = 1,
    this.totalElements = 0,
    this.searchQuery = '',
    this.roleFilter = 'ALL',
    this.statusFilter = 'ALL',
    this.error,
    this.healthcareOverviews = const {},
    this.isOverviewLoading = false,
  });

  int get totalCount => totalElements;
  int get activeCount => users.where((u) => u.isActive).length;
  int get inactiveCount => users.where((u) => !u.isActive).length;
  int get adminCount => users.where((u) => u.isAdmin).length;

  List<AdminUser> get filteredUsers {
    return users.where((u) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchName = u.fullName.toLowerCase().contains(q);
        final matchEmail = u.email.toLowerCase().contains(q);
        if (!matchName && !matchEmail) return false;
      }
      if (roleFilter != 'ALL' && u.role.toUpperCase() != roleFilter) {
        return false;
      }
      if (statusFilter == 'ACTIVE' && !u.isActive) return false;
      if (statusFilter == 'INACTIVE' && u.isActive) return false;
      return true;
    }).toList();
  }

  AdminState copyWith({
    bool? isLoading,
    bool? isActionLoading,
    List<AdminUser>? users,
    int? page,
    int? totalPages,
    int? totalElements,
    String? searchQuery,
    String? roleFilter,
    String? statusFilter,
    String? error,
    bool clearError = false,
    Map<String, AdminUserHealthcareOverview>? healthcareOverviews,
    bool? isOverviewLoading,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      users: users ?? this.users,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: roleFilter ?? this.roleFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      error: clearError ? null : (error ?? this.error),
      healthcareOverviews: healthcareOverviews ?? this.healthcareOverviews,
      isOverviewLoading: isOverviewLoading ?? this.isOverviewLoading,
    );
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(ref);
});

class AdminNotifier extends StateNotifier<AdminState> {
  final Ref ref;

  AdminNotifier(this.ref) : super(const AdminState());

  Future<void> fetchUsers({int page = 0}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/v1/admin/users', queryParameters: {
        'page': page,
        'size': 20,
      });

      final data = response.data['data'] as Map<String, dynamic>;
      final paginated = AdminPaginatedUsers.fromJson(data);

      state = state.copyWith(
        isLoading: false,
        users: paginated.content,
        page: paginated.page,
        totalPages: paginated.totalPages,
        totalElements: paginated.totalElements,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setRoleFilter(String role) {
    state = state.copyWith(roleFilter: role);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  Future<(bool, String?)> createUser(AdminCreateUserRequest request) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/v1/admin/users', data: request.toJson());
      await fetchUsers(page: state.page);
      state = state.copyWith(isActionLoading: false);
      return (true, null);
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isActionLoading: false, error: msg);
      return (false, msg);
    }
  }

  Future<(bool, String?)> updateUserRole(String userId, String newRole) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      final dio = ref.read(dioProvider);
      await dio.patch(
        '/v1/admin/users/$userId/role',
        data: {'role': newRole.toUpperCase()},
      );
      await fetchUsers(page: state.page);
      state = state.copyWith(isActionLoading: false);
      return (true, null);
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isActionLoading: false, error: msg);
      return (false, msg);
    }
  }

  Future<(bool, String?)> updateUserStatus(String userId, bool isActive) async {
    state = state.copyWith(isActionLoading: true, clearError: true);
    try {
      final dio = ref.read(dioProvider);
      await dio.patch(
        '/v1/admin/users/$userId/status',
        data: {'isActive': isActive},
      );
      await fetchUsers(page: state.page);
      state = state.copyWith(isActionLoading: false);
      return (true, null);
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isActionLoading: false, error: msg);
      return (false, msg);
    }
  }

  Future<AdminUserHealthcareOverview?> fetchHealthcareOverview(String userId) async {
    state = state.copyWith(isOverviewLoading: true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/v1/admin/users/$userId/healthcare-overview');
      final overview = AdminUserHealthcareOverview.fromJson(response.data);
      
      final updated = Map<String, AdminUserHealthcareOverview>.from(state.healthcareOverviews);
      updated[userId] = overview;
      state = state.copyWith(
        isOverviewLoading: false,
        healthcareOverviews: updated,
      );
      return overview;
    } catch (e) {
      state = state.copyWith(isOverviewLoading: false);
      return null;
    }
  }

  String _extractError(Object e) {
    if (e is DioException) {
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('message') && data['message'] != null) {
          return data['message'].toString();
        }
      }
      if (e.response?.statusCode == 403) {
        return 'Access forbidden. Admin privileges required.';
      }
      return e.message ?? 'A network error occurred';
    }
    return e.toString();
  }
}
