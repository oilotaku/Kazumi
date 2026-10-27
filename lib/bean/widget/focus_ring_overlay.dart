import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Draws a visible ring around the focused control while navigating with a
/// remote or keyboard. Material's own focus overlays are too faint on TV and
/// are often hidden under cover images.
class FocusRingOverlay extends StatefulWidget {
  const FocusRingOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<FocusRingOverlay> createState() => _FocusRingOverlayState();
}

class _FocusRingOverlayState extends State<FocusRingOverlay> {
  final _rect = ValueNotifier<Rect?>(null);
  final _overlayKey = GlobalKey();
  bool _tracking = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_scheduleTrack);
    FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);
    _scheduleTrack();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_scheduleTrack);
    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);
    _rect.dispose();
    super.dispose();
  }

  void _onHighlightModeChanged(FocusHighlightMode _) => _scheduleTrack();

  // Re-measures after every frame that actually renders, so the ring follows
  // scrolling and animations without scheduling frames of its own.
  void _scheduleTrack({bool requestFrame = true}) {
    if (!_tracking) {
      _tracking = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _tracking = false;
        if (!mounted) return;
        final rect = _measure();
        if (rect != _rect.value) _rect.value = rect;
        if (rect != null) _scheduleTrack(requestFrame: false);
      });
    }
    if (requestFrame) SchedulerBinding.instance.ensureVisualUpdate();
  }

  Rect? _measure() {
    final manager = FocusManager.instance;
    if (manager.highlightMode != FocusHighlightMode.traditional) return null;
    final node = manager.primaryFocus;
    if (node == null || node is FocusScopeNode || !node.canRequestFocus) {
      return null;
    }
    final target = node.context?.findRenderObject();
    final overlay = _overlayKey.currentContext?.findRenderObject();
    if (target is! RenderBox ||
        overlay is! RenderBox ||
        !target.attached ||
        !target.hasSize ||
        !overlay.hasSize) {
      return null;
    }
    final topLeft = target.localToGlobal(Offset.zero, ancestor: overlay);
    final rect = topLeft & target.size;
    final area = overlay.size.width * overlay.size.height;
    // Large focus targets such as the video surface need no ring.
    if (rect.isEmpty || rect.width * rect.height > area * 0.5) return null;
    return rect;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      key: _overlayKey,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _FocusRingPainter(
                  rect: _rect,
                  color: colors.primary,
                  outline: colors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter({
    required this.rect,
    required this.color,
    required this.outline,
  }) : super(repaint: rect);

  final ValueNotifier<Rect?> rect;
  final Color color;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final r = rect.value;
    if (r == null) return;
    final ring = RRect.fromRectAndRadius(
      r.inflate(3),
      const Radius.circular(14),
    );
    // The thin light edge keeps the ring visible on primary-coloured items.
    canvas.drawRRect(
      ring.inflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = outline,
    );
    canvas.drawRRect(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) =>
      oldDelegate.rect != rect ||
      oldDelegate.color != color ||
      oldDelegate.outline != outline;
}
