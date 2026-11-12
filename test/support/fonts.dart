import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Local golden rendering uses an installed system font, never downloads assets.
Future<void> loadGoldenFont() async {
  if (!Platform.isMacOS) return;
  TestWidgetsFlutterBinding.ensureInitialized();
  final configured = Platform.environment['XIAOYU_TEST_FONT'];
  final font = configured != null
      ? File(configured)
      : Directory('/System/Library/AssetsV2/com_apple_MobileAsset_Font7')
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((f) => f.path.endsWith('/PingFang.ttc'))
            .first;
  final bytes = ByteData.sublistView(font.readAsBytesSync());
  for (final family in [
    'CupertinoSystemDisplay',
    'CupertinoSystemText',
    '.AppleSystemUIFont',
    'Ahem',
    'Roboto',
    '.SF UI Text',
    '.SF UI Display',
    '.SF Pro Text',
    '.SF Pro Display',
  ]) {
    await (FontLoader(family)..addFont(Future.value(bytes))).load();
  }
  final packages = jsonDecode(
    File('.dart_tool/package_config.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final flutter = (packages['packages'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((p) => p['name'] == 'flutter');
  final root = Directory.fromUri(Uri.parse(flutter['rootUri'] as String))
      .parent
      .parent
      .uri;
  final icons = File.fromUri(
    root.resolve(
      'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ),
  );
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync()))))
      .load();
  final cupertino = (packages['packages'] as List)
      .cast<Map<String, dynamic>>()
      .firstWhere((p) => p['name'] == 'cupertino_icons');
  final cupertinoFont = File.fromUri(
    Directory.fromUri(Uri.parse(cupertino['rootUri'] as String)).uri
        .resolve('assets/CupertinoIcons.ttf'),
  );
  await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
        Future.value(ByteData.sublistView(cupertinoFont.readAsBytesSync())),
      ))
      .load();
}
