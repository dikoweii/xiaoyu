import 'dart:async';

import '../domain/models.dart';

typedef _AssetKey = (String, String, String, String, String);

/// One bounded polling loop for saved avatars while the home route is visible.
class AvatarStatusSync {
  AvatarStatusSync({
    required this.credential,
    required this.refresh,
    this.interval = const Duration(seconds: 3),
    this.maxAttempts = 40,
  });

  final Credential? Function() credential;
  final Future<Character> Function(Character) refresh;
  final Duration interval;
  final int maxAttempts;
  final _attempts = <_AssetKey, int>{};
  List<Character> _characters = [];
  Timer? _timer;
  bool _active = false, _disposed = false, _running = false, _wake = false;

  _AssetKey _key(Character c) =>
      (c.id, c.avatarId, c.credentialId, c.imagePath, c.sourceImageUrl);

  bool _pending(Character c) =>
      c.avatarId.isNotEmpty &&
      {'created', 'processing'}.contains(c.assetStatus);

  Iterable<Character> get _eligible => _characters.where(
    (c) =>
        _pending(c) &&
        c.credentialId == credential()?.id &&
        (_attempts[_key(c)] ?? 0) < maxAttempts,
  );

  void update(List<Character> values) {
    if (_disposed) return;
    final old = _characters.where(_pending).map(_key).toSet();
    _characters = values;
    final current = values.where(_pending).map(_key).toSet();
    _attempts.removeWhere((key, _) => !current.contains(key));
    // A processing response or text edit must not restart the polling window.
    if (current.difference(old).isNotEmpty) {
      _request();
    } else if (_eligible.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void setActive(bool value) {
    if (_disposed || _active == value) return;
    _active = value;
    _timer?.cancel();
    _timer = null;
    if (value) {
      _attempts.clear();
      _request();
    }
  }

  void _request() {
    if (!_active || _disposed) return;
    _timer?.cancel();
    _timer = null;
    if (_running) {
      _wake = true;
    } else {
      unawaited(_poll());
    }
  }

  Future<void> _poll() async {
    _running = true;
    _wake = false;
    try {
      final assets = _eligible.map((c) => (c.credentialId, c.avatarId)).toSet();
      for (final asset in assets) {
        if (!_active || _disposed) break;
        // Recheck after each await. References to one asset share the repo GET.
        final current = _eligible
            .where((c) => (c.credentialId, c.avatarId) == asset)
            .toList();
        await Future.wait(current.map(_refreshOne));
      }
    } finally {
      _running = false;
      if (_active && !_disposed && _eligible.isNotEmpty) {
        _timer = Timer(_wake ? Duration.zero : interval, _request);
      }
    }
  }

  Future<void> _refreshOne(Character c) async {
    final key = _key(c);
    _attempts[key] = (_attempts[key] ?? 0) + 1;
    try {
      final result = await refresh(c);
      if (_disposed) return;
      _characters = [
        for (final saved in _characters)
          if (_key(saved) == key)
            saved.copyWith(assetStatus: result.assetStatus)
          else
            saved,
      ];
    } on AppFailure {
      // A failed GET leaves the asset pending, with a bounded later retry.
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
  }
}
