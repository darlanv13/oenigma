import 'package:intl/intl.dart';

class RankingPlayerModel {
  final String objectId;
  final String name;
  final String? photoURL;
  final int phasesCompleted;
  final int totalPhases;
  int position;
  final int latestCompletionTime;

  RankingPlayerModel({
    required this.objectId,
    required this.name,
    this.photoURL,
    required this.phasesCompleted,
    required this.totalPhases,
    this.position = 0,
    this.latestCompletionTime = 0,
  });

  double get progress => totalPhases > 0 ? (phasesCompleted / totalPhases).clamp(0.0, 1.0) : 0.0;
  int get progressPercent => (progress * 100).round();

  String get formattedCompletionTime {
    if (latestCompletionTime <= 0) return 'Recentemente';
    final date = DateTime.fromMillisecondsSinceEpoch(latestCompletionTime);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (difference.inMinutes < 60) {
      return 'Há ${difference.inMinutes} min';
    } else if (difference.inHours < 24 && date.day == now.day) {
      return 'Hoje às ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays <= 1 || (now.day - date.day == 1 && difference.inHours < 48)) {
      return 'Ontem às ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return 'Há ${difference.inDays} dias';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  factory RankingPlayerModel.fromMap(Map<String, dynamic> map) {
    return RankingPlayerModel(
      objectId: map['objectId'] ?? '',
      name: map['name'] ?? 'Anônimo',
      photoURL: map['photoURL'],
      phasesCompleted: (map['phasesCompleted'] as num?)?.toInt() ?? 0,
      totalPhases: (map['totalPhases'] as num?)?.toInt() ?? 0,
      position: (map['position'] as num?)?.toInt() ?? 0,
      latestCompletionTime: (map['latestCompletionTime'] as num?)?.toInt() ?? 0,
    );
  }
}
