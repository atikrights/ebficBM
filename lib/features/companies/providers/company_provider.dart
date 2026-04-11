import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ebficbm/features/companies/models/company.dart';

class CompanyProvider with ChangeNotifier {
  List<Company> _companies = [];
  List<String> _categories = ['Tech', 'Finance', 'Manufacturing', 'Healthcare', 'Retail'];
  
  String _searchQuery = '';
  String? _filterCategory;
  CompanyStatus? _filterStatus;
  
  // For Master-Detail view selection on Desktop
  String? _selectedCompanyId;

  CompanyProvider() {
    _loadFromStorage();
  }

  static const String _storageKey = 'bizos_company_registry';

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    final isComplete = prefs.getBool('bizos_setup_complete_companies');
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        _companies = (decoded['companies'] as List).map((m) => Company.fromMap(m)).toList();
        _categories = List<String>.from(decoded['categories']);
        notifyListeners();
      } catch (e) {
        if (isComplete != true) _loadDummyData();
      }
    } else {
      if (isComplete != true) _loadDummyData();
    }
  }

  void reload() => _loadFromStorage();

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bizos_setup_complete_companies', true);
    final data = {
      'companies': _companies.map((c) => c.toMap()).toList(),
      'categories': _categories,
    };
    await prefs.setString(_storageKey, json.encode(data));
  }

  // Getters
  List<Company> get companies {
    return _companies.where((c) {
      if (c.status == CompanyStatus.archived) return false; // Hide archived from main list
      final matchesSearch = c.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _filterCategory == null || c.categories.contains(_filterCategory!);
      final matchesStatus = _filterStatus == null || c.status == _filterStatus;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }
  
  List<Company> get archivedCompanies => _companies.where((c) => c.status == CompanyStatus.archived).toList();

  List<Company> get allCompanies => [..._companies];
  List<String> get categories => [..._categories];
  
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
  
  void selectCompany(String? id) {
    _selectedCompanyId = id;
    notifyListeners();
  }

  void manageCategory(String? oldName, String newName, List<String> assignedCompanyIds) {
    if (oldName != null && oldName != newName) {
      final index = _categories.indexOf(oldName);
      if (index != -1) _categories[index] = newName;
    } else if (oldName == null && !_categories.contains(newName)) {
      _categories.add(newName);
    }
    
    // Update company assignments
    for (var i = 0; i < _companies.length; i++) {
        final c = _companies[i];
        final cats = List<String>.from(c.categories);
        
        if (oldName != null) cats.remove(oldName);
        cats.remove(newName); // Prevent duplicates

        if (assignedCompanyIds.contains(c.id)) {
            cats.add(newName);
        }
        _companies[i] = c.copyWith(categories: cats.toSet().toList());
    }
    
    if (_filterCategory == oldName) _filterCategory = newName;
    _saveToStorage();
    notifyListeners();
  }

  void deleteCategory(String category) {
    _categories.remove(category);
    for (var i = 0; i < _companies.length; i++) {
       _companies[i] = _companies[i].copyWith(
         categories: _companies[i].categories.where((c) => c != category).toList(),
       );
    }
    if (_filterCategory == category) _filterCategory = null;
    _saveToStorage();
    notifyListeners();
  }

  void addCategory(String category) {
    if (!_categories.contains(category)) {
      _categories.add(category);
      _saveToStorage();
      notifyListeners();
    }
  }

  void addCompany(Company company) {
    _companies.add(company);
    _saveToStorage();
    notifyListeners();
  }

  void archiveCompany(String id) {
    final index = _companies.indexWhere((c) => c.id == id);
    if (index != -1) {
      _companies[index] = _companies[index].copyWith(status: CompanyStatus.archived);
      _saveToStorage();
      notifyListeners();
    }
  }

  void restoreCompany(String id) {
    final index = _companies.indexWhere((c) => c.id == id);
    if (index != -1) {
      _companies[index] = _companies[index].copyWith(status: CompanyStatus.active);
      _saveToStorage();
      notifyListeners();
    }
  }

  void deleteCompany(String id) {
    _companies.removeWhere((c) => c.id == id);
    _saveToStorage();
    notifyListeners();
  }

  void _loadDummyData() {
    _companies = [
      Company(
        id: '1',
        name: 'Nexus Tech Global',
        categories: ['Tech'],
        website: 'nexustech.io',
        activeEmployees: 145,
        annualRevenue: 2400000,
        healthScore: 0.95,
        budgetUtilized: 1800000,
        status: CompanyStatus.active,
        primaryEmail: 'contact@nexustech.io',
        phone: '+1 800 123 4567',
        location: 'Silicon Valley, CA',
        projectIds: ['p1', 'p2', 'p3'],
      ),
      Company(
        id: '2',
        name: 'Apex Manufacturing',
        categories: ['Manufacturing'],
        website: 'apex-mfg.com',
        activeEmployees: 420,
        annualRevenue: 8500000,
        healthScore: 0.72,
        budgetUtilized: 7900000,
        status: CompanyStatus.active,
        primaryEmail: 'info@apex-mfg.com',
        phone: '+1 888 987 6543',
        location: 'Detroit, MI',
        projectIds: ['p4'],
      ),
      Company(
        id: '3',
        name: 'Zenith Finance Group',
        categories: ['Finance', 'Tech'],
        website: 'zenithfinance.net',
        activeEmployees: 85,
        annualRevenue: 5200000,
        healthScore: 0.88,
        budgetUtilized: 3100000,
        status: CompanyStatus.active,
        primaryEmail: 'hello@zenithfinance.net',
        phone: '+44 20 7123 4567',
        location: 'London, UK',
        projectIds: ['p5', 'p6'],
      ),
      Company(
        id: '4',
        name: 'Pulse HealthCare',
        categories: ['Healthcare'],
        website: 'pulsehealth.org',
        activeEmployees: 310,
        annualRevenue: 4100000,
        healthScore: 0.65,
        budgetUtilized: 4500000,
        status: CompanyStatus.onHold,
        primaryEmail: 'admin@pulsehealth.org',
        phone: '+1 500 456 7890',
        location: 'Boston, MA',
        projectIds: ['p7'],
      ),
      Company(
        id: '5',
        name: 'Lumina Retail Corp',
        categories: ['Retail', 'Tech'],
        website: 'luminaretail.com',
        activeEmployees: 1200,
        annualRevenue: 12500000,
        healthScore: 0.98,
        budgetUtilized: 8500000,
        status: CompanyStatus.active,
        primaryEmail: 'corp@luminaretail.com',
        phone: '+1 212 555 0198',
        location: 'New York, NY',
        projectIds: ['p8', 'p9', 'p10', 'p11'],
      ),
    ];
    // Set initially selected company
    _selectedCompanyId = _companies.first.id;
  }
}
