import 'package:flutter/foundation.dart';

enum CompanyStatus { active, onHold, archived }

class Company {
  final String id;
  final String name;
  final String? logoUrl;
  final List<String> categories;
  final String website;
  
  // Stats
  final int activeEmployees;
  final double annualRevenue;
  final double healthScore; // 0.0 to 1.0 (Health / Risk factor)
  final double budgetUtilized;
  
  // Status
  final CompanyStatus status;
  
  // Contact
  final String primaryEmail;
  final String phone;
  final String location;
  
  // Relational Data
  final List<String> projectIds;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.categories,
    required this.website,
    this.activeEmployees = 0,
    this.annualRevenue = 0.0,
    this.healthScore = 0.9,
    this.budgetUtilized = 0.0,
    this.status = CompanyStatus.active,
    required this.primaryEmail,
    required this.phone,
    required this.location,
    this.projectIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Company copyWith({
    String? id,
    String? name,
    String? logoUrl,
    List<String>? categories,
    String? website,
    int? activeEmployees,
    double? annualRevenue,
    double? healthScore,
    double? budgetUtilized,
    CompanyStatus? status,
    String? primaryEmail,
    String? phone,
    String? location,
    List<String>? projectIds,
    DateTime? createdAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      categories: categories ?? this.categories,
      website: website ?? this.website,
      activeEmployees: activeEmployees ?? this.activeEmployees,
      annualRevenue: annualRevenue ?? this.annualRevenue,
      healthScore: healthScore ?? this.healthScore,
      budgetUtilized: budgetUtilized ?? this.budgetUtilized,
      status: status ?? this.status,
      primaryEmail: primaryEmail ?? this.primaryEmail,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      projectIds: projectIds ?? this.projectIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'categories': categories,
      'website': website,
      'activeEmployees': activeEmployees,
      'annualRevenue': annualRevenue,
      'healthScore': healthScore,
      'budgetUtilized': budgetUtilized,
      'status': status.index,
      'primaryEmail': primaryEmail,
      'phone': phone,
      'location': location,
      'projectIds': projectIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed Organization',
      logoUrl: map['logoUrl'],
      categories: List<String>.from(map['categories'] ?? []),
      website: map['website'] ?? '',
      activeEmployees: map['activeEmployees'] ?? 0,
      annualRevenue: (map['annualRevenue'] ?? 0).toDouble(),
      healthScore: (map['healthScore'] ?? 0.9).toDouble(),
      budgetUtilized: (map['budgetUtilized'] ?? 0).toDouble(),
      status: CompanyStatus.values[map['status'] ?? 0],
      primaryEmail: map['primaryEmail'] ?? 'contact@organization.reg',
      phone: map['phone'] ?? 'System Direct',
      location: map['location'] ?? 'Global Network',
      projectIds: List<String>.from(map['projectIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
