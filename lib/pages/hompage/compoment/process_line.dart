// process_line.dart
import 'package:flutter/material.dart';

class ProcessLine extends StatelessWidget {
  final double progress;
  final double height;
  final Color progressColor;
  final Color backgroundColor;
  final double borderRadius;

  const ProcessLine({
    super.key,
    required this.progress,
    this.height = 25.0,
    this.progressColor = const Color(0xFF9DE073),
    this.backgroundColor = const Color(0xFFE8E8E8),
    this.borderRadius = 25.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final progressWidth =
              constraints.maxWidth * (progress.clamp(0.0, 100.0) / 100);

          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: progressWidth,
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
              Center(
                child: Text(
                  '${progress.round()}%',
                  style: TextStyle(
                    color: progressWidth > constraints.maxWidth / 2
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: height * 0.6,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
