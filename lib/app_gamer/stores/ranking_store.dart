import 'package:mobx/mobx.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/models/ranking_player_model.dart';

part 'ranking_store.g.dart';

class RankingStore = _RankingStore with _$RankingStore;

abstract class _RankingStore with Store {
  @observable
  String? selectedEventId;

  @observable
  List<RankingPlayerModel> currentRanking = [];

  List<EventModel> _availableEvents = [];
  List<dynamic> _allPlayers = [];

  @action
  void init(List<EventModel> events, List<dynamic> players) {
    _availableEvents = events;
    _allPlayers = players;
    if (_availableEvents.isNotEmpty && selectedEventId == null) {
      selectedEventId = _availableEvents.first.id;
    }
    calculateRanking();
  }

  @action
  void setSelectedEventId(String? id) {
    if (id != selectedEventId) {
      selectedEventId = id;
      calculateRanking();
    }
  }

  @action
  void calculateRanking() {
    if (selectedEventId == null || selectedEventId!.isEmpty) {
      currentRanking = [];
      return;
    }

    EventModel? selectedEvent;
    try {
      selectedEvent = _availableEvents.firstWhere(
        (e) => e.id == selectedEventId,
      );
    } catch (e) {
      currentRanking = [];
      return;
    }

    final totalPhases = selectedEvent.phases.length;

    var rankedPlayers = _allPlayers
        .where(
          (p) => p['events'] != null && p['events'][selectedEventId] != null,
        )
        .map((p) {
          final progress = p['events'][selectedEventId];
          return RankingPlayerModel(
            uid: p['id'],
            name: p['name'] ?? 'Anônimo',
            photoURL: p['photoURL'],
            phasesCompleted: progress['currentPhase'] != null
                ? progress['currentPhase'] - 1
                : 0,
            totalPhases: totalPhases,
          );
        })
        .toList();

    rankedPlayers.sort(
      (a, b) => b.phasesCompleted.compareTo(a.phasesCompleted),
    );

    currentRanking = rankedPlayers.asMap().entries.map((entry) {
      entry.value.position = entry.key + 1;
      return entry.value;
    }).toList();
  }
}
