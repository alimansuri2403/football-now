import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: child,
    );
  }

  static Widget cardList({int count = 3}) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          count,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(height: 16, width: 150, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(height: 12, width: 100, color: Colors.white),
                        ],
                      ),
                    ),
                    Container(height: 50, width: 50, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget scoreboardCarousel() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 320,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget statsList() {
    return Column(
      children: List.generate(
        6,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 14, width: 80, color: Colors.white),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Container(height: 12, color: Colors.white)),
                  const SizedBox(width: 16),
                  Expanded(child: Container(height: 12, color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
