import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/features/event/providers/event_repository_provider.dart';

final homeEventsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final eventRepository = ref.watch(eventRepositoryProvider);
  return await eventRepository.getHomeScreenData();
});
