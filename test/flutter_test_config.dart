import 'dart:async';
import 'dart:io';

Future<void> testExecutable(FutureOr<void> Function() testMain) =>
    HttpOverrides.runZoned(
      () async => await testMain(),
      createHttpClient: (_) =>
          throw StateError('Network forbidden in offline tests'),
    );
