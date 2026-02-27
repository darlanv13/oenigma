import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/utils/app_colors.dart';
import '../../stores/event_store.dart';

class InfoGrid extends StatelessWidget {
  final EventModel event;
  final EventStore store;

  const InfoGrid({
    super.key,
    required this.event,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        String solvedText = '...';
        String totalText = '...';

        if (store.stats != null) {
             final solved = store.stats!['solved'] ?? 0;
             final total = store.stats!['total'] ?? 0;
             if (event.eventType == 'find_and_win') {
                solvedText = '$solved / $total';
             } else {
                totalText = total.toString();
             }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildInfoPill(
                Icons.location_on_outlined,
                'Local',
                event.location,
              ),
              _buildInfoPill(
                Icons.calendar_today_outlined,
                'Data',
                event.startDate,
              ),

              if (event.eventType == 'find_and_win')
                _buildInfoPill(
                  Icons.track_changes,
                  'Enigmas Resolvidos',
                  solvedText,
                )
              else
                _buildInfoPill(
                  Icons.filter_alt_outlined,
                  'Fases',
                  store.stats == null ? '...' : totalText,
                ),

              _buildInfoPill(
                Icons.monetization_on_outlined,
                'Inscrição',
                'R\$ ${event.price.toStringAsFixed(2)}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoPill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: secondaryTextColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
