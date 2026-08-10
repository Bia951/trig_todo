import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A consistent right-hand presentation for todo details and editing.
///
/// On narrow canvases it overlays the current page; wide desktop layouts can
/// use [TodoSidePanelSurface] directly as their reserved third column.
class TodoSidePanelOverlay extends StatefulWidget {
  const TodoSidePanelOverlay({
    required this.child,
    required this.onDismiss,
    super.key,
  });

  final Widget child;
  final VoidCallback onDismiss;

  @override
  State<TodoSidePanelOverlay> createState() => _TodoSidePanelOverlayState();
}

class _TodoSidePanelOverlayState extends State<TodoSidePanelOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _panelController;
  late final Animation<double> _panelProgress;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _panelProgress = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _panelController.forward();
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  void _updateDrag(DragUpdateDetails details, double panelWidth) {
    final nextValue = (_panelController.value - details.delta.dx / panelWidth)
        .clamp(0.0, 1.0)
        .toDouble();
    _panelController.value = nextValue;
  }

  Future<void> _finishDrag(DragEndDetails details, double panelWidth) async {
    final travelled = (1 - _panelController.value) * panelWidth;
    final shouldDismiss =
        travelled > panelWidth * 0.16 ||
        details.velocity.pixelsPerSecond.dx > 700;
    if (!shouldDismiss) {
      await _panelController.forward();
      return;
    }

    await _panelController.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Keep a visible sliver of the page even on phones so tapping the
          // scrim remains a reliable dismissal affordance.
          final panelWidth = (constraints.maxWidth - 40)
              .clamp(0, 360)
              .toDouble();
          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  await _panelController.reverse();
                  if (mounted) widget.onDismiss();
                },
                child: AnimatedBuilder(
                  animation: _panelController,
                  builder: (context, _) => ColoredBox(
                    color: theme.colorScheme.scrim.withValues(
                      alpha: 0.14 * _panelProgress.value,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedBuilder(
                  animation: _panelController,
                  child: SizedBox(
                    width: panelWidth,
                    child: Focus(
                      autofocus: true,
                      onKeyEvent: (_, event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.escape) {
                          _panelController.reverse().whenComplete(() {
                            if (mounted) widget.onDismiss();
                          });
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TodoSidePanelSurface(
                        onDragUpdate: (details) =>
                            _updateDrag(details, panelWidth),
                        onDragEnd: (details) =>
                            _finishDrag(details, panelWidth),
                        child: widget.child,
                      ),
                    ),
                  ),
                  builder: (context, panel) => Transform.translate(
                    offset: Offset(panelWidth * (1 - _panelProgress.value), 0),
                    child: Opacity(opacity: _panelProgress.value, child: panel),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Adds the intentionally narrow right-swipe dismissal affordance to a pane.
class TodoSidePanelSurface extends StatelessWidget {
  const TodoSidePanelSurface({
    required this.child,
    this.onDismiss,
    this.onDragUpdate,
    this.onDragEnd,
    super.key,
  });

  final Widget child;
  final VoidCallback? onDismiss;
  final ValueChanged<DragUpdateDetails>? onDragUpdate;
  final ValueChanged<DragEndDetails>? onDragEnd;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 24,
          child: _NarrowDismissStrip(
            onDismiss: onDismiss,
            onDragUpdate: onDragUpdate,
            onDragEnd: onDragEnd,
          ),
        ),
      ],
    );
  }
}

class _NarrowDismissStrip extends StatefulWidget {
  const _NarrowDismissStrip({
    this.onDismiss,
    this.onDragUpdate,
    this.onDragEnd,
  });

  final VoidCallback? onDismiss;
  final ValueChanged<DragUpdateDetails>? onDragUpdate;
  final ValueChanged<DragEndDetails>? onDragEnd;

  @override
  State<_NarrowDismissStrip> createState() => _NarrowDismissStripState();
}

class _NarrowDismissStripState extends State<_NarrowDismissStrip> {
  double _dragDistance = 0;

  void _finishDrag(DragEndDetails details) {
    final wasRightSwipe =
        _dragDistance > 54 || details.velocity.pixelsPerSecond.dx > 700;
    _dragDistance = 0;
    if (wasRightSwipe) widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        final callback = widget.onDragUpdate;
        if (callback != null) {
          callback(details);
          return;
        }
        _dragDistance += details.delta.dx;
      },
      onHorizontalDragEnd: widget.onDragEnd ?? _finishDrag,
      child: const SizedBox.expand(),
    );
  }
}
