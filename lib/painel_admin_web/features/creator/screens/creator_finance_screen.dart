import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';

class CreatorFinanceScreen extends StatefulWidget {
  const CreatorFinanceScreen({super.key});

  @override
  State<CreatorFinanceScreen> createState() => _CreatorFinanceScreenState();
}

class _CreatorFinanceScreenState extends State<CreatorFinanceScreen> {
  bool _isLoading = true;
  ParseUser? _currentUser;

  double _availableBalance = 0.0;
  double _totalEarned = 0.0;
  List<ParseObject> _transactions = [];
  List<ParseObject> _withdrawals = [];

  final _pixKeyController = TextEditingController();
  String _pixKeyType = 'CPF';
  bool _isSavingPix = false;

  final _withdrawAmountController = TextEditingController();
  bool _isRequestingWithdraw = false;

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  @override
  void dispose() {
    _pixKeyController.dispose();
    _withdrawAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadFinanceData() async {
    setState(() => _isLoading = true);
    try {
      final user = await ParseUser.currentUser() as ParseUser?;
      _currentUser = user;

      if (user != null) {
        await user.fetch();
        _availableBalance = (user.get<num>('balance') ?? 0.0).toDouble();
        _totalEarned = (user.get<num>('totalEarned') ?? 0.0).toDouble();

        _pixKeyController.text = user.get<String>('pixKey') ?? '';
        _pixKeyType = user.get<String>('pixKeyType') ?? 'CPF';

        // 1. Busca transações do criador
        final txQuery = QueryBuilder<ParseObject>(ParseObject('Transaction'))
          ..whereEqualTo('creatorId', user.objectId)
          ..orderByDescending('createdAt')
          ..setLimit(50);

        final txRes = await txQuery.query();
        if (txRes.success && txRes.results != null) {
          _transactions = List<ParseObject>.from(txRes.results!);
        }

        // 2. Busca saques anteriores
        final wQuery = QueryBuilder<ParseObject>(ParseObject('Withdrawal'))
          ..whereEqualTo('user', user)
          ..orderByDescending('createdAt')
          ..setLimit(20);

        final wRes = await wQuery.query();
        if (wRes.success && wRes.results != null) {
          _withdrawals = List<ParseObject>.from(wRes.results!);
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados financeiros do criador: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePixKey() async {
    if (_pixKeyController.text.trim().isEmpty) return;
    setState(() => _isSavingPix = true);
    try {
      if (_currentUser != null) {
        _currentUser!.set('pixKey', _pixKeyController.text.trim());
        _currentUser!.set('pixKeyType', _pixKeyType);
        await _currentUser!.save();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chave Pix salva com sucesso!'),
              backgroundColor: AppColors.verdeVale,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao salvar Pix: $e');
    } finally {
      if (mounted) setState(() => _isSavingPix = false);
    }
  }

  Future<void> _requestWithdrawal() async {
    final amountText = _withdrawAmountController.text
        .replaceAll('R\$', '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) {
      _showError('Informe um valor de saque válido.');
      return;
    }

    if (amount > _availableBalance) {
      _showError('Saldo insuficiente. Seu saldo disponível é R\$ ${_availableBalance.toStringAsFixed(2)}');
      return;
    }

    if (_pixKeyController.text.trim().isEmpty) {
      _showError('Cadastre sua chave Pix antes de solicitar o saque.');
      return;
    }

    setState(() => _isRequestingWithdraw = true);
    try {
      final function = ParseCloudFunction('requestWithdrawal');
      final params = {
        'amount': amount,
        'pixKey': _pixKeyController.text.trim(),
        'pixKeyType': _pixKeyType,
      };

      final response = await function.execute(parameters: params);
      if (response.success) {
        _withdrawAmountController.clear();
        await _loadFinanceData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saque de R\$ ${amount.toStringAsFixed(2)} solicitado com sucesso!'),
              backgroundColor: AppColors.verdeVale,
            ),
          );
        }
      } else {
        throw Exception(response.error?.message ?? 'Falha ao solicitar saque.');
      }
    } catch (e) {
      _showError('Erro ao solicitar saque: $e');
    } finally {
      if (mounted) setState(() => _isRequestingWithdraw = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.verdeVale),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de Saldo & Chave Pix
          _buildBalanceAndPixSection(),
          const SizedBox(height: 24),

          // Tabela de Transações Recentes
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.clockRotateLeft, color: AppColors.amareloVale, size: 16),
              const SizedBox(width: 10),
              Text(
                'Extrato de Vendas & Comissões (Split Pix)',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTransactionsTable(),
        ],
      ),
    );
  }

  Widget _buildBalanceAndPixSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        final balanceCard = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F262F), Color(0xFF131D24)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SALDO LÍQUIDO DISPONÍVEL',
                style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ ${_availableBalance.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  color: AppColors.amareloVale,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Faturamento Total Histórico: R\$ ${_totalEarned.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
              ),
              const SizedBox(height: 18),

              // Formulário de Solicitação de Saque
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _withdrawAmountController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Valor R\$ (ex: 50,00)',
                        hintStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                        prefixText: 'R\$ ',
                        prefixStyle: GoogleFonts.poppins(color: AppColors.amareloVale),
                        filled: true,
                        fillColor: AppColors.darkBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: _isRequestingWithdraw
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const FaIcon(FontAwesomeIcons.pix, size: 13),
                    label: const Text('Sacar Pix'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amareloVale,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isRequestingWithdraw ? null : _requestWithdrawal,
                  ),
                ],
              ),
            ],
          ),
        );

        final pixCard = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.darkCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SUA CHAVE PIX PARA RECEBIMENTO',
                    style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const FaIcon(FontAwesomeIcons.key, color: AppColors.verdeVale, size: 14),
                ],
              ),
              const SizedBox(height: 12),

              // Seletor de Tipo de Chave
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: ['CPF', 'CNPJ', 'EMAIL', 'TELEFONE', 'ALEATORIA'].map((type) {
                  final isSel = _pixKeyType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSel,
                    selectedColor: AppColors.verdeVale,
                    backgroundColor: AppColors.darkBackground,
                    labelStyle: GoogleFonts.poppins(
                      color: isSel ? Colors.white : AppColors.cinzaMedio,
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _pixKeyType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pixKeyController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Digite sua chave Pix',
                        hintStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.darkBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verdeVale,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _isSavingPix ? null : _savePixKey,
                    child: _isSavingPix
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Salvar'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Os saques são transferidos diretamente para esta chave Pix.',
                style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11),
              ),
            ],
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: balanceCard),
              const SizedBox(width: 16),
              Expanded(child: pixCard),
            ],
          );
        }

        return Column(
          children: [
            balanceCard,
            const SizedBox(height: 16),
            pixCard,
          ],
        );
      },
    );
  }

  Widget _buildTransactionsTable() {
    if (_transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkCardBorder),
        ),
        child: Column(
          children: [
            const FaIcon(FontAwesomeIcons.receipt, color: AppColors.cinzaMedio, size: 28),
            const SizedBox(height: 12),
            Text(
              'Nenhuma venda registrada ainda',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Assim que seus seguidores comprarem ingressos ou Super Dicas, as vendas e comissões aparecerão aqui em tempo real.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        if (isMobile) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tx = _transactions[index];
              final type = tx.get<String>('type') ?? 'ticket';
              final isTicket = type == 'ticket';
              final name = tx.get<String>('eventName') ?? 'Desafio';
              final buyer = tx.get<String>('buyerName') ?? 'Seguidor';
              final gross = (tx.get<num>('grossAmount') ?? tx.get<num>('amount') ?? 0.0).toDouble();
              final fee = (tx.get<num>('feeAmount') ?? (gross * 0.15)).toDouble();
              final net = (tx.get<num>('netAmount') ?? (gross - fee)).toDouble();
              final status = tx.get<String>('status') ?? 'pending';
              final date = tx.createdAt ?? DateTime.now();

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkCardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isTicket
                                ? Colors.blue.withValues(alpha: 0.15)
                                : AppColors.amareloVale.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isTicket ? '🎟️ INGRESSO' : '💡 SUPER DICA',
                            style: GoogleFonts.poppins(
                              color: isTicket ? Colors.lightBlueAccent : AppColors.amareloVale,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '+ R\$ ${net.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Comprador: $buyer',
                          style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11.5),
                        ),
                        Text(
                          dateFormat.format(date),
                          style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.darkCardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkCardBorder),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.darkBackground),
              columns: const [
                DataColumn(label: Text('TIPO')),
                DataColumn(label: Text('DESAFIO / ENIGMA')),
                DataColumn(label: Text('COMPRADOR')),
                DataColumn(label: Text('BRUTO')),
                DataColumn(label: Text('TAXA (15%)')),
                DataColumn(label: Text('LÍQUIDO')),
                DataColumn(label: Text('DATA')),
                DataColumn(label: Text('STATUS')),
              ],
              rows: _transactions.map((tx) {
                final type = tx.get<String>('type') ?? 'ticket';
                final isTicket = type == 'ticket';
                final name = tx.get<String>('eventName') ?? 'Desafio';
                final buyer = tx.get<String>('buyerName') ?? 'Seguidor';
                final gross = (tx.get<num>('grossAmount') ?? tx.get<num>('amount') ?? 0.0).toDouble();
                final fee = (tx.get<num>('feeAmount') ?? (gross * 0.15)).toDouble();
                final net = (tx.get<num>('netAmount') ?? (gross - fee)).toDouble();
                final status = tx.get<String>('status') ?? 'pending';
                final date = tx.createdAt ?? DateTime.now();

                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isTicket
                              ? Colors.blue.withValues(alpha: 0.15)
                              : AppColors.amareloVale.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isTicket ? 'INGRESSO' : 'SUPER DICA',
                          style: GoogleFonts.poppins(
                            color: isTicket ? Colors.lightBlueAccent : AppColors.amareloVale,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12))),
                    DataCell(Text(buyer, style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12))),
                    DataCell(Text('R\$ ${gross.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12))),
                    DataCell(Text('- R\$ ${fee.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12))),
                    DataCell(
                      Text(
                        '+ R\$ ${net.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    DataCell(Text(dateFormat.format(date), style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11))),
                    DataCell(
                      Text(
                        status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: status == 'approved' ? Colors.greenAccent : AppColors.amareloVale,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
