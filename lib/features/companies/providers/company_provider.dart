import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_service.dart';
import '../models/company.dart';

class CompanyProvider with ChangeNotifier {
  ApiService? _api;
  List<Company> _companies = [];
  List<String> _categories = [];
  
  String _searchQuery = '';
  String? _filterCategory;
  CompanyStatus? _filterStatus;
  String? _selectedCompanyId;
  bool _isLoading = false;

  CompanyProvider();

  // Method to update the API service (e.g., when token changes in AuthProvider)
  void update(ApiService api) {
    _api = api;
    if (_companies.isEmpty) {
      _loadFromStorage().then((_) => _startPeriodicSync());
    }
  }

  bool _isSyncing = false;

  void _startPeriodicSync() {
    syncWithDatabase();
    // 5 seconds — optimistic updates handle instant feel, this catches other clients' changes
    Future.delayed(const Duration(seconds: 5), () {
      if (_api != null) {
        _startPeriodicSync();
      }
    });
  }

  static const String _storageKey = 'ebm_app_company_registry_v3';

  bool get isLoading => _isLoading;

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final dynamic decoded = json.decode(jsonStr);
        if (decoded is! Map<String, dynamic>) throw const FormatException('Invalid JSON structure');
        
        _companies = (decoded['companies'] as List).map((m) => Company.fromMap(m)).toList();
        _categories = List<String>.from(decoded['categories'] ?? []);
        notifyListeners();
      } catch (e) {
        debugPrint('SharedPreferences corrupted: $e. Clearing cache.');
        await prefs.remove(_storageKey);
      }
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'companies': _companies.map((c) => c.toMap()).toList(),
      'categories': _categories,
    };
    await prefs.setString(_storageKey, json.encode(data));
  }

  // ── Sync with Backend ──────────────────────────
  
  void reload() => syncWithDatabase();

  Future<void> syncWithDatabase() async {
    if (_api == null || _isSyncing) return;
    _isSyncing = true;
    final isFirstLoad = _companies.isEmpty;
    if (isFirstLoad) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      // Fetch both in parallel for speed
      final results = await Future.wait([
        _api!.get('/companies'),
        _api!.get('/categories'),
      ]);
      final companyRes = results[0];
      final catRes = results[1];
      if (companyRes is List && catRes is List) {
        _companies = companyRes.map((m) => Company.fromMap(m)).toList();
        
        // ✅ Trust backend for visibility
        // Remove any existing 'all' (case-insensitive) to prevent duplicates before adding UI 'All'
        final serverCategories = catRes.map((c) => c['name'].toString()).toList();
        _categories = serverCategories.where((c) => c.toLowerCase() != 'all').toList();
        _categories.insert(0, 'All');
        
        // Ensure UI doesn't break if the selected category was deleted by admin
        if (_filterCategory != null && !_categories.contains(_filterCategory)) {
          _filterCategory = null;
        }
        
        _saveToStorage();
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    } finally {
      _isSyncing = false;
      if (_isLoading) _isLoading = false;
      notifyListeners();
    }
  }

  // Getters
  List<Company> get companies {
    return _companies.where((c) {
      if (c.status == CompanyStatus.archived) return false;
      final matchesSearch = c.name.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Category filter: if filtering by a category, show companies that belong to it
      // 'All' shows everything. Pending companies with no categories also pass through.
      final matchesCategory = _filterCategory == null || 
        _filterCategory == 'All' ||
        c.categories.any((cat) => cat.toLowerCase() == _filterCategory!.toLowerCase()) ||
        (c.status == CompanyStatus.pending && c.categories.isEmpty);
        
      final matchesStatus = _filterStatus == null || c.status == _filterStatus;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }
  
  List<Company> get archivedCompanies => _companies.where((c) => c.status == CompanyStatus.archived).toList();
  List<Company> get allCompanies => [..._companies];
  List<String> get categories => [..._categories];
  
  List<String> get allCategories => [..._categories];
  String? get filterCategory => _filterCategory;
  CompanyStatus? get filterStatus => _filterStatus;
  
  Company? get selectedCompany {
    if (_selectedCompanyId == null) return null;
    try {
      return _companies.firstWhere((c) => c.id == _selectedCompanyId);
    } catch (e) {
      return null;
    }
  }

  // Actions
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _filterCategory = category;
    notifyListeners();
  }

  void setStatusFilter(CompanyStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }
  
  Future<void> selectCompany(String? id) async {
    _selectedCompanyId = id;
    notifyListeners();
    
    // Sync with backend so global TenantScope knows which company is active
    if (_api != null && id != null) {
      try {
        await _api!.post('/companies/switch', {'company_id': id});
        debugPrint('✅ Switched to company context: $id');
      } catch (e) {
        debugPrint('❌ Failed to switch company context on backend: $e');
      }
    }
  }

  Future<void> manageCategory(String? oldName, String newName, List<String> assignedCompanyIds) async {
    if (_api == null) return;
    
    // 1. OPTIMISTIC UPDATE
    if (oldName != null && oldName != newName) {
      final index = _categories.indexOf(oldName);
      if (index != -1) _categories[index] = newName;
    } else if (oldName == null && !_categories.contains(newName)) {
      _categories.add(newName);
    }
    
    for (var i = 0; i < _companies.length; i++) {
      final company = _companies[i];
      final cats = List<String>.from(company.categories);
      bool changed = false;
      
      if (oldName != null) {
        if (cats.remove(oldName)) changed = true;
      }
      if (cats.remove(newName)) changed = true;
      
      if (assignedCompanyIds.contains(company.id)) {
        cats.add(newName);
        changed = true;
      }
      
      if (changed) {
        _companies[i] = company.copyWith(categories: cats.toSet().toList());
      }
    }
    
    _saveToStorage();
    notifyListeners();
    
    // 2. BACKGROUND API SYNC
    try {
      await _api!.post('/categories', {'name': newName});

      final futures = <Future>[];
      for (var company in _companies) {
         final isCurrentlyAssigned = company.categories.contains(oldName ?? newName);
         final shouldBeAssigned = assignedCompanyIds.contains(company.id);

         if (isCurrentlyAssigned != shouldBeAssigned || (oldName != null && isCurrentlyAssigned)) {
            final cats = List<String>.from(company.categories);
            if (oldName != null) cats.remove(oldName);
            cats.remove(newName);
            if (shouldBeAssigned) cats.add(newName);
            
            futures.add(_api!.put('/companies/${company.id}', {'categories': cats.toSet().toList()}));
         }
      }

      if (oldName != null && oldName != newName) {
         final oldId = oldName.toLowerCase().replaceAll(' ', '_');
         futures.add(_api!.delete('/categories/$oldId'));
      }

      await Future.wait(futures);
      await syncWithDatabase();
    } catch (e) {
      debugPrint('Manage Category Error: $e');
      await syncWithDatabase(); // Revert
    }
  }

  Future<void> deleteCategory(String category) async {
    if (_api == null) return;
    
    _categories.remove(category);
    if (_filterCategory == category) _filterCategory = null;
    
    for (var i = 0; i < _companies.length; i++) {
       final cats = List<String>.from(_companies[i].categories);
       if (cats.remove(category)) {
          _companies[i] = _companies[i].copyWith(categories: cats);
       }
    }
    
    _saveToStorage();
    notifyListeners();
    
    try {
      final catId = category.toLowerCase().replaceAll(' ', '_');
      final futures = <Future>[];
      futures.add(_api!.delete('/categories/$catId'));

      for (var company in _companies) {
         if (company.categories.contains(category)) {
            final cats = company.categories.where((cat) => cat != category).toList();
            futures.add(_api!.put('/companies/${company.id}', {'categories': cats}));
         }
      }
      
      await Future.wait(futures);
      await syncWithDatabase();
    } catch (e) {
      debugPrint('Delete Category Error: $e');
      await syncWithDatabase();
    }
  }

  Future<void> addCompany(Company company) async {
    if (_api == null) return;
    
    _isLoading = true;
    
    // Optimistic UI for Managers
    Company companyToSave = company;
    if (company.status == CompanyStatus.active) {
       companyToSave = company.copyWith(status: CompanyStatus.pending);
    }
    
    _companies.insert(0, companyToSave); // Add to top of list instantly
    notifyListeners();

    try {
      await _api!.post('/companies', companyToSave.toMap());
      await syncWithDatabase();
    } catch (e) {
      _companies.removeAt(0); // rollback
      debugPrint('Add Company Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCompany(Company company) async {
    if (_api == null) return;
    
    // ── OPTIMISTIC UPDATE ──
    // Update local state immediately for instant UI feedback
    final oldCompanies = List<Company>.from(_companies);
    final index = _companies.indexWhere((c) => c.id == company.id);
    if (index != -1) {
      _companies[index] = company;
      notifyListeners();
      _saveToStorage();
    }

    try {
      await _api!.put('/companies/${company.id}', company.toMap());
      // Re-sync to ensure server-side computed fields (like counts) are updated
      await syncWithDatabase();
    } catch (e) {
      debugPrint('Update Company Error: $e');
      // Rollback on failure
      _companies = oldCompanies;
      notifyListeners();
      _saveToStorage();
    }
  }

  void updateCompanyLogo(String id, String logoUrl) async {
    final company = _companies.firstWhere((c) => c.id == id);
    await updateCompany(company.copyWith(logoUrl: logoUrl));
  }

  void updateOnlinePlatforms(String id, List<Map<String, String>> platforms) async {
    final company = _companies.firstWhere((c) => c.id == id);
    await updateCompany(company.copyWith(onlinePlatforms: platforms));
  }

  Future<void> archiveCompany(String id) async {
    final company = _companies.firstWhere((c) => c.id == id);
    await updateCompany(company.copyWith(status: CompanyStatus.archived));
  }

  Future<void> restoreCompany(String id) async {
    final index = _companies.indexWhere((c) => c.id == id);
    if (index != -1) {
      await updateCompany(_companies[index].copyWith(status: CompanyStatus.active));
    }
  }

  Future<void> deleteCompany(String id) async {
    if (_api == null) return;
    
    // Optimistic removal — instantly disappears from UI
    final backup = List<Company>.from(_companies);
    _companies.removeWhere((c) => c.id == id);
    if (_filterCategory != null && _companies.isEmpty) _filterCategory = null;
    _saveToStorage();
    notifyListeners();
    
    try {
      await _api!.delete('/companies/$id');
      await syncWithDatabase(); // Confirm deletion with server
    } catch (e) {
      debugPrint('Delete Company Error: $e');
      _companies = backup; // Rollback if API fails
      notifyListeners();
    }
  }
}
