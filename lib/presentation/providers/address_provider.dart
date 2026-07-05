import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../core/constants/app_messages.dart';
import '../../data/models/profile_models.dart';
import '../../core/constants/storage_keys.dart';

class AddressProvider extends ChangeNotifier {
  final AuthRemoteDataSource authRemoteDataSource;

  AddressProvider(this.authRemoteDataSource);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<AddressItem> _addressList = [];
  List<AddressItem> get addressList => _addressList;

  Future<void> fetchAddresses() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      // Addresses are part of Profile, so we fetch Profile
      final response =
          await authRemoteDataSource.getProfile(accessToken, customerId);
      final profileResponse = ProfileResponse.fromJson(response);

      final results = profileResponse.results;
      if (results != null && results.isNotEmpty && results.first != null) {
        _addressList = results.first!.addressesList ?? [];
      } else {
        _addressList = [];
      }
    } catch (e) {
      _errorMessage = AppMessages.failureMsg;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAddress({
    required String firstName,
    required String lastName,
    required String mobile,
    required String email,
    required String street,
    required String street2,
    required String suburb,
    required String state,
    required String postcode,
    required String defaultAddress,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final response = await authRemoteDataSource.addAddress(
          accessToken: accessToken,
          customerId: customerId,
          firstName: firstName,
          lastName: lastName,
          mobile: mobile,
          email: email,
          street: street,
          street2: street2,
          suburb: suburb,
          state: state,
          postcode: postcode,
          defaultAddress: defaultAddress);

      if (response['status'] == 200) {
        await fetchAddresses(); // Refresh list
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? AppMessages.failureMsg;
      }
    } catch (e) {
      _errorMessage = AppMessages.failureMsg;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> editAddress({
    required String addressId,
    required String firstName,
    required String lastName,
    required String mobile,
    required String email,
    required String street,
    required String street2,
    required String suburb,
    required String state,
    required String postcode,
    required String defaultAddress,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final response = await authRemoteDataSource.editAddressBook(
          accessToken: accessToken,
          customerId: customerId,
          addressId: addressId,
          firstName: firstName,
          lastName: lastName,
          mobile: mobile,
          email: email,
          street: street,
          street2: street2,
          suburb: suburb,
          state: state,
          postcode: postcode,
          defaultAddress: defaultAddress);

      if (response['status'] == 200) {
        await fetchAddresses(); // Refresh list
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? AppMessages.failureMsg;
      }
    } catch (e) {
      _errorMessage = AppMessages.failureMsg;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> setDefaultAddress(AddressItem address) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final response = await authRemoteDataSource.editAddressBook(
          accessToken: accessToken,
          customerId: customerId,
          addressId: address.addressId ?? "",
          firstName: address.firstName ?? "",
          lastName: address.lastName ?? "",
          mobile: address.phone ?? "",
          email: address.email ?? "",
          street: address.street ?? "",
          street2: address.street2 ?? "",
          suburb: address.suburb ?? "",
          state: address.state ?? "",
          postcode: address.postcode ?? "",
          defaultAddress: "Yes");

      if (response['status'] == 200) {
        await fetchAddresses(); // Refresh list
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? AppMessages.failureMsg;
      }
    } catch (e) {
      _errorMessage = AppMessages.failureMsg;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteAddress(String addressId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final response = await authRemoteDataSource.deleteAddress(
          accessToken: accessToken,
          customerId: customerId,
          addressId: addressId);

      if (response['status'] == 200) {
        await fetchAddresses(); // Refresh list
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? AppMessages.failureMsg;
      }
    } catch (e) {
      _errorMessage = AppMessages.failureMsg;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
