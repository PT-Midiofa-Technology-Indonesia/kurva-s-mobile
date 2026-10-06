import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_spacing.dart';

class InputPasswordTextField extends StatefulWidget {
  const InputPasswordTextField({
    required this.label,
    this.value = '',
    this.controller,
    this.hintText,
    this.isRequired = false,
    this.initialObscureText = true,
    this.textInputAction = TextInputAction.next,
    this.errorText,
    this.onChanged,
    super.key,
  });

  final String label;
  final String value;
  final TextEditingController? controller;
  final String? hintText;
  final bool isRequired;
  final bool initialObscureText;
  final TextInputAction textInputAction;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  State<InputPasswordTextField> createState() => _InputPasswordTextFieldState();
}

class _InputPasswordTextFieldState extends State<InputPasswordTextField> {
  late final FocusNode _focusNode;
  late TextEditingController _controller;
  late bool _obscureText;
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
    _obscureText = widget.initialObscureText;
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(InputPasswordTextField oldWidget) {
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

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trailingWidth = _hasText ? 48.0 : 0.0;
    final borderColor = _hasError ? AppColors.error : AppColors.line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
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
                      right: trailingWidth,
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
                    right: trailingWidth,
                    bottom: 0,
                    child: EditableText(
                      focusNode: _focusNode,
                      controller: _controller,
                      maxLines: 1,
                      obscureText: _obscureText,
                      obscuringCharacter: '●',
                      keyboardType: TextInputType.visiblePassword,
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
                  if (_hasText)
                    Positioned(
                      right: 0,
                      top: _isLabelFloating ? 16 : -8,
                      child: IconButton(
                        tooltip: _obscureText
                            ? 'Tampilkan kata sandi'
                            : 'Sembunyikan kata sandi',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 40,
                        ),
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.ink,
                          size: 20,
                        ),
                        onPressed: _toggleObscureText,
                      ),
                    ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    top: 0,
                    left: 0,
                    right: trailingWidth,
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
