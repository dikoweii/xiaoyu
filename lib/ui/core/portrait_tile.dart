import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design.dart';

/// Fits the rounded image itself, keeping its controls and caption on the photo.
class PortraitTile extends StatefulWidget {
  const PortraitTile({
    super.key,
    required this.image,
    required this.name,
    required this.description,
    required this.onTap,
    this.actionLabel,
    this.menu,
  });

  final ImageProvider<Object>? image;
  final String name, description;
  final VoidCallback onTap;
  final String? actionLabel;
  final Widget? menu;

  @override
  State<PortraitTile> createState() => _PortraitTileState();
}

class _PortraitTileState extends State<PortraitTile> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double _aspectRatio = 3 / 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(PortraitTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) _resolveImage();
  }

  void _resolveImage() {
    final stream = widget.image?.resolve(
      createLocalImageConfiguration(context),
    );
    if (_stream?.key == stream?.key) return;
    _detachImage();
    _aspectRatio = 3 / 4;
    _stream = stream;
    _listener = ImageStreamListener(
      (info, _) {
        final ratio = info.image.width / info.image.height;
        info.dispose();
        if (mounted && ratio != _aspectRatio) {
          setState(() => _aspectRatio = ratio);
        }
      },
      // Image.errorBuilder presents the shared placeholder on decode failure.
      onError: (Object _, StackTrace? _) {},
    );
    stream?.addListener(_listener!);
  }

  void _detachImage() {
    if (_listener != null) _stream?.removeListener(_listener!);
  }

  @override
  void dispose() {
    _detachImage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.hasBoundedHeight
          ? math.min(constraints.maxWidth, constraints.maxHeight * _aspectRatio)
          : constraints.maxWidth;
      return Align(
        alignment: Alignment.topLeft,
        widthFactor: 1,
        heightFactor: 1,
        child: SizedBox(
          width: width,
          height: width / _aspectRatio,
          child: ClipRRect(
            key: const Key('portrait-tile-image'),
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.image case final image?)
                  Image(
                    image: image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const PortraitPlaceholder(),
                  )
                else
                  const PortraitPlaceholder(),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xD9000000)],
                          stops: [.45, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xE6FFFFFF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: Semantics(
                    button: true,
                    label: widget.actionLabel ?? widget.name,
                    onTap: widget.onTap,
                    child: InkWell(
                      excludeFromSemantics: true,
                      onTap: widget.onTap,
                    ),
                  ),
                ),
                if (widget.menu case final menu?)
                  Positioned(top: 4, right: 4, child: menu),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class PortraitPlaceholder extends StatelessWidget {
  const PortraitPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFF282435),
    child: Center(
      child: Icon(
        Icons.person_outline_rounded,
        size: 64,
        color: XiaoyuDesign.lavender,
      ),
    ),
  );
}
