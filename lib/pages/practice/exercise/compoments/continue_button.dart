import 'package:do_an_test/common/constant/const_value.dart';
import 'package:flutter/material.dart';

class ContinueButton extends StatelessWidget {
  final bool canContinue;
  final int selectedItemsCount;
  final VoidCallback? onPressed;

  const ContinueButton({
    super.key,
    required this.canContinue,
    required this.selectedItemsCount,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Material(
          elevation: canContinue ? 4 : 0,
          borderRadius: BorderRadius.circular(12),
          color: canContinue ? kPrimaryColor : Colors.grey[300],
          child: InkWell(
            onTap: canContinue ? onPressed : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(
                'Continue ($selectedItemsCount items selected)',
                style: TextStyle(
                  color: canContinue ? Colors.white : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}