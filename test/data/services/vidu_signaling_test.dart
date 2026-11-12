import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/data/services/vidu_signaling.dart';
import 'package:xiaoyu/domain/models.dart';

class SocketDouble extends Stream<Object?> implements WebSocket {
  final source = StreamController<Object?>.broadcast();
  final sent = <String>[];
  bool closed = false;
  @override
  int get readyState => closed ? WebSocket.closed : WebSocket.open;
  @override
  Duration? pingInterval;
  @override
  void add(Object? data) {
    sent.add(data as String);
  }

  @override
  Future<void> close([int? code, String? reason]) async {
    closed = true;
  }

  @override
  StreamSubscription<Object?> listen(
    void Function(Object?)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => source.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const credential = Credential('offline', 'test-only-key');
  test(
    'signaling authenticates to WSS and routes only the owned live',
    () async {
      final socket = SocketDouble();
      String? url;
      Map<String, String>? headers;
      final signal = ViduSignaling(
        credential,
        'live',
        connector: (u, h) async {
          url = u;
          headers = h;
          return socket;
        },
      );
      final events = <Json>[];
      final sub = signal.events.listen(events.add);
      await signal.connect();
      expect(Uri.parse(url!).scheme, 'wss');
      expect(Uri.parse(url!).host, 'api.vidu.cn');
      expect(headers!['Authorization'], 'Token ${credential.key}');
      expect(socket.pingInterval, const Duration(seconds: 8));
      socket.source.add(jsonEncode({'type': 2, 'live_id': 'other'}));
      socket.source.add(jsonEncode({'type': 2, 'live_id': 'live'}));
      socket.source.add('not-json');
      socket.source.add([1, 2]);
      await Future<void>.delayed(Duration.zero);
      expect(events.map((e) => e['type']), [2, -2]);
      signal.send(102, {'text': 'hello'});
      signal.send(5, {});
      expect(socket.sent.map((s) => (jsonDecode(s) as Map)['seq_id']), [1, 2]);
      await socket.source.close();
      await Future<void>.delayed(Duration.zero);
      expect(events.last['type'], -1);
      await signal.close();
      await sub.cancel();
      expect(() => signal.send(1, {}), throwsA(isA<AppFailure>()));
    },
  );
  test('late socket is closed after a timed-out connection', () async {
    final pending = Completer<WebSocket>(), socket = SocketDouble();
    final signal = ViduSignaling(
      credential,
      'live',
      connector: (_, _) => pending.future,
      connectTimeout: const Duration(milliseconds: 1),
    );
    await expectLater(signal.connect(), throwsA(isA<AppFailure>()));
    pending.complete(socket);
    await Future<void>.delayed(Duration.zero);
    expect(socket.closed, isTrue);
    await signal.close();
    await socket.source.close();
  });
  test('closing while connecting never attaches to a late socket', () async {
    final pending = Completer<WebSocket>(), socket = SocketDouble();
    final signal = ViduSignaling(
      credential,
      'live',
      connector: (_, _) => pending.future,
    );
    final connecting = signal.connect();
    await signal.close();
    pending.complete(socket);
    await connecting;
    expect(socket.closed, isTrue);
    await socket.source.close();
  });
  test(
    'socket error becomes connection-lost without exposing raw exceptions',
    () async {
      final socket = SocketDouble();
      final signal = ViduSignaling(
        credential,
        'live',
        connector: (_, _) async => socket,
      );
      final events = <Json>[];
      final sub = signal.events.listen(events.add);
      await signal.connect();
      socket.source.addError(StateError('private diagnostics'));
      await Future<void>.delayed(Duration.zero);
      expect(events.single, {'type': -1});
      await signal.close();
      await sub.cancel();
      await socket.source.close();
    },
  );
}
