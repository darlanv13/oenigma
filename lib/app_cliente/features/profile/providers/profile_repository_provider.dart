import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/app_cliente/features/profile/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});
