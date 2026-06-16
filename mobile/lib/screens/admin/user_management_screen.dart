import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/loading_overlay.dart';
class _UserType {
  static const String farmer = 'farmer';
  static const String buyer = 'buyer';
  static const String admin = 'admin';
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'newest';
  String? _filterByRegion;

  final List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _adminService.getUsers(limit: 200);
      if (!mounted) return;
      setState(() {
        _users
          ..clear()
          ..addAll(users);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load users: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> get _filteredUsers {
    return _users.where((final user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!user.fullName.toLowerCase().contains(query) &&
            !user.email.toLowerCase().contains(query) &&
            !(user.phone?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Region filter
      if (_filterByRegion != null && user.region != _filterByRegion) {
        return false;
      }

      // Tab filter
      switch (_tabController.index) {
        case 1:
          return user.userType == _UserType.farmer;
        case 2:
          return user.userType == _UserType.buyer;
        case 3:
          return user.userType == _UserType.admin;
        default:
          return true;
      }
    }).toList()
      ..sort((final a, final b) {
        switch (_sortBy) {
          case 'newest':
            return b.createdAt.compareTo(a.createdAt);
          case 'oldest':
            return a.createdAt.compareTo(b.createdAt);
          case 'name':
            return a.fullName.compareTo(b.fullName);
          default:
            return 0;
        }
      });
  }

  @override
  Widget build(final BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.grey900,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.grey500,
            indicatorColor: AppColors.primaryGreen,
            onTap: (_) => setState(() {}),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Farmers'),
              Tab(text: 'Buyers'),
              Tab(text: 'Admins'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _showFilterSheet,
              icon: Badge(
                isLabelVisible: _filterByRegion != null,
                child: const Icon(Icons.filter_list),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search & Sort
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (final value) =>
                            setState(() => _searchQuery = value),
                        decoration: const InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.sort),
                      onSelected: (final value) => setState(() => _sortBy = value),
                      itemBuilder: (final context) => [
                        PopupMenuItem(
                          value: 'newest',
                          child: Row(
                            children: [
                              if (_sortBy == 'newest')
                                const Icon(Icons.check,
                                    size: 18, color: AppColors.primaryGreen),
                              if (_sortBy == 'newest') const SizedBox(width: 8),
                              const Text('Newest First'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'oldest',
                          child: Row(
                            children: [
                              if (_sortBy == 'oldest')
                                const Icon(Icons.check,
                                    size: 18, color: AppColors.primaryGreen),
                              if (_sortBy == 'oldest') const SizedBox(width: 8),
                              const Text('Oldest First'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'name',
                          child: Row(
                            children: [
                              if (_sortBy == 'name')
                                const Icon(Icons.check,
                                    size: 18, color: AppColors.primaryGreen),
                              if (_sortBy == 'name') const SizedBox(width: 8),
                              const Text('Name A-Z'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stats Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', _users.length.toString()),
                  Container(height: 30, width: 1, color: AppColors.grey300),
                  _buildStatItem(
                      'Farmers',
                      _users
                          .where((final u) => u.userType == _UserType.farmer)
                          .length
                          .toString()),
                  Container(height: 30, width: 1, color: AppColors.grey300),
                  _buildStatItem(
                      'Buyers',
                      _users
                          .where((final u) => u.userType == _UserType.buyer)
                          .length
                          .toString()),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // User List
            Expanded(
              child: _filteredUsers.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (final context, final index) {
                          return _buildUserCard(_filteredUsers[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(final String label, final String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(final UserModel user) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: user.userType == _UserType.farmer
                        ? AppColors.primaryGreen.withOpacity(0.1)
                        : AppColors.info.withOpacity(0.1),
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.fullName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: user.userType == _UserType.farmer
                                  ? AppColors.primaryGreen
                                  : AppColors.info,
                            ),
                          )
                        : null,
                  ),
                  if (user.isVerified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: AppColors.info,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: user.userType == _UserType.farmer
                                ? AppColors.primaryGreen.withOpacity(0.1)
                                : AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.userType == _UserType.farmer
                                ? 'Farmer'
                                : 'Buyer',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: user.userType == _UserType.farmer
                                  ? AppColors.primaryGreen
                                  : AppColors.info,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on,
                            size: 12, color: AppColors.grey500),
                        const SizedBox(width: 4),
                        Text(
                          user.region ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.grey600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dateFormat.format(user.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                onSelected: (final value) => _handleUserAction(user, value),
                itemBuilder: (final context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 18),
                        SizedBox(width: 12),
                        Text('View Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (!user.isVerified && user.userType == _UserType.farmer)
                    const PopupMenuItem(
                      value: 'verify',
                      child: Row(
                        children: [
                          Icon(Icons.verified, size: 18, color: AppColors.info),
                          SizedBox(width: 12),
                          Text('Verify'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'suspend',
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 18, color: AppColors.warning),
                        SizedBox(width: 12),
                        Text('Suspend / Unsuspend'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUserAction(final UserModel user, final String action) {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'verify':
        _verifyUser(user);
        break;
      case 'suspend':
        _suspendUser(user);
        break;
      case 'delete':
        _deleteUser(user);
        break;
    }
  }

  void _showUserDetails(final UserModel user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (final context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (final context, final scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                    child: Text(
                      user.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Center(
                  child: Text(
                    user.email,
                    style: const TextStyle(color: AppColors.grey600),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailItem('Phone', user.phone ?? 'Not provided'),
                _buildDetailItem('User Type',
                  user.userType == _UserType.farmer
                    ? 'Farmer'
                    : user.userType == _UserType.admin
                      ? 'Admin'
                      : 'Buyer'),
                _buildDetailItem('Region', user.region ?? 'Not provided'),
                _buildDetailItem('District', user.district ?? 'Not provided'),
                _buildDetailItem(
                    'Joined', DateFormat('MMMM dd, yyyy').format(user.createdAt)),
                _buildDetailItem('Status', user.isVerified ? 'Verified' : 'Pending'),
                _buildDetailItem('Rating', '${user.rating.toStringAsFixed(1)} ⭐'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _suspendUser(user);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                        ),
                        child: Text(user.isSuspended ? 'Unsuspend' : 'Suspend'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditUserDialog(user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                        ),
                        child: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(final String label, final String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.grey600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (final context) => StatefulBuilder(
        builder: (final context, final setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          _filterByRegion = null;
                        });
                        setState(() {});
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Region',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Central', 'Eastern', 'Northern', 'Western']
                      .map((final region) => ChoiceChip(
                            label: Text(region),
                            selected: _filterByRegion == region,
                            onSelected: (final selected) {
                              setSheetState(() {
                                _filterByRegion = selected ? region : null;
                              });
                              setState(() {});
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEditUserDialog(final UserModel user) async {
    var selectedRole = user.userType;
    var isVerified = user.isVerified;
    var isPremium = user.isPremium;
    var isSuspended = user.isSuspended;

    await showDialog<void>(
      context: context,
      builder: (final context) => StatefulBuilder(
        builder: (final context, final setModalState) => AlertDialog(
          title: Text('Edit ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'buyer', child: Text('Buyer')),
                  DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (final value) {
                  if (value != null) {
                    setModalState(() => selectedRole = value);
                  }
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Verified'),
                value: isVerified,
                onChanged: (final value) => setModalState(() => isVerified = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Premium'),
                value: isPremium,
                onChanged: (final value) => setModalState(() => isPremium = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Suspended'),
                value: isSuspended,
                onChanged: (final value) => setModalState(() => isSuspended = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  final updated = await _adminService.updateUser(
                    userId: user.id,
                    role: selectedRole,
                    isVerified: isVerified,
                    isPremium: isPremium,
                    isSuspended: isSuspended,
                  );

                  final index = _users.indexWhere((final u) => u.id == user.id);
                  if (index >= 0) {
                    _users[index] = updated;
                  }

                  if (!mounted) return;
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User updated successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: AppColors.error,
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyUser(final UserModel user) {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Verify User'),
        content: Text('Are you sure you want to verify ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _runVerification(user);
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _runVerification(
    final UserModel user, {
    final bool override = false,
    final String? overrideReason,
  }) async {
    setState(() => _isLoading = true);
    try {
      final updated = await _adminService.verifyFarmer(
        user.id,
        override: override,
        overrideReason: overrideReason,
      );
      final index = _users.indexWhere((final u) => u.id == user.id);
      if (index >= 0) {
        _users[index] = updated;
      }
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.fullName} has been verified'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (!mounted) return;
      if (!override && message.toLowerCase().contains('criteria')) {
        await _showOverrideDialog(user, message);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showOverrideDialog(final UserModel user, final String reason) async {
    final reasonController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Override Verification Criteria?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Override reason',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Override reason is required'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              await _runVerification(
                user,
                override: true,
                overrideReason: reasonController.text.trim(),
              );
            },
            child: const Text('Verify with Override'),
          ),
        ],
      ),
    );
    reasonController.dispose();
  }

  void _suspendUser(final UserModel user) {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: Text(user.isSuspended ? 'Unsuspend User' : 'Suspend User'),
        content: Text(
          user.isSuspended
              ? 'Are you sure you want to unsuspend ${user.fullName}?'
              : 'Are you sure you want to suspend ${user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                if (user.isSuspended) {
                  await _adminService.unsuspendUser(user.id);
                } else {
                  await _adminService.suspendUser(
                    user.id,
                    reason: 'Suspended by admin',
                  );
                }
                await _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      user.isSuspended
                          ? '${user.fullName} has been unsuspended'
                          : '${user.fullName} has been suspended',
                    ),
                    backgroundColor:
                        user.isSuspended ? AppColors.success : AppColors.warning,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: AppColors.error,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: Text(
              user.isSuspended ? 'Unsuspend' : 'Suspend',
              style: const TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteUser(final UserModel user) {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${user.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _adminService.deleteUser(user.id);
                _users.removeWhere((final u) => u.id == user.id);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${user.fullName} has been deleted'),
                    backgroundColor: AppColors.error,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: AppColors.error,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
