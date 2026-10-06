import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/errors/app_exception.dart';

enum AppToastType { error, success, info, warning }

class AppToast {
  const AppToast._();

  static _AppToastHandle? _current;

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.error,
    Duration duration = const Duration(seconds: 3),
    double topOffset = 72,
  }) {
    final style = _AppToastStyle.fromType(type);
    final overlay = Overlay.of(context);
    final top = MediaQuery.paddingOf(context).top + topOffset;

    final previous = _current;
    if (previous != null) {
      _hide(previous);
    }

    late final _AppToastHandle handle;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: top,
          left: AppSpacing.md,
          right: AppSpacing.md,
          child: _AppToastOverlay(
            message: message,
            style: style,
            onReady: (close) => handle.close = close,
            onDismissed: () => _remove(handle),
          ),
        );
      },
    );

    handle = _AppToastHandle(entry);
    _current = handle;
    overlay.insert(entry);
    handle.timer = Timer(duration, () => _hide(handle));
  }

  static void _hide(_AppToastHandle handle) {
    handle.timer?.cancel();
    handle.timer = null;
    final close = handle.close;
    if (close == null) {
      _remove(handle);
      return;
    }

    close();
  }

  static void _remove(_AppToastHandle handle) {
    handle.timer?.cancel();
    handle.timer = null;
    handle.close = null;
    if (handle.entry.mounted) {
      handle.entry.remove();
    }
    if (identical(_current, handle)) {
      _current = null;
    }
  }

  static void error(
    BuildContext context,
    Object error, {
    double topOffset = 72,
  }) {
    if (error case AppException(hasErrors: true)) return;

    final message = switch (error) {
      AppException(:final message) => message,
      _ =>
        error
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('Bad state: ', ''),
    };
    if (message.trim().isEmpty) return;

    show(context, message: message, topOffset: topOffset);
  }

  static void success(
    BuildContext context,
    String message, {
    double topOffset = 72,
  }) {
    show(
      context,
      message: message,
      type: AppToastType.success,
      topOffset: topOffset,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    double topOffset = 72,
  }) {
    show(
      context,
      message: message,
      type: AppToastType.info,
      topOffset: topOffset,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    double topOffset = 72,
  }) {
    show(
      context,
      message: message,
      type: AppToastType.warning,
      topOffset: topOffset,
    );
  }
}

class _AppToastHandle {
  _AppToastHandle(this.entry);

  final OverlayEntry entry;
  Timer? timer;
  VoidCallback? close;
}

class _AppToastOverlay extends StatefulWidget {
  const _AppToastOverlay({
    required this.message,
    required this.style,
    required this.onReady,
    required this.onDismissed,
  });

  final String message;
  final _AppToastStyle style;
  final ValueChanged<VoidCallback> onReady;
  final VoidCallback onDismissed;

  @override
  State<_AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<_AppToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 180),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _offset = Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(curve);

    widget.onReady(_close);
    _controller.forward();
  }

  Future<void> _close() async {
    if (_isClosing) {
      return;
    }

    _isClosing = true;
    await _controller.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          child: Material(
            color: AppColors.transparent,
            child: _AppToastContent(
              message: widget.message,
              style: widget.style,
              onClose: _close,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppToastContent extends StatelessWidget {
  const _AppToastContent({
    required this.message,
    required this.style,
    required this.onClose,
  });

  final String message;
  final _AppToastStyle style;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        border: Border.all(color: style.borderColor),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: style.iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(style.icon, color: AppColors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: style.textColor,
                fontFamily: AppFonts.inter,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: onClose,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.ink,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppToastStyle {
  const _AppToastStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBackgroundColor,
    required this.textColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color iconBackgroundColor;
  final Color textColor;
  final IconData icon;

  factory _AppToastStyle.fromType(AppToastType type) {
    return switch (type) {
      AppToastType.success => const _AppToastStyle(
        backgroundColor: AppColors.toastSuccessBackground,
        borderColor: AppColors.green,
        iconBackgroundColor: AppColors.green,
        textColor: AppColors.green,
        icon: Icons.check_rounded,
      ),
      AppToastType.info => const _AppToastStyle(
        backgroundColor: AppColors.workforceIconBackground,
        borderColor: AppColors.dashboardTeal,
        iconBackgroundColor: AppColors.dashboardTeal,
        textColor: AppColors.dashboardTeal,
        icon: Icons.info_outline_rounded,
      ),
      AppToastType.warning => const _AppToastStyle(
        backgroundColor: AppColors.warningBackground,
        borderColor: AppColors.orange,
        iconBackgroundColor: AppColors.orange,
        textColor: AppColors.orange,
        icon: Icons.warning_amber_rounded,
      ),
      AppToastType.error => const _AppToastStyle(
        backgroundColor: AppColors.toastDangerBackground,
        borderColor: AppColors.rose,
        iconBackgroundColor: AppColors.rose,
        textColor: AppColors.rose,
        icon: Icons.error_outline_rounded,
      ),
    };
  }
}
