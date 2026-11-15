import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../repositories/auth_repository.dart';

final creatorAuthRepositoryProvider = Provider<CreatorAuthRepository>((ref) {
  return CreatorAuthRepository();
});

final creatorAuthStateProvider = StreamProvider<ParseUser?>((ref) {
  return ref.watch(creatorAuthRepositoryProvider).authStateChanges;
});
