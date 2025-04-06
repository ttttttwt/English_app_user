import 'package:do_an_test/common/constant/const_class.dart';
import 'package:do_an_test/common/constant/const_value.dart';
import 'package:flutter/material.dart';

class ExerciseTypeCard extends StatelessWidget {
  final ExerciseType type;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const ExerciseTypeCard({
    super.key,
    required this.type,
    required this.isSelected,
    this.isDisabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDisabled 
        ? Colors.grey[300]
        : isSelected 
            ? kPrimaryColor 
            : Colors.white;
            
    final textColor = isDisabled
        ? Colors.grey[600]
        : isSelected
            ? Colors.white
            : Colors.grey[800];

    return Material(
      elevation: isSelected ? 8 : 2,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isDisabled ? 0.7 : 1.0,
        child: Tooltip(
          message: isDisabled 
              ? 'This exercise type is not available with Reading'
              : '',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type.icon,
                    size: 28,
                    color: textColor,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    type.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      type.description,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : Colors.grey[600],
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}