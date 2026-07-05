import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../core/errors/failures.dart';

import '../../core/di/service_locator.dart';
import '../../core/services/session_service.dart';
import '../utils/common_methods.dart';

class ApiClient {
  final http.Client client;
  final Logger logger;

  ApiClient({http.Client? client, Logger? logger})
      : client = client ?? http.Client(),
        logger = logger ?? Logger();

  Future<dynamic> post(String uri,
      {Map<String, dynamic>? body, Map<String, String>? headers, bool isRetry = false}) async {
    try {
      // Clean up body to match Retrofit behavior (omit nulls and empty strings for optional params)
      // Exception: selected_products must be sent even if empty for Banners/Promotions filters to work.
      if (body != null) {
        body.removeWhere((key, value) => value == null);
      }

      logger.d('POST Request: $uri\nBody: $body');

      final response = await client.post(
        Uri.parse(uri),
        body:
            body, // http package handles map -> form-url-encoded automatically for map body
        headers: headers,
      );

      logger.d('Response Status: ${response.statusCode}');

      return _processResponse(response);
    } on SocketException {
      logger.e('SocketException for POST URI: $uri\nNo Internet connection');
      throw const ServerFailure('No Internet connection');
    } catch (e) {
      if (!isRetry && e.toString().contains('Connection closed before full header was received')) {
        logger.w('Connection closed prematurely. Retrying POST request...');
        return post(uri, body: body, headers: headers, isRetry: true);
      }
      logger.e('POST Request failed for URI: $uri\nError: $e');
      throw ServerFailure(e.toString());
    }
  }

  Future<dynamic> get(String uri, {Map<String, String>? headers, bool isRetry = false}) async {
    try {
      logger.d('GET Request: $uri');

      final response = await client.get(
        Uri.parse(uri),
        headers: headers,
      );

      logger.d('Response Status: ${response.statusCode}');

      return _processResponse(response);
    } on SocketException {
      logger.e('SocketException for GET URI: $uri\nNo Internet connection');
      throw const ServerFailure('No Internet connection');
    } catch (e) {
      if (!isRetry && e.toString().contains('Connection closed before full header was received')) {
        logger.w('Connection closed prematurely. Retrying GET request...');
        return get(uri, headers: headers, isRetry: true);
      }
      logger.e('GET Request failed for URI: $uri\nError: $e');
      throw ServerFailure(e.toString());
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        final sanitized = _sanitizeJsonString(response.body);
        final decoded = json.decode(sanitized);

        // Check for universal session expiration in the body
        if (decoded is Map) {
          final status = decoded['status'];
          final message = decoded['message'];
          // Only trigger global logout for 401 or explicit messages.
          // 403 is too broad for global logout as it can be used for generic data errors.
          if (status == 401 ||
              message == "Unauthorized" ||
              message == "Session Expired") {
            getIt<SessionService>().notifySessionExpired();
          }

          // Check for Store Not Available
          if (decoded['results'] is List && (decoded['results'] as List).isNotEmpty) {
             final firstResult = decoded['results'][0];
             if (firstResult is Map && firstResult['store_not_available'] == 'Yes') {
                final reason = firstResult['store_not_available_reason']?.toString() ?? "Store is currently not available.";
                CommonMethods.showStoreNotAvailableDialog(reason, data: firstResult as Map<String, dynamic>);
             }
          } else if (decoded['store_not_available'] == 'Yes') {
             final reason = decoded['store_not_available_reason']?.toString() ?? "Store is currently not available.";
             CommonMethods.showStoreNotAvailableDialog(reason, data: decoded as Map<String, dynamic>);
          } else if ((status == 500 || status == 403) && decoded['error'] != null) {
              // Limit to specific endpoints as per user request (add-to-cart, create-order, update-cart).
              // Do NOT trigger on generic 500 errors from other APIs like re-order.
              final String url = response.request?.url.toString() ?? "";
              final errorStr = decoded['error'].toString();
              
              bool isStoreClosedError = false;
              if (status == 500) {
                 isStoreClosedError = true;
              } else if (status == 403 && (errorStr.contains('&lt;') || errorStr.contains('<'))) {
                 isStoreClosedError = true;
              }

              if (isStoreClosedError && (url.contains('add-to-cart') ||
                  url.contains('update-cart') ||
                  url.contains('create-order') ||
                  url.contains('checkout'))) {
                CommonMethods.showStoreNotAvailableDialog(errorStr, data: decoded as Map<String, dynamic>);
              }
          }
        }

        return decoded;
      } catch (e) {
        logger.w('Failed to parse response as JSON. Returning raw string body. Error: $e');
        return response.body; // Return string if not JSON
      }
    } else {
      // Check for 401 status code (Global Unauthorized)
      if (response.statusCode == 401) {
        getIt<SessionService>().notifySessionExpired();
      }

      // Check for 500 store not available
      if (response.statusCode == 500) {
        try {
          final sanitized = _sanitizeJsonString(response.body);
          final decoded = json.decode(sanitized);
          if (decoded is Map && decoded['store_not_available'] == 'Yes') {
             final reason = decoded['store_not_available_reason']?.toString() ?? "Store is currently not available.";
             CommonMethods.showStoreNotAvailableDialog(reason, data: decoded as Map<String, dynamic>);
          }
        } catch (_) {}
      }

      throw ServerFailure('Error ${response.statusCode}: ${response.body}');
    }
  }

  /// Sanitizes PHP deprecation warnings or debug output prepended to the JSON body.
  /// It finds the first occurrence of '{' or '[' and extracts the JSON substring.
  String _sanitizeJsonString(String responseBody) {
    final trimmed = responseBody.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return trimmed;
    }

    final int braceIndex = trimmed.indexOf('{');
    final int bracketIndex = trimmed.indexOf('[');

    int startIndex = -1;
    if (braceIndex != -1 && bracketIndex != -1) {
      startIndex = braceIndex < bracketIndex ? braceIndex : bracketIndex;
    } else if (braceIndex != -1) {
      startIndex = braceIndex;
    } else if (bracketIndex != -1) {
      startIndex = bracketIndex;
    }

    if (startIndex != -1) {
      final int lastBraceIndex = trimmed.lastIndexOf('}');
      final int lastBracketIndex = trimmed.lastIndexOf(']');

      int endIndex = -1;
      if (lastBraceIndex != -1 && lastBracketIndex != -1) {
        endIndex = lastBraceIndex > lastBracketIndex ? lastBraceIndex : lastBracketIndex;
      } else if (lastBraceIndex != -1) {
        endIndex = lastBraceIndex;
      } else if (lastBracketIndex != -1) {
        endIndex = lastBracketIndex;
      }

      if (endIndex != -1 && endIndex > startIndex) {
        return trimmed.substring(startIndex, endIndex + 1);
      }
    }

    return trimmed;
  }
}
