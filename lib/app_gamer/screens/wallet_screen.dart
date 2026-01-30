import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';

class WalletScreen extends StatefulWidget {
  // Tornamos o parâmetro opcional para evitar erros de navegação
  final UserWalletModel? walletData;

  const WalletScreen({super.key, this.walletData});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  UserWalletModel? _wallet;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Se recebeu dados da tela anterior, usa eles. Se não, busca.
    if (widget.walletData != null) {
      _wallet = widget.walletData;
    } else {
      _fetchWalletData();
    }
  }

  Future<void> _fetchWalletData() async {
    setState(() => _isLoading = true);
    try {
      final wallet = await _firebaseService.getUserWalletData();
      if (mounted) {
        setState(() {
          _wallet = wallet;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao carregar carteira: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        // Opcional: Mostrar SnackBar de erro
      }
    }
  }

  void _buyCredits(BuildContext context, double amount) {
    if (_wallet == null) return;

    // Lógica simplificada de compra (exemplo)
    // Aqui você chamaria seu BottomSheet de pagamento real
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Gerar PIX",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Valor: R\$ ${amount.toStringAsFixed(2)}",
              style: const TextStyle(color: primaryAmber, fontSize: 24),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                // Simulação de sucesso para atualizar a UI
                Navigator.pop(ctx);
                _fetchWalletData(); // Recarrega o saldo ao voltar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pedido de recarga criado!")),
                );
              },
              child: const Text("Confirmar"),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Solicitar Saque',
          style: GoogleFonts.orbitron(color: primaryAmber),
        ),
        content: const Text(
          'O saque mínimo é de R\$ 50,00. Informe sua chave PIX para análise.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'SOLICITAR',
              style: TextStyle(color: primaryAmber),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se estiver carregando e não tiver dados antigos, mostra loading
    if (_isLoading && _wallet == null) {
      return const Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: CircularProgressIndicator(color: primaryAmber)),
      );
    }

    // Se falhou e não tem dados
    if (_wallet == null) {
      return Scaffold(
        backgroundColor: darkBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              const Text(
                "Erro ao carregar carteira",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchWalletData,
                child: const Text("Tentar Novamente"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "MINHA CARTEIRA",
          style: GoogleFonts.orbitron(color: Colors.white, letterSpacing: 2),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryAmber),
            onPressed: _fetchWalletData,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryAmber,
        backgroundColor: cardColor,
        onRefresh: _fetchWalletData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de Saldo Principal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryAmber.withOpacity(0.8),
                      Colors.orangeAccent.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAmber.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "SALDO DISPONÍVEL",
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "R\$ ${_wallet!.balance.toStringAsFixed(2)}",
                      style: GoogleFonts.orbitron(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          Icons.add,
                          "Recarregar",
                          () => _buyCredits(context, 20.0),
                        ),
                        _buildActionButton(
                          Icons.download,
                          "Sacar",
                          _showWithdrawDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                "Histórico de Transações",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Lista de Histórico
              if (_wallet!.history.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 50,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Nenhuma movimentação ainda.",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _wallet!.history.length,
                  itemBuilder: (context, index) {
                    final item = _wallet!.history[index];
                    // Adapte conforme a estrutura do seu objeto 'history' (Map ou Model)
                    final isDeposit =
                        item['type'] == 'deposit' ||
                        (item['amount'] as num) > 0;
                    final date = item['date'] != null
                        ? DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format((item['date'] as dynamic).toDate())
                        : 'Data desc.';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isDeposit ? Colors.green : Colors.red)
                                .withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDeposit
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isDeposit ? Colors.green : Colors.redAccent,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item['description'] ?? 'Transação',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          date,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Text(
                          "${isDeposit ? '+' : ''} R\$ ${(item['amount'] as num).abs().toStringAsFixed(2)}",
                          style: GoogleFonts.inter(
                            color: isDeposit
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
