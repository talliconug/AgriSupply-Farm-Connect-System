import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';

class CustomTextField extends StatefulWidget {

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.prefix,
    this.suffix,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.contentPadding,
  });
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: _isFocused ? AppColors.primaryGreen : AppColors.grey700,
                ),
          ),
          const SizedBox(height: 8),
        ],
        Focus(
          onFocusChange: (final hasFocus) {
            setState(() => _isFocused = hasFocus);
          },
          child: TextFormField(
            controller: widget.controller,
            obscureText: _obscureText,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            inputFormatters: widget.inputFormatters,
            focusNode: widget.focusNode,
            textCapitalization: widget.textCapitalization,
            autofocus: widget.autofocus,
            style: TextStyle(
              color: widget.enabled ? AppColors.grey900 : AppColors.grey500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: AppColors.grey400),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused ? AppColors.primaryGreen : AppColors.grey500,
                      size: 20,
                    )
                  : widget.prefix,
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.grey500,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscureText = !_obscureText);
                      },
                    )
                  : widget.suffixIcon ?? widget.suffix,
              filled: true,
              fillColor: widget.enabled ? AppColors.grey100 : AppColors.grey50,
              contentPadding: widget.contentPadding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryGreen,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.error,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              errorStyle: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomSearchField extends StatelessWidget {

  const CustomSearchField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
  });
  final TextEditingController? controller;
  final String? hint;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final bool autofocus;

  @override
  Widget build(final BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTap: onTap,
        autofocus: autofocus,
        decoration: InputDecoration(
          hintText: hint ?? 'Search...',
          hintStyle: const TextStyle(color: AppColors.grey400),
          prefixIcon: const Icon(Icons.search, color: AppColors.grey500),
          suffixIcon: controller?.text.isNotEmpty ?? false
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.grey500),
                  onPressed: () {
                    controller?.clear();
                    onChanged?.call('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class PhoneTextField extends StatelessWidget {

  const PhoneTextField({
    super.key,
    this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  @override
  Widget build(final BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: 'Phone Number',
      hint: '7XX XXX XXX',
      keyboardType: TextInputType.phone,
      enabled: enabled,
      prefix: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/uganda_flag.png',
              width: 24,
              height: 16,
              errorBuilder: (_, final __, final ___) => const Text('🇺🇬'),
            ),
            const SizedBox(width: 8),
            const Text(
              '+256',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.grey700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 24,
              width: 1,
              color: AppColors.grey300,
            ),
          ],
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
        _PhoneNumberFormatter(),
      ],
      validator: validator ??
          (final value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            final digits = value.replaceAll(' ', '');
            if (digits.length < 9) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
      onChanged: onChanged,
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    final TextEditingValue oldValue,
    final TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
