import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> {
  int _selectedTab = 0; // 0: Saques Pendentes, 1: Histórico de Saques, 2: Depósitos
  bool _isLoading = true;

  List<ParseObject> _pendingWithdrawals = [];
  List<ParseObject> _allWithdrawals = [];
  List<ParseObject> _deposits = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  ParseObject? _getSafeUser(ParseObject obj) {
    final raw = obj.get<dynamic>('user');
    if (raw is ParseObject) return raw;
    if (raw is Map) {
      final uMap = Map<String, dynamic>.from(raw);
      final userObj = ParseUser(null, null, null);
      userObj.objectId = uMap['objectId']?.toString();
      uMap.forEach((k, v) {
        if (k != 'objectId' && v != null) userObj.set(k, v);
      });
      return userObj;
    }
    return null;
  }

  ParseObject _parseObjectFromMap(String className, Map<dynamic, dynamic> map) {
    final Map<String, dynamic> cleanMap = Map<String, dynamic>.from(map);
    final obj = ParseObject(className);
    if (cleanMap['objectId'] != null) {
      obj.objectId = cleanMap['objectId'].toString();
    }
    if (cleanMap['createdAt'] != null) {
      final dt = DateTime.tryParse(cleanMap['createdAt'].toString());
      if (dt != null) obj.set<DateTime>('createdAt', dt);
    }
    if (cleanMap['updatedAt'] != null) {
      final dt = DateTime.tryParse(cleanMap['updatedAt'].toString());
      if (dt != null) obj.set<DateTime>('updatedAt', dt);
    }
    cleanMap.forEach((key, val) {
      if (key != 'objectId' && key != 'createdAt' && key != 'updatedAt' && val != null) {
        if (key == 'amount') {
          obj.set<num>('amount', val is num ? val : (num.tryParse(val.toString()) ?? 0.0));
        } else if (key == 'user' && val is Map) {
          final uMap = Map<String, dynamic>.from(val);
          final userObj = ParseUser(null, null, null);
          userObj.objectId = uMap['objectId']?.toString();
          uMap.forEach((uK, uV) {
            if (uK != 'objectId' && uV != null) userObj.set(uK, uV);
          });
          obj.set('user', userObj);
        } else {
          obj.set(key, val);
        }
      }
    });
    return obj;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      List<ParseObject> withdrawals = [];
      List<ParseObject> allTx = [];

      // 1. Obtém sessão do usuário admin atual
      final currentUser = await ParseUser.currentUser() as ParseUser?;
      final sessionToken = currentUser?.sessionToken;

      // 2. Carrega via Cloud Function segura (usa MasterKey no backend, sem expor permissão pública de CLP)
      try {
        final params = <String, dynamic>{};
        if (sessionToken != null) params['sessionToken'] = sessionToken;

        final headers = <String, String>{};
        if (sessionToken != null) headers['X-Parse-Session-Token'] = sessionToken;

        final cloudRes = await ParseCloudFunction('getAdminFinancialData').execute(
          parameters: params.isNotEmpty ? params : null,
          headers: headers.isNotEmpty ? headers : null,
        );
        if (cloudRes.success && cloudRes.result != null) {
          final data = Map<String, dynamic>.from(cloudRes.result as Map);
          final rawW = (data['withdrawals'] as List?) ?? [];
          final rawT = (data['transactions'] as List?) ?? [];

          withdrawals = rawW
              .map((item) => _parseObjectFromMap('Withdrawal', item as Map))
              .toList();
          allTx = rawT
              .map((item) => _parseObjectFromMap('Transaction', item as Map))
              .toList();
        } else {
          debugPrint('[AdminMobileFinance] Cloud Function aviso: ${cloudRes.error?.message}');
        }
      } catch (e) {
        debugPrint('[AdminMobileFinance] Erro ao carregar via Cloud Function: $e');
      }

      // Fallback para queries diretas caso necessário
      if (withdrawals.isEmpty) {
        final qAllW = QueryBuilder<ParseObject>(ParseObject('Withdrawal'))
          ..includeObject(['user'])
          ..orderByDescending('createdAt')
          ..setLimit(300);
        final resAllW = await qAllW.query();
        if (resAllW.success && resAllW.results != null) {
          withdrawals = resAllW.results as List<ParseObject>;
        }
      }

      if (allTx.isEmpty) {
        final qDep = QueryBuilder<ParseObject>(ParseObject('Transaction'))
          ..includeObject(['user'])
          ..orderByDescending('createdAt')
          ..setLimit(300);
        final resDep = await qDep.query();
        if (resDep.success && resDep.results != null) {
          allTx = resDep.results as List<ParseObject>;
        }
      }

      final pendingList = withdrawals.where((w) => (w.get<String>('status') ?? 'pending') == 'pending').toList();
      final depList = allTx.where((tx) => tx.get<String>('type') == 'deposit').toList();

      if (mounted) {
        setState(() {
          _pendingWithdrawals = pendingList;
          _allWithdrawals = withdrawals;
          _deposits = depList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Executa Saque (auto_payout, approve, reject)
  Future<void> _handleWithdrawal(
    String withdrawalId,
    String? userId,
    String action, {
    String? receipt,
    String? rejectionReason,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.verdeVale)),
    );

    try {
      final currentUser = await ParseUser.currentUser() as ParseUser?;
      final sessionToken = currentUser?.sessionToken;

      final params = <String, dynamic>{
        'withdrawalId': withdrawalId,
        'action': action,
      };
      if (sessionToken != null) params['sessionToken'] = sessionToken;
      if (userId != null && userId.isNotEmpty) params['objectId'] = userId;
      if (receipt != null && receipt.isNotEmpty) params['receipt'] = receipt;
      if (rejectionReason != null && rejectionReason.isNotEmpty) {
        params['rejectionReason'] = rejectionReason;
      }

      final headers = <String, String>{};
      if (sessionToken != null) headers['X-Parse-Session-Token'] = sessionToken;

      final res = await ParseCloudFunction('processWithdrawal').execute(
        parameters: params,
        headers: headers.isNotEmpty ? headers : null,
      );

      if (mounted) {
        Navigator.pop(context); // Fecha dialog de loading
        if (res.success) {
          final resData = res.result is Map ? Map<String, dynamic>.from(res.result as Map) : null;
          final receiptMsg = (resData != null && resData['receipt'] != null)
              ? '\nComprovante: ${resData['receipt']}'
              : '';

          String msg = 'Saque processado com sucesso!';
          if (action == 'auto_payout') {
            msg = '⚡ Pagamento automático Pix realizado com sucesso!$receiptMsg';
          } else if (action == 'approve') {
            msg = 'Saque aprovado manualmente!$receiptMsg';
          } else {
            msg = 'Saque rejeitado e saldo estornado para a carteira.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: action == 'reject' ? Colors.redAccent : AppColors.verdeVale,
              duration: const Duration(seconds: 4),
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: ${res.error?.message ?? "Falha ao processar"}'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exceção ao processar saque: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Diálogo para Pagamento Automático
  void _confirmAutoPayout(ParseObject w, String userName, double amount, String pixKey, String pixKeyType, String? userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.bolt, color: AppColors.amareloVale, size: 20),
            const SizedBox(width: 10),
            Text('Pagamento Pix API', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jogador: $userName', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text('Valor: R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(color: AppColors.amareloVale, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            Text('Chave Pix ($pixKeyType):', style: const TextStyle(color: Colors.white70)),
            SelectableText(pixKey, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'A transferência Pix será realizada imediatamente através da API do Gateway ativo.',
              style: TextStyle(color: AppColors.cinzaMedio, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppColors.cinzaMedio))),
          ElevatedButton.icon(
            icon: const FaIcon(FontAwesomeIcons.bolt, size: 14),
            label: const Text('Confirmar & Pagar'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amareloVale, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              _handleWithdrawal(w.objectId!, userId, 'auto_payout');
            },
          ),
        ],
      ),
    );
  }

  // Diálogo para Aprovação Manual
  void _confirmManualApproval(ParseObject w, String userName, double amount, String pixKey, String? userId) {
    final receiptController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Aprovação Manual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jogador: $userName', style: const TextStyle(color: Colors.white70)),
            Text('Valor: R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(color: AppColors.verdeVale, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: receiptController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Comprovante / Código de Autenticação (Opcional)',
                labelStyle: TextStyle(color: AppColors.cinzaMedio, fontSize: 12),
                hintText: 'Ex: E123456789...',
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppColors.cinzaMedio))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.verdeVale, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _handleWithdrawal(w.objectId!, userId, 'approve', receipt: receiptController.text.trim());
            },
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );
  }

  // Diálogo para Rejeitar Saque e Estornar Saldo
  void _confirmReject(ParseObject w, String userName, double amount, String? userId) {
    final reasonController = TextEditingController(text: 'Dados Pix inconsistentes');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rejeitar & Estornar Saldo', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('O valor de R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')} será estornado integralmente para a carteira de $userName.',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Motivo da rejeição',
                labelStyle: TextStyle(color: AppColors.cinzaMedio, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Voltar', style: TextStyle(color: AppColors.cinzaMedio))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _handleWithdrawal(w.objectId!, userId, 'reject', rejectionReason: reasonController.text.trim());
            },
            child: const Text('Rejeitar & Estornar'),
          ),
        ],
      ),
    );
  }

  // Aprovação Manual de Depósito
  Future<void> _approveDepositManual(String transactionId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.verdeVale)),
    );

    try {
      final res = await ParseCloudFunction('approveDepositManual').execute(
        parameters: {'transactionId': transactionId},
      );

      if (mounted) {
        Navigator.pop(context);
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Depósito aprovado e saldo creditado!'), backgroundColor: AppColors.verdeVale),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: ${res.error?.message ?? "Falha ao aprovar"}'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exceção ao aprovar depósito: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título e Botão Recarregar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gestão Financeira (Pix)',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, color: Colors.white70, size: 16),
              tooltip: 'Recarregar dados',
              onPressed: _loadData,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTabPill('Pendentes (${_pendingWithdrawals.length})', 0, FontAwesomeIcons.clock),
              const SizedBox(width: 8),
              _buildTabPill('Todos os Saques (${_allWithdrawals.length})', 1, FontAwesomeIcons.listCheck),
              const SizedBox(width: 8),
              _buildTabPill('Depósitos (${_deposits.length})', 2, FontAwesomeIcons.arrowDown),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.verdeVale))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.verdeVale,
                  backgroundColor: AppColors.darkCardColor,
                  child: _buildSelectedTabContent(),
                ),
        ),
      ],
    );
  }

  Widget _buildTabPill(String label, int index, dynamic icon) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.verdeVale : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.verdeVale : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            FaIcon(icon, size: 12, color: isSelected ? Colors.white : AppColors.cinzaMedio),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : AppColors.cinzaMedio,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    if (_selectedTab == 0) {
      return _buildPendingWithdrawalsList();
    } else if (_selectedTab == 1) {
      return _buildAllWithdrawalsList();
    } else {
      return _buildDepositsList();
    }
  }

  Widget _buildPendingWithdrawalsList() {
    if (_pendingWithdrawals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.circleCheck, color: AppColors.verdeVale, size: 40),
            const SizedBox(height: 12),
            Text('Nenhuma solicitação de saque pendente!', style: GoogleFonts.inter(color: Colors.white70)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemCount: _pendingWithdrawals.length,
      itemBuilder: (context, index) {
        final w = _pendingWithdrawals[index];
        final user = _getSafeUser(w);
        final userId = user?.objectId;
        final userName = w.get<String>('userName') ?? user?.get<String>('name') ?? 'Jogador';
        final userEmail = w.get<String>('userEmail') ?? user?.get<String>('email') ?? '';
        final amount = (w.get<num>('amount') ?? 0.0).toDouble();
        final pixKey = w.get<String>('pixKey') ?? 'Não informada';
        final pixKeyType = w.get<String>('pixKeyType') ?? 'CHAVE_ALEATORIA';
        final date = w.createdAt;
        final dateStr = date != null ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}' : '';

        return Card(
          color: AppColors.darkCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          if (userEmail.isNotEmpty)
                            Text(userEmail, style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(
                      'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.poppins(color: AppColors.amareloVale, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.pix, color: Color(0xFF32BCAD), size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          '$pixKey ($pixKeyType)',
                          style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Solicitado em: $dateStr', style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 10)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.bolt, size: 12),
                        label: const Text('Pagar API'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amareloVale,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _confirmAutoPayout(w, userName, amount, pixKey, pixKeyType, userId),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.check, size: 12),
                        label: const Text('Manual'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.verdeVale,
                          side: const BorderSide(color: AppColors.verdeVale),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _confirmManualApproval(w, userName, amount, pixKey, userId),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.redAccent, size: 14),
                      tooltip: 'Rejeitar & Estornar',
                      onPressed: () => _confirmReject(w, userName, amount, userId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllWithdrawalsList() {
    if (_allWithdrawals.isEmpty) {
      return const Center(child: Text('Nenhum registro de saque.', style: TextStyle(color: AppColors.cinzaMedio)));
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemCount: _allWithdrawals.length,
      itemBuilder: (context, index) {
        final w = _allWithdrawals[index];
        final userName = w.get<String>('userName') ?? 'Jogador';
        final amount = (w.get<num>('amount') ?? 0.0).toDouble();
        final status = w.get<String>('status') ?? 'pending';
        final pixKey = w.get<String>('pixKey') ?? '';
        final receipt = w.get<String>('receipt');
        final reason = w.get<String>('rejectionReason');

        Color statusColor = AppColors.cinzaMedio;
        String statusLabel = 'PENDENTE';
        if (status == 'completed' || status == 'approved') {
          statusColor = AppColors.verdeVale;
          statusLabel = 'CONCLUÍDO';
        } else if (status == 'rejected') {
          statusColor = Colors.redAccent;
          statusLabel = 'ESTORNADO';
        }

        return Card(
          color: AppColors.darkCardColor,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chave: $pixKey', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                if (receipt != null && receipt.isNotEmpty)
                  Text('Comprovante: $receipt', style: const TextStyle(color: AppColors.verdeVale, fontSize: 10)),
                if (reason != null && reason.isNotEmpty)
                  Text('Motivo: $reason', style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDepositsList() {
    if (_deposits.isEmpty) {
      return const Center(child: Text('Nenhum depósito registrado.', style: TextStyle(color: AppColors.cinzaMedio)));
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemCount: _deposits.length,
      itemBuilder: (context, index) {
        final d = _deposits[index];
        final user = _getSafeUser(d);
        final userName = user?.get<String>('name') ?? 'Jogador';
        final amount = (d.get<num>('amount') ?? 0.0).toDouble();
        final status = d.get<String>('status') ?? 'pending';
        final isApproved = status == 'approved' || status == 'completed';

        return Card(
          color: AppColors.darkCardColor,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isApproved ? AppColors.verdeVale.withValues(alpha: 0.2) : AppColors.amareloVale.withValues(alpha: 0.2),
              child: FaIcon(
                isApproved ? FontAwesomeIcons.arrowTrendUp : FontAwesomeIcons.clock,
                color: isApproved ? AppColors.verdeVale : AppColors.amareloVale,
                size: 14,
              ),
            ),
            title: Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(
              isApproved ? 'Depósito Confirmado' : 'Aguardando Pagamento Pix',
              style: TextStyle(color: isApproved ? AppColors.verdeVale : AppColors.cinzaMedio, fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+ R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(color: isApproved ? AppColors.verdeVale : Colors.white70, fontWeight: FontWeight.bold),
                ),
                if (!isApproved) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.circleCheck, color: AppColors.verdeVale, size: 16),
                    tooltip: 'Aprovar Manualmente',
                    onPressed: () => _approveDepositManual(d.objectId!),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
