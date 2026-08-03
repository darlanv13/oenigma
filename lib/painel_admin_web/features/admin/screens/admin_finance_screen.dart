import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;
import 'package:fl_chart/fl_chart.dart';
import 'package:oenigma/painel_admin_web/core/utils/app_colors.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> {
  late Future<ParseResponse> _withdrawalsFuture;

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  void _loadWithdrawals() {
    setState(() {
      _withdrawalsFuture =
          (QueryBuilder<ParseObject>(ParseObject('Withdrawal'))
                ..whereEqualTo('status', 'pending')
                ..orderByAscending('createdAt'))
              .query();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gestão Financeira e Saques (Pix)',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.filePdf, size: 16),
              label: const Text('Exportar Relatório'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryAmber, foregroundColor: Colors.black),
              onPressed: () => _exportFinancialReport(context),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: [
                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.blue)]),
                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: Colors.green)]),
                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 14, color: Colors.orange)]),
                BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15, color: Colors.pink)]),
                BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 13, color: Colors.red)]),
                BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 10, color: Colors.purple)]),
              ],
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: FutureBuilder<ParseResponse>(
            future: _withdrawalsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }
              if (!snapshot.hasData ||
                  !snapshot.data!.success ||
                  snapshot.data!.results == null ||
                  snapshot.data!.results!.isEmpty) {
                return const Center(
                  child: Text(
                    'Não há solicitações de saque pendentes.',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                );
              }

              final requests = snapshot.data!.results as List<ParseObject>;

              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  final requestId = request.objectId!;
                  final objectId =
                      request.get<String>('objectId') ?? 'Desconhecido';
                  final amount = request.get<num>('amount') ?? 0;
                  final pixKey =
                      request.get<String>('pixKey') ?? 'Chave não informada';
                  final pixKeyType =
                      request.get<String>('pixKeyType') ?? 'Desconhecido';
                  final createdAt = request.createdAt;
                  final dateStr = (createdAt != null
                      ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
                      : 'Data desconhecida');

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: FaIcon(
                          FontAwesomeIcons.pix,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        'Valor: R\$ $amount - Chave: $pixKey ($pixKeyType)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'UID: $objectId\nData da Solicitação: $dateStr',
                        style: const TextStyle(color: secondaryTextColor),
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            icon: const FaIcon(
                              FontAwesomeIcons.solidCircleCheck,
                              color: Colors.green,
                            ),
                            label: const Text(
                              'Aprovar & Pagar',
                              style: TextStyle(color: Colors.green),
                            ),
                            onPressed: () => _handleWithdrawal(
                              context,
                              requestId,
                              objectId,
                              'approve',
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const FaIcon(
                              FontAwesomeIcons.xmark,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'Rejeitar & Estornar',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                            onPressed: () => _handleWithdrawal(
                              context,
                              requestId,
                              objectId,
                              'reject',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _exportFinancialReport(BuildContext context) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Relatório Financeiro Geral', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Compras Recentes de Ferramentas (Simulado):'),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Data', 'Produto', 'Valor'],
                    <String>['10/08/2026', 'Dica (Enigma 3)', 'R\$ 0,50'],
                    <String>['11/08/2026', 'Bússola (Enigma 4)', 'R\$ 15,00'],
                    <String>['12/08/2026', 'Mapa (Enigma 1)', 'R\$ 20,00'],
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Text('Totais: R\$ 35,50', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ],
            );
          },
        ),
      );

      final bytes = await doc.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'Relatorio_Financeiro.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Relatório exportado!')));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _handleWithdrawal(
    BuildContext context,
    String withdrawalId,
    String objectId,
    String action,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ParseCloudFunction('processWithdrawal').execute(
        parameters: {
          'withdrawalId': withdrawalId,
          'objectId': objectId,
          'action': action,
        },
      );

      if (context.mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saque processado com sucesso: $action')),
        );
        _loadWithdrawals();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar saque: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
