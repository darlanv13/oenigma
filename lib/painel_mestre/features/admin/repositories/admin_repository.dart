import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

class AdminRepository {
  Future<ParseResponse> callFunction(
    String functionName, [
    Map<String, dynamic>? payload,
  ]) async {
    final ParseCloudFunction function = ParseCloudFunction(functionName);
    try {
      final response = await function.execute(parameters: payload);
      if (!response.success) {
        throw response.error ?? ParseError();
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAdminDashboardData() async {
    final result = await callFunction('getAdminDashboardData');
    return Map<String, dynamic>.from(result.result);
  }

  /// Busca dados completos, resilientes e aprofundados do Dashboard com base na estrutura real do jogo.
  Future<Map<String, dynamic>> getComprehensiveDashboardData() async {
    // 1. Tenta obter base rápida de cloud functions se disponível
    Map<String, dynamic> cloudData = {};
    try {
      final res = await callFunction('getAdminDashboardData');
      if (res.success && res.result is Map) {
        cloudData = Map<String, dynamic>.from(res.result);
      }
    } catch (e) {
      debugPrint('[AdminDashboard] Cloud function getAdminDashboardData indisponível: $e');
    }

    // 2. Consulta Eventos
    int totalEvents = 0;
    int activeEvents = 0;
    double totalPrizePool = 0.0;
    final List<Map<String, dynamic>> recentEvents = [];
    try {
      final eventsQuery = QueryBuilder<ParseObject>(ParseObject('Event'))
        ..orderByDescending('createdAt')
        ..setLimit(50);
      final eventsRes = await eventsQuery.query();
      if (eventsRes.success && eventsRes.results != null) {
        final events = List<ParseObject>.from(eventsRes.results!);
        totalEvents = events.length;
        for (final ev in events) {
          final status = (ev.get<String>('status') ?? 'draft').toLowerCase();
          final isOpen = status == 'open' || status == 'aberto' || status == 'active';
          if (isOpen) {
            activeEvents++;
            final prizeStr = ev.get<dynamic>('prize')?.toString() ??
                ev.get<dynamic>('prizePool')?.toString() ??
                '';
            final prizeClean = prizeStr
                .replaceAll(RegExp(r'[^0-9,\.]'), '')
                .replaceAll(',', '.');
            final prizeNum = double.tryParse(prizeClean) ??
                (ev.get<num>('prize') ?? 0.0).toDouble();
            totalPrizePool += prizeNum;
          }

          if (recentEvents.length < 5) {
            recentEvents.add({
              'id': ev.objectId ?? '',
              'name': ev.get<String>('name') ??
                  ev.get<String>('title') ??
                  'Caçada Sem Título',
              'status': status,
              'eventType': ev.get<String>('eventType') ?? 'classic',
              'prize': ev.get<dynamic>('prize')?.toString() ??
                  (ev.get<dynamic>('prizePool')?.toString() ?? 'R\$ 0,00'),
              'prizeType': ev.get<String>('prizeType') ?? 'dinheiro',
              'playerCount': ev.get<int>('playerCount') ?? 0,
              'location': ev.get<String>('location') ?? 'Global',
              'startDate': ev.get<String>('startDate') ?? '',
              'isOpen': isOpen,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[AdminDashboard] Erro ao carregar eventos: $e');
    }

    // 3. Consulta Enigmas e Ferramentas Táticas
    int totalEnigmas = 0;
    int activeEnigmas = 0;
    final Map<String, int> difficultyCounts = {
      'FÁCIL': 0,
      'MÉDIA': 0,
      'DIFÍCIL': 0,
    };
    int withCompass = 0;
    int withRadar = 0;
    int withMap = 0;
    int withAudio = 0;
    int withGps = 0;
    try {
      final enigmasQuery = QueryBuilder<ParseObject>(ParseObject('Enigma'))
        ..orderByDescending('createdAt')
        ..setLimit(200);
      final enigmasRes = await enigmasQuery.query();
      if (enigmasRes.success && enigmasRes.results != null) {
        final enigmas = List<ParseObject>.from(enigmasRes.results!);
        totalEnigmas = enigmas.length;
        for (final en in enigmas) {
          final status = en.get<String>('status')?.toLowerCase() ?? 'open';
          if (status != 'closed' && status != 'resolvido') {
            activeEnigmas++;
          }
          final diff = (en.get<String>('difficulty') ?? 'MÉDIA').toUpperCase();
          if (diff.contains('FÁCIL') || diff.contains('FACIL')) {
            difficultyCounts['FÁCIL'] = (difficultyCounts['FÁCIL'] ?? 0) + 1;
          } else if (diff.contains('DIFÍCIL') || diff.contains('DIFICIL')) {
            difficultyCounts['DIFÍCIL'] = (difficultyCounts['DIFÍCIL'] ?? 0) + 1;
          } else {
            difficultyCounts['MÉDIA'] = (difficultyCounts['MÉDIA'] ?? 0) + 1;
          }

          if (en.get<bool>('hasCompass') == true) withCompass++;
          if (en.get<bool>('hasRadar') == true) withRadar++;
          if (en.get<bool>('hasMap') == true) withMap++;
          final audio = en.get<String>('audioUrl');
          if (audio != null && audio.trim().isNotEmpty) withAudio++;
          if (en.get<dynamic>('location') != null) withGps++;
        }
      }
    } catch (e) {
      debugPrint('[AdminDashboard] Erro ao carregar enigmas: $e');
    }

    // 4. Consulta Usuários / Caçadores
    int totalUsers = cloudData['users'] ?? 0;
    double totalUsersBalance = 0.0;
    List<Map<String, dynamic>> topPlayers = [];
    try {
      final usersRes = await callFunction('listAllUsers');
      if (usersRes.success && usersRes.result is List) {
        final list = List<dynamic>.from(usersRes.result);
        totalUsers = list.length;
        for (final u in list) {
          final bal = (u['walletBalance'] is num)
              ? (u['walletBalance'] as num).toDouble()
              : 0.0;
          totalUsersBalance += bal;
        }
        final sorted = List<Map<String, dynamic>>.from(
          list.map((item) => Map<String, dynamic>.from(item)),
        );
        sorted.sort((a, b) {
          final balA = (a['walletBalance'] is num)
              ? (a['walletBalance'] as num).toDouble()
              : 0.0;
          final balB = (b['walletBalance'] is num)
              ? (b['walletBalance'] as num).toDouble()
              : 0.0;
          return balB.compareTo(balA);
        });
        topPlayers = sorted.take(5).toList();
      }
    } catch (_) {
      try {
        final uQuery = QueryBuilder<ParseUser>(ParseUser.forQuery())
          ..orderByDescending('createdAt')
          ..setLimit(50);
        final uRes = await uQuery.query();
        if (uRes.success && uRes.results != null) {
          final list = List<ParseUser>.from(uRes.results!);
          if (totalUsers == 0) totalUsers = list.length;
          for (final u in list) {
            final bal = (u.get<num>('balance') ?? 0.0).toDouble();
            totalUsersBalance += bal;
            if (topPlayers.length < 5) {
              topPlayers.add({
                'objectId': u.objectId ?? '',
                'name': u.get<String>('name') ?? u.username ?? 'Caçador',
                'email': u.emailAddress ?? '',
                'walletBalance': bal,
                'isAdmin': u.get<bool>('isAdmin') ?? false,
                'createdAt': u.createdAt,
              });
            }
          }
        }
      } catch (e) {
        debugPrint('[AdminDashboard] Erro ao carregar usuários: $e');
      }
    }

    // 5. Consulta Finanças (Saques, Depósitos e Atividade Recente)
    int pendingWithdrawalsCount = cloudData['pendingWithdrawals'] ?? 0;
    double pendingWithdrawalsAmount = 0.0;
    double totalDepositedAmount = 0.0;
    int totalDepositsCount = cloudData['totalDeposits'] ?? 0;
    final List<Map<String, dynamic>> recentActivity = [];
    try {
      final wQuery = QueryBuilder<ParseObject>(ParseObject('Withdrawal'))
        ..includeObject(['user'])
        ..orderByDescending('createdAt')
        ..setLimit(50);
      final wRes = await wQuery.query();
      if (wRes.success && wRes.results != null) {
        final withdrawals = List<ParseObject>.from(wRes.results!);
        int pCount = 0;
        double pAmount = 0.0;
        for (final w in withdrawals) {
          final status = (w.get<String>('status') ?? 'pending').toLowerCase();
          final amount = (w.get<num>('amount') ?? 0.0).toDouble();
          if (status == 'pending') {
            pCount++;
            pAmount += amount;
          }
        }
        pendingWithdrawalsCount = pCount;
        pendingWithdrawalsAmount = pAmount;

        for (final w in withdrawals.take(4)) {
          final u = w.get<ParseObject>('user');
          final userName = w.get<String>('userName') ??
              (u?.get<String>('name')) ??
              'Jogador';
          recentActivity.add({
            'id': w.objectId ?? '',
            'type': 'withdrawal',
            'amount': (w.get<num>('amount') ?? 0.0).toDouble(),
            'status': w.get<String>('status') ?? 'pending',
            'userName': userName,
            'createdAt': w.createdAt ?? DateTime.now(),
            'description': 'Solicitação de Saque PIX',
          });
        }
      }

      final tQuery = QueryBuilder<ParseObject>(ParseObject('Transaction'))
        ..includeObject(['user'])
        ..orderByDescending('createdAt')
        ..setLimit(50);
      final tRes = await tQuery.query();
      if (tRes.success && tRes.results != null) {
        final txList = List<ParseObject>.from(tRes.results!);
        int dCount = 0;
        double dAmount = 0.0;
        for (final tx in txList) {
          final type = tx.get<String>('type') ?? '';
          final status = tx.get<String>('status') ?? '';
          final amount = (tx.get<num>('amount') ?? 0.0).toDouble();
          if (type == 'deposit') {
            dCount++;
            if (status == 'approved' || status == 'completed') {
              dAmount += amount;
            }
          }
        }
        if (dCount > 0) totalDepositsCount = dCount;
        totalDepositedAmount = dAmount;

        for (final tx in txList.take(4)) {
          final u = tx.get<ParseObject>('user');
          final userName = (u?.get<String>('name')) ?? 'Jogador';
          final type = tx.get<String>('type') ?? 'deposit';
          recentActivity.add({
            'id': tx.objectId ?? '',
            'type': type,
            'amount': (tx.get<num>('amount') ?? 0.0).toDouble(),
            'status': tx.get<String>('status') ?? 'completed',
            'userName': userName,
            'createdAt': tx.createdAt ?? DateTime.now(),
            'description': tx.get<String>('description') ??
                (type == 'deposit' ? 'Depósito PIX' : 'Transação no Jogo'),
          });
        }
      }

      recentActivity.sort((a, b) {
        final dateA = a['createdAt'] is DateTime
            ? a['createdAt'] as DateTime
            : DateTime.now();
        final dateB = b['createdAt'] is DateTime
            ? b['createdAt'] as DateTime
            : DateTime.now();
        return dateB.compareTo(dateA);
      });
    } catch (e) {
      debugPrint('[AdminDashboard] Erro ao carregar finanças: $e');
    }

    // 6. Consulta Banners
    int totalBanners = 0;
    try {
      final bQuery = QueryBuilder<ParseObject>(ParseObject('Banner'));
      final bRes = await bQuery.query();
      if (bRes.success && bRes.results != null) {
        totalBanners = bRes.results!.length;
      }
    } catch (_) {}

    // 7. Consulta Dicas
    int totalHints = 0;
    try {
      final hQuery = QueryBuilder<ParseObject>(ParseObject('Hint'));
      final hRes = await hQuery.query();
      if (hRes.success && hRes.results != null) {
        totalHints = hRes.results!.length;
      }
    } catch (_) {}

    return {
      'totalPlayers': totalUsers,
      'totalUsersBalance': totalUsersBalance,
      'topPlayers': topPlayers,
      'totalEvents': totalEvents > 0
          ? totalEvents
          : (cloudData['totalEvents'] ?? cloudData['activeEvents'] ?? 0),
      'activeEvents':
          activeEvents > 0 ? activeEvents : (cloudData['activeEvents'] ?? 0),
      'totalPrizePool': totalPrizePool,
      'recentEvents': recentEvents,
      'totalEnigmas':
          totalEnigmas > 0 ? totalEnigmas : (cloudData['totalEnigmas'] ?? 0),
      'activeEnigmas': activeEnigmas,
      'difficultyCounts': difficultyCounts,
      'withCompass': withCompass,
      'withRadar': withRadar,
      'withMap': withMap,
      'withAudio': withAudio,
      'withGps': withGps,
      'totalBanners':
          totalBanners > 0 ? totalBanners : (cloudData['totalBanners'] ?? 0),
      'totalHints':
          totalHints > 0 ? totalHints : (cloudData['totalHints'] ?? 0),
      'pendingWithdrawalsCount': pendingWithdrawalsCount,
      'pendingWithdrawalsAmount': pendingWithdrawalsAmount,
      'totalDepositsCount': totalDepositsCount,
      'totalDepositedAmount': totalDepositedAmount,
      'recentActivity': recentActivity.take(6).toList(),
      'lastUpdated': DateTime.now(),
    };
  }

  Future<List<dynamic>> listAllUsers() async {
    final result = await callFunction('listAllUsers');
    return result.result as List<dynamic>;
  }

  Future<void> grantAdminRole(String objectId) {
    return callFunction('grantAdminRole', {'objectId': objectId});
  }

  Future<void> revokeAdminRole(String objectId) {
    return callFunction('revokeAdminRole', {'objectId': objectId});
  }

  Future<void> createOrUpdateHint(
    Map<String, dynamic> data, {
    String? hintId,
  }) async {
    final payload = <String, dynamic>{'data': data};
    if (hintId != null) {
      payload['hintId'] = hintId;
    }
    await callFunction('createOrUpdateHint', payload);
  }

  Future<void> deleteHint(String hintId) async {
    await callFunction('deleteHint', {'hintId': hintId});
  }
}
