import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/features/ranking/repositories/ranking_repository.dart';

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return RankingRepository();
});
