import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class StatusStepperSkeleton extends StatelessWidget {
  const StatusStepperSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar skeleton
        Shimmer.fromColors(
          baseColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          highlightColor: isDark ? Colors.grey.shade600 : Colors.grey.shade100,
          child: Container(
            width: double.infinity,
            height: 3,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 20),

        // Status steps skeleton (6 steps)
        ...List.generate(6, (_) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Shimmer.fromColors(
                  baseColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  highlightColor: isDark ? Colors.grey.shade600 : Colors.grey.shade100,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    highlightColor: isDark ? Colors.grey.shade600 : Colors.grey.shade100,
                    child: Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
