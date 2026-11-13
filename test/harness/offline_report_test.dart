import 'package:flutter_test/flutter_test.dart';

import '../../tool/harness/offline_report.dart';

void main() {
  Map<String, dynamic> complete() => {
    'offlineSmokeCompleted': true,
    'loadingDismissedAfterFrame': true,
    'videoRetainedAcrossLoading': true,
    'sqliteReopened': true,
    'hangupReturnedHome': true,
    'backgroundEnded': true,
    'screenAwakeDuringCall': true,
    'screenSleepRestored': true,
    'screenshots': [
      for (final name in [
        'home',
        'me',
        'editor',
        'voices',
        'connecting',
        'call',
      ])
        {
          'screenshotName': 'offline-$name',
          'bytes': [1],
        },
    ],
  };

  test('rejects absent evidence even when the driver exit was zero', () {
    expect(() => requireOfflineReport(null), throwsStateError);
    expect(() => requireOfflineReport({}), throwsStateError);
    final missing = complete()..remove('offlineSmokeCompleted');
    expect(() => requireOfflineReport(missing), throwsStateError);
    final incomplete = complete()..['backgroundEnded'] = false;
    expect(() => requireOfflineReport(incomplete), throwsStateError);
    for (final flag in ['screenAwakeDuringCall', 'screenSleepRestored']) {
      expect(
        () => requireOfflineReport(complete()..remove(flag)),
        throwsStateError,
      );
      expect(
        () => requireOfflineReport(complete()..[flag] = false),
        throwsStateError,
      );
    }
  });

  test('requires every screen and accepts the complete offline run', () {
    final missing = complete();
    (missing['screenshots'] as List).removeLast();
    expect(() => requireOfflineReport(missing), throwsStateError);
    expect(requireOfflineReport(complete())['offlineSmokeCompleted'], isTrue);
  });
}
