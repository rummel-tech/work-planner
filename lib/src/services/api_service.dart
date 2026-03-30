import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Low-level API client. All methods return the decoded JSON body.
/// Throws [ApiException] on non-2xx responses.
/// Throws [ApiNetworkException] on connectivity failures.
class ApiService {
  final AuthService _auth;

  ApiService(this._auth);

  // ---------------------------------------------------------------------------
  // Goals
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getGoals({String? goalType, String? status}) async {
    var path = '/goals';
    final params = <String, String>{};
    if (goalType != null) params['goal_type'] = goalType;
    if (status != null) params['goal_status'] = status;
    if (params.isNotEmpty) {
      path += '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    }
    final resp = await _get(path);
    return (resp as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> body) async {
    return await _post('/goals', body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateGoal(String id, Map<String, dynamic> body) async {
    return await _patch('/goals/$id', body) as Map<String, dynamic>;
  }

  Future<void> deleteGoal(String id) async {
    await _delete('/goals/$id');
  }

  // ---------------------------------------------------------------------------
  // Plans
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getPlans({String? goalId, String? status}) async {
    var path = '/plans';
    final params = <String, String>{};
    if (goalId != null) params['goal_id'] = goalId;
    if (status != null) params['plan_status'] = status;
    if (params.isNotEmpty) {
      path += '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    }
    final resp = await _get(path);
    return (resp as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> body) async {
    return await _post('/plans', body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePlan(String id, Map<String, dynamic> body) async {
    return await _patch('/plans/$id', body) as Map<String, dynamic>;
  }

  Future<void> deletePlan(String id) async {
    await _delete('/plans/$id');
  }

  // ---------------------------------------------------------------------------
  // Day Planners & Tasks
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getDayPlanner(String date) async {
    return await _get('/day-planners/$date') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> upsertDayPlanner(String date, {String? notes}) async {
    return await _post('/day-planners', {'date': date, if (notes != null) 'notes': notes}) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTask(String date, Map<String, dynamic> body) async {
    return await _post('/day-planners/$date/tasks', body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTask(String taskId, Map<String, dynamic> body) async {
    return await _patch('/tasks/$taskId', body) as Map<String, dynamic>;
  }

  Future<void> deleteTask(String taskId) async {
    await _delete('/tasks/$taskId');
  }

  // ---------------------------------------------------------------------------
  // Week Planners
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getWeekPlanner(String weekStartDate) async {
    return await _get('/week-planners/$weekStartDate') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> upsertWeekPlanner(String weekStartDate, {List<String>? weeklyGoals, String? notes}) async {
    return await _post('/week-planners', {
      'week_start_date': weekStartDate,
      if (weeklyGoals != null) 'weekly_goals': weeklyGoals,
      if (notes != null) 'notes': notes,
    }) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getWeekStats(String weekStartDate) async {
    return await _get('/week-planners/$weekStartDate/stats') as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // HTTP helpers
  // ---------------------------------------------------------------------------

  Future<dynamic> _get(String path) async {
    try {
      final resp = await _auth.authenticatedRequest(method: 'GET', endpoint: path);
      _checkStatus(resp);
      return jsonDecode(resp.body);
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiNetworkException(e.toString());
    }
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    try {
      final resp = await _auth.authenticatedRequest(method: 'POST', endpoint: path, body: body);
      _checkStatus(resp);
      return jsonDecode(resp.body);
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiNetworkException(e.toString());
    }
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    try {
      final resp = await _auth.authenticatedRequest(method: 'PATCH', endpoint: path, body: body);
      _checkStatus(resp);
      return jsonDecode(resp.body);
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiNetworkException(e.toString());
    }
  }

  Future<void> _delete(String path) async {
    try {
      final resp = await _auth.authenticatedRequest(method: 'DELETE', endpoint: path);
      if (resp.statusCode != 204 && resp.statusCode != 200) {
        throw ApiException(resp.statusCode, _errorDetail(resp));
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiNetworkException(e.toString());
    }
  }

  void _checkStatus(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(resp.statusCode, _errorDetail(resp));
    }
  }

  String _errorDetail(http.Response resp) {
    try {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return body['detail'] as String? ?? resp.reasonPhrase ?? 'Unknown error';
    } catch (_) {
      return resp.reasonPhrase ?? 'Unknown error';
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String detail;
  const ApiException(this.statusCode, this.detail);
  @override
  String toString() => 'ApiException($statusCode): $detail';
}

class ApiNetworkException implements Exception {
  final String message;
  const ApiNetworkException(this.message);
  @override
  String toString() => 'ApiNetworkException: $message';
}
