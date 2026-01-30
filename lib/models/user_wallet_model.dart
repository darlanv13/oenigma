class UserWalletModel {
  final String uid;
  final String name;
  final String email;
  final String? photoURL;
  final double balance;
  final String? lastWonEventName;
  final int? lastEventRank;
  final String? lastEventName;
  final List<dynamic> history; // Adicionei o final aqui para consistência

  UserWalletModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoURL,
    required this.balance,
    this.lastWonEventName,
    this.lastEventRank,
    this.lastEventName,
    required this.history,
  });

  factory UserWalletModel.fromMap(Map<String, dynamic> map) {
    return UserWalletModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'Utilizador',
      email: map['email'] ?? 'email@indisponivel.com',
      photoURL: map['photoURL'],
      // Converte para num primeiro para aceitar tanto int quanto double do Firebase
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      lastWonEventName: map['lastWonEventName'] as String?,
      lastEventRank: map['lastEventRank'] as int?,
      lastEventName: map['lastEventName'] as String?,
      // CORREÇÃO: Tenta ler a lista, se for nula, usa lista vazia
      history: (map['history'] as List<dynamic>?) ?? [],
    );
  }
}
