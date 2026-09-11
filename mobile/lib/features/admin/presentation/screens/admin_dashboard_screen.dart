import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/features/admin/data/models/admin_models.dart';
import 'package:caresync/features/admin/presentation/providers/admin_provider.dart';
import 'package:caresync/features/admin/presentation/widgets/admin_create_user_dialog.dart';
import 'package:caresync/features/admin/presentation/widgets/admin_user_detail_dialog.dart';
import 'package:caresync/features/auth/presentation/providers/auth_provider.dart';
import 'package:caresync/shared/widgets/app_logo.dart';
import 'package:caresync/shared/widgets/pwa_install_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).fetchUsers(page: 0);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => const AdminCreateUserDialog(),
    );
  }

  void _showUserDetailDialog(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AdminUserDetailDialog(user: user),
    );
  }

  Future<void> _confirmRoleChange(AdminUser user) async {
    final newRole = user.isAdmin ? 'USER' : 'ADMIN';
    final actionName = user.isAdmin ? 'demote' : 'promote';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Role Change'),
        content: Text(
          'Are you sure you want to $actionName ${user.fullName} to $newRole?\n\n'
          '${user.isAdmin ? "They will lose administrative access immediately." : "They will receive administrative access immediately."}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isAdmin ? AppColors.warning : Colors.purple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(user.isAdmin ? 'Demote to USER' : 'Promote to ADMIN'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final (success, error) =
          await ref.read(adminProvider.notifier).updateUserRole(user.id, newRole);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated ${user.fullName}\'s role to $newRole'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to update role'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmStatusChange(AdminUser user) async {
    final nextStatus = !user.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${nextStatus ? "Reactivate" : "Deactivate"} User'),
        content: Text(
          nextStatus
              ? 'Reactivating ${user.fullName} will restore their login access and preserve all healthcare records.'
              : 'Deactivating ${user.fullName} will immediately revoke login access. All their healthcare records will remain safely preserved (soft delete).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: nextStatus ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(nextStatus ? 'Reactivate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final (success, error) =
          await ref.read(adminProvider.notifier).updateUserStatus(user.id, nextStatus);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account ${user.fullName} is now ${nextStatus ? "active" : "deactivated"}'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to update user status'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final currentUserId = authState.user?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const AppLogo(size: 28),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          const PwaInstallButton(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Admin Center',
            onPressed: () => ref.read(adminProvider.notifier).fetchUsers(page: state.page),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(adminProvider.notifier).fetchUsers(page: state.page),
          child: CustomScrollView(
            slivers: [
              // Top Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 600;

                          final titleContent = Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.admin_panel_settings, color: Colors.purple, size: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          'CareSync Admin Center',
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                          ),
                                          child: const Text(
                                            'ADMIN ACCESS',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Manage user accounts, credentials, administrative roles, and system health.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );

                          final addUserBtn = SizedBox(
                            width: isWide ? null : double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showCreateUserDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add User', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 42),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          );

                          if (isWide) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: titleContent),
                                const SizedBox(width: 16),
                                addUserBtn,
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              titleContent,
                              const SizedBox(height: 14),
                              addUserBtn,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Metrics Cards
                      _buildMetricsRow(state, isDesktop),
                      const SizedBox(height: 24),

                      // Filter and Search Toolbar
                      _buildFilterToolbar(state),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Users Content
              if (state.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Loading user directory...'),
                      ],
                    ),
                  ),
                )
              else if (state.error != null && state.users.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          state.error!,
                          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(adminProvider.notifier).fetchUsers(page: 0),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (state.filteredUsers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.searchQuery.isNotEmpty
                                ? 'No user matches "${state.searchQuery}". Try a different search.'
                                : 'No users match the selected filters.',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: isDesktop
                      ? SliverToBoxAdapter(
                          child: _buildDesktopUserTable(state.filteredUsers, currentUserId),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final user = state.filteredUsers[index];
                              return _buildMobileUserCard(user, currentUserId);
                            },
                            childCount: state.filteredUsers.length,
                          ),
                        ),
                ),

              // Pagination Footer
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildPaginationFooter(state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow(AdminState state, bool isDesktop) {
    final metrics = [
      _MetricData(
        title: 'Total Users',
        value: state.totalCount.toString(),
        icon: Icons.people_alt_outlined,
        color: AppColors.primary,
        bgColor: const Color(0xFFEFF6FF),
      ),
      _MetricData(
        title: 'Active Accounts',
        value: state.activeCount.toString(),
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        bgColor: const Color(0xFFF0FDF4),
      ),
      _MetricData(
        title: 'Deactivated',
        value: state.inactiveCount.toString(),
        icon: Icons.block_outlined,
        color: AppColors.error,
        bgColor: const Color(0xFFFEF2F2),
      ),
      _MetricData(
        title: 'Administrators',
        value: state.adminCount.toString(),
        icon: Icons.shield_outlined,
        color: Colors.purple,
        bgColor: const Color(0xFFFAF5FF),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: metrics
            .map(
              (m) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildMetricCard(m),
                ),
              ),
            )
            .toList(),
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics
                .map(
                  (m) => SizedBox(
                    width: halfWidth,
                    child: _buildMetricCard(m),
                  ),
                )
                .toList(),
          );
        },
      );
    }
  }

  Widget _buildMetricCard(_MetricData m) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: m.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(m.icon, color: m.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  m.title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(AdminState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(adminProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                  onChanged: (val) {
                    ref.read(adminProvider.notifier).setSearchQuery(val);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: IconButton(
                  tooltip: 'Refresh list',
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF475569)),
                  onPressed: () => ref.read(adminProvider.notifier).fetchUsers(page: state.page),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Role:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              _buildChoiceChip('All Roles', 'ALL', state.roleFilter, (val) {
                ref.read(adminProvider.notifier).setRoleFilter(val);
              }),
              _buildChoiceChip('Admins', 'ADMIN', state.roleFilter, (val) {
                ref.read(adminProvider.notifier).setRoleFilter(val);
              }),
              _buildChoiceChip('Users', 'USER', state.roleFilter, (val) {
                ref.read(adminProvider.notifier).setRoleFilter(val);
              }),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Status:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              _buildChoiceChip('All', 'ALL', state.statusFilter, (val) {
                ref.read(adminProvider.notifier).setStatusFilter(val);
              }),
              _buildChoiceChip('Active', 'ACTIVE', state.statusFilter, (val) {
                ref.read(adminProvider.notifier).setStatusFilter(val);
              }),
              _buildChoiceChip('Deactivated', 'INACTIVE', state.statusFilter, (val) {
                ref.read(adminProvider.notifier).setStatusFilter(val);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(
    String label,
    String value,
    String currentValue,
    ValueChanged<String> onSelected,
  ) {
    final selected = currentValue == value;
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopUserTable(List<AdminUser> users, String? currentUserId) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Joined', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: users.map((user) {
            final isSelf = user.id == currentUserId;
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: user.isAdmin
                            ? Colors.purple.withOpacity(0.15)
                            : AppColors.primaryLight.withOpacity(0.2),
                        child: Text(
                          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: user.isAdmin ? Colors.purple : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      ),
                      if (isSelf) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () => _showUserDetailDialog(user),
                ),
                DataCell(Text(user.email, style: const TextStyle(color: AppColors.textSecondary))),
                DataCell(_buildRoleBadge(user.role)),
                DataCell(_buildStatusBadge(user.isActive)),
                DataCell(
                  Text(
                    user.createdAt != null ? dateFormat.format(user.createdAt!) : '—',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'View Details & Healthcare Overview',
                        icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.primary),
                        onPressed: () => _showUserDetailDialog(user),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Account Actions',
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (action) {
                          if (action == 'toggle_role') {
                            _confirmRoleChange(user);
                          } else if (action == 'toggle_status') {
                            _confirmStatusChange(user);
                          } else if (action == 'details') {
                            _showUserDetailDialog(user);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'details',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 18),
                                SizedBox(width: 8),
                                Text('User Overview'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle_role',
                            child: Row(
                              children: [
                                Icon(
                                  user.isAdmin ? Icons.person : Icons.shield_outlined,
                                  size: 18,
                                  color: user.isAdmin ? AppColors.warning : Colors.purple,
                                ),
                                const SizedBox(width: 8),
                                Text(user.isAdmin ? 'Demote to USER' : 'Promote to ADMIN'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle_status',
                            child: Row(
                              children: [
                                Icon(
                                  user.isActive ? Icons.block : Icons.check_circle,
                                  size: 18,
                                  color: user.isActive ? AppColors.error : AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                Text(user.isActive ? 'Deactivate Account' : 'Reactivate Account'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileUserCard(AdminUser user, String? currentUserId) {
    final isSelf = user.id == currentUserId;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: user.isAdmin
                      ? Colors.purple.withOpacity(0.15)
                      : AppColors.primaryLight.withOpacity(0.2),
                  child: Text(
                    user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: user.isAdmin ? Colors.purple : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    if (action == 'details') {
                      _showUserDetailDialog(user);
                    } else if (action == 'toggle_role') {
                      _confirmRoleChange(user);
                    } else if (action == 'toggle_status') {
                      _confirmStatusChange(user);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Overview'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_role',
                      child: Row(
                        children: [
                          Icon(
                            user.isAdmin ? Icons.person : Icons.shield_outlined,
                            size: 18,
                            color: user.isAdmin ? AppColors.warning : Colors.purple,
                          ),
                          const SizedBox(width: 8),
                          Text(user.isAdmin ? 'Demote to USER' : 'Promote to ADMIN'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            user.isActive ? Icons.block : Icons.check_circle,
                            size: 18,
                            color: user.isActive ? AppColors.error : AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(user.isActive ? 'Deactivate' : 'Reactivate'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildRoleBadge(user.role),
                const SizedBox(width: 8),
                _buildStatusBadge(user.isActive),
                const Spacer(),
                if (user.createdAt != null)
                  Text(
                    'Joined ${dateFormat.format(user.createdAt!)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final isAdmin = role.toUpperCase() == 'ADMIN';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.purple.withOpacity(0.12) : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin ? Colors.purple.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isAdmin ? Colors.purple : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'DEACTIVATED',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(AdminState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${state.filteredUsers.length} of ${state.totalElements} users',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: state.page > 0
                  ? () => ref.read(adminProvider.notifier).fetchUsers(page: state.page - 1)
                  : null,
              child: const Text('Previous'),
            ),
            const SizedBox(width: 8),
            Text(
              'Page ${state.page + 1} of ${state.totalPages.clamp(1, 9999)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: (state.page + 1) < state.totalPages
                  ? () => ref.read(adminProvider.notifier).fetchUsers(page: state.page + 1)
                  : null,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
