class WithdrawalModel {
  final String id;
  final String userId;
  final String userName;
  final String pixKey; // ou dados bancários
  final double amount;
  final String status; // 'pending', 'approved', 'rejected'
  final String requestedAt;

  WithdrawalModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.pixKey,
    required this.amount,
    required this.status,
    required this.requestedAt,
  });

  factory WithdrawalModel.fromMap(Map<String, dynamic> map) {
    return WithdrawalModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Desconhecido',
      pixKey: map['pixKey'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      requestedAt: map['requestedAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'pixKey': pixKey,
      'amount': amount,
      'status': status,
      'requestedAt': requestedAt,
    };
  }
}
