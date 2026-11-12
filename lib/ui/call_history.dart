import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/models.dart';
import '../domain/call_ports.dart';
import '../presentation/controllers.dart';
import 'account_editor.dart';
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
  Timer? timer;
  final input = TextEditingController();
  bool actionMode = false, sending = false, leaving = false;
  @override
  void initState() {
    super.initState();
    if (ref.read(presenceAnimationProvider)) {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, coordinator = ref.read(controllerProvider).calls;
    final call = ref.watch(callProvider).value ?? coordinator.snapshot;
    final preparing =
        call.active && !call.interactive && call.phase != CallPhase.ending;
    final elapsed = coordinator.elapsed.inSeconds;
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 256,
                      height: 256,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Positioned.fill(
                            child: CustomPaint(painter: _PresenceDots()),
                          ),
                          ClipOval(
                            child: SizedBox(
                              width: 96,
                              height: 96,
                              child: call.character == null
                                  ? const Icon(Icons.person_outline)
                                  : Portrait(call.character!, height: 96),
                            ),
                          ),
                        ],
                      ),
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
                    gap(56),
                    SizedBox(
                      width: 220,
                      child: AppButton(
                        key: const Key('end-call'),
                        primary: true,
                        icon: const Icon(Icons.close, color: Color(0xFFFF453A)),
                        onPressed: () =>
                            unawaited(guarded(context, _endAndLeave)),
                        child: Text(s.cancelConnection),
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
                    Row(
                      children: [
                        Expanded(
                          child: AppSurface(
                            radius: 99,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Text(
                              '${call.character?.name ?? s.appName} · ${s.status(call.phase.name)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppSurface(
                          radius: 99,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            '${elapsed ~/ 60}:${(elapsed % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        _more(call),
                      ],
                    ),
                    SizedBox(height: math.max(60, box.maxHeight * .40)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (call.error != null)
                          AppSurface(child: Text(s.error(call.error!))),
                        if (call.phase == CallPhase.pending)
                          AppSurface(child: Text(s.endPending)),
                        if (call.callId != null)
                          ref
                              .watch(messagesProvider(call.callId!))
                              .when(
                                data: (messages) => AppSurface(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    messages.lastOrNull?.content ??
                                        s.emptyTranscript,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                loading: () =>
                                    const Center(child: AppLoading()),
                                error: (_, _) => Text(s.error('storage')),
                              ),
                        gap(16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                key: const Key('chat-input'),
                                controller: input,
                                enabled: call.interactive && !sending,
                                maxLength: actionMode ? 200 : 1000,
                                minLines: 1,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: actionMode
                                      ? s.actionHint
                                      : s.chatHint,
                                  counterText: '',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppIconButton(
                              key: const Key('chat-send'),
                              lite: platformBackdrop,

                              icon: const Icon(Icons.arrow_upward),
                              label: s.send,
                              onPressed: call.interactive && !sending
                                  ? () => unawaited(_send())
                                  : null,
                            ),
                          ],
                        ),
                        gap(16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _control(
                              s: call.muted ? s.unmute : s.mute,
                              icon: call.muted
                                  ? CupertinoIcons.mic_slash
                                  : CupertinoIcons.mic,
                              action: call.interactive
                                  ? coordinator.mute
                                  : null,
                            ),
                            _control(
                              s: s.audioRoute,
                              icon: CupertinoIcons.speaker_2,
                              action: call.interactive
                                  ? () => _route(call.route)
                                  : null,
                            ),
                            _control(
                              s: s.actions,
                              icon: actionMode
                                  ? CupertinoIcons.keyboard
                                  : CupertinoIcons.bolt,
                              action: call.interactive
                                  ? () async =>
                                        setState(() => actionMode = !actionMode)
                                  : null,
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

  Widget _more(CallSnapshot call) => PopupMenuButton<String>(
    key: const Key('call-menu'),
    tooltip: '',
    icon: Icon(CupertinoIcons.ellipsis, semanticLabel: context.s.more),
    itemBuilder: (context) => [
      PopupMenuItem(
        value: 'interrupt',
        enabled: call.interactive,
        child: Text(context.s.interrupt),
      ),
      PopupMenuItem(
        value: 'voice',
        enabled: call.interactive,
        child: Text(context.s.voice),
      ),
      if (call.callId != null)
        PopupMenuItem(value: 'transcript', child: Text(context.s.transcript)),
    ],
    onSelected: (action) => switch (action) {
      'interrupt' => unawaited(
        guarded(context, ref.read(controllerProvider).calls.interrupt),
      ),
      'voice' => unawaited(_changeVoice(call)),
      _ => unawaited(_transcript(call.callId!)),
    },
  );

  Future<void> _changeVoice(CallSnapshot call) async {
    final voice = await chooseVoice(context, call.voice ?? 'Serena');
    if (voice != null && mounted) {
      await guarded(
        context,
        () => ref.read(controllerProvider).calls.changeVoice(voice),
      );
    }
  }

  Future<void> _transcript(String callId) => sheet<void>(
    context,
    Consumer(
      builder: (context, ref, _) => ref
          .watch(messagesProvider(callId))
          .when(
            data: (messages) => Column(
              children: [
                for (final message in messages)
                  ListTile(
                    title: Text(message.content),
                    leading: Icon(
                      message.speaker == 'user'
                          ? CupertinoIcons.person
                          : CupertinoIcons.sparkles,
                    ),
                  ),
              ],
            ),
            loading: () => const AppLoading(),
            error: (_, _) => Text(context.s.error('storage')),
          ),
    ),
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

  Future<void> _send() async {
    setState(() => sending = true);
    await guarded(context, () async {
      final coordinator = ref.read(controllerProvider).calls;
      if (actionMode) {
        coordinator.sendAction(input.text);
      } else {
        await coordinator.sendText(input.text);
      }
      input.clear();
      if (mounted && actionMode) notice(context, context.s.sent);
    });
    if (mounted) setState(() => sending = false);
  }

  Future<void> _route(String current) async {
    final selected = await sheet<String>(context, const RoutePicker());
    if (selected != null && mounted) {
      await guarded(
        context,
        () => ref.read(controllerProvider).calls.setRoute(selected),
      );
    }
  }
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

class _PresenceDots extends CustomPainter {
  const _PresenceDots();
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var ring = 0; ring < 4; ring++) {
      final radius = 68 + ring * 18.0;
      for (var i = 0; i < 64; i++) {
        final angle = i * math.pi / 32;
        canvas.drawCircle(
          center + Offset(math.cos(angle), math.sin(angle)) * radius,
          1.3,
          Paint()
            ..color = XiaoyuDesign.lavender.withValues(alpha: .32 - ring * .06),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PresenceDots oldDelegate) => false;
}

class RoutePicker extends StatelessWidget {
  const RoutePicker({super.key});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      section(context, context.s.audioRoute),
      for (final e in {
        'speakerphone': context.s.speaker,
        'earpiece': context.s.earpiece,
        'routeDefault': context.s.systemRoute,
      }.entries)
        ListTile(title: Text(e.value), onTap: () => context.pop(e.key)),
    ],
  );
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
