import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'ui/core/design.dart';
import 'app/runtime.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(XiaoyuBootstrap(initialize: _initialize));
}

Future<Widget> _initialize() async {
  await LiquidGlassShaders.ensureLoaded();
  LiquidGlassEngine.liteGlassOnSkia = true;
  final runtime = await AppRuntime.open();
  unawaited(runtime.reconcileKnownCalls());
  return ProviderScope(
    overrides: [runtimeProvider.overrideWithValue(runtime)],
    child: const XiaoyuApp(),
  );
}
