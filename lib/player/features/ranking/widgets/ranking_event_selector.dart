import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
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
    if (availableEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentEvent = availableEvents.firstWhere(
      (e) => e.id == selectedEventId,
      orElse: () => availableEvents.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E3A45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedEventId,
          isExpanded: true,
          dropdownColor: const Color(0xFF131D24),
          borderRadius: BorderRadius.circular(20),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.verdeVale.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const FaIcon(
              FontAwesomeIcons.chevronDown,
              color: AppColors.verdeVale,
              size: 12,
            ),
          ),
          selectedItemBuilder: (BuildContext context) {
            return availableEvents.map<Widget>((EventModel event) {
              return Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.gradienteVerdeVale,
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.mapPin,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          event.name,
                          style: GoogleFonts.cinzel(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Prêmio: ${event.prize}',
                          style: GoogleFonts.orbitron(
                            color: AppColors.amareloVale,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList();
          },
          onChanged: onChanged,
          items: availableEvents.map<DropdownMenuItem<String>>((
            EventModel event,
          ) {
            final isSelected = event.id == currentEvent.id;
            return DropdownMenuItem<String>(
              value: event.id,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.verdeVale
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                      child: Center(
                        child: FaIcon(
                          FontAwesomeIcons.trophy,
                          size: 11,
                          color: isSelected ? Colors.white : AppColors.cinzaMedio,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.name,
                            style: GoogleFonts.cinzel(
                              color: isSelected ? AppColors.verdeVale : Colors.white,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 12.5,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Prêmio: ${event.prize}',
                            style: GoogleFonts.orbitron(
                              color: AppColors.amareloVale,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const FaIcon(
                        FontAwesomeIcons.check,
                        size: 12,
                        color: AppColors.verdeVale,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
