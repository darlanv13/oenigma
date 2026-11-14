class CreatorProfileModel {
  final String userId;
  final String displayName;
  final String handle; // ex: @felipeneto ou canal-tech
  final String bio;
  final String? avatarUrl;
  final String? instagram;
  final String? youtube;
  final String? tiktok;
  final String? pixKey;
  final String pixKeyType; // 'CPF', 'CNPJ', 'EMAIL', 'TELEFONE', 'ALEATORIA'
  final double availableBalance; // Saldo disponível para saque Pix
  final double pendingBalance; // Saldo em processamento
  final double totalEarned; // Faturamento líquido total acumulado
  final int totalParticipants; // Total de seguidores que já jogaram seus desafios
  final int activeEventsCount; // Desafios ativos no momento

  CreatorProfileModel({
    required this.userId,
    required this.displayName,
    required this.handle,
    this.bio = '',
    this.avatarUrl,
    this.instagram,
    this.youtube,
    this.tiktok,
    this.pixKey,
    this.pixKeyType = 'CPF',
    this.availableBalance = 0.0,
    this.pendingBalance = 0.0,
    this.totalEarned = 0.0,
    this.totalParticipants = 0,
    this.activeEventsCount = 0,
  });

  factory CreatorProfileModel.fromMap(Map<String, dynamic> map) {
    return CreatorProfileModel(
      userId: map['userId']?.toString() ?? map['objectId']?.toString() ?? '',
      displayName: map['name']?.toString() ?? map['displayName']?.toString() ?? 'Criador',
      handle: map['handle']?.toString() ?? (map['username']?.toString() ?? 'criador'),
      bio: map['bio']?.toString() ?? '',
      avatarUrl: map['avatarUrl']?.toString() ?? map['photoURL']?.toString(),
      instagram: map['instagram']?.toString(),
      youtube: map['youtube']?.toString(),
      tiktok: map['tiktok']?.toString(),
      pixKey: map['pixKey']?.toString(),
      pixKeyType: map['pixKeyType']?.toString() ?? 'CPF',
      availableBalance: map['availableBalance'] != null
          ? double.tryParse(map['availableBalance'].toString()) ?? 0.0
          : (map['balance'] != null ? double.tryParse(map['balance'].toString()) ?? 0.0 : 0.0),
      pendingBalance: map['pendingBalance'] != null
          ? double.tryParse(map['pendingBalance'].toString()) ?? 0.0
          : 0.0,
      totalEarned: map['totalEarned'] != null
          ? double.tryParse(map['totalEarned'].toString()) ?? 0.0
          : 0.0,
      totalParticipants: map['totalParticipants'] != null
          ? int.tryParse(map['totalParticipants'].toString()) ?? 0
          : 0,
      activeEventsCount: map['activeEventsCount'] != null
          ? int.tryParse(map['activeEventsCount'].toString()) ?? 0
          : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'handle': handle,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'instagram': instagram,
      'youtube': youtube,
      'tiktok': tiktok,
      'pixKey': pixKey,
      'pixKeyType': pixKeyType,
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
      'totalEarned': totalEarned,
      'totalParticipants': totalParticipants,
      'activeEventsCount': activeEventsCount,
    };
  }
}
