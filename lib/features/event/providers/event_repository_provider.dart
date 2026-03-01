import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/features/event/repositories/event_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});
