class RankingPlayerModel {
  final String uid;
  final String name;
  final String? photoURL;
  final int phasesCompleted;
  final int totalPhases;
  int position;

  RankingPlayerModel({
    required this.uid,
    required this.name,
    this.photoURL,
    required this.phasesCompleted,
    required this.totalPhases,
    this.position = 0,
  });

  double get progress => totalPhases > 0 ? phasesCompleted / totalPhases : 0.0;

  factory RankingPlayerModel.fromMap(Map<String, dynamic> map) {
    return RankingPlayerModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'Anônimo',
      photoURL: map['photoURL'],
      phasesCompleted: map['phasesCompleted'] ?? 0,
      totalPhases: map['totalPhases'] ?? 0,
      position: map['position'] ?? 0,
    );
  }
}
