import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../repositories/auth_repository.dart';

final masterAuthRepositoryProvider = Provider<MasterAuthRepository>((ref) {
  return MasterAuthRepository();
});

final masterAuthStateProvider = StreamProvider<ParseUser?>((ref) {
  return ref.watch(masterAuthRepositoryProvider).authStateChanges;
});
