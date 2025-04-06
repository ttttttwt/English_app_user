import 'package:flutter/material.dart';

class TotalProcessLine extends StatelessWidget {
  final int currentStep;
  final double progress;
  final List<String> labels;

  const TotalProcessLine({
    super.key,
    required this.currentStep,
    required this.progress,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stepper row with integrated progress indicator
        SizedBox(
          height: 80,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final progressWidth = (constraints.maxWidth - 40) * progress;
              return Stack(
                children: [
                  // Progress percentage text
                  Positioned(
                    left: 20 +
                        progressWidth -
                        45, // Position above the progress line end
                    top: -30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Transform.translate(
                          offset: const Offset(0, 4),
                          child: const Icon(
                            Icons.arrow_drop_down,
                            size: 32,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress line
                  Positioned(
                    top: 15,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Active progress line
                  Positioned(
                    top: 15,
                    left: 20,
                    child: Container(
                      height: 10,
                      width: progressWidth,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9CE37D),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Step circles and labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      labels.length,
                      (index) => Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index < currentStep
                                  ? const Color(0xFF9CE37D)
                                  : Colors.grey.shade200,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: index < currentStep
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            labels[index],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
