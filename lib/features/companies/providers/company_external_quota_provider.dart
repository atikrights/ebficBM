import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_service.dart';
import '../models/company_external_quota.dart';

class CompanyExternalQuotaProvider with ChangeNotifier {
  ApiService? _api;
  List<CompanyExternalQuota> _quotas = [];
  List<CompanyExternalQuota> _trashedQuotas = [];
  bool _isLoading = false;

  List<CompanyExternalQuota> get quotas => _quotas;
  List<CompanyExternalQuota> get trashedQuotas => _trashedQuotas;
  bool get isLoading => _isLoading;

  void update(ApiService api) {
    _api = api;
  }

  Future<void> fetchQuotas(String companyId, {bool showTrashed = false}) async {
    if (_api == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final endpoint = showTrashed 
          ? '/companies/$companyId/external-quotas/trashed' 
          : '/companies/$companyId/external-quotas';
      final dynamic response = await _api!.get(endpoint);
      
      if (response is List) {
        final list = response.map((e) => CompanyExternalQuota.fromMap(e as Map<String, dynamic>)).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        if (showTrashed) {
          _trashedQuotas = list;
          // Fetch active in background for count
          _fetchActiveQuotasInBackground(companyId);
        } else {
          _quotas = list;
          // Fetch trashed in background for count
          _fetchTrashedQuotasInBackground(companyId);
        }
      }
    } catch (e) {
      debugPrint('Error loading external quotas for $companyId: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchActiveQuotasInBackground(String companyId) async {
    if (_api == null) return;
    try {
      final dynamic response = await _api!.get('/companies/$companyId/external-quotas');
      if (response is List) {
        _quotas = response.map((e) => CompanyExternalQuota.fromMap(e as Map<String, dynamic>)).toList();
        _quotas.sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading active quotas in background: $e');
    }
  }

  Future<void> _fetchTrashedQuotasInBackground(String companyId) async {
    if (_api == null) return;
    try {
      final dynamic response = await _api!.get('/companies/$companyId/external-quotas/trashed');
      if (response is List) {
        _trashedQuotas = response.map((e) => CompanyExternalQuota.fromMap(e as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading trashed quotas in background: $e');
    }
  }

  Future<void> addQuota(String companyId, {required String title, required String tag}) async {
    if (_api == null) return;
    final random = Random();
    final rand1 = random.nextInt(900) + 100; // 3 digits: 100 to 999
    final rand2 = random.nextInt(9000) + 1000; // 4 digits: 1000 to 9999
    final qid = 'QID-$rand1-$rand2';

    final newQuota = CompanyExternalQuota(
      id: const Uuid().v4(),
      companyId: companyId,
      earn: 0.0,
      expense: 0.0,
      date: DateTime.now(),
      title: title,
      tag: tag,
      qid: qid,
      earnDescription: '',
      earnTime: '',
      expenseDescription: '',
      expenseTime: '',
    );
    
    try {
      await _api!.post('/companies/$companyId/external-quotas', newQuota.toMap());
      await fetchQuotas(companyId, showTrashed: false);
    } catch (e) {
      debugPrint('Error adding quota: $e');
      rethrow;
    }
  }

  Future<void> updateQuota(String companyId, CompanyExternalQuota updatedQuota) async {
    if (_api == null) return;
    try {
      await _api!.put('/external-quotas/${updatedQuota.id}', updatedQuota.toMap());
      await fetchQuotas(companyId, showTrashed: false);
    } catch (e) {
      debugPrint('Error updating quota: $e');
      rethrow;
    }
  }

  Future<void> deleteQuota(String companyId, String id, {bool isShowingTrashed = false}) async {
    if (_api == null) return;
    try {
      await _api!.delete('/external-quotas/$id');
      await fetchQuotas(companyId, showTrashed: isShowingTrashed);
    } catch (e) {
      debugPrint('Error deleting quota: $e');
      rethrow;
    }
  }

  Future<void> restoreQuota(String companyId, String id) async {
    if (_api == null) return;
    try {
      await _api!.post('/external-quotas/$id/restore', {});
      await fetchQuotas(companyId, showTrashed: true);
    } catch (e) {
      debugPrint('Error restoring quota: $e');
      rethrow;
    }
  }

  Future<void> forceDeleteQuota(String companyId, String id) async {
    if (_api == null) return;
    try {
      await _api!.delete('/external-quotas/$id/force-delete');
      await fetchQuotas(companyId, showTrashed: true);
    } catch (e) {
      debugPrint('Error force deleting quota: $e');
      rethrow;
    }
  }
}
