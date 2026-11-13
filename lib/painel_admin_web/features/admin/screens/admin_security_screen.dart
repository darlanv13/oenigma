import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AdminSecurityScreen extends StatefulWidget {
  const AdminSecurityScreen({super.key});

  @override
  State<AdminSecurityScreen> createState() => _AdminSecurityScreenState();
}

class _AdminSecurityScreenState extends State<AdminSecurityScreen> {
  late Future<List<dynamic>> _logsFuture;
  List<dynamic> _allLogs = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _logsFuture = _fetchFraudLogs();
    });
  }

  Future<List<dynamic>> _fetchFraudLogs() async {
    try {
      final response = await ParseCloudFunction('getFraudLogs').execute();
      if (response.success && response.result != null) {
        final list = List<dynamic>.from(response.result as List);
        _allLogs = list;
        return list;
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar logs de fraude: $e');
      return [];
    }
  }

  Future<void> _toggleBanUser(String userId, String userName, bool currentBanned) async {
    final willBan = !currentBanned;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131D24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: willBan ? Colors.redAccent : AppColors.verdeVale),
        ),
        title: Row(
          children: [
            FaIcon(
              willBan ? FontAwesomeIcons.userSlash : FontAwesomeIcons.userCheck,
              color: willBan ? Colors.redAccent : AppColors.verdeVale,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              willBan ? 'Banir Usuário?' : 'Remover Banimento?',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          willBan
              ? 'Tem certeza que deseja banir o caçador "$userName"? Ele não poderá mais validar enigmas ou receber prêmios.'
              : 'Deseja reativar o acesso do caçador "$userName"?',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('CANCELAR', style: GoogleFonts.poppins(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: willBan ? Colors.redAccent : AppColors.verdeVale,
              foregroundColor: Colors.white,
            ),
            child: Text(willBan ? 'SIM, BANIR' : 'REATIVAR', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final response = await ParseCloudFunction('toggleBanUser').execute(parameters: {
        'userId': userId,
        'isBanned': willBan,
      });

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(willBan ? 'Caçador banido com sucesso.' : 'Acesso reativado.'),
            backgroundColor: willBan ? Colors.redAccent : AppColors.verdeVale,
          ),
        );
        _loadLogs();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.shieldHalved, color: Colors.redAccent, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Segurança & Anti-Fraude (Zero Trust)',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitoramento de tentativas de GPS falso, Impossible Travel e integridade das caçadas',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.cinzaMedio),
                ),
              ],
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.rotateRight, color: Colors.white),
              onPressed: _loadLogs,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // KPIs
        FutureBuilder<List<dynamic>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            final logs = snapshot.data ?? _allLogs;
            final mockCount = logs.where((l) => (l['reason'] ?? '').toString().contains('Mock') || (l['reason'] ?? '').toString().contains('Fake')).length;
            final speedCount = logs.where((l) => (l['reason'] ?? '').toString().contains('Impossible') || (l['speedKmH'] != null)).length;

            return Row(
              children: [
                Expanded(
                  child: _buildSecurityKpi(
                    title: 'TOTAL DE INCIDENTES',
                    value: logs.length.toString(),
                    icon: FontAwesomeIcons.triangleExclamation,
                    color: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildSecurityKpi(
                    title: 'FAKE GPS BLOQUEADOS',
                    value: mockCount.toString(),
                    icon: FontAwesomeIcons.locationDot,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildSecurityKpi(
                    title: 'IMPOSSIBLE TRAVEL',
                    value: speedCount.toString(),
                    icon: FontAwesomeIcons.gaugeHigh,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // Tabela de Logs
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _logsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && _allLogs.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: AppColors.amareloVale));
              }

              final logs = snapshot.data ?? _allLogs;
              if (logs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(FontAwesomeIcons.circleCheck, color: AppColors.verdeVale, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum incidente de fraude detectado!',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'O ecossistema está operando em conformidade com as regras de integridade física.',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final item = logs[index];
                    final user = item['user'] as Map?;
                    final userName = user != null ? (user['name'] ?? 'Explorador') : 'Desconhecido';
                    final userEmail = user != null ? (user['email'] ?? '') : '';
                    final userId = user != null ? user['objectId'] : null;
                    final isBanned = user != null ? (user['isBanned'] == true) : false;
                    final reason = (item['reason'] ?? 'Atividade Suspeita').toString();
                    final speed = item['speedKmH'];
                    final createdAt = item['createdAt'];
                    final dateStr = createdAt != null ? createdAt.toString().split('T').first : '-';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                            ),
                            child: const FaIcon(FontAwesomeIcons.ban, color: Colors.redAccent, size: 14),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      userName,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (isBanned) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'BANIDO',
                                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  userEmail.isNotEmpty ? userEmail : 'ID: $userId',
                                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reason,
                                  style: GoogleFonts.poppins(
                                    color: Colors.amberAccent,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (speed != null)
                                  Text(
                                    'Velocidade registrada: ${(speed as num).toStringAsFixed(1)} km/h',
                                    style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(width: 16),
                          if (userId != null)
                            ElevatedButton.icon(
                              onPressed: _isProcessing ? null : () => _toggleBanUser(userId, userName, isBanned),
                              icon: FaIcon(
                                isBanned ? FontAwesomeIcons.userCheck : FontAwesomeIcons.userSlash,
                                size: 11,
                                color: isBanned ? Colors.white : Colors.black,
                              ),
                              label: Text(
                                isBanned ? 'REATIVAR' : 'BANIR',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isBanned ? Colors.white : Colors.black,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isBanned ? AppColors.verdeVale : Colors.redAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityKpi({
    required String title,
    required String value,
    required dynamic icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: FaIcon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  color: AppColors.cinzaMedio,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
