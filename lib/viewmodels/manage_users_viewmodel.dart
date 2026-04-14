import 'package:flutter/material.dart';
import 'package:badminton_ai/data/models/user_model.dart';

class ManageUsersViewModel extends ChangeNotifier {
  String _searchQuery = '';
  String _selectedRole = 'all'; // all, admin, court_owner, user

  String get searchQuery => _searchQuery;
  String get selectedRole => _selectedRole;

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void setSelectedRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  List<UserModel> applyFilters(List<UserModel> users) {
    return users.where((user) {
      // Role filter
      final matchesRole = _selectedRole == 'all' || user.role == _selectedRole;
      
      // Search filter
      final name = user.displayName?.toLowerCase() ?? '';
      final email = user.email?.toLowerCase() ?? '';
      final phone = user.phoneNumber?.toLowerCase() ?? '';
      final matchesSearch = _searchQuery.isEmpty || 
          name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          phone.contains(_searchQuery);

      return matchesRole && matchesSearch;
    }).toList();
  }
}
