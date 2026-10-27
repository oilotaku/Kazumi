import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kazumi/bean/widget/side_panel_transition.dart';

class VideoSidePanel extends StatefulWidget {
  const VideoSidePanel({
    super.key,
    required this.fullscreen,
    required this.child,
    this.disableAnimations = false,
    this.onOpened,
    this.onClosed,
  });

  final bool fullscreen;
  final bool disableAnimations;
  final Widget child;
  final VoidCallback? onOpened;
  final VoidCallback? onClosed;

  @override
  State<VideoSidePanel> createState() => VideoSidePanelState();
}

class VideoSidePanelState extends State<VideoSidePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: SidePanelTransition.duration,
  );
  late final Animation<double> _opacity =
      _animation.drive(CurveTween(curve: Curves.easeIn));

  // Lets the system back key close the panel before leaving the page.
  LocalHistoryEntry? _historyEntry;
  ModalRoute<dynamic>? _historyRoute;

  bool get _isOpening =>
      _animation.status == AnimationStatus.forward ||
      _animation.status == AnimationStatus.completed;

  void toggle() {
    if (_isOpening) {
      close();
    } else {
      if (widget.disableAnimations) {
        _animation.value = 1;
      } else {
        _animation.forward();
      }
      _historyEntry = LocalHistoryEntry(onRemove: _onHistoryRemoved);
      _historyRoute = ModalRoute.of(context);
      _historyRoute?.addLocalHistoryEntry(_historyEntry!);
      widget.onOpened?.call();
    }
  }

  void _removeHistoryEntry() {
    final entry = _historyEntry;
    _historyEntry = null;
    // A route that is already leaving drops its local history itself.
    if (entry != null && (_historyRoute?.isActive ?? false)) entry.remove();
  }

  void _onHistoryRemoved() {
    if (_historyEntry == null) return;
    _historyEntry = null;
    close();
  }

  void close() {
    _removeHistoryEntry();
    if (widget.disableAnimations) {
      _animation.value = 0;
    } else {
      _animation.reverse();
    }
    widget.onClosed?.call();
  }

  @override
  void didUpdateWidget(VideoSidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset before rendering the new mode to avoid a sidebar flash.
    if (oldWidget.fullscreen != widget.fullscreen) {
      _animation.value = 0;
      _removeHistoryEntry();
    }
  }

  @override
  void dispose() {
    _removeHistoryEntry();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            if (_animation.isDismissed) return const SizedBox.shrink();
            return Stack(
              alignment: Alignment.centerRight,
              children: [
                FadeTransition(
                  opacity: _opacity,
                  child: GestureDetector(
                    onTap: close,
                    child: SizedBox.expand(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SidePanelTransition(animation: _animation, child: child!),
              ],
            );
          },
          child: SizedBox(
            // Keep space outside the panel for dismissal.
            width: math.min(constraints.maxWidth * 0.9,
                (constraints.maxWidth / 3).clamp(320.0, 420.0)),
            height: constraints.maxHeight,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(28),
                bottomStart: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              // Consume the hidden status-bar inset for the entire overlay.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeLeft: true,
                child: SafeArea(child: widget.child),
              ),
            ),
          ),
        ),
      );
}
