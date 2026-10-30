import 'package:flutter/material.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class RankingEventSelector extends StatelessWidget {
  final String? selectedEventId;
  final List<EventModel> availableEvents;
  final ValueChanged<String?> onChanged;

  const RankingEventSelector({
    super.key,
    required this.selectedEventId,
    required this.availableEvents,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: selectedEventId,
        isExpanded: true,
        dropdownColor: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(20),
        icon: const FaIcon(FontAwesomeIcons.chevronDown, color: AppColors.verdeVale, size: 14),
        underline: const SizedBox(),
        onChanged: onChanged,
        items: availableEvents.map<DropdownMenuItem<String>>((
          EventModel event,
        ) {
          return DropdownMenuItem<String>(
            value: event.id,
            child: Text(
              event.name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }
}
