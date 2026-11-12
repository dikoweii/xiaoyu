import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

import '../../data/services/agora_rtc.dart';
import '../../domain/call_ports.dart';
import '../../domain/models.dart';

class RtcVideoSurface extends StatefulWidget {
  const RtcVideoSurface({
    super.key,
    required this.session,
    required this.video,
  });
  final RtcSession? session;
  final RemoteVideo video;

  @override
  State<RtcVideoSurface> createState() => _RtcVideoSurfaceState();
}

class _RtcVideoSurfaceState extends State<RtcVideoSurface> {
  VideoViewController? _controller;

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    if (session is AgoraRtcSession && session.engine != null) {
      _controller = VideoViewController.remote(
        rtcEngine: session.engine!,
        useFlutterTexture: defaultTargetPlatform == TargetPlatform.iOS,
        canvas: VideoCanvas(
          uid: widget.video.uid,
          renderMode: RenderModeType.renderModeHidden,
        ),
        connection: RtcConnection(channelId: widget.video.roomId),
      );
    }
  }

  @override
  Widget build(BuildContext context) => _controller == null
      ? const SizedBox.expand()
      : AgoraVideoView(controller: _controller!);
}
