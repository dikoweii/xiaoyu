import 'package:dio/dio.dart';

import '../../domain/models.dart';

/// A website catalog observed on 2026-11-09, separate from the public OpenAPI.
/// Never sends the user's Vidu API Key or browser cookies to this service.
class OfficialCatalog {
  OfficialCatalog({Dio? client})
    : _client =
          client ??
          Dio(
            BaseOptions(
              baseUrl: 'https://service.vidu.cn',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              followRedirects: false,
            ),
          );
  final Dio _client;
  void dispose() => _client.close();
  Future<List<Json>> load() async {
    try {
      final response = await _client.get<Object?>(
        '/live/v1/keeper/avatar/roles',
        queryParameters: {
          'pager.page': 0,
          'pager.pagesz': 100,
          'avatar_types': 'system',
        },
        options: Options(
          headers: {'x-platform': 'web', 'accept-language': 'zh'},
        ),
      );
      final roles = jsonObject(response.data)['roles'];
      if (roles is! List) throw const AppFailure('protocol');
      return roles
          .map(jsonObject)
          .where((r) => r['enabled'] == true && r['image_uri'] is String)
          .toList();
    } on DioException {
      throw const AppFailure('catalogUnavailable');
    }
  }
}
