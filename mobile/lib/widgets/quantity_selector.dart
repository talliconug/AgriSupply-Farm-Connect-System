import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';

class QuantitySelector extends StatelessWidget {

  const QuantitySelector({
    required this.quantity, required this.onChanged, super.key,
    this.minQuantity = 1,
    this.maxQuantity = 99,
    this.unit,
    this.isCompact = false,
    this.showLabel = false,
  });
  final int quantity;
  final int minQuantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;
  final String? unit;
  final bool isCompact;
  final bool showLabel;

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Quantity${unit != null ? ' ($unit)' : ''}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.grey700,
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
            border: Border.all(color: AppColors.grey300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrease Button
              _QuantityButton(
                icon: Icons.remove,
                onPressed: quantity > minQuantity
                    ? () {
                        HapticFeedback.lightImpact();
                        onChanged(quantity - 1);
                      }
                    : null,
                isCompact: isCompact,
              ),

              // Quantity Display
              Container(
                constraints: BoxConstraints(
                  minWidth: isCompact ? 32 : 48,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 8 : 12,
                  vertical: isCompact ? 4 : 8,
                ),
                decoration: const BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(color: AppColors.grey300),
                  ),
                ),
                child: Text(
                  quantity.toString(),
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Increase Button
              _QuantityButton(
                icon: Icons.add,
                onPressed: quantity < maxQuantity
                    ? () {
                        HapticFeedback.lightImpact();
                        onChanged(quantity + 1);
                      }
                    : null,
                isCompact: isCompact,
              ),
            ],
          ),
        ),
        if (unit != null && !showLabel)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              unit!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.grey500,
              ),
            ),
          ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {

  const _QuantityButton({
    required this.icon,
    this.onPressed,
    this.isCompact = false,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isCompact;

  @override
  Widget build(final BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 6 : 10),
        child: Icon(
          icon,
          size: isCompact ? 16 : 20,
          color: onPressed != null ? AppColors.primaryGreen : AppColors.grey400,
        ),
      ),
    );
  }
}

class QuantitySelectorWithInput extends StatefulWidget {

  const QuantitySelectorWithInput({
    required this.quantity, required this.onChanged, super.key,
    this.minQuantity = 1,
    this.maxQuantity = 9999,
    this.unit,
    this.label,
  });
  final int quantity;
  final int minQuantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;
  final String? unit;
  final String? label;

  @override
  State<QuantitySelectorWithInput> createState() =>
      _QuantitySelectorWithInputState();
}

class _QuantitySelectorWithInputState extends State<QuantitySelectorWithInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _validateAndUpdate();
      }
    });
  }

  @override
  void didUpdateWidget(final QuantitySelectorWithInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity && !_focusNode.hasFocus) {
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateAndUpdate() {
    final value = int.tryParse(_controller.text) ?? widget.minQuantity;
    final clampedValue = value.clamp(widget.minQuantity, widget.maxQuantity);
    
    if (clampedValue != widget.quantity) {
      widget.onChanged(clampedValue);
    }
    _controller.text = clampedValue.toString();
  }

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.grey700,
              ),
            ),
          ),
        Row(
          children: [
            // Decrease Button
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.remove),
                onPressed: widget.quantity > widget.minQuantity
                    ? () {
                        HapticFeedback.lightImpact();
                        widget.onChanged(widget.quantity - 1);
                      }
                    : null,
                color: AppColors.primaryGreen,
                disabledColor: AppColors.grey400,
              ),
            ),
            const SizedBox(width: 8),

            // Input Field
            SizedBox(
              width: 80,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primaryGreen),
                  ),
                  suffixText: widget.unit,
                  suffixStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
                onSubmitted: (_) => _validateAndUpdate(),
              ),
            ),
            const SizedBox(width: 8),

            // Increase Button
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.add),
                onPressed: widget.quantity < widget.maxQuantity
                    ? () {
                        HapticFeedback.lightImpact();
                        widget.onChanged(widget.quantity + 1);
                      }
                    : null,
                color: AppColors.primaryGreen,
                disabledColor: AppColors.grey400,
              ),
            ),
          ],
        ),
        if (widget.unit != null && widget.label == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'per ${widget.unit}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.grey500,
              ),
            ),
          ),
      ],
    );
  }
}

class CartQuantitySelector extends StatelessWidget {

  const CartQuantitySelector({
    required this.quantity, required this.onChanged, super.key,
    this.maxQuantity = 99,
    this.onRemove,
  });
  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(final BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease or Remove
          GestureDetector(
            onTap: quantity > 1
                ? () {
                    HapticFeedback.lightImpact();
                    onChanged(quantity - 1);
                  }
                : onRemove,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                quantity > 1 ? Icons.remove : Icons.delete_outline,
                size: 18,
                color: quantity > 1 ? AppColors.primaryGreen : AppColors.error,
              ),
            ),
          ),

          // Quantity
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Increase
          GestureDetector(
            onTap: quantity < maxQuantity
                ? () {
                    HapticFeedback.lightImpact();
                    onChanged(quantity + 1);
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.add,
                size: 18,
                color: quantity < maxQuantity
                    ? AppColors.primaryGreen
                    : AppColors.grey400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuantityBadge extends StatelessWidget {

  const QuantityBadge({
    required this.count, super.key,
    this.color,
    this.size = 18,
  });
  final int count;
  final Color? color;
  final double size;

  @override
  Widget build(final BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color ?? AppColors.error,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
