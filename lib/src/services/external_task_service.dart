import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/external_task.dart';
import 'api_config.dart';
import 'auth_service.dart';

/// Fetches tasks from external Artemis modules (home-manager, vehicle-manager)
/// and surfaces them in the Home & Auto dashboard tab.
class ExternalTaskService {
  final AuthService _auth;
  static const _timeout = Duration(seconds: 15);

  ExternalTaskService(this._auth);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<List<ExternalTask>> getHomeManagerTasks() async {
    return _fetchTasks(
      ApiConfig.homeManagerUri('/api/v1/work-planner/tasks'),
      ExternalTaskSource.homeManager,
    );
  }

  Future<List<ExternalTask>> getVehicleManagerTasks() async {
    return _fetchTasks(
      ApiConfig.vehicleManagerUri('/api/v1/work-planner/tasks'),
      ExternalTaskSource.vehicleManager,
    );
  }

  /// Fetches both sources concurrently and returns the combined list.
  /// Never throws — returns empty list on any error so the tab degrades
  /// gracefully when services are offline.
  Future<List<ExternalTask>> getAll() async {
    try {
      final results = await Future.wait([
        getHomeManagerTasks(),
        getVehicleManagerTasks(),
      ]);
      return [...results[0], ...results[1]];
    } catch (e) {
      debugPrint('[ExternalTaskService] getAll error: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<List<ExternalTask>> _fetchTasks(
    Uri uri,
    ExternalTaskSource source,
  ) async {
    final token = await _auth.getAccessToken();
    try {
      final resp = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      if (resp.statusCode != 200) {
        debugPrint(
          '[ExternalTaskService] ${source.name} returned ${resp.statusCode}',
        );
        return [];
      }

      final data = jsonDecode(resp.body) as List;
      return data
          .cast<Map<String, dynamic>>()
          .map((j) => ExternalTask.fromJson(j, source))
          .toList();
    } catch (e) {
      debugPrint('[ExternalTaskService] ${source.name} error: $e');
      return [];
    }
  }
}
