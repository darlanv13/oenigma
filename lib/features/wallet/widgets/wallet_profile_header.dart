import 'package:flutter/material.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class WalletProfileHeader extends StatelessWidget {
  final UserWalletModel wallet;

  const WalletProfileHeader({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryAmber, width: 2),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: darkBackground,
            backgroundImage: (wallet.photoURL != null && wallet.photoURL!.isNotEmpty)
                ? NetworkImage(wallet.photoURL!)
                : null,
            child: (wallet.photoURL == null || wallet.photoURL!.isEmpty)
                ? const Icon(Icons.person, color: secondaryTextColor, size: 30)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wallet.name,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                wallet.email,
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
