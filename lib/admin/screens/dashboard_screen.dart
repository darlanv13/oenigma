import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/admin/services/admin_service.dart';
import 'package:oenigma/admin/widgets/admin_scaffold.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import 'package:oenigma/models/withdrawal_model.dart';
import 'package:oenigma/utils/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _debugAdminToken(); // <--- CHAMADA DE DEBUG
  }

  // FUNÇÃO DE DEBUG TEMPORÁRIA
  Future<void> _debugAdminToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print("--- INICIANDO DIAGNÓSTICO DE ADMIN ---");
    print("UID: ${user.uid}");

    // false = usa cache, true = força atualização
    final tokenResult = await user.getIdTokenResult(true);

    final claims = tokenResult.claims;
    print("CLAIMS ENCONTRADAS: $claims");

    if (claims?['role'] == 'admin') {
      print("✅ STATUS: O Firebase reconhece este usuário como ADMIN.");
    } else {
      print("❌ STATUS: O Firebase AINDA acha que este usuário é JOGADOR.");
      print("SOLUÇÃO: Faça Logout e Login novamente.");
    }
    print("--------------------------------------");
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Dashboard Gerencial',
      selectedIndex: 0,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Visão Geral",
              style: TextStyle(
                fontSize: 24,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // GRID DE MÉTRICAS CONECTADA
            // Usamos StreamBuilder para atualizar os cards em tempo real
            StreamBuilder(
              stream: _adminService.getEvents(),
              builder: (context, AsyncSnapshot<List<EventModel>> eventsSnap) {
                return StreamBuilder(
                  stream: _adminService.getUsers(),
                  builder: (context, AsyncSnapshot<List<UserWalletModel>> usersSnap) {
                    return StreamBuilder(
                      stream: _adminService.getPendingWithdrawals(),
                      builder:
                          (
                            context,
                            AsyncSnapshot<List<WithdrawalModel>>
                            withdrawalsSnap,
                          ) {
                            // Calculando Totais
                            final int totalEvents =
                                eventsSnap.data?.length ?? 0;
                            final int totalUsers = usersSnap.data?.length ?? 0;
                            final int pendingWithdrawals =
                                withdrawalsSnap.data?.length ?? 0;

                            // Exemplo de cálculo de Faturamento Estimado (soma de saldos dos usuários)
                            // Em um app real, você somaria uma coleção de 'transactions'
                            final double totalUserBalance =
                                usersSnap.data?.fold(
                                  0.0,
                                  (sum, user) => sum! + user.balance,
                                ) ??
                                0.0;

                            return GridView.count(
                              crossAxisCount:
                                  MediaQuery.of(context).size.width > 1100
                                  ? 4
                                  : 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              shrinkWrap: true,
                              childAspectRatio: 1.5,
                              children: [
                                MetricCard(
                                  title:
                                      "Saldo em Carteiras", // Dinheiro circulando no sistema
                                  value:
                                      "R\$ ${totalUserBalance.toStringAsFixed(2)}",
                                  icon: Icons.account_balance_wallet,
                                  color: Colors.green,
                                ),
                                MetricCard(
                                  title: "Jogadores Cadastrados",
                                  value: "$totalUsers",
                                  icon: Icons.people,
                                  color: Colors.blue,
                                ),
                                MetricCard(
                                  title: "Eventos Criados",
                                  value: "$totalEvents",
                                  icon: Icons.emoji_events,
                                  color: primaryAmber,
                                ),
                                MetricCard(
                                  title: "Saques Pendentes",
                                  value: "$pendingWithdrawals",
                                  icon: Icons.attach_money,
                                  color: pendingWithdrawals > 0
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                              ],
                            );
                          },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 40),

            // LISTA DE ÚLTIMAS SOLICITAÇÕES (Substituindo transações fake)
            const Text(
              "Solicitações de Saque Pendentes",
              style: TextStyle(
                fontSize: 20,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<List<WithdrawalModel>>(
              stream: _adminService.getPendingWithdrawals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final withdrawals = snapshot.data ?? [];

                if (withdrawals.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Nenhuma solicitação pendente no momento.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      color: primaryAmber,
                      fontWeight: FontWeight.bold,
                    ),
                    dataTextStyle: const TextStyle(color: textColor),
                    columns: const [
                      DataColumn(label: Text('Usuário')),
                      DataColumn(label: Text('Chave PIX')),
                      DataColumn(label: Text('Valor')),
                      DataColumn(label: Text('Data')),
                    ],
                    rows: withdrawals.take(5).map((w) {
                      // Pegamos apenas os 5 primeiros para o dashboard não ficar gigante
                      return DataRow(
                        cells: [
                          DataCell(Text(w.userName)),
                          DataCell(Text(w.pixKey)),
                          DataCell(
                            Text(
                              "R\$ ${w.amount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text(w.requestedAt)),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 30),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
