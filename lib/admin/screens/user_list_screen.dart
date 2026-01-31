import 'package:flutter/material.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<dynamic>> _futureUsers;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allUsers = [];
  List<dynamic> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    _futureUsers = _firebaseService.listAllUsers();
    _futureUsers
        .then((users) {
          if (mounted) {
            setState(() {
              _allUsers = users;
              _filteredUsers = users;
            });
          }
        })
        .catchError((e) {
          print("Erro carregando usuarios: $e");
        });
    setState(() {});
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = _allUsers);
    } else {
      setState(() {
        _filteredUsers = _allUsers.where((user) {
          final name = (user['name'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // REMOVIDO: O cabeçalho manual. Agora focamos apenas na busca e lista.
    return Column(
      children: [
        // Barra de Busca Estilizada
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Buscar Usuário...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: const Icon(Icons.search, color: primaryAmber),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryAmber),
              ),
            ),
            onChanged: _filterUsers,
          ),
        ),

        // Lista de Usuários
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _futureUsers,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryAmber),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Erro: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              // Sincronização segura
              if (snapshot.hasData && _allUsers.isEmpty) {
                _allUsers = snapshot.data!;
                if (_searchController.text.isEmpty) _filteredUsers = _allUsers;
              }

              if (_filteredUsers.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 48,
                        color: secondaryTextColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Nenhum usuário encontrado.",
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return _buildUserTile(user);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserTile(dynamic user) {
    final bool isAdmin = user['isAdmin'] == true;
    final String uid = user['uid'];
    final String name = user['name'] ?? 'Sem nome';
    final String email = user['email'] ?? 'Sem email';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAdmin
              ? primaryAmber.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isAdmin
              ? primaryAmber.withOpacity(0.2)
              : Colors.white10,
          child: Icon(
            isAdmin ? Icons.security : Icons.person,
            color: isAdmin ? primaryAmber : Colors.white70,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          email,
          style: const TextStyle(color: secondaryTextColor, fontSize: 12),
        ),
        trailing: Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isAdmin,
            activeColor: primaryAmber,
            activeTrackColor: primaryAmber.withOpacity(0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
            onChanged: (val) => _toggleAdmin(uid, val, name),
          ),
        ),
        onTap: () {
          // TODO: Adicionar aqui a chamada para o Modal de Detalhes (Passo 3 do plano anterior)
        },
      ),
    );
  }

  Future<void> _toggleAdmin(String uid, bool newValue, String name) async {
    // Confirmação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          newValue ? "Promover a Admin" : "Remover Admin",
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          "Tem certeza que deseja ${newValue ? 'tornar' : 'remover'} $name como administrador?",
          style: const TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            child: const Text("Confirmar"),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (newValue) {
          await _firebaseService.grantAdminRole(uid);
        } else {
          await _firebaseService.revokeAdminRole(uid);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Permissões de $name atualizadas."),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers(); // Recarrega a lista
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
