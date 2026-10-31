import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/admin_modal.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> {
  int _selectedTab = 0; // 0: Saques, 1: Depósitos, 2: Extrato Geral
  bool _isLoading = true;

  // Filtros de Saques
  String _withdrawalFilter = 'all'; // all, pending, completed, rejected
  // Filtros de Depósitos
  String _depositFilter = 'all'; // all, approved, pending, failed
  // Filtro de Extrato Geral
  String _statementFilter = 'all'; // all, deposit, withdrawal, reward

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<ParseObject> _withdrawals = [];
  List<ParseObject> _deposits = [];
  List<ParseObject> _allTransactions = [];

  // KPIs
  double _totalDeposited = 0.0;
  double _totalWithdrawn = 0.0;
  double _totalPendingWithdrawalsAmount = 0.0;
  int _pendingWithdrawalsCount = 0;
  double _totalUsersBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAllFinancialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadAllFinancialData() async {
    setState(() => _isLoading = true);
    try {
      List<ParseObject> withdrawals = [];
      List<ParseObject> allTx = [];

      // 1. Obtém a sessão do usuário admin atual
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
          debugPrint('[AdminFinance] Cloud Function aviso: ${cloudRes.error?.message}');
        }
      } catch (e) {
        debugPrint('[AdminFinance] Erro ao carregar via Cloud Function: $e');
      }

      // Fallback para query direta (se CLP estiver aberta)
      if (withdrawals.isEmpty) {
        final wQuery = QueryBuilder<ParseObject>(ParseObject('Withdrawal'))
          ..includeObject(['user'])
          ..orderByDescending('createdAt')
          ..setLimit(500);
        final wResponse = await wQuery.query();
        if (wResponse.success && wResponse.results != null) {
          withdrawals = wResponse.results as List<ParseObject>;
        }
      }

      if (allTx.isEmpty) {
        final tQuery = QueryBuilder<ParseObject>(ParseObject('Transaction'))
          ..includeObject(['user'])
          ..orderByDescending('createdAt')
          ..setLimit(1000);
        final tResponse = await tQuery.query();
        if (tResponse.success && tResponse.results != null) {
          allTx = tResponse.results as List<ParseObject>;
        }
      }

      // Separa depósitos
      final deposits = allTx.where((tx) => tx.get<String>('type') == 'deposit').toList();

      // 3. Calcula KPIs
      double sumDeposited = 0.0;
      for (final d in deposits) {
        if (d.get<String>('status') == 'approved' || d.get<String>('status') == 'completed') {
          sumDeposited += (d.get<num>('amount') ?? 0.0).toDouble();
        }
      }

      double sumWithdrawn = 0.0;
      double sumPendingW = 0.0;
      int countPendingW = 0;
      for (final w in withdrawals) {
        final status = w.get<String>('status') ?? 'pending';
        final amount = (w.get<num>('amount') ?? 0.0).toDouble();
        if (status == 'completed' || status == 'approved') {
          sumWithdrawn += amount;
        } else if (status == 'pending') {
          sumPendingW += amount;
          countPendingW++;
        }
      }

      // 4. Saldo total de usuários (opcional para KPI)
      double sumUsersBalance = 0.0;
      try {
        final uQuery = QueryBuilder<ParseUser>(ParseUser.forQuery())
          ..whereGreaterThan('balance', 0)
          ..setLimit(500);
        final uRes = await uQuery.query();
        if (uRes.success && uRes.results != null) {
          for (final u in (uRes.results as List<ParseObject>)) {
            sumUsersBalance += (u.get<num>('balance') ?? 0.0).toDouble();
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _withdrawals = withdrawals;
          _deposits = deposits;
          _allTransactions = allTx;
          _totalDeposited = sumDeposited;
          _totalWithdrawn = sumWithdrawn;
          _totalPendingWithdrawalsAmount = sumPendingW;
          _pendingWithdrawalsCount = countPendingW;
          _totalUsersBalance = sumUsersBalance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados financeiros: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // ==========================================
  // FILTRAGEM
  // ==========================================
  List<ParseObject> get _filteredWithdrawals {
    return _withdrawals.where((w) {
      final status = w.get<String>('status') ?? 'pending';
      if (_withdrawalFilter != 'all') {
        if (_withdrawalFilter == 'completed' && (status != 'completed' && status != 'approved')) return false;
        if (_withdrawalFilter == 'pending' && status != 'pending') return false;
        if (_withdrawalFilter == 'rejected' && status != 'rejected') return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final userName = (w.get<String>('userName') ?? '').toLowerCase();
        final userEmail = (w.get<String>('userEmail') ?? '').toLowerCase();
        final pixKey = (w.get<String>('pixKey') ?? '').toLowerCase();
        final id = (w.objectId ?? '').toLowerCase();
        return userName.contains(query) || userEmail.contains(query) || pixKey.contains(query) || id.contains(query);
      }
      return true;
    }).toList();
  }

  List<ParseObject> get _filteredDeposits {
    return _deposits.where((d) {
      final status = d.get<String>('status') ?? 'pending';
      if (_depositFilter != 'all') {
        if (_depositFilter == 'approved' && (status != 'approved' && status != 'completed')) return false;
        if (_depositFilter == 'pending' && status != 'pending') return false;
        if (_depositFilter == 'failed' && (status != 'failed' && status != 'cancelled')) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final desc = (d.get<String>('description') ?? '').toLowerCase();
        final gateway = (d.get<String>('gateway') ?? '').toLowerCase();
        final id = (d.objectId ?? '').toLowerCase();
        final user = _getSafeUser(d);
        final userName = (user?.get<String>('name') ?? user?.get<String>('username') ?? '').toLowerCase();
        final userEmail = (user?.get<String>('email') ?? '').toLowerCase();
        return desc.contains(query) || gateway.contains(query) || id.contains(query) || userName.contains(query) || userEmail.contains(query);
      }
      return true;
    }).toList();
  }

  List<ParseObject> get _filteredStatement {
    return _allTransactions.where((tx) {
      final type = tx.get<String>('type') ?? 'deposit';
      if (_statementFilter != 'all' && type != _statementFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final desc = (tx.get<String>('description') ?? '').toLowerCase();
        final id = (tx.objectId ?? '').toLowerCase();
        final user = _getSafeUser(tx);
        final userName = (user?.get<String>('name') ?? user?.get<String>('username') ?? '').toLowerCase();
        return desc.contains(query) || id.contains(query) || userName.contains(query);
      }
      return true;
    }).toList();
  }

  // ==========================================
  // BUILD PRINCIPAL
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildKpisRow(),
        const SizedBox(height: 24),
        _buildTabsAndSearch(),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.verdeVale))
              : _buildTabContent(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.verdeVale.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.moneyBillTransfer,
                    color: AppColors.verdeVale,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'GESTÃO DE SAQUES & DEPÓSITOS',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Auditoria, aprovação de saques Pix, controle de depósitos e conciliação financeira',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.cinzaMedio,
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 13),
              label: const Text('Atualizar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cinzaMedio,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _loadAllFinancialData,
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.filePdf, size: 14),
              label: const Text('Exportar Relatório PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amareloVale,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _exportFinancialReport(context),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // CARDS DE KPIS
  // ==========================================
  Widget _buildKpisRow() {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: 'TOTAL DEPOSITADO',
            value: 'R\$ ${_totalDeposited.toStringAsFixed(2).replaceAll('.', ',')}',
            icon: FontAwesomeIcons.circleArrowDown,
            iconColor: AppColors.verdeVale,
            badgeText: 'Entradas Aprovadas',
            badgeColor: AppColors.verdeVale,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            title: 'TOTAL SACADO (PAGO)',
            value: 'R\$ ${_totalWithdrawn.toStringAsFixed(2).replaceAll('.', ',')}',
            icon: FontAwesomeIcons.circleArrowUp,
            iconColor: const Color(0xFF3B82F6),
            badgeText: 'Saídas Concluídas',
            badgeColor: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            title: 'SAQUES PENDENTES',
            value: 'R\$ ${_totalPendingWithdrawalsAmount.toStringAsFixed(2).replaceAll('.', ',')}',
            icon: FontAwesomeIcons.triangleExclamation,
            iconColor: AppColors.amareloVale,
            badgeText: '$_pendingWithdrawalsCount aguardando',
            badgeColor: _pendingWithdrawalsCount > 0 ? AppColors.amareloVale : AppColors.cinzaMedio,
            isHighlighted: _pendingWithdrawalsCount > 0,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            title: 'SALDO EM CUSTÓDIA',
            value: 'R\$ ${_totalUsersBalance.toStringAsFixed(2).replaceAll('.', ',')}',
            icon: FontAwesomeIcons.vault,
            iconColor: const Color(0xFFA855F7),
            badgeText: 'Carteiras de Jogadores',
            badgeColor: const Color(0xFFA855F7),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required dynamic icon,
    required Color iconColor,
    required String badgeText,
    required Color badgeColor,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted
              ? AppColors.amareloVale.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.08),
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? AppColors.amareloVale.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.cinzaMedio,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(icon, color: iconColor, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: isHighlighted ? AppColors.amareloVale : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.inter(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ABAS E BUSCA
  // ==========================================
  Widget _buildTabsAndSearch() {
    return Row(
      children: [
        // Botões de Abas
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.darkCardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              _buildTabButton(
                index: 0,
                label: 'Solicitações de Saque',
                icon: FontAwesomeIcons.moneyBillWave,
                badgeCount: _pendingWithdrawalsCount,
              ),
              const SizedBox(width: 4),
              _buildTabButton(
                index: 1,
                label: 'Depósitos & Entradas',
                icon: FontAwesomeIcons.circleArrowDown,
              ),
              const SizedBox(width: 4),
              _buildTabButton(
                index: 2,
                label: 'Extrato Geral',
                icon: FontAwesomeIcons.receipt,
              ),
            ],
          ),
        ),
        const Spacer(),
        // Campo de Pesquisa
        SizedBox(
          width: 280,
          height: 42,
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar jogador, email, pix, id...',
              hintStyle: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: AppColors.cinzaMedio, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: AppColors.cinzaMedio, size: 16),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.darkCardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.verdeVale),
              ),
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val.trim());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required dynamic icon,
    int badgeCount = 0,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.verdeVale.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.verdeVale.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              icon,
              size: 13,
              color: isSelected ? AppColors.verdeVale : AppColors.cinzaMedio,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.cinzaMedio,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amareloVale,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CONTEÚDO DA ABA SELECIONADA
  // ==========================================
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildWithdrawalsTab();
      case 1:
        return _buildDepositsTab();
      case 2:
      default:
        return _buildStatementTab();
    }
  }

  // ==========================================
  // 1. ABA DE SAQUES
  // ==========================================
  Widget _buildWithdrawalsTab() {
    final list = _filteredWithdrawals;

    return Column(
      children: [
        // Pílulas de filtro
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill('Todos (${_withdrawals.length})', 'all', _withdrawalFilter, (v) => setState(() => _withdrawalFilter = v)),
              const SizedBox(width: 8),
              _buildFilterPill('Pendentes ($_pendingWithdrawalsCount)', 'pending', _withdrawalFilter, (v) => setState(() => _withdrawalFilter = v), highlightColor: AppColors.amareloVale),
              const SizedBox(width: 8),
              _buildFilterPill('Pagos / Aprovados', 'completed', _withdrawalFilter, (v) => setState(() => _withdrawalFilter = v), highlightColor: AppColors.verdeVale),
              const SizedBox(width: 8),
              _buildFilterPill('Rejeitados', 'rejected', _withdrawalFilter, (v) => setState(() => _withdrawalFilter = v), highlightColor: Colors.redAccent),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyState('Nenhuma solicitação de saque encontrada.')
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildWithdrawalCard(list[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildWithdrawalCard(ParseObject w) {
    final user = _getSafeUser(w);
    final userId = user?.objectId ?? (w.get<String>('objectId') ?? '');
    final userName = w.get<String>('userName') ?? (user?.get<String>('name') ?? user?.get<String>('username') ?? 'Jogador Desconhecido');
    final userEmail = w.get<String>('userEmail') ?? (user?.get<String>('email') ?? 'Sem email');
    final amount = (w.get<num>('amount') ?? 0.0).toDouble();
    final pixKey = w.get<String>('pixKey') ?? 'Não informada';
    final pixKeyType = w.get<String>('pixKeyType') ?? 'CHAVE_ALEATORIA';
    final status = w.get<String>('status') ?? 'pending';
    final receipt = w.get<String>('receipt');
    final rejectionReason = w.get<String>('rejectionReason');

    final createdAt = w.createdAt;
    final dateStr = createdAt != null
        ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} às ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '-';

    Color statusColor;
    String statusLabel;
    dynamic statusIcon;
    if (status == 'completed' || status == 'approved') {
      statusColor = AppColors.verdeVale;
      statusLabel = 'PAGO / CONCLUÍDO';
      statusIcon = FontAwesomeIcons.solidCircleCheck;
    } else if (status == 'rejected') {
      statusColor = Colors.redAccent;
      statusLabel = 'REJEITADO & ESTORNADO';
      statusIcon = FontAwesomeIcons.circleXmark;
    } else {
      statusColor = AppColors.amareloVale;
      statusLabel = 'PENDENTE DE APROVAÇÃO';
      statusIcon = FontAwesomeIcons.clock;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'pending'
              ? AppColors.amareloVale.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar do Jogador
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.verdeVale.withValues(alpha: 0.2),
            child: Text(
              userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'J',
              style: GoogleFonts.poppins(
                color: AppColors.verdeVale,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Informações do Jogador e da Chave Pix
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'UID: $userId',
                        style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  userEmail,
                  style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 12),
                ),
                const SizedBox(height: 8),
                // Box Chave Pix com Cópia Rápida
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1821),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.pix, color: Color(0xFF32BCAD), size: 12),
                          const SizedBox(width: 6),
                          Text(
                            '$pixKeyType: ',
                            style: GoogleFonts.inter(
                              color: AppColors.cinzaMedio,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SelectableText(
                            pixKey,
                            style: GoogleFonts.robotoMono(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.copy, size: 13, color: AppColors.amareloVale),
                      tooltip: 'Copiar Chave Pix',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: pixKey));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Chave Pix copiada: $pixKey'),
                            backgroundColor: AppColors.verdeVale,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Valor e Data
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: GoogleFonts.poppins(
                    color: AppColors.amareloVale,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    FaIcon(statusIcon, color: statusColor, size: 11),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Solicitado: $dateStr',
                  style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 11),
                ),
                if (receipt != null && receipt.isNotEmpty)
                  Text(
                    'Comprovante: $receipt',
                    style: GoogleFonts.inter(color: AppColors.verdeVale, fontSize: 11),
                  ),
                if (rejectionReason != null && rejectionReason.isNotEmpty)
                  Text(
                    'Motivo: $rejectionReason',
                    style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 11),
                  ),
              ],
            ),
          ),
          // Ações Administrativas
          if (status == 'pending') ...[
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.bolt, size: 12),
              label: const Text('Pagar Pix (API)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amareloVale,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showAutoPayoutModal(w, userName, amount, pixKey, pixKeyType, userId),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.check, size: 12),
              label: const Text('Aprovar Manual'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeVale,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showApproveWithdrawalModal(w, userName, amount, pixKey, pixKeyType, userId),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.xmark, size: 12),
              label: const Text('Rejeitar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showRejectWithdrawalModal(w, userName, amount, userId),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                status == 'completed' ? 'Finalizado' : 'Estornado',
                style: GoogleFonts.inter(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 2. ABA DE DEPÓSITOS
  // ==========================================
  Widget _buildDepositsTab() {
    final list = _filteredDeposits;

    return Column(
      children: [
        // Pílulas de filtro
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill('Todos (${_deposits.length})', 'all', _depositFilter, (v) => setState(() => _depositFilter = v)),
              const SizedBox(width: 8),
              _buildFilterPill('Aprovados', 'approved', _depositFilter, (v) => setState(() => _depositFilter = v), highlightColor: AppColors.verdeVale),
              const SizedBox(width: 8),
              _buildFilterPill('Pendentes', 'pending', _depositFilter, (v) => setState(() => _depositFilter = v), highlightColor: AppColors.amareloVale),
              const SizedBox(width: 8),
              _buildFilterPill('Falhas / Cancelados', 'failed', _depositFilter, (v) => setState(() => _depositFilter = v), highlightColor: Colors.redAccent),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyState('Nenhum depósito registrado no momento.')
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildDepositCard(list[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildDepositCard(ParseObject d) {
    final user = _getSafeUser(d);
    final userName = user?.get<String>('name') ?? user?.get<String>('username') ?? 'Jogador';
    final userEmail = user?.get<String>('email') ?? '';
    final amount = (d.get<num>('amount') ?? 0.0).toDouble();
    final gateway = (d.get<String>('gateway') ?? 'mercadopago').toUpperCase();
    final status = d.get<String>('status') ?? 'pending';
    final description = d.get<String>('description') ?? 'Depósito via Pix';
    final id = d.objectId!;

    final createdAt = d.createdAt;
    final dateStr = createdAt != null
        ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} às ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '-';

    Color statusColor;
    String statusLabel;
    if (status == 'approved' || status == 'completed') {
      statusColor = AppColors.verdeVale;
      statusLabel = 'APROVADO';
    } else if (status == 'failed' || status == 'cancelled') {
      statusColor = Colors.redAccent;
      statusLabel = 'FALHOU';
    } else {
      statusColor = AppColors.amareloVale;
      statusLabel = 'PENDENTE';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'pending'
              ? AppColors.amareloVale.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.verdeVale.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const FaIcon(FontAwesomeIcons.circleArrowDown, color: AppColors.verdeVale, size: 20),
          ),
          const SizedBox(width: 16),
          // Info Jogador e Gateway
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        gateway,
                        style: GoogleFonts.inter(color: AppColors.amareloVale, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail.isNotEmpty ? '$userEmail • $description' : description,
                  style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'ID: $id',
                      style: GoogleFonts.robotoMono(color: AppColors.cinzaMedio, fontSize: 11),
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.copy, size: 11, color: AppColors.cinzaMedio),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Copiar ID',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ID da transação copiado!'), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Valor e Data
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+ R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: GoogleFonts.poppins(
                    color: AppColors.verdeVale,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: GoogleFonts.inter(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 11),
                ),
              ],
            ),
          ),
          // Ação para Aprovar Manualmente caso webhook tenha falhado
          if (status == 'pending') ...[
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.circleCheck, size: 12),
              label: const Text('Aprovar Manual'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amareloVale,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showApproveDepositManualModal(d, userName, amount),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.xmark, size: 12),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _executeCancelDeposit(d.objectId!),
            ),
          ]
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusLabel,
                style: GoogleFonts.inter(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. ABA DE EXTRATO CONSOLIDADO
  // ==========================================
  Widget _buildStatementTab() {
    final list = _filteredStatement;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill('Todas as Movimentações (${_allTransactions.length})', 'all', _statementFilter, (v) => setState(() => _statementFilter = v)),
              const SizedBox(width: 8),
              _buildFilterPill('Depósitos', 'deposit', _statementFilter, (v) => setState(() => _statementFilter = v), highlightColor: AppColors.verdeVale),
              const SizedBox(width: 8),
              _buildFilterPill('Saques', 'withdrawal', _statementFilter, (v) => setState(() => _statementFilter = v), highlightColor: const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _buildFilterPill('Prêmios Concedidos', 'reward', _statementFilter, (v) => setState(() => _statementFilter = v), highlightColor: AppColors.amareloVale),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyState('Nenhuma movimentação registrada no extrato.')
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tx = list[index];
                    final type = tx.get<String>('type') ?? 'deposit';
                    final amount = (tx.get<num>('amount') ?? 0.0).toDouble();
                    final status = tx.get<String>('status') ?? 'pending';
                    final desc = tx.get<String>('description') ?? type.toUpperCase();
                    final user = _getSafeUser(tx);
                    final userName = user?.get<String>('name') ?? user?.get<String>('username') ?? 'Usuário';

                    final isIncome = type == 'deposit' || type == 'reward';
                    final color = isIncome ? AppColors.verdeVale : (type == 'withdrawal' ? const Color(0xFF3B82F6) : Colors.redAccent);
                    final icon = isIncome ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp;

                    final createdAt = tx.createdAt;
                    final dateStr = createdAt != null
                        ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                        : '-';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.darkCardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: FaIcon(icon, color: color, size: 14),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  desc,
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Jogador: $userName • $dateStr',
                                  style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'} R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: GoogleFonts.poppins(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                status.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: status == 'approved' || status == 'completed' ? AppColors.verdeVale : AppColors.cinzaMedio,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  // MODAIS DE AÇÃO
  // ==========================================
  void _showAutoPayoutModal(
    ParseObject w,
    String userName,
    double amount,
    String pixKey,
    String pixKeyType,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AdminModal(
          title: '⚡ Pagamento Automático Pix (API)',
          maxWidth: 550,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.amareloVale.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Jogador:', style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13)),
                        Text(userName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Valor da Transferência:', style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13)),
                        Text(
                          'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: GoogleFonts.poppins(color: AppColors.amareloVale, fontWeight: FontWeight.w800, fontSize: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tipo de Chave:', style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13)),
                        Text(pixKeyType, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Chave Pix Destino:', style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13)),
                        SelectableText(
                          pixKey,
                          style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.circleInfo, size: 16, color: AppColors.amareloVale),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'O sistema executará a transferência Pix imediata via API do Gateway ativo configurado. O comprovante bancário e o EndToEnd ID serão salvos automaticamente.',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.cinzaMedio)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.bolt, size: 14),
                    label: const Text('Confirmar & Transferir Agora'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amareloVale,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      await _executeWithdrawalAction(
                        w.objectId!,
                        userId,
                        'auto_payout',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showApproveWithdrawalModal(
    ParseObject w,
    String userName,
    double amount,
    String pixKey,
    String pixKeyType,
    String userId,
  ) {
    final receiptController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AdminModal(
          title: 'Aprovar e Pagar Saque Pix',
          maxWidth: 550,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.verdeVale.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Jogador:', style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13)),
                        Text(userName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Valor a Pagar:', style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13)),
                        Text(
                          'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: GoogleFonts.poppins(color: AppColors.amareloVale, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tipo de Chave:', style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13)),
                        Text(pixKeyType, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Chave Pix:', style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13)),
                        SelectableText(
                          pixKey,
                          style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Código de Autenticação / Comprovante Bancário (Opcional):',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: receiptController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Ex: E202610301234567890ABCDEF...',
                  hintStyle: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.darkCardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.cinzaMedio)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.check, size: 14),
                    label: const Text('Confirmar Pagamento Realizado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verdeVale,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      await _executeWithdrawalAction(
                        w.objectId!,
                        userId,
                        'approve',
                        receipt: receiptController.text.trim(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRejectWithdrawalModal(
    ParseObject w,
    String userName,
    double amount,
    String userId,
  ) {
    final reasonController = TextEditingController(text: 'Dados Pix inconsistentes ou solicitação cancelada');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AdminModal(
          title: 'Rejeitar Saque e Devolver Saldo',
          maxWidth: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ao rejeitar, o valor de R\$ ${amount.toStringAsFixed(2)} será imediatamente estornado para a carteira de $userName.',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Motivo da Rejeição (Será visível ao jogador):',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 2,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Informe o motivo...',
                  filled: true,
                  fillColor: AppColors.darkCardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.cinzaMedio)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                    label: const Text('Confirmar Rejeição & Estorno'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      await _executeWithdrawalAction(
                        w.objectId!,
                        userId,
                        'reject',
                        rejectionReason: reasonController.text.trim(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showApproveDepositManualModal(ParseObject d, String userName, double amount) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AdminModal(
          title: 'Aprovar Depósito Manualmente',
          maxWidth: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirmação de Crédito Manual',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                'Você está confirmando manualmente o recebimento de R\$ ${amount.toStringAsFixed(2)} para o jogador $userName.\n\nO saldo será creditado imediatamente na conta do usuário.',
                style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.cinzaMedio)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.check, size: 14),
                    label: const Text('Confirmar e Creditar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verdeVale,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      await _executeApproveDepositManual(d.objectId!);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // EXECUÇÃO DE AÇÕES NO BACKEND
  // ==========================================
  Future<void> _executeWithdrawalAction(
    String withdrawalId,
    String userId,
    String action, {
    String? receipt,
    String? rejectionReason,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.verdeVale)),
    );

    try {
      final currentUser = await ParseUser.currentUser() as ParseUser?;
      final sessionToken = currentUser?.sessionToken;

      final params = <String, dynamic>{
        'withdrawalId': withdrawalId,
        'objectId': userId,
        'action': action,
      };
      if (sessionToken != null) params['sessionToken'] = sessionToken;
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
        Navigator.pop(context); // fecha loading
        if (res.success) {
          final resData = res.result is Map ? Map<String, dynamic>.from(res.result as Map) : null;
          final receiptMsg = (resData != null && resData['receipt'] != null)
              ? '\nComprovante: ${resData['receipt']}'
              : '';
          String feedback = 'Operação realizada com sucesso!';
          if (action == 'auto_payout') {
            feedback = (resData != null && resData['message'] != null)
                ? '${resData['message']}$receiptMsg'
                : '⚡ Pagamento automático Pix executado com sucesso!$receiptMsg';
          } else if (action == 'approve') {
            feedback = 'Saque aprovado e marcado como pago!$receiptMsg';
          } else {
            feedback = 'Saque rejeitado e saldo estornado com sucesso!';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(feedback),
              backgroundColor: action == 'reject' ? Colors.redAccent : AppColors.verdeVale,
              duration: const Duration(seconds: 4),
            ),
          );
          _loadAllFinancialData();
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

  Future<void> _executeCancelDeposit(String transactionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar Depósito?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Deseja realmente cancelar esta solicitação de depósito pendente?',
          style: TextStyle(color: AppColors.cinzaMedio),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar', style: TextStyle(color: AppColors.cinzaMedio)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.verdeVale)),
    );

    try {
      final currentUser = await ParseUser.currentUser() as ParseUser?;
      final sessionToken = currentUser?.sessionToken;

      final params = <String, dynamic>{'transactionId': transactionId};
      if (sessionToken != null) params['sessionToken'] = sessionToken;

      final headers = <String, String>{};
      if (sessionToken != null) headers['X-Parse-Session-Token'] = sessionToken;

      final res = await ParseCloudFunction('cancelDeposit').execute(
        parameters: params,
        headers: headers.isNotEmpty ? headers : null,
      );

      if (mounted) {
        Navigator.pop(context);
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Depósito pendente cancelado com sucesso.'), backgroundColor: Colors.redAccent),
          );
          _loadAllFinancialData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: ${res.error?.message ?? "Falha ao cancelar"}'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exceção ao cancelar depósito: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _executeApproveDepositManual(String transactionId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.verdeVale)),
    );

    try {
      final currentUser = await ParseUser.currentUser() as ParseUser?;
      final sessionToken = currentUser?.sessionToken;

      final params = <String, dynamic>{'transactionId': transactionId};
      if (sessionToken != null) params['sessionToken'] = sessionToken;

      final headers = <String, String>{};
      if (sessionToken != null) headers['X-Parse-Session-Token'] = sessionToken;

      final res = await ParseCloudFunction('approveDepositManual').execute(
        parameters: params,
        headers: headers.isNotEmpty ? headers : null,
      );

      if (mounted) {
        Navigator.pop(context);
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Depósito aprovado com sucesso! Saldo creditado na conta.'),
              backgroundColor: AppColors.verdeVale,
            ),
          );
          _loadAllFinancialData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: ${res.error?.message}'), backgroundColor: Colors.redAccent),
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

  // ==========================================
  // EXPORTAÇÃO REAL DE RELATÓRIO PDF
  // ==========================================
  Future<void> _exportFinancialReport(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.verdeVale)),
    );

    try {
      final doc = pw.Document();
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} às ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Dados de Saques
      final withdrawalsData = _withdrawals.take(40).map((w) {
        final userName = w.get<String>('userName') ?? 'Jogador';
        final amount = (w.get<num>('amount') ?? 0.0).toDouble();
        final pixKey = w.get<String>('pixKey') ?? '-';
        final status = (w.get<String>('status') ?? 'pending').toUpperCase();
        final createdAt = w.createdAt;
        final dStr = createdAt != null ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' : '-';
        return [dStr, userName, pixKey, 'R\$ ${amount.toStringAsFixed(2)}', status];
      }).toList();

      // Dados de Depósitos
      final depositsData = _deposits.take(40).map((d) {
        final user = _getSafeUser(d);
        final userName = user?.get<String>('name') ?? user?.get<String>('username') ?? 'Jogador';
        final gateway = (d.get<String>('gateway') ?? 'MERCADOPAGO').toUpperCase();
        final amount = (d.get<num>('amount') ?? 0.0).toDouble();
        final status = (d.get<String>('status') ?? 'pending').toUpperCase();
        final createdAt = d.createdAt;
        final dStr = createdAt != null ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' : '-';
        return [dStr, userName, gateway, 'R\$ ${amount.toStringAsFixed(2)}', status];
      }).toList();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('O ENIGMA - Relatório Financeiro Consolidado', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Emissão: $dateStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(children: [
                      pw.Text('Total Depositado', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('R\$ ${_totalDeposited.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    ]),
                    pw.Column(children: [
                      pw.Text('Total Sacado (Pago)', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('R\$ ${_totalWithdrawn.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    ]),
                    pw.Column(children: [
                      pw.Text('Saques Pendentes', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('R\$ ${_totalPendingWithdrawalsAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.amber800)),
                    ]),
                    pw.Column(children: [
                      pw.Text('Custódia Jogadores', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('R\$ ${_totalUsersBalance.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ]),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text('Últimas Solicitações de Saque Pix', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Data', 'Jogador', 'Chave Pix', 'Valor', 'Status'],
                data: withdrawalsData.isEmpty
                    ? [['-', 'Nenhum saque', '-', '-', '-']]
                    : withdrawalsData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
              pw.SizedBox(height: 24),
              pw.Text('Últimos Depósitos via Gateways', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Data', 'Jogador', 'Gateway', 'Valor', 'Status'],
                data: depositsData.isEmpty
                    ? [['-', 'Nenhum depósito', '-', '-', '-']]
                    : depositsData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
            ];
          },
        ),
      );

      final bytes = await doc.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'Relatorio_Financeiro_Enigma_${now.millisecondsSinceEpoch}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório PDF gerado e baixado com sucesso!'), backgroundColor: AppColors.verdeVale),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar PDF: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // ==========================================
  // HELPERS VISUAIS
  // ==========================================
  Widget _buildFilterPill(
    String label,
    String value,
    String current,
    ValueChanged<String> onSelect, {
    Color? highlightColor,
  }) {
    final isSelected = current == value;
    final color = highlightColor ?? AppColors.verdeVale;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : AppColors.cinzaMedio,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(FontAwesomeIcons.receipt, size: 36, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
