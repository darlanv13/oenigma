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
    _futureUsers.then((users) {
       if (mounted) {
         setState(() {
           _allUsers = users;
           _filteredUsers = users;
         });
       }
    }).catchError((e) {
       print("Erro carregando usuarios: $e");
    });
    setState(() {}); // Trigger rebuild to show loading from FutureBuilder
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _allUsers;
      });
    } else {
      setState(() {
        _filteredUsers = _allUsers.where((user) {
          final name = (user['name'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase()) || email.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
           padding: const EdgeInsets.all(16),
           child: Row(
             children: [
                const Icon(Icons.people, color: primaryAmber, size: 28),
                const SizedBox(width: 8),
                Text("Gerenciar Usuários", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                       hintText: "Buscar por nome ou email...",
                       hintStyle: const TextStyle(color: Colors.grey),
                       prefixIcon: const Icon(Icons.search, color: Colors.grey),
                       filled: true,
                       fillColor: cardColor,
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    onChanged: _filterUsers,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
             ],
           ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
             future: _futureUsers,
             builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator(color: primaryAmber));
                }
                if (snapshot.hasError) {
                   return Center(child: Text("Erro ao carregar usuários: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }

                // Sincroniza dados se o Future completou mas o .then ainda não atualizou o estado (race condition fix)
                if (snapshot.hasData && _allUsers.isEmpty) {
                    _allUsers = snapshot.data!;
                    if (_searchController.text.isEmpty) {
                        _filteredUsers = _allUsers;
                    }
                }

                if (_filteredUsers.isEmpty) {
                   // Se filtered estiver vazio mas allUsers nao, é filtro. Se ambos vazios, é nada encontrado.
                   if (_allUsers.isNotEmpty) {
                       return const Center(child: Text("Nenhum usuário encontrado com esse termo.", style: TextStyle(color: secondaryTextColor)));
                   }
                   return const Center(child: Text("Nenhum usuário cadastrado.", style: TextStyle(color: secondaryTextColor)));
                }

                return ListView.builder(
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

     return Card(
        color: cardColor,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
           leading: CircleAvatar(
              backgroundColor: isAdmin ? primaryAmber : Colors.grey.shade800,
              child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: isAdmin ? darkBackground : Colors.white),
           ),
           title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
           subtitle: Text(email, style: const TextStyle(color: secondaryTextColor)),
           trailing: Switch(
              value: isAdmin,
              activeColor: primaryAmber,
              onChanged: (val) => _toggleAdmin(uid, val, name),
           ),
        ),
     );
  }

  Future<void> _toggleAdmin(String uid, bool newValue, String name) async {
      // Confirmação
      final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
             backgroundColor: cardColor,
             title: Text(newValue ? "Promover a Admin" : "Remover Admin", style: const TextStyle(color: Colors.white)),
             content: Text("Tem certeza que deseja ${newValue ? 'tornar' : 'remover'} $name como administrador?", style: const TextStyle(color: secondaryTextColor)),
             actions: [
                TextButton(child: const Text("Cancelar", style: TextStyle(color: Colors.white)), onPressed: () => Navigator.pop(ctx, false)),
                ElevatedButton(child: const Text("Confirmar"), onPressed: () => Navigator.pop(ctx, true)),
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
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Permissões de $name atualizadas."), backgroundColor: Colors.green));
                 _loadUsers(); // Recarrega a lista
             }
         } catch (e) {
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
             }
         }
      }
  }
}
