import 'package:flutter/material.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalRequestsScreen extends StatefulWidget {
  const WithdrawalRequestsScreen({super.key});

  @override
  State<WithdrawalRequestsScreen> createState() => _WithdrawalRequestsScreenState();
}

class _WithdrawalRequestsScreenState extends State<WithdrawalRequestsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Map<String, dynamic>>> _futureWithdrawals;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureWithdrawals = _firebaseService.getPendingWithdrawals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
               const Icon(Icons.attach_money, color: primaryAmber, size: 28),
               const SizedBox(width: 8),
               Text("Solicitações de Saque", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureWithdrawals,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryAmber));
              }
              if (snapshot.hasError) {
                return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("Nenhuma solicitação pendente.", style: TextStyle(color: secondaryTextColor)));
              }

              final requests = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return _buildRequestCard(req);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final amount = (req['amount'] as num?)?.toDouble() ?? 0.0;
    final userName = req['userName'] ?? 'Desconhecido';
    final pixKey = req['pixKey'] ?? 'N/A';
    
    DateTime date = DateTime.now();
    if (req['requestedAt'] != null) {
      if (req['requestedAt'] is Timestamp) {
        date = (req['requestedAt'] as Timestamp).toDate();
      } else if (req['requestedAt'] is String) {
        date = DateTime.tryParse(req['requestedAt']) ?? DateTime.now();
      }
    }
    
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
    final id = req['id'];

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                 Text("R\$ ${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.greenAccent)),
               ],
             ),
             const SizedBox(height: 8),
             Text("Chave Pix: $pixKey", style: const TextStyle(color: Colors.white70)),
             Text("Solicitado em: $formattedDate", style: const TextStyle(color: secondaryTextColor, fontSize: 12)),
             const SizedBox(height: 16),
             Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                 OutlinedButton.icon(
                   icon: const Icon(Icons.close, color: Colors.red),
                   label: const Text("Rejeitar", style: TextStyle(color: Colors.red)),
                   onPressed: () => _handleReject(id, userName, amount),
                 ),
                 const SizedBox(width: 12),
                 ElevatedButton.icon(
                   icon: const Icon(Icons.check, color: darkBackground),
                   label: const Text("Aprovar"),
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                   onPressed: () => _handleApprove(id, userName, amount),
                 ),
               ],
             )
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(String id, String userName, double amount) async {
     final confirm = await showDialog<bool>(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: cardColor,
         title: const Text("Confirmar Aprovação", style: TextStyle(color: Colors.white)),
         content: Text("Deseja aprovar o saque de R\$ ${amount.toStringAsFixed(2)} para $userName?\nIsso marcará a transação como paga.", style: const TextStyle(color: secondaryTextColor)),
         actions: [
            TextButton(child: const Text("Cancelar", style: TextStyle(color: Colors.white)), onPressed: () => Navigator.pop(ctx, false)),
            ElevatedButton(child: const Text("Confirmar"), onPressed: () => Navigator.pop(ctx, true)),
         ],
       ),
     );

     if (confirm == true) {
       try {
         await _firebaseService.approveWithdrawal(id);
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saque aprovado!"), backgroundColor: Colors.green));
            _loadData();
         }
       } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
         }
       }
     }
  }

  Future<void> _handleReject(String id, String userName, double amount) async {
     final reasonController = TextEditingController();
     final confirm = await showDialog<bool>(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: cardColor,
         title: const Text("Rejeitar Saque", style: TextStyle(color: Colors.white)),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Text("Deseja rejeitar o saque de R\$ ${amount.toStringAsFixed(2)} para $userName?\nO valor será estornado para a conta do usuário.", style: const TextStyle(color: secondaryTextColor)),
             const SizedBox(height: 10),
             TextField(
               controller: reasonController,
               decoration: const InputDecoration(labelText: "Motivo da rejeição", labelStyle: TextStyle(color: secondaryTextColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
               style: const TextStyle(color: Colors.white),
             )
           ],
         ),
         actions: [
            TextButton(child: const Text("Cancelar", style: TextStyle(color: Colors.white)), onPressed: () => Navigator.pop(ctx, false)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Rejeitar"), 
              onPressed: () => Navigator.pop(ctx, true)
            ),
         ],
       ),
     );

     if (confirm == true) {
       try {
         await _firebaseService.rejectWithdrawal(id, reason: reasonController.text);
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saque rejeitado e estornado."), backgroundColor: Colors.orange));
            _loadData();
         }
       } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
         }
       }
     }
  }
}
