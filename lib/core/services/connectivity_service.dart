import 'dart:async';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService {
  bool _isDialogShowing = false;

  bool get isDialogShowing => _isDialogShowing;

  final _connectivityErrorController = StreamController<void>.broadcast();
  Stream<void> get connectivityErrorStream => _connectivityErrorController.stream;

  void setDialogShowing(bool showing) {
    _isDialogShowing = showing;
  }

  void notifyConnectivityError() {
     _connectivityErrorController.add(null);
  }

  /// Checks if there is an actual internet connection.
  Future<bool> get hasConnection async {
    return await InternetConnection().hasInternetAccess;
  }

  void dispose() {
    _connectivityErrorController.close();
  }
}
