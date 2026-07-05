import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:logger/logger.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  final _logger = Logger();

  /// Checks for app updates and triggers the appropriate flow.
  /// This should be called from the main screen's initState.
  Future<void> checkForUpdate(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          _logger.i("Performing immediate update");
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          _logger.i("Starting flexible update");
          await InAppUpdate.startFlexibleUpdate();
          
          if (context.mounted) {
            _showRestartSnackbar(context);
          }
        }
      }
    } catch (e) {
      _logger.e("Error checking for update: $e");
    }
  }

  /// Checks if a flexible update has been downloaded and prompts for restart.
  /// Similar to the native onResume implementation.
  Future<void> checkFlexibleUpdateDownloaded(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.installStatus == InstallStatus.downloaded) {
        if (context.mounted) {
          _showRestartSnackbar(context);
        }
      }
    } catch (e) {
      _logger.e("Error checking flexible update status: $e");
    }
  }

  void _showRestartSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("An update has just been downloaded."),
        duration: const Duration(days: 1), // Keep it open
        action: SnackBarAction(
          label: "RESTART",
          onPressed: () async {
            try {
              await InAppUpdate.completeFlexibleUpdate();
            } catch (e) {
              _logger.e("Error completing flexible update: $e");
            }
          },
        ),
      ),
    );
  }
}
