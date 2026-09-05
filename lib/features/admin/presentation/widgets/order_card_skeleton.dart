import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class OrderCardSkeleton extends StatelessWidget {
  final int count;

  const OrderCardSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: List.generate(count, (index) => _buildSkeletonCard(context, isDark)),
    );
  }

  Widget _buildSkeletonCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + tracking code + status badge
            Row(
              children: [
                _skeletonBox(context, width: 36, height: 36, borderRadius: 10),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _skeletonBox(context, width: double.infinity, height: 14, borderRadius: 4),
                      const SizedBox(height: 6),
                      _skeletonBox(context, width: 120, height: 10, borderRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _skeletonBox(context, width: 70, height: 22, borderRadius: 16),
              ],
            ),
            const Divider(height: 24),
            // Customer info row
            Row(
              children: [
                _skeletonBox(context, width: 20, height: 20, borderRadius: 5),
                const SizedBox(width: 8),
                Expanded(child: _skeletonBox(context, width: double.infinity, height: 14, borderRadius: 4)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _skeletonBox(context, width: 20, height: 20, borderRadius: 5),
                const SizedBox(width: 8),
                Expanded(child: _skeletonBox(context, width: double.infinity, height: 14, borderRadius: 4)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonBox(BuildContext context,
      {required double width, required double height, required double borderRadius}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade700! : Colors.grey.shade300!,
      highlightColor: isDark ? Colors.grey.shade600! : Colors.grey.shade100!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
