import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class CreatorRepository {
  Future<List<ParseObject>> getMyEvents({String? creatorId}) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Event'))
      ..orderByDescending('createdAt');
    if (creatorId != null && creatorId.isNotEmpty) {
      query.whereEqualTo('creatorId', creatorId);
    }
    final response = await query.query();
    if (response.success && response.results != null) {
      return List<ParseObject>.from(response.results!);
    }
    return [];
  }

  Future<List<ParseObject>> getPhasesForEvent(String eventId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Phase'))
      ..whereEqualTo('eventId', eventId)
      ..orderByAscending('order');
    final response = await query.query();
    if (response.success && response.results != null) {
      return List<ParseObject>.from(response.results!);
    }
    return [];
  }

  Future<List<ParseObject>> getEnigmasForEvent(String eventId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Enigma'))
      ..whereEqualTo('eventId', eventId)
      ..orderByAscending('order');
    final response = await query.query();
    if (response.success && response.results != null) {
      return List<ParseObject>.from(response.results!);
    }
    return [];
  }

  Future<List<ParseObject>> getHintsForEnigma(String enigmaId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Hint'))
      ..whereEqualTo('enigmaId', enigmaId)
      ..orderByAscending('order');
    final response = await query.query();
    if (response.success && response.results != null) {
      return List<ParseObject>.from(response.results!);
    }
    return [];
  }

  Future<Map<String, dynamic>> getCreatorMetrics({String? creatorId}) async {
    final events = await getMyEvents(creatorId: creatorId);
    int totalEvents = events.length;
    int activeEvents = events.where((e) => e.get<String>('status') == 'open').length;
    int totalPlayers = 0;
    double estimatedRevenue = 0.0;

    for (var ev in events) {
      final players = ev.get<num>('playerCount')?.toInt() ?? 0;
      final price = (ev.get<num>('price') ?? 0.0).toDouble();
      totalPlayers += players;
      estimatedRevenue += (players * price);
    }

    return {
      'totalEvents': totalEvents,
      'activeEvents': activeEvents,
      'totalPlayers': totalPlayers,
      'estimatedRevenue': estimatedRevenue,
    };
  }
}
