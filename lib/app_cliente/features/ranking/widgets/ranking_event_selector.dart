import 'package:flutter/material.dart';
import 'package:oenigma/core/models/event_model.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFCBD5E1).withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: selectedEventId,
        isExpanded: true,
        dropdownColor: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(32),
        icon: const FaIcon(
          FontAwesomeIcons.chevronDown,
          color: Color(0xFF8B5CF6),
          size: 16,
        ),
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
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }
}
