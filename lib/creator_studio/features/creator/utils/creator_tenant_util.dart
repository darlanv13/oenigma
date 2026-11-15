import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// Utilitário central de governança Multi-Tenant para o Creator Studio.
/// Garante isolamento estrito de dados entre criadores/tenants.
class CreatorTenantUtil {
  CreatorTenantUtil._();

  /// Retorna o usuário criador atualmente autenticado
  static Future<ParseUser?> getCurrentUser() async {
    return await ParseUser.currentUser() as ParseUser?;
  }

  /// Retorna se o usuário logado é o Administrador Global (Master Admin)
  static bool isMasterAdmin(ParseUser? user) {
    if (user == null) return false;
    final isAdmin = user.get<bool>('isAdmin') ?? false;
    final role = (user.get<String>('role') ?? '').toLowerCase();
    return isAdmin || role == 'admin' || role == 'administrador';
  }

  /// Retorna o Tenant ID do criador atual (formatado para exibição)
  static String getDisplayTenantId(ParseUser? user) {
    if (user == null) return 'TENANT-GUEST';
    final customTenant = user.get<String>('tenantId');
    if (customTenant != null && customTenant.isNotEmpty) return customTenant;
    final id = user.objectId ?? 'UNKNOWN';
    final shortId = id.length > 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();
    return 'TENANT-$shortId';
  }

  /// Aplica o filtro estrito de tenant a uma query de Evento.
  /// Cada criador só enxerga, lista e gerencia seus próprios eventos.
  static Future<QueryBuilder<ParseObject>> scopeEventQuery(
    QueryBuilder<ParseObject> query,
  ) async {
    final user = await getCurrentUser();
    if (!isMasterAdmin(user) && user?.objectId != null) {
      query.whereEqualTo('creatorId', user!.objectId);
    }
    return query;
  }

  /// Injeta os metadados de tenant nos dados de criação/atualização de um evento
  static Future<Map<String, dynamic>> injectTenantData(Map<String, dynamic> data) async {
    final user = await getCurrentUser();
    if (user != null) {
      data['creatorId'] = user.objectId;
      data['tenantId'] = getDisplayTenantId(user);
      data['creatorName'] = user.get<String>('name') ?? (user.get<String>('username') ?? 'Criador');
      data['isGlobal'] = true; // Evento é visível globalmente aos caçadores
    }
    return data;
  }
}
