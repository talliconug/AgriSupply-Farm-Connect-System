import 'package:flutter/material.dart';

import '../config/theme.dart';

class LoadingOverlay extends StatelessWidget {

  const LoadingOverlay({
    required this.child, required this.isLoading, super.key,
    this.message,
    this.backgroundColor,
    this.progressColor,
  });
  final Widget child;
  final bool isLoading;
  final String? message;
  final Color? backgroundColor;
  final Color? progressColor;

  @override
  Widget build(final BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          ColoredBox(
            color: backgroundColor ?? Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressColor ?? AppColors.primaryGreen,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.grey700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class LoadingIndicator extends StatelessWidget {

  const LoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
    this.strokeWidth = 3,
  });
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primaryGreen,
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {

  const LoadingScreen({super.key, this.message});
  final String? message;

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoadingIndicator(size: 48),
            if (message != null) ...[
              const SizedBox(height: 24),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.grey600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ShimmerLoading extends StatefulWidget {

  const ShimmerLoading({
    required this.width, required this.height, super.key,
    this.borderRadius,
  });
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (final context, final child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                AppColors.grey200,
                AppColors.grey100,
                AppColors.grey200,
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(final BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                ShimmerLoading(
                  width: 100,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                ShimmerLoading(
                  width: 80,
                  height: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListItemShimmer extends StatelessWidget {
  const ListItemShimmer({super.key});

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ShimmerLoading(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                ShimmerLoading(
                  width: 150,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                ShimmerLoading(
                  width: 80,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {

  const AnimatedBuilder({
    required final Animation<double> animation, required this.builder, super.key,
  }) : super(listenable: animation);
  final TransitionBuilder builder;

  @override
  Widget build(final BuildContext context) {
    return builder(context, null);
  }
}
