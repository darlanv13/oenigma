import 'package:flutter/material.dart';
import 'package:oenigma/utils/app_colors.dart';

class CreditOptions extends StatelessWidget {
  final Function(double) onBuyCredits;

  const CreditOptions({super.key, required this.onBuyCredits});

  @override
  Widget build(BuildContext context) {
    final options = [5, 10, 15, 20, 50, 100];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final amount = options[index];
        return Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => onBuyCredits(amount.toDouble()),
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                'R\$ $amount',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
