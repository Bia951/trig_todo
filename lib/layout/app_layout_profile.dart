import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Describes the presentation and input affordances available to the app.
///
/// Width determines how much UI fits, while the platform determines whether
/// mouse/keyboard-first affordances are appropriate. This keeps wide tablets
/// from accidentally behaving like desktop computers.
class AppLayoutProfile {
  const AppLayoutProfile._({
    required this.width,
    required this.isDesktopPlatform,
  });

  static const double compactDesktopBreakpoint = 700;
  static const double tabletNavigationBreakpoint = 840;
  static const double dockedPanelBreakpoint = 1024;

  final double width;
  final bool isDesktopPlatform;

  bool get usesDesktopInteractions =>
      isDesktopPlatform && width >= compactDesktopBreakpoint;

  bool get hasPersistentNavigation => isDesktopPlatform
      ? width >= compactDesktopBreakpoint
      : width >= tabletNavigationBreakpoint;

  /// Native desktop has a fixed third column once the task canvas can still
  /// remain useful beside the navigation rail and the detail sidebar.
  bool get hasDockedDetailsPanel =>
      usesDesktopInteractions && width >= dockedPanelBreakpoint;

  /// Below the fixed three-column breakpoint, the same sidebar becomes an
  /// on-demand right-side drawer rather than a centered dialog.
  bool get usesSidePanel => true;

  static AppLayoutProfile of(BuildContext context) {
    final platform = defaultTargetPlatform;
    final isDesktopPlatform =
        kIsWeb ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;
    return AppLayoutProfile._(
      width: MediaQuery.sizeOf(context).width,
      isDesktopPlatform: isDesktopPlatform,
    );
  }
}
