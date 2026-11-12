import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../../domain/call_ports.dart';
import '../../domain/models.dart';

class ViduSignaling implements Signaling {
  ViduSignaling(
    this.credential,
    this.liveId, {
    Future<WebSocket> Function(String, Map<String, String>)? connector,
    this.connectTimeout = const Duration(seconds: 10),
  }) : _connector = connector ?? _connect;
  static Future<WebSocket> _connect(String url, Map<String, String> headers) =>
      WebSocket.connect(url, headers: headers);
  final Future<WebSocket> Function(String, Map<String, String>) _connector;
  final Duration connectTimeout;
  final Credential credential;
  final String liveId;
  final String connectionId = const Uuid().v4();
  final _events = StreamController<Json>.broadcast();
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  int _sequence = 0;
  bool _closing = false;
  @override
  Stream<Json> get events => _events.stream;
  @override
  Future<void> connect() async {
    final uri = Uri.https('api.vidu.cn', '/live/ws/live/connect', {
      'live_id': liveId,
      'conn_id': connectionId,
    }).replace(scheme: 'wss');
    final pending = _connector(uri.toString(), {
      'Authorization': 'Token ${credential.key}',
    });
    try {
      _socket = await pending.timeout(connectTimeout);
    } on Object {
      unawaited(
        pending.then<void>((socket) async {
          await socket.close();
        }, onError: (Object _) {}),
      );
      throw const AppFailure('connectionFailed');
    }
    if (_closing) {
      await _socket!.close();
      return;
    }
    // Protocol Ping/Pong is an M0 candidate, not a verified Vidu business heartbeat.
    _socket!.pingInterval = const Duration(seconds: 8);
    _subscription = _socket!.listen(
      (Object? frame) {
        if (_closing || frame is! String) return;
        try {
          final value = jsonObject(jsonDecode(frame));
          if (value['live_id'] != null && '${value['live_id']}' != liveId) {
            return;
          }
          _events.add(value);
        } on Object {
          _events.add({'type': -2});
        }
      },
      onError: (Object _) {
        if (!_closing) _events.add({'type': -1});
      },
      onDone: () {
        if (!_closing) _events.add({'type': -1});
      },
    );
  }

  @override
  void send(int type, Json payload) {
    if (_socket?.readyState != WebSocket.open || _closing) {
      throw const AppFailure('connectionLost');
    }
    _socket!.add(
      jsonEncode({
        'type': type,
        'live_id': liveId,
        'conn_id': connectionId,
        'seq_id': ++_sequence,
        'payload': payload,
      }),
    );
  }

  @override
  Future<void> close() async {
    _closing = true;
    try {
      await _socket?.close().timeout(const Duration(seconds: 2));
    } finally {
      await _subscription?.cancel();
      await _events.close();
    }
  }
}
