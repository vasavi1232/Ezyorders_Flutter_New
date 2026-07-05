import 'package:flutter/material.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';

class ScanProvider extends ChangeNotifier {
  final AuthRemoteDataSource _dataSource;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _cartQuantity;

  ScanProvider(this._dataSource);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get cartQuantity => _cartQuantity;

  Future<bool> scanProduct(String barcode) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? "";
      final customerId = prefs.getString(StorageKeys.userId) ?? "";

      // Trim barcode to prevent "invalid_data" issues
      final sanitizedBarcode = barcode.trim();

      final response = await _dataSource.scanProduct(
        accessToken: accessToken,
        customerId: customerId,
        barcode: sanitizedBarcode,
      );

      // Handle status more robustly (can be int or string)
      final status = response['status']?.toString();
      if (status == '200') {
        _successMessage = "Scanned Product has been added to Cart.";
        if (response.containsKey('cart_quantity')) {
          _cartQuantity = response['cart_quantity']?.toString();
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? "Product not found.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Network Error: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
