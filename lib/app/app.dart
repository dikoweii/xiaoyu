import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../ui/screens.dart';
import '../ui/core/design.dart';
import 'runtime.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', pageBuilder: (_, s) => _page(s, const HomeScreen())),
      GoRoute(
        path: '/account',
        pageBuilder: (_, s) => _page(s, const AccountScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, s) => _page(s, const SettingsScreen()),
      ),
      GoRoute(
        path: '/edit/:id',
        pageBuilder: (_, s) =>
            _page(s, EditorScreen(id: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/call',
        pageBuilder: (_, s) => _page(s, const CallScreen()),
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (_, s) => _page(s, const HistoryScreen()),
      ),
      GoRoute(
        path: '/history/:id',
        pageBuilder: (_, s) =>
            _page(s, HistoryScreen(id: s.pathParameters['id'])),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

// Use the SDK page explicitly: go_router's automatic app detection uses
// material_ui, while Xiaoyu uses Flutter's MaterialApp. SDK transitions provide
// interactive iOS edge navigation and the Android platform transition.
MaterialPage<void> _page(GoRouterState state, Widget child) =>
    MaterialPage<void>(
      key: state.pageKey,
      name: state.uri.toString(),
      restorationId: state.pageKey.value,
      child: child,
    );

Locale resolveLocale(List<Locale>? locales) {
  for (final locale in locales ?? <Locale>[]) {
    if (locale.languageCode == 'zh') return const Locale('zh');
    if (locale.languageCode == 'en') return const Locale('en');
  }
  return const Locale('en');
}

class XiaoyuApp extends ConsumerStatefulWidget {
  const XiaoyuApp({super.key});
  @override
  ConsumerState<XiaoyuApp> createState() => _XiaoyuAppState();
}

class _XiaoyuAppState extends ConsumerState<XiaoyuApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(ref.read(runtimeProvider).calls.end('app_background'));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      localeListResolutionCallback: (locales, _) => resolveLocale(locales),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: XiaoyuDesign.theme,
      builder: (context, child) => TooltipVisibility(
        visible: false,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
