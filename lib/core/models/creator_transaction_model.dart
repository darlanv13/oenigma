class CreatorTransactionModel {
  final String id;
  final String eventId;
  final String eventName;
  final String creatorId;
  final String? enigmaId; // Preenchido se for compra de Super Dica
  final String? buyerId; // Usuário/Jogador que pagou
  final String? buyerName;
  final String? buyerEmail;
  final String type; // 'ticket' (inscrição pay-to-play) ou 'super_hint' (dica de R$ 1,99)
  final double grossAmount; // Valor bruto pago (ex: R$ 10,00 ou R$ 1,99)
  final double feePercent; // Taxa da plataforma retida (ex: 15.0%)
  final double feeAmount; // Valor retido pela plataforma
  final double netAmount; // Valor líquido creditado ao criador
  final String status; // 'pending', 'paid', 'refunded', 'cancelled'
  final String paymentMethod; // 'pix'
  final String? txid;
  final String? pixQrCode;
  final String? pixCopiaECola;
  final DateTime createdAt;
  final DateTime? paidAt;

  CreatorTransactionModel({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.creatorId,
    this.enigmaId,
    this.buyerId,
    this.buyerName,
    this.buyerEmail,
    required this.type,
    required this.grossAmount,
    this.feePercent = 15.0,
    required this.feeAmount,
    required this.netAmount,
    this.status = 'pending',
    this.paymentMethod = 'pix',
    this.txid,
    this.pixQrCode,
    this.pixCopiaECola,
    required this.createdAt,
    this.paidAt,
  });

  bool get isPaid => status == 'paid';
  bool get isTicket => type == 'ticket';
  bool get isSuperHint => type == 'super_hint';

  factory CreatorTransactionModel.fromMap(Map<String, dynamic> map) {
    final double gross = map['grossAmount'] != null
        ? double.tryParse(map['grossAmount'].toString()) ?? 0.0
        : (map['amount'] != null ? double.tryParse(map['amount'].toString()) ?? 0.0 : 0.0);

    final double feePct = map['feePercent'] != null
        ? double.tryParse(map['feePercent'].toString()) ?? 15.0
        : 15.0;

    final double fee = map['feeAmount'] != null
        ? double.tryParse(map['feeAmount'].toString()) ?? (gross * (feePct / 100.0))
        : (gross * (feePct / 100.0));

    final double net = map['netAmount'] != null
        ? double.tryParse(map['netAmount'].toString()) ?? (gross - fee)
        : (gross - fee);

    DateTime created = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is DateTime) {
        created = map['createdAt'];
      } else {
        created = DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now();
      }
    }

    DateTime? paid;
    if (map['paidAt'] != null) {
      if (map['paidAt'] is DateTime) {
        paid = map['paidAt'];
      } else {
        paid = DateTime.tryParse(map['paidAt'].toString());
      }
    }

    return CreatorTransactionModel(
      id: map['id']?.toString() ?? map['objectId']?.toString() ?? '',
      eventId: map['eventId']?.toString() ?? '',
      eventName: map['eventName']?.toString() ?? 'Desafio do Criador',
      creatorId: map['creatorId']?.toString() ?? '',
      enigmaId: map['enigmaId']?.toString(),
      buyerId: map['buyerId']?.toString(),
      buyerName: map['buyerName']?.toString(),
      buyerEmail: map['buyerEmail']?.toString(),
      type: map['type']?.toString() ?? 'ticket',
      grossAmount: gross,
      feePercent: feePct,
      feeAmount: fee,
      netAmount: net,
      status: map['status']?.toString() ?? 'pending',
      paymentMethod: map['paymentMethod']?.toString() ?? 'pix',
      txid: map['txid']?.toString(),
      pixQrCode: map['pixQrCode']?.toString(),
      pixCopiaECola: map['pixCopiaECola']?.toString() ?? map['brCode']?.toString(),
      createdAt: created,
      paidAt: paid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'eventName': eventName,
      'creatorId': creatorId,
      'enigmaId': enigmaId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'type': type,
      'grossAmount': grossAmount,
      'feePercent': feePercent,
      'feeAmount': feeAmount,
      'netAmount': netAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'txid': txid,
      'pixQrCode': pixQrCode,
      'pixCopiaECola': pixCopiaECola,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
    };
  }
}
