import 'dart:io';
import 'package:flutter/material.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final UserWalletModel walletData;
  final Map<String, dynamic> playerData;
  final File? selectedImage;
  final VoidCallback onPickImage;

  const ProfileHeader({
    super.key,
    required this.walletData,
    required this.playerData,
    required this.selectedImage,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryAmber, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: primaryAmber.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: darkBackground,
                    backgroundImage: selectedImage != null
                        ? FileImage(selectedImage!)
                        : (playerData['photoURL'] != null &&
                                playerData['photoURL'].isNotEmpty
                            ? NetworkImage(playerData['photoURL'])
                            : null) as ImageProvider?,
                    child: selectedImage == null &&
                            (playerData['photoURL'] == null ||
                                playerData['photoURL'].isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: secondaryTextColor,
                          )
                        : null,
                  ),
                ),
                GestureDetector(
                  onTap: onPickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: primaryAmber,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: darkBackground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              walletData.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              walletData.email,
              style: const TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
