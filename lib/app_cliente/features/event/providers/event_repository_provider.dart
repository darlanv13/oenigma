import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/app_cliente/features/event/repositories/event_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});
