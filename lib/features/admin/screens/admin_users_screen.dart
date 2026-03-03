import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<dynamic>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<dynamic>> _fetchUsers() async {
    final result = await FirebaseFunctions.instanceFor(region: 'southamerica-east1')
        .httpsCallable('listAllUsers')
        .call();
    return result.data as List<dynamic>;
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
              'Gestão de Usuários e Carteira',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {
                  _usersFuture = _fetchUsers();
                });
              },
            )
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _usersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print("Erro no FutureBuilder de usuários: \${snapshot.error}");
                return Center(
                  child: Text('Erro ao carregar usuários: \n\${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Nenhum usuário encontrado.', style: TextStyle(color: secondaryTextColor)),
                );
              }

              final users = snapshot.data!;

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index] as Map<String, dynamic>;
                  final uid = user['uid'] as String;
                  final name = user['name'] ?? user['displayName'] ?? 'Sem Nome';
                  final email = user['email'] ?? 'Sem Email';
                  final photoURL = user['photoURL'] as String?;
                  final isAdmin = user['isAdmin'] ?? false;

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isAdmin ? Colors.blueAccent : primaryAmber,
                        backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                        child: photoURL == null ? Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.black)) : null,
                      ),
                      title: Text(name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('$email${isAdmin ? " • Admin" : ""}', style: const TextStyle(color: secondaryTextColor)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.account_balance_wallet, color: Colors.greenAccent),
                            onPressed: () {
                              // Action to view/edit wallet
                            },
                            tooltip: 'Ver Carteira',
                          ),
                          IconButton(
                            icon: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: isAdmin ? Colors.blueAccent : Colors.grey),
                            onPressed: () async {
                              final functionName = isAdmin ? 'revokeAdminRole' : 'grantAdminRole';
                              try {
                                await FirebaseFunctions.instanceFor(region: 'southamerica-east1')
                                    .httpsCallable(functionName)
                                    .call({'uid': uid});
                                setState(() {
                                  _usersFuture = _fetchUsers();
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(isAdmin ? 'Admin revogado.' : 'Admin concedido.')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erro ao atualizar admin: \$e')),
                                  );
                                }
                              }
                            },
                            tooltip: isAdmin ? 'Revogar Admin' : 'Tornar Admin',
                          ),
                          IconButton(
                            icon: const Icon(Icons.block, color: Colors.redAccent),
                            onPressed: () {
                              // Action to ban/suspend
                            },
                            tooltip: 'Banir/Suspender',
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
}
