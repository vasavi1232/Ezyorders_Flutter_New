import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/order_models.dart';
import '../../core/utils/common_methods.dart';

class OrdersProvider with ChangeNotifier {
  final AuthRemoteDataSource _dataSource;

  OrdersProvider(this._dataSource);

  // Order History State
  List<OrderHistoryResult> _orders = [];
  List<OrderHistoryResult> get orders => _orders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isMoreLoading = false;
  bool get isMoreLoading => _isMoreLoading;

  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _error;
  String? get error => _error;

  String? _actionError;
  String? get actionError => _actionError;

  // Search/Filters
  String _searchText = "";
  String _startDate = "";
  String _endDate = "";

  // Order Details State
  OrderDetailsResponse? _orderDetails;
  OrderDetailsResponse? get orderDetails => _orderDetails;

  String? _orderIdCreated;
  String? get orderIdCreated => _orderIdCreated;

  // Initialize and Fetch History
  Future<void> fetchOrders({
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      _currentPage = 1;
      _orders = [];
      _hasMore = true;
      _isLoading = true;
    } else {
      if (!_hasMore || _isMoreLoading) return;
      if (_currentPage == 1) {
        _isLoading = true;
      } else {
        _isMoreLoading = true;
      }
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final json = await _dataSource.getOrderHistory(
        accessToken: accessToken,
        customerId: customerId,
        page: _currentPage,
        searchText: _searchText,
        startDate: _startDate,
        endDate: _endDate,
      );

      final response = OrderHistoryResponse.fromJson(json);

      if (response.status == 200) {
        if (_currentPage == 1) {
          _orders = response.results ?? [];
        } else {
          _orders.addAll(response.results ?? []);
        }

        _hasMore = (response.results?.length ?? 0) > 0;
        if (_hasMore) _currentPage++;
      } else {
        _hasMore = false;
        if (_currentPage == 1) _orders = [];
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isMoreLoading = false;
      notifyListeners();
    }
  }

  // Update Filters
  void updateFilters(String search, String start, String end) {
    _searchText = search;
    _startDate = start;
    _endDate = end;
  }

  void clearFilters() {
    _searchText = "";
    _startDate = "";
    _endDate = "";
  }

  // Fetch Order Details
  Future<void> fetchOrderDetails({
    required String orderId,
  }) async {
    _isLoading = true;
    _orderDetails = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final json = await _dataSource.getOrderDetails(
        accessToken: accessToken,
        customerId: customerId,
        orderId: orderId,
      );
      _orderDetails = OrderDetailsResponse.fromJson(json);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Order Actions
  Future<bool> cancelOrder({
    required String orderId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final json = await _dataSource.deleteOrder(
        accessToken: accessToken,
        customerId: customerId,
        orderId: orderId,
      );
      bool success = json['status'] == 200;
      if (success) {
        await fetchOrders(isRefresh: true);
      }
      return success;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> duplicateOrder({
    required String oldOrderId,
  }) async {
    _isLoading = true;
    _actionError = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final json = await _dataSource.duplicateOrder(
        accessToken: accessToken,
        customerId: customerId,
        oldOrderId: oldOrderId,
      );
      if (json['status'] == 200) {
        _orderIdCreated = json['RefNo'];
        return _orderIdCreated;
      }
      _actionError = json['error'] ?? json['message'] ?? "Failed to duplicate order";
      return null;
    } catch (e) {
      _actionError = CommonMethods.formatErrorMessage(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reorderOrder({
    required String oldOrderId,
  }) async {
    _isLoading = true;
    _actionError = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final json = await _dataSource.reorderOrder(
        accessToken: accessToken,
        customerId: customerId,
        oldOrderId: oldOrderId,
      );
      bool success = json['status'] == 200;
      if (!success) {
        _actionError = CommonMethods.formatErrorMessage(json['error'] ?? json['message'] ?? "Failed to re-order");
      }
      return success;
    } catch (e) {
      _actionError = CommonMethods.formatErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
