import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';
import '../../domain/call_ports.dart';

class ViduApi implements LiveApi {
  ViduApi({Dio? client})
    : _client =
          client ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.vidu.cn',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              followRedirects: false,
            ),
          );
  final Dio _client;
  Future<Json> request(
    Credential c,
    String method,
    String path, {
    Json? data,
    Map<String, dynamic>? query,
    int timeout = 20,
  }) async {
    try {
      final response = await _client.request<Object?>(
        path,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          followRedirects: false,
          receiveTimeout: Duration(seconds: timeout),
          headers: {
            'Authorization': 'Token ${c.key}',
            'X-Request-ID': const Uuid().v4(),
          },
        ),
      );
      final body = jsonObject(response.data);
      return body['data'] is Map ? jsonObject(body['data']) : body;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      throw AppFailure(
        switch (status) {
          401 => 'unauthorized',
          403 => 'forbidden',
          503 => 'channelUnavailable',
          402 => 'insufficientCredit',
          404 => 'notFound',
          _ => 'network',
        },
        status: status,
        outcomeUnknown: method == 'POST' && (status == null || status >= 500),
      );
    } on FormatException {
      throw const AppFailure('protocol', outcomeUnknown: true);
    }
  }

  Future<void> check(Credential c) async => request(
    c,
    'GET',
    '/live/v1/avatars',
    query: {'pager.page': 0, 'pager.pagesz': 1},
  );
  @override
  Future<Json> createLive(Credential c, Json body) =>
      request(c, 'POST', '/live/s_avatar/realtime', data: body, timeout: 45);
  @override
  Future<Json> getLive(Credential c, String id) =>
      request(c, 'GET', '/live/v1/lives/${Uri.encodeComponent(id)}');
  Future<Json> avatars(Credential c) => request(
    c,
    'GET',
    '/live/v1/avatars',
    query: {'pager.page': 0, 'pager.pagesz': 100},
  );
  Future<Json> avatar(Credential c, String id) =>
      request(c, 'GET', '/live/v1/avatars/${Uri.encodeComponent(id)}');
  Future<Json> uploadAvatar(Credential c, File image, String name) async {
    final path = image.path;
    final uri = await Isolate.run(() {
      final bytes = File(path).readAsBytesSync();
      if (bytes.length >= 20 * 1024 * 1024) {
        throw const AppFailure('imageInvalid');
      }
      final mime = path.toLowerCase().endsWith('.png')
          ? 'png'
          : path.toLowerCase().endsWith('.webp')
          ? 'webp'
          : 'jpeg';
      return 'data:image/$mime;base64,${base64Encode(bytes)}';
    });
    return request(
      c,
      'POST',
      '/live/v1/avatars',
      data: {'name': name, 'image_uri': uri},
      timeout: 90,
    );
  }

  void dispose() => _client.close();
}
