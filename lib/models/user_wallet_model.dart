class UserWalletModel {
  final String uid;
  final String name;
  final String email;
  final String? photoURL;
  final double balance;
  final String? lastWonEventName; // Campo alterado
  final int? lastEventRank;
  final String? lastEventName;

  UserWalletModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoURL,
    required this.balance,
    this.lastWonEventName, // Campo alterado
    this.lastEventRank,
    this.lastEventName,
  });

  factory UserWalletModel.fromMap(Map<String, dynamic> map) {
    return UserWalletModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'Utilizador',
      email: map['email'] ?? 'email@indisponivel.com',
      photoURL: map['photoURL'],
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      lastWonEventName:
          map['lastWonEventName'] as String?, // Mapeia o novo campo
      lastEventRank: map['lastEventRank'] as int?,
      lastEventName: map['lastEventName'] as String?,
    );
  }
}
