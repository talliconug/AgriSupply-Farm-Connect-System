import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

enum UsersStatus {
  initial,
  loading,
  loaded,
  error,
}

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  UsersStatus _status = UsersStatus.initial;
  List<UserModel> _users = [];
  List<UserModel> _farmers = [];
  List<UserModel> _buyers = [];
  UserModel? _selectedUser;
  String? _errorMessage;
  bool _isLoading = false;

  // Filters
  String? _selectedRole;
  String? _selectedRegion;
  bool? _verifiedOnly;
  String _searchQuery = '';

  // Statistics
  int _totalUsers = 0;
  int _totalFarmers = 0;
  int _totalBuyers = 0;
  int _totalAdmins = 0;
  int _verifiedUsers = 0;

  // Getters
  UsersStatus get status => _status;
  List<UserModel> get users => _filterUsers(_users);
  List<UserModel> get farmers => _farmers;
  List<UserModel> get buyers => _buyers;
  UserModel? get selectedUser => _selectedUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String? get selectedRole => _selectedRole;
  String? get selectedRegion => _selectedRegion;
  bool? get verifiedOnly => _verifiedOnly;
  String get searchQuery => _searchQuery;

  int get totalUsers => _totalUsers;
  int get totalFarmers => _totalFarmers;
  int get totalBuyers => _totalBuyers;
  int get totalAdmins => _totalAdmins;
  int get verifiedUsers => _verifiedUsers;

  // Fetch all users (admin)
  Future<void> fetchAllUsers() async {
    _status = UsersStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _userService.getAllUsers();
      _calculateStats();
      _status = UsersStatus.loaded;
    } catch (e) {
      _status = UsersStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  // Fetch farmers
  Future<void> fetchFarmers({final String? region}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _farmers = await _userService.getFarmers(region: region);
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }

    notifyListeners();
  }

  // Fetch buyers
  Future<void> fetchBuyers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _buyers = await _userService.getBuyers();
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }

    notifyListeners();
  }

  // Get user by ID
  Future<void> fetchUserById(final String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedUser = await _userService.getUserById(userId);
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }

    notifyListeners();
  }

  // Search users
  Future<void> searchUsers(final String query) async {
    _searchQuery = query;
    
    if (query.isEmpty) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _userService.searchUsers(query);
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }

    notifyListeners();
  }

  // Verify user (admin)
  Future<bool> verifyUser(final String userId) async {
    _errorMessage = null;

    try {
      await _userService.verifyUser(userId);

      final index = _users.indexWhere((final u) => u.id == userId);
      if (index >= 0) {
        _users[index] = _users[index].copyWith(isVerified: true);
      }

      if (_selectedUser?.id == userId) {
        _selectedUser = _selectedUser!.copyWith(isVerified: true);
      }

      _verifiedUsers = _users.where((final u) => u.isVerified).length;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Suspend user (admin)
  Future<bool> suspendUser(final String userId, {final String? reason}) async {
    _errorMessage = null;

    try {
      await _userService.suspendUser(userId, reason: reason);

      final index = _users.indexWhere((final u) => u.id == userId);
      if (index >= 0) {
        _users[index] = _users[index].copyWith(isSuspended: true);
      }

      if (_selectedUser?.id == userId) {
        _selectedUser = _selectedUser!.copyWith(isSuspended: true);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Unsuspend user (admin)
  Future<bool> unsuspendUser(final String userId) async {
    _errorMessage = null;

    try {
      await _userService.unsuspendUser(userId);

      final index = _users.indexWhere((final u) => u.id == userId);
      if (index >= 0) {
        _users[index] = _users[index].copyWith(isSuspended: false);
      }

      if (_selectedUser?.id == userId) {
        _selectedUser = _selectedUser!.copyWith(isSuspended: false);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete user (admin)
  Future<bool> deleteUser(final String userId) async {
    _errorMessage = null;

    try {
      await _userService.deleteUser(userId);

      _users.removeWhere((final u) => u.id == userId);
      _farmers.removeWhere((final u) => u.id == userId);
      _buyers.removeWhere((final u) => u.id == userId);

      if (_selectedUser?.id == userId) {
        _selectedUser = null;
      }

      _calculateStats();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update user role (admin)
  Future<bool> updateUserRole(final String userId, final String newRole) async {
    _errorMessage = null;

    try {
      await _userService.updateUserRole(userId, newRole);

      final index = _users.indexWhere((final u) => u.id == userId);
      if (index >= 0) {
        _users[index] = _users[index].copyWith(userType: newRole);
      }

      if (_selectedUser?.id == userId) {
        _selectedUser = _selectedUser!.copyWith(userType: newRole);
      }

      _calculateStats();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Filter users based on current filters
  List<UserModel> _filterUsers(final List<UserModel> users) {
    var filtered = users;

    // Filter by role
    if (_selectedRole != null) {
      filtered = filtered.where((final u) => u.role == _selectedRole).toList();
    }

    // Filter by region
    if (_selectedRegion != null && _selectedRegion!.isNotEmpty) {
      filtered = filtered.where((final u) => u.region == _selectedRegion).toList();
    }

    // Filter by verified status
    if (_verifiedOnly ?? false) {
      filtered = filtered.where((final u) => u.isVerified).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((final u) {
        return u.fullName.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            (u.phone?.toLowerCase().contains(query) ?? false) ||
            (u.farmName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  // Set filters
  void setRoleFilter(final String? role) {
    _selectedRole = role;
    notifyListeners();
  }

  void setRegionFilter(final String? region) {
    _selectedRegion = region;
    notifyListeners();
  }

  void setVerifiedFilter(final bool? verified) {
    _verifiedOnly = verified;
    notifyListeners();
  }

  void setSearchQuery(final String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedRole = null;
    _selectedRegion = null;
    _verifiedOnly = null;
    _searchQuery = '';
    notifyListeners();
  }

  void _calculateStats() {
    _totalUsers = _users.length;
    _totalFarmers = _users.where((final u) => u.role == UserRole.farmer).length;
    _totalBuyers = _users.where((final u) => u.role == UserRole.buyer).length;
    _totalAdmins = _users.where((final u) => u.role == UserRole.admin).length;
    _verifiedUsers = _users.where((final u) => u.isVerified).length;
  }

  void setSelectedUser(final UserModel? user) {
    _selectedUser = user;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get users by role
  List<UserModel> getUsersByRole(final String role) {
    return _users.where((final u) => u.role == role).toList();
  }

  // Get user statistics by region
  Map<String, int> getUsersByRegion() {
    final regionCounts = <String, int>{};
    
    for (final user in _users) {
      if (user.region != null) {
        regionCounts[user.region!] = (regionCounts[user.region!] ?? 0) + 1;
      }
    }
    
    return regionCounts;
  }
}
