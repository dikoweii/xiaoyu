import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/models.dart';
import '../domain/call_ports.dart';
import '../presentation/controllers.dart';
import 'call_composer.dart';
import 'core/design.dart';
import 'core/widgets.dart';
import 'integrations/rtc_video_surface.dart';

final presenceAnimationProvider = Provider<bool>((ref) => true);

class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key});
  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  final input = TextEditingController();
  bool composerOpen = false, leaving = false;

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, coordinator = ref.read(controllerProvider).calls;
    final call = ref.watch(callProvider).value ?? coordinator.snapshot;
    final preparing =
        call.active && !call.interactive && call.phase != CallPhase.ending;
    if (preparing) {
      return AppPage(
        background: _CallBackdrop(
          call: call,
          session: coordinator.rtc,
          preparing: true,
        ),
        body: SafeArea(
          key: const Key('call-loading'),
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              key: const Key('call-scroll'),
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, box.maxHeight - 48),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: math.max(0, box.maxHeight * .14 - 24),
                      ),
                      child: Column(
                        children: [
                          _ConnectingPresence(
                            character: call.character,
                            animate: ref.watch(presenceAnimationProvider),
                          ),
                          gap(24),
                          Text(
                            call.character?.name ?? s.appName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          gap(14),
                          Text(
                            s.status(call.phase.name),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: XiaoyuDesign.lavender,
                            ),
                          ),
                          gap(10),
                          Text(
                            s.connectPreparing,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: XiaoyuDesign.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 48, bottom: 16),
                      child: Column(
                        children: [
                          SizedBox.square(
                            dimension: 56,
                            child: Semantics(
                              key: const Key('end-call'),
                              label: s.cancelConnection,
                              button: true,
                              excludeSemantics: true,
                              onTap: () =>
                                  unawaited(guarded(context, _endAndLeave)),
                              child: IconButton.filled(
                                tooltip: s.cancelConnection,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFFFF3B30),
                                  shape: const CircleBorder(),
                                ),
                                icon: const Icon(Icons.close, size: 24),
                                onPressed: () =>
                                    unawaited(guarded(context, _endAndLeave)),
                              ),
                            ),
                          ),
                          gap(10),
                          Text(
                            s.cancelConnection,
                            style: const TextStyle(
                              fontSize: 11,
                              color: XiaoyuDesign.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final platformBackdrop =
        defaultTargetPlatform == TargetPlatform.android && call.video != null;
    return AppPage(
      background: _CallBackdrop(
        call: call,
        session: coordinator.rtc,
        preparing: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            key: const Key('call-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: XiaoyuDesign.contentWidth,
                  minHeight: math.max(0, box.maxHeight - 28),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: LiquidGlassLens(
                        key: const Key('call-status'),
                        style:
                            XiaoyuDesign.glass(
                              context,
                              lite: platformBackdrop,
                            ).copyWith(
                              blur: 10,
                              shape: const LiquidGlassShape(cornerRadius: 99),
                            ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (call.interactive) ...[
                                _CallPresence(
                                  animate: ref.watch(presenceAnimationProvider),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  call.character?.name ?? s.appName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _CallDuration(
                                elapsed: () => coordinator.elapsed,
                                running:
                                    call.active &&
                                    call.controlReady &&
                                    call.phase != CallPhase.ending,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (call.error != null)
                          AppSurface(child: Text(s.error(call.error!))),
                        if (call.phase == CallPhase.pending)
                          AppSurface(child: Text(s.endPending)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _control(
                              key: const Key('toggle-microphone'),
                              s: call.muted ? s.unmute : s.mute,
                              icon: call.muted
                                  ? CupertinoIcons.mic_slash
                                  : CupertinoIcons.mic,
                              action: call.interactive
                                  ? coordinator.mute
                                  : null,
                            ),
                            _control(
                              key: const Key('toggle-playback'),
                              s: call.playbackMuted
                                  ? s.unmutePlayback
                                  : s.mutePlayback,
                              icon: call.playbackMuted
                                  ? CupertinoIcons.speaker_slash
                                  : CupertinoIcons.speaker_2,
                              action: call.interactive
                                  ? coordinator.togglePlayback
                                  : null,
                            ),
                            _control(
                              key: const Key('open-call-composer'),
                              s: s.keyboardChat,
                              icon: CupertinoIcons.keyboard,
                              action: call.interactive ? _openComposer : null,
                            ),
                            _control(
                              key: const Key('end-call'),
                              s: s.endCall,
                              icon: CupertinoIcons.phone_down_fill,
                              destructive: true,
                              action: _endAndLeave,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _control({
    Key? key,
    required String s,
    required IconData icon,
    Future<void> Function()? action,
    bool destructive = false,
  }) => AppIconButton(
    key: key,
    icon: Icon(icon),
    label: s,
    destructive: destructive,
    lite:
        defaultTargetPlatform == TargetPlatform.android &&
        ref.read(controllerProvider).calls.snapshot.video != null,
    onPressed: action == null
        ? null
        : () => unawaited(guarded(context, action)),
  );

  Future<void> _endAndLeave() async {
    if (leaving) return;
    leaving = true;
    // The app owns cleanup, so navigation does not wait for native release,
    // late creation responses or platform billing reconciliation.
    final ending = ref.read(controllerProvider).calls.end();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
    await ending;
  }

  Future<void> _openComposer() async {
    if (composerOpen) return;
    composerOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x26000000),
        builder: (_) => CallComposer(input: input),
      );
    } finally {
      composerOpen = false;
    }
  }
}

/// Refreshes only the time label, using the coordinator's existing stopwatch.
class _CallDuration extends StatefulWidget {
  const _CallDuration({required this.elapsed, required this.running});
  final Duration Function() elapsed;
  final bool running;

  @override
  State<_CallDuration> createState() => _CallDurationState();
}

class _CallDurationState extends State<_CallDuration> {
  Timer? _timer;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _CallDuration oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    _seconds = widget.elapsed().inSeconds;
    if (widget.running) {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        final seconds = widget.elapsed().inSeconds;
        if (seconds != _seconds) setState(() => _seconds = seconds);
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
    '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}',
    key: const Key('call-duration'),
    style: const TextStyle(
      fontSize: 12,
      color: Color(0x99FFFFFF),
      fontFeatures: [FontFeature.tabularFigures()],
    ),
  );
}

/// A live indicator that respects the system's reduced motion setting.
class _CallPresence extends StatefulWidget {
  const _CallPresence({required this.animate});
  final bool animate;

  @override
  State<_CallPresence> createState() => _CallPresenceState();
}

class _CallPresenceState extends State<_CallPresence>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final opacity = animation
      .drive(CurveTween(curve: Curves.easeInOut))
      .drive(Tween<double>(begin: .4, end: 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant _CallPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.animate && !MediaQuery.disableAnimationsOf(context)) {
      if (!animation.isAnimating) animation.repeat(reverse: true);
    } else {
      animation.stop();
      animation.value = 1;
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.s.status('connected'),
    child: FadeTransition(
      key: const Key('call-live-indicator'),
      opacity: opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF35D39A),
          boxShadow: [
            BoxShadow(color: Color(0x6635D39A), blurRadius: 6, spreadRadius: 1),
          ],
        ),
      ),
    ),
  );
}

/// One stable video element survives the loading-to-call body transition.
class _CallBackdrop extends StatelessWidget {
  const _CallBackdrop({
    required this.call,
    required this.session,
    required this.preparing,
  });
  final CallSnapshot call;
  final RtcSession? session;
  final bool preparing;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      if (call.video != null && call.active && call.phase != CallPhase.ending)
        RtcVideoSurface(
          key: ValueKey('${call.video!.roomId}:${call.video!.uid}'),
          session: session,
          video: call.video!,
        )
      else if (call.character != null)
        Portrait(call.character!, height: double.infinity)
      else
        const _CallGlow(),
      // Keep the native video mounted beneath the loading cover. A rendered
      // first-frame callback is required before the coordinator is connected.
      if (preparing) const _CallGlow(),
      if (!preparing)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x6608090D), Color(0x0008090D), Color(0xDD08090D)],
              stops: [0, .35, 1],
            ),
          ),
        ),
    ],
  );
}

class _CallGlow extends StatelessWidget {
  const _CallGlow();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        colors: [Color(0xFF252031), XiaoyuDesign.canvas],
        radius: .7,
      ),
    ),
  );
}

class _ConnectingPresence extends StatefulWidget {
  const _ConnectingPresence({required this.character, required this.animate});
  final Character? character;
  final bool animate;
  @override
  State<_ConnectingPresence> createState() => _ConnectingPresenceState();
}

class _ConnectingPresenceState extends State<_ConnectingPresence>
    with SingleTickerProviderStateMixin {
  late final pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  void _syncAnimation() {
    final enabled =
        widget.animate &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled && !pulse.isAnimating) {
      pulse.repeat();
    } else if (!enabled) {
      pulse.stop();
      pulse.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _ConnectingPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: const Key('connecting-particles'),
    child: SizedBox.square(
      dimension: 256,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _PresenceDots(pulse))),
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x18FFFFFF),
              border: Border.all(color: const Color(0x40FFFFFF)),
            ),
            child: ClipOval(
              child: widget.character == null
                  ? const Icon(Icons.person_outline)
                  : Portrait(widget.character!, height: 88),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PresenceDots extends CustomPainter {
  _PresenceDots(this.animation) : super(repaint: animation);
  final Animation<double> animation;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final phase = animation.value * math.pi * 2;
    final scale = math.min(size.width, size.height) / 256;
    final paint = Paint();
    for (final radius in [88.0, 72.0]) {
      final wave = (math.sin(phase - radius / 25) + 1) / 2;
      final r = (radius + 2 * wave) * scale;
      canvas.drawCircle(
        center,
        r,
        paint
          ..style = PaintingStyle.fill
          ..color = XiaoyuDesign.lavender.withValues(alpha: .025 + .025 * wave),
      );
      canvas.drawCircle(
        center,
        r,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = scale
          ..color = XiaoyuDesign.lavender.withValues(alpha: .08 + .06 * wave),
      );
    }
    paint.style = PaintingStyle.fill;
    for (var ring = 0; ring < 4; ring++) {
      final wave = (math.sin(phase - ring * .8) + 1) / 2;
      final radius = (60 + ring * 20 + 2 * wave) * scale;
      for (var i = 0; i < 64; i++) {
        final angle = i * math.pi / 32;
        final sparkle = math
            .pow((math.sin(phase + i * 2.4 + ring) + 1) / 2, 3)
            .toDouble();
        canvas.drawCircle(
          center + Offset(math.cos(angle), math.sin(angle)) * radius,
          (1 + .35 * sparkle) * scale,
          paint
            ..color = XiaoyuDesign.lavender.withValues(
              alpha: (.15 - ring * .025) * (.45 + .55 * wave) + .16 * sparkle,
            ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PresenceDots oldDelegate) =>
      animation != oldDelegate.animation;
}

class CallTile extends StatelessWidget {
  const CallTile(this.record, {super.key});
  final CallRecord record;
  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('history-${record.id}'),
    borderRadius: BorderRadius.circular(14),
    onTap: () => context.push('/history/${record.id}'),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 48,
            child: Portrait(record.character, height: 48),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.character.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                gap(5),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      DateFormat.yMd(Localizations.localeOf(context).toString())
                          .add_Hm()
                          .format(record.createdAt.toLocal()),
                      style: const TextStyle(
                        fontSize: 12,
                        color: XiaoyuDesign.muted,
                      ),
                    ),
                    Text(
                      context.s.status(record.phase),
                      style: TextStyle(
                        fontSize: 12,
                        color: record.phase == 'failed'
                            ? Colors.redAccent
                            : !record.endConfirmed
                            ? XiaoyuDesign.lavender
                            : XiaoyuDesign.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 14,
            color: XiaoyuDesign.muted,
          ),
        ],
      ),
    ),
  );
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, this.id});
  final String? id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s, controller = ref.read(controllerProvider);
    return AppPage(
      title: s.history,
      body: ref
          .watch(historyProvider)
          .when(
            loading: () => const Center(child: AppLoading()),
            error: (_, _) => Center(child: Text(s.error('storage'))),
            data: (records) {
              if (id == null) {
                return Builder(
                  builder: (context) {
                    final insets = MediaQuery.paddingOf(context);
                    return SafeArea(
                      top: false,
                      bottom: false,
                      child: ListView.builder(
                        key: const Key('history-list'),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          insets.top + 8,
                          16,
                          insets.bottom + 32,
                        ),
                        itemCount: records.isEmpty ? 1 : records.length,
                        itemBuilder: (context, index) => records.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Center(
                                  child: Text(
                                    s.noHistory,
                                    style: const TextStyle(
                                      color: XiaoyuDesign.muted,
                                    ),
                                  ),
                                ),
                              )
                            : CallTile(records[index]),
                      ),
                    );
                  },
                );
              }
              final record = records.where((r) => r.id == id).firstOrNull;
              if (record == null) return Center(child: Text(s.noHistory));
              return PageBody(
                children: [
                  section(context, record.character.name),
                  Text(s.status(record.phase)),
                  gap(),
                  Text(
                    record.billedSeconds == null || record.creditsCost == null
                        ? s.usagePending
                        : s.usage(record.billedSeconds!, record.creditsCost!),
                  ),
                  gap(),
                  if (!record.endConfirmed && record.phase != 'failed')
                    Text(
                      record.liveId == null ? s.unknownCreation : s.endPending,
                    ),
                  if (record.liveId != null)
                    AppButton(
                      onPressed: () =>
                          guarded(context, () => controller.reconcile(record)),
                      child: Text(s.checkStatus),
                    ),
                  section(context, s.chat),
                  ref
                      .watch(messagesProvider(record.id))
                      .when(
                        loading: () => const AppLoading(),
                        error: (_, _) => Text(s.error('storage')),
                        data: (messages) => Column(
                          children: [
                            if (messages.isEmpty) Text(s.emptyTranscript),
                            for (final m in messages)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  m.speaker == 'user'
                                      ? Icons.person_outline
                                      : Icons.auto_awesome,
                                ),
                                title: Text(m.content),
                              ),
                          ],
                        ),
                      ),
                  if (record.endConfirmed || record.phase == 'failed')
                    AppButton(
                      onPressed: () => guarded(context, () async {
                        if (!await confirm(
                          context,
                          s.delete,
                          s.history,
                          destructive: true,
                        )) {
                          return;
                        }
                        await controller.deleteCall(record.id);
                        if (context.mounted) context.pop();
                      }),
                      child: Text(s.delete),
                    ),
                ],
              );
            },
          ),
    );
  }
}
