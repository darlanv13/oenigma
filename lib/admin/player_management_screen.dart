import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

class PlayerManagementScreen extends StatefulWidget {
  const PlayerManagementScreen({super.key});

  @override
  State<PlayerManagementScreen> createState() => _PlayerManagementScreenState();
}

class _PlayerManagementScreenState extends State<PlayerManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Future<List<dynamic>>? _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = _firebaseService.listAllUsers();
    });
  }

  Future<void> _updateRole(String uid, bool isAdmin) async {
    try {
      if (isAdmin) {
        await _firebaseService.revokeAdminRole(uid);
      } else {
        await _firebaseService.grantAdminRole(uid);
      }
      _loadUsers(); // Recarrega a lista após a alteração
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao atualizar permissão: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gerenciamento de Jogadores")),
      body: FutureBuilder<List<dynamic>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text("Erro ao carregar jogadores: ${snapshot.error}"),
            );
          }

          final users = snapshot.data!;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Nome')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Permissão')),
                DataColumn(label: Text('Ação')),
              ],
              rows: users.map((user) {
                final bool isAdmin = user['isAdmin'] ?? false;
                return DataRow(
                  cells: [
                    DataCell(Text(user['displayName'])),
                    DataCell(Text(user['email'])),
                    DataCell(
                      Text(
                        isAdmin ? "Admin" : "Jogador",
                        style: TextStyle(
                          color: isAdmin ? primaryAmber : textColor,
                          fontWeight: isAdmin
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    DataCell(
                      ElevatedButton(
                        onPressed: () => _updateRole(user['uid'], isAdmin),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAdmin
                              ? Colors.redAccent
                              : Colors.green,
                        ),
                        child: Text(isAdmin ? "Revogar Admin" : "Tornar Admin"),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
