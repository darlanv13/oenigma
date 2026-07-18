import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/features/event/providers/event_repository_provider.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';

final homeEventsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Watch auth state to trigger re-fetch when user logs in/out
  ref.watch(authStateProvider);

  final eventRepository = ref.watch(eventRepositoryProvider);
  return await eventRepository.getHomeScreenData();
});
