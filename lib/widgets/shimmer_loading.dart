import 'package:flutter/material.dart';

/// Wraps children in an animated shimmer effect.
/// All [ShimmerBox] descendants will animate together.
class ShimmerContainer extends StatefulWidget {
  final Widget child;

  const ShimmerContainer({super.key, required this.child});

  @override
  State<ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      controller: _controller,
      child: widget.child,
    );
  }
}

class _ShimmerScope extends InheritedWidget {
  final AnimationController controller;

  const _ShimmerScope({
    required this.controller,
    required super.child,
  });

  static AnimationController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.controller;
  }

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) =>
      controller != oldWidget.controller;
}

/// A single shimmer placeholder box.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final controller = _ShimmerScope.maybeOf(context);
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor = Theme.of(context).colorScheme.surfaceContainerHigh;

    if (controller == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (controller.value - 0.3).clamp(0.0, 1.0),
                controller.value.clamp(0.0, 1.0),
                (controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer placeholder matching a list tile layout.
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const ShimmerBox(width: 48, height: 48, borderRadius: 8),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                ShimmerBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 10,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder matching a bus line card layout.
class ShimmerLineCard extends StatelessWidget {
  const ShimmerLineCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const ShimmerBox(width: 40, height: 40, borderRadius: 8),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 16,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    height: 12,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            const ShimmerBox(width: 16, height: 16, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder matching a bus arrival card.
class ShimmerArrivalCard extends StatelessWidget {
  const ShimmerArrivalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const ShimmerBox(width: 40, height: 40, borderRadius: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 14,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.25,
                    height: 10,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            const ShimmerBox(width: 60, height: 24, borderRadius: 8),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder matching a route result summary card.
class ShimmerRouteResultCard extends StatelessWidget {
  const ShimmerRouteResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const ShimmerBox(width: 24, height: 24, borderRadius: 4),
                const SizedBox(width: 8),
                ShimmerBox(
                  width: MediaQuery.of(context).size.width * 0.35,
                  height: 18,
                  borderRadius: 4,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                3,
                (_) => Column(
                  children: const [
                    ShimmerBox(width: 24, height: 24, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: 40, height: 16, borderRadius: 4),
                    SizedBox(height: 4),
                    ShimmerBox(width: 50, height: 10, borderRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
