/// A zero driver exit alone cannot establish that the offline test ran.
/// Flutter's integration driver may omit setUpAll failures from its result map.
Map<String, dynamic> requireOfflineReport(Map<String, dynamic>? data) {
  const requiredFlags = [
    'offlineSmokeCompleted',
    'loadingDismissedAfterFrame',
    'videoRetainedAcrossLoading',
    'sqliteReopened',
    'hangupReturnedHome',
    'backgroundEnded',
  ];
  if (data == null || requiredFlags.any((key) => data[key] != true)) {
    throw StateError('Offline test did not produce all completion evidence.');
  }
  final images = data['screenshots'];
  const requiredScreens = [
    'home',
    'me',
    'editor',
    'voices',
    'connecting',
    'call',
  ];
  if (images is! List ||
      requiredScreens.any(
        (name) => !images.any(
          (image) =>
              image is Map &&
              image['screenshotName'] == 'offline-$name' &&
              image['bytes'] is List &&
              (image['bytes'] as List).isNotEmpty,
        ),
      )) {
    throw StateError('Offline test did not capture all six screens.');
  }
  return Map<String, dynamic>.from(data);
}
