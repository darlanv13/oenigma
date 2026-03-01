import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/features/enigma/repositories/enigma_repository.dart';

final enigmaRepositoryProvider = Provider<EnigmaRepository>((ref) {
  return EnigmaRepository();
});
