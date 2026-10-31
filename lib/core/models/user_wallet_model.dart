class UserWalletModel {
  final String objectId;
  final String name;
  final String email;
  final String? photoURL;
  final double balance;
  final String? lastWonEventName;
  final int? lastEventRank;
  final String? lastEventName;
  final List<dynamic> transactions;

  UserWalletModel({
    required this.objectId,
    required this.name,
    required this.email,
    this.photoURL,
    required this.balance,
    this.lastWonEventName,
    this.lastEventRank,
    this.lastEventName,
    this.transactions = const [],
  });

  factory UserWalletModel.fromMap(Map<String, dynamic> map) {
    return UserWalletModel(
      objectId: map['objectId'] ?? '',
      name: map['name'] ?? 'Utilizador',
      email: map['email'] ?? 'email@indisponivel.com',
      photoURL: map['photoURL'],
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      lastWonEventName: map['lastWonEventName'] as String?,
      lastEventRank: map['lastEventRank'] as int?,
      lastEventName: map['lastEventName'] as String?,
      transactions: map['transactions'] as List<dynamic>? ?? const [],
    );
  }
}
