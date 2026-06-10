import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_service.dart';
import '../models/company_stock.dart';

class CompanyStockProvider with ChangeNotifier {
  ApiService? _api;
  List<CompanyStock> _stocks = [];
  List<CompanyStock> _trashedStocks = [];
  bool _isLoading = false;

  List<CompanyStock> get stocks => _stocks;
  List<CompanyStock> get trashedStocks => _trashedStocks;
  bool get isLoading => _isLoading;

  void update(ApiService api) {
    _api = api;
  }

  Future<void> fetchStocks(String companyId, {bool showTrashed = false}) async {
    if (_api == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final endpoint = showTrashed 
          ? '/companies/$companyId/stocks/trashed' 
          : '/companies/$companyId/stocks';
      final dynamic response = await _api!.get(endpoint);
      
      if (response is List) {
        final list = response.map((e) => CompanyStock.fromMap(e as Map<String, dynamic>)).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        if (showTrashed) {
          _trashedStocks = list;
          // Fetch active in background for count
          _fetchActiveStocksInBackground(companyId);
        } else {
          _stocks = list;
          // Fetch trashed in background for count
          _fetchTrashedStocksInBackground(companyId);
        }
      }
    } catch (e) {
      debugPrint('Error loading company stocks for $companyId: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchActiveStocksInBackground(String companyId) async {
    if (_api == null) return;
    try {
      final dynamic response = await _api!.get('/companies/$companyId/stocks');
      if (response is List) {
        _stocks = response.map((e) => CompanyStock.fromMap(e as Map<String, dynamic>)).toList();
        _stocks.sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading active stocks in background: $e');
    }
  }

  Future<void> _fetchTrashedStocksInBackground(String companyId) async {
    if (_api == null) return;
    try {
      final dynamic response = await _api!.get('/companies/$companyId/stocks/trashed');
      if (response is List) {
        _trashedStocks = response.map((e) => CompanyStock.fromMap(e as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading trashed stocks in background: $e');
    }
  }

  Future<void> addStock(String companyId, {required String title, String stkCode = ''}) async {
    if (_api == null) return;
    final newStock = CompanyStock(
      id: const Uuid().v4(),
      companyId: companyId,
      title: title,
      stkCode: stkCode,
      date: DateTime.now(),
    );
    
    try {
      await _api!.post('/companies/$companyId/stocks', newStock.toMap());
      await fetchStocks(companyId, showTrashed: false);
    } catch (e) {
      debugPrint('Error adding stock: $e');
      rethrow;
    }
  }

  Future<void> updateStock(String companyId, CompanyStock updatedStock) async {
    if (_api == null) return;
    try {
      await _api!.put('/stocks/${updatedStock.id}', updatedStock.toMap());
      await fetchStocks(companyId, showTrashed: false);
    } catch (e) {
      debugPrint('Error updating stock: $e');
      rethrow;
    }
  }

  Future<void> deleteStock(String companyId, String id, {bool isShowingTrashed = false}) async {
    if (_api == null) return;
    try {
      await _api!.delete('/stocks/$id');
      await fetchStocks(companyId, showTrashed: isShowingTrashed);
    } catch (e) {
      debugPrint('Error deleting stock: $e');
      rethrow;
    }
  }

  Future<void> restoreStock(String companyId, String id) async {
    if (_api == null) return;
    try {
      await _api!.post('/stocks/$id/restore', {});
      await fetchStocks(companyId, showTrashed: true);
    } catch (e) {
      debugPrint('Error restoring stock: $e');
      rethrow;
    }
  }

  Future<void> forceDeleteStock(String companyId, String id) async {
    if (_api == null) return;
    try {
      await _api!.delete('/stocks/$id/force-delete');
      await fetchStocks(companyId, showTrashed: true);
    } catch (e) {
      debugPrint('Error force deleting stock: $e');
      rethrow;
    }
  }
}
