import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

import 'offline_report.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final saved = requireOfflineReport(data);
    final screenshots = saved['screenshots'];
    if (screenshots is List) {
      saved['screenshots'] = [
        for (final raw in screenshots)
          (() {
            final image = raw as Map;
            final name = '${image['screenshotName']}'.replaceAll(
              RegExp(r'[^a-zA-Z0-9_-]'),
              '_',
            );
            final png = File('build/harness/device-screenshots/$name.png');
            png.parent.createSync(recursive: true);
            png.writeAsBytesSync((image['bytes'] as List).cast<int>());
            return {'name': name, 'path': png.path};
          })(),
      ];
    }
    final file = File('build/harness/device-response.json');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(saved));
  },
);
