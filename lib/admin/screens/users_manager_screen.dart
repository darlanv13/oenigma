import 'package:flutter/material.dart';
import 'package:oenigma/admin/services/admin_service.dart';
import 'package:oenigma/admin/widgets/admin_scaffold.dart';
import 'package:oenigma/utils/app_colors.dart';

class UsersManagerScreen extends StatefulWidget {
  const UsersManagerScreen({super.key});

  @override
  State<UsersManagerScreen> createState() => _UsersManagerScreenState();
}

class _UsersManagerScreenState extends State<UsersManagerScreen> {
  final AdminService _adminService = AdminService();

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Busca os dados reais usando a Cloud Function
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final users = await _adminService.listAllUsers();

      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _isLoading = false;
        });
        // Reaplica o filtro se houver texto na busca
        if (_searchQuery.isNotEmpty) {
          _filterUsers(_searchQuery);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erro ao carregar: $e";
        });
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          final name = (user['name'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // --- Lógica do Diálogo de Permissões ---
  void _openPermissionsDialog(Map<String, dynamic> user) {
    final String uid = user['uid'];
    final String name = user['name'] ?? 'Usuário';

    // Lê o estado atual
    bool isAdmin = user['isAdmin'] == true;
    Map<String, dynamic> currentPerms = user['permissions'] != null
        ? Map<String, dynamic>.from(user['permissions'])
        : {};

    bool canCreate = currentPerms['create_events'] == true;
    bool canEdit = currentPerms['edit_events'] == true;
    bool canDelete = currentPerms['delete_events'] == true;
    bool canFinance = currentPerms['manage_finance'] == true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: cardColor,
              title: Text(
                "Acesso: $name",
                style: const TextStyle(color: textColor),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text(
                        "É Admin?",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: isAdmin,
                      activeColor: Colors.green,
                      onChanged: (val) => setStateDialog(() => isAdmin = val),
                    ),
                    const Divider(color: Colors.grey),
                    if (isAdmin) ...[
                      CheckboxListTile(
                        title: const Text(
                          "Criar Eventos",
                          style: TextStyle(color: textColor),
                        ),
                        value: canCreate,
                        activeColor: primaryAmber,
                        onChanged: (v) => setStateDialog(() => canCreate = v!),
                      ),
                      CheckboxListTile(
                        title: const Text(
                          "Editar Eventos",
                          style: TextStyle(color: textColor),
                        ),
                        value: canEdit,
                        activeColor: primaryAmber,
                        onChanged: (v) => setStateDialog(() => canEdit = v!),
                      ),
                      CheckboxListTile(
                        title: const Text(
                          "Excluir (Perigo)",
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: const Text(
                          "Apagar eventos e enigmas",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        value: canDelete,
                        activeColor: Colors.red,
                        onChanged: (v) => setStateDialog(() => canDelete = v!),
                      ),
                      CheckboxListTile(
                        title: const Text(
                          "Financeiro",
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: const Text(
                          "Aprovar saques",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        value: canFinance,
                        activeColor: Colors.green,
                        onChanged: (v) => setStateDialog(() => canFinance = v!),
                      ),
                    ] else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Usuários comuns não têm acesso ao painel.",
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _savePermissions(uid, isAdmin, {
                      'create_events': canCreate,
                      'edit_events': canEdit,
                      'delete_events': canDelete,
                      'manage_finance': canFinance,
                    });
                  },
                  child: const Text("Salvar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _savePermissions(
    String uid,
    bool isAdmin,
    Map<String, bool> perms,
  ) async {
    // Feedback visual imediato
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Salvando permissões..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await _adminService.updateUserPermissions(
        uid: uid,
        isAdmin: isAdmin,
        permissions: perms,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Atualizado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        _fetchUsers(); // Recarrega a lista para mostrar os novos ícones
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Gerenciar Perfis',
      selectedIndex: 2,
      body: Column(
        children: [
          // Barra de topo: Busca e Refresh
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: textColor),
                  onChanged: _filterUsers,
                  decoration: InputDecoration(
                    hintText: "Buscar por nome ou email...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: primaryAmber),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _fetchUsers,
                icon: const Icon(Icons.refresh, color: primaryAmber),
                tooltip: "Recarregar Lista",
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tabela de Dados Real
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryAmber),
                  )
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingTextStyle: const TextStyle(
                          color: primaryAmber,
                          fontWeight: FontWeight.bold,
                        ),
                        dataTextStyle: const TextStyle(color: textColor),
                        columns: const [
                          DataColumn(label: Text('Nome / UID')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Permissões')),
                          DataColumn(label: Text('Ações')),
                        ],
                        rows: _filteredUsers.map((user) {
                          final bool isUserAdmin = user['isAdmin'] == true;
                          final Map perms = user['permissions'] ?? {};

                          // Ícones visuais das permissões
                          List<Widget> badges = [];
                          if (perms['create_events'] == true)
                            badges.add(
                              const Icon(
                                Icons.add_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                            );
                          if (perms['delete_events'] == true)
                            badges.add(
                              const Icon(
                                Icons.delete,
                                size: 14,
                                color: Colors.red,
                              ),
                            );
                          if (perms['manage_finance'] == true)
                            badges.add(
                              const Icon(
                                Icons.attach_money,
                                size: 14,
                                color: Colors.amber,
                              ),
                            );

                          return DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['name'] ?? 'Sem nome',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      user['uid'],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(user['email'] ?? '-')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUserAdmin
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isUserAdmin
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isUserAdmin ? "ADMIN" : "JOGADOR",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isUserAdmin
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                isUserAdmin
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: badges.isNotEmpty
                                            ? badges
                                            : [
                                                const Text(
                                                  "-",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                      )
                                    : const Text("-"),
                              ),
                              DataCell(
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.settings, size: 16),
                                  label: const Text("Editar"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () => _openPermissionsDialog(user),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
