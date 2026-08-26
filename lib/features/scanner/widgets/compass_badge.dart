import 'package:flutter/material.dart';
import 'scanner_math.dart';

/// Chip nhỏ hiển thị góc la bàn hiện tại (vd "127° ĐN") — chỉ mang
/// tính phản hồi cho user biết máy đang hướng về đâu, không phải la
/// bàn đầy đủ với các mốc độ.
class CompassBadge extends StatelessWidget {
  final double heading;

  const CompassBadge({super.key, required this.heading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: heading * (3.14159265 / 180),
            child: const Icon(Icons.navigation, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            '${heading.round()}° ${headingToCardinal(heading)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
