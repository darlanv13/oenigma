import 'package:flutter/material.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: DropdownButton<String>(
        value: selectedEventId,
        isExpanded: true,
        dropdownColor: cardColor,
        icon: const Icon(Icons.keyboard_arrow_down, color: primaryAmber),
        underline: const SizedBox(),
        onChanged: onChanged,
        items: availableEvents.map<DropdownMenuItem<String>>((EventModel event) {
          return DropdownMenuItem<String>(
            value: event.id,
            child: Text(
              event.name,
              style: const TextStyle(
                color: textColor,
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
