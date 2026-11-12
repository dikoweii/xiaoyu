import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../ui/core/design.dart';
import 'app.dart';

/// Shows the supplied artwork while shaders and local storage initialize.
class XiaoyuBootstrap extends StatefulWidget {
  const XiaoyuBootstrap({super.key, required this.initialize});

  final Future<Widget> Function() initialize;

  @override
  State<XiaoyuBootstrap> createState() => _XiaoyuBootstrapState();
}

class _XiaoyuBootstrapState extends State<XiaoyuBootstrap> {
  late Future<Widget> _ready;

  @override
  void initState() {
    super.initState();
    _ready = _initialize();
  }

  Future<Widget> _initialize() async {
    // Paint the artwork before initialization can occupy the UI isolate.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return const SizedBox.shrink();
    await precacheImage(
      const AssetImage('assets/branding/launch.jpg'),
      context,
    );
    if (!mounted) return const SizedBox.shrink();
    return widget.initialize();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
    future: _ready,
    builder: (context, snapshot) {
      if (snapshot.hasData) return snapshot.requireData;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: XiaoyuDesign.theme,
        localeListResolutionCallback: (locales, _) => resolveLocale(locales),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: Transform.scale(
                    scale: 1.06,
                    child: Image.asset(
                      'assets/branding/launch.jpg',
                      key: const Key('launch-artwork'),
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                if (snapshot.hasError)
                  SafeArea(
                    child: Center(
                      child: Card(
                        margin: const EdgeInsets.all(24),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context).error('startup'),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => setState(() {
                                  _ready = _initialize();
                                }),
                                child: Text(
                                  AppLocalizations.of(context).refresh,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
