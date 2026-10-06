import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_spacing.dart';

class InputSingleLineTextField extends StatefulWidget {
  const InputSingleLineTextField({
    required this.label,
    this.value = '',
    this.controller,
    this.hintText,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.errorText,
    this.showBottomBorder = true,
    this.onChanged,
    super.key,
  });

  final String label;
  final String value;
  final TextEditingController? controller;
  final String? hintText;
  final bool isRequired;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? errorText;
  final bool showBottomBorder;
  final ValueChanged<String>? onChanged;

  @override
  State<InputSingleLineTextField> createState() =>
      _InputSingleLineTextFieldState();
}

class _InputSingleLineTextFieldState extends State<InputSingleLineTextField> {
  late final FocusNode _focusNode;
  late TextEditingController _controller;
  bool _hasText = false;

  bool get _isLabelFloating => _focusNode.hasFocus || _hasText;

  bool get _hasError => widget.errorText?.isNotEmpty ?? false;

  double get _fieldHeight => _isLabelFloating ? 56 : 24;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
    _controller =
        widget.controller ?? TextEditingController(text: widget.value);
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(InputSingleLineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_handleControllerChanged);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller =
          widget.controller ?? TextEditingController(text: widget.value);
      _controller.addListener(_handleControllerChanged);
    } else if (widget.controller == null && oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }

    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      _hasText = hasText;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  void _handleControllerChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText == hasText) return;

    setState(() {
      _hasText = hasText;
    });
  }

  void _handleChanged(String value) {
    final hasText = value.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _hasError ? AppColors.error : AppColors.line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: widget.showBottomBorder
                ? Border(bottom: BorderSide(color: borderColor, width: 1.5))
                : null,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _focusNode.requestFocus,
            child: SizedBox(
              height: _fieldHeight,
              child: Stack(
                children: [
                  if (_isLabelFloating &&
                      widget.hintText != null &&
                      _controller.text.isEmpty)
                    Positioned(
                      left: 0,
                      top: 24,
                      right: 0,
                      child: IgnorePointer(
                        child: Text(
                          widget.hintText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.inputBorder,
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    top: 24,
                    right: 0,
                    bottom: 0,
                    child: EditableText(
                      focusNode: _focusNode,
                      controller: _controller,
                      maxLines: 1,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      textAlign: TextAlign.left,
                      textDirection: TextDirection.ltr,
                      backgroundCursorColor: AppColors.inputBorder,
                      cursorColor: AppColors.dashboardTeal,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                      onChanged: _handleChanged,
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    top: _isLabelFloating ? 0 : 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _FieldLabel(
                          label: widget.label,
                          isRequired: widget.isRequired,
                          isFloating: _isLabelFloating,
                          hasError: _hasError,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_hasError)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: AppColors.error,
                fontFamily: AppFonts.inter,
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.isRequired,
    required this.isFloating,
    required this.hasError,
  });

  final String label;
  final bool isRequired;
  final bool isFloating;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          color: hasError ? AppColors.error : AppColors.muted,
          fontFamily: AppFonts.inter,
          fontSize: isFloating ? 14 : 16,
          height: isFloating ? 1.43 : 1.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        children: [
          TextSpan(text: label),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.rose),
            ),
        ],
      ),
    );
  }
}
