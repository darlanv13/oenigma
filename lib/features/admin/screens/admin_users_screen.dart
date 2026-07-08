import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


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
    final result = await ParseCloudFunction('listAllUsers').execute();
      if (!result.success) throw result.error ?? ParseError();
    return result.result as List<dynamic>;
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
              icon: const FaIcon(FontAwesomeIcons.rotateRight, color: Colors.white),
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
                            icon: const FaIcon(FontAwesomeIcons.wallet, color: Colors.greenAccent),
                            onPressed: () {
                              // Action to view/edit wallet
                            },
                            tooltip: 'Ver Carteira',
                          ),
                          IconButton(
                            icon: FaIcon(isAdmin ? FontAwesomeIcons.userShield : FontAwesomeIcons.solidUser, color: isAdmin ? Colors.blueAccent : Colors.grey),
                            onPressed: () async {
                              final functionName = isAdmin ? 'revokeAdminRole' : 'grantAdminRole';
                              try {
                                final response = await ParseCloudFunction(functionName).execute(parameters: {'uid': uid});
      if (!response.success) throw response.error ?? ParseError();
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
                            icon: const FaIcon(FontAwesomeIcons.ban, color: Colors.redAccent),
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
