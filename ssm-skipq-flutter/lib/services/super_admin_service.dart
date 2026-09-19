import 'package:dio/dio.dart';

import '../models/super_admin.dart';
import 'api_client.dart';

class SuperAdminService {
  SuperAdminService(this._api);

  final ApiClient _api;

  Options get _options => Options(headers: {
        'X-Super-Admin-Id': 'superadmin',
        'X-Super-Admin-Password': '1234admin',
      });

  Future<List<ManagedManager>> fetchManagers() async {
    final response = await _api.dio
        .get<Map<String, dynamic>>('/super-admin/managers', options: _options);
    final data = response.data?['data'] as Map<String, dynamic>?;
    return (data?['managers'] as List<dynamic>? ?? [])
        .map((item) => ManagedManager.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ManagedManager> createManager(
      {required String name,
      required String managerId,
      required String password}) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/super-admin/managers',
      data: {'name': name, 'managerId': managerId, 'password': password},
      options: _options,
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    return ManagedManager.fromJson(data?['manager'] as Map<String, dynamic>);
  }
}
