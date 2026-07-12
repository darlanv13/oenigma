<<<<<<< HEAD:lib/admin/screens/admin_users_screen.dart
import 'package:oenigma/core/utils/app_colors.dart';
=======
import 'package:flutter/foundation.dart';
>>>>>>> origin/feature/mobile-admin-creation-panel-3405278983593723524:lib/features/admin/screens/admin_users_screen.dart
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';
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
    try {
      final response = await ParseCloudFunction('listAllUsers').execute();
      if (response.success && response.result != null) {
        return List<dynamic>.from(response.result);
      } else {
        throw response.error ?? ParseError();
      }
    } catch (e) {
      debugPrint('Erro ao buscar usuários: $e');
      return [];
    }
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
              'Gestão de Usuários',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.rotateRight,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _usersFuture = _fetchUsers();
                });
              },
            ),
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
                debugPrint(
                  "Erro no FutureBuilder de usuários: ${snapshot.error}",
                );
                return Center(
                  child: Text(
                    'Erro ao carregar usuários: \n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum usuário encontrado.',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                );
              }

              final users = snapshot.data!;

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final objectId = user['objectId'] as String;
                  final name =
                      user['name'] ?? user['displayName'] ?? 'Sem Nome';
                  final email = user['email'] ?? 'Sem Email';
                  final photoURL = user['photoURL'] as String?;
                  final isAdmin = user['isAdmin'] ?? false;
                  final isBanned = user['isBanned'] ?? false;
                  final role = user['role'] ?? 'player';

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isAdmin
                            ? Colors.blueAccent
                            : primaryAmber,
                        backgroundImage: photoURL != null
                            ? NetworkImage(photoURL)
                            : null,
                        child: photoURL == null
                            ? Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.black),
                              )
                            : null,
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: isBanned ? Colors.grey : Colors.white,
                          decoration: isBanned
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        '$email${isAdmin ? " • Admin" : ""}${role == "creator" ? " • Creator" : ""}${isBanned ? " • Banido" : ""}',
                        style: const TextStyle(color: secondaryTextColor),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.wallet,
                              color: Colors.greenAccent,
                            ),
                            onPressed: () {
                              // Action to view/edit wallet
                            },
                            tooltip: 'Ver Carteira',
                          ),
                          IconButton(
                            icon: FaIcon(
                              role == 'creator'
                                  ? FontAwesomeIcons.camera
                                  : FontAwesomeIcons.userPen,
                              color: role == 'creator' ? primaryAmber : Colors.grey,
                            ),
                            onPressed: () async {
                              final newRole = role == 'creator' ? 'player' : 'creator';
                              try {
                                // Simplified update mechanism. Ideally, use a cloud function dedicated to updating roles
                                final response = await ParseCloudFunction('updateUserRole').execute(parameters: {'objectId': objectId, 'role': newRole});
                                if (!response.success) {
                                  // Fallback to basic object update if the function doesn't exist, though modifying users might require Master Key
                                }
                                setState(() {
                                  _usersFuture = _fetchUsers();
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        role == 'creator'
                                            ? 'Creator revogado.'
                                            : 'Creator concedido.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erro ao atualizar creator (Requer backend setup): $e')),
                                  );
                                }
                              }
                            },
                            tooltip: role == 'creator' ? 'Revogar Creator' : 'Tornar Creator',
                          ),
                          IconButton(
                            icon: FaIcon(
                              isAdmin
                                  ? FontAwesomeIcons.userShield
                                  : FontAwesomeIcons.solidUser,
                              color: isAdmin ? Colors.blueAccent : Colors.grey,
                            ),
                            onPressed: () async {
                              final functionName = isAdmin
                                  ? 'revokeAdminRole'
                                  : 'grantAdminRole';
                              try {
                                final response = await ParseCloudFunction(
                                  functionName,
                                ).execute(parameters: {'objectId': objectId});
                                if (!response.success) {
                                  throw response.error ?? ParseError();
                                }
                                setState(() {
                                  _usersFuture = _fetchUsers();
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isAdmin
                                            ? 'Admin revogado.'
                                            : 'Admin concedido.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao atualizar admin: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            tooltip: isAdmin ? 'Revogar Admin' : 'Tornar Admin',
                          ),
                          IconButton(
                            icon: FaIcon(
                              isBanned
                                  ? FontAwesomeIcons.check
                                  : FontAwesomeIcons.ban,
                              color: isBanned ? Colors.green : Colors.redAccent,
                            ),
                            onPressed: () async {
                              try {
                                final response = await ParseCloudFunction(
                                  'toggleUserBan',
                                ).execute(parameters: {'objectId': objectId});
                                if (!response.success) {
                                  throw response.error ?? ParseError();
                                }
                                setState(() {
                                  _usersFuture = _fetchUsers();
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isBanned
                                            ? 'Usuário desbanido.'
                                            : 'Usuário banido.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao atualizar banimento: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            tooltip: isBanned ? 'Desbanir' : 'Banir',
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
