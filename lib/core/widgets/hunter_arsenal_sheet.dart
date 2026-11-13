import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class ArsenalToolItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final FaIconData icon;
  final Color accentColor;
  final bool isConsumableInstant;

  const ArsenalToolItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
    required this.accentColor,
    this.isConsumableInstant = false,
  });
}

/// Arsenal do Caçador: Bottom Sheet de compra e ativação de ferramentas táticas
class HunterArsenalSheet extends StatefulWidget {
  final String eventId;
  final String? enigmaId;
  final List<String> activeTools;
  final Map<String, int> toolTimes;
  final VoidCallback onToolsUpdated;

  const HunterArsenalSheet({
    super.key,
    required this.eventId,
    this.enigmaId,
    this.activeTools = const [],
    this.toolTimes = const {},
    required this.onToolsUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required String eventId,
    String? enigmaId,
    List<String> activeTools = const [],
    Map<String, int> toolTimes = const {},
    required VoidCallback onToolsUpdated,
  }) async {
    SoundService.playOpen();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HunterArsenalSheet(
        eventId: eventId,
        enigmaId: enigmaId,
        activeTools: activeTools,
        toolTimes: toolTimes,
        onToolsUpdated: onToolsUpdated,
      ),
    );
  }

  @override
  State<HunterArsenalSheet> createState() => _HunterArsenalSheetState();
}

class _HunterArsenalSheetState extends State<HunterArsenalSheet> {
  double _balance = 0.0;
  bool _isLoadingBalance = true;
  String? _purchasingToolId;

  static const List<ArsenalToolItem> _catalog = [
    ArsenalToolItem(
      id: 'compass',
      title: 'Bússola Ancestral',
      description: 'Aponta o vetor direcional e azimute magnético em tempo real até o enigma físico.',
      price: 15.00,
      icon: FontAwesomeIcons.compass,
      accentColor: AppColors.amareloVale,
    ),
    ArsenalToolItem(
      id: 'radar',
      title: 'Radar Místico 360°',
      description: 'Emite varreduras de proximidade em anéis concêntricos com resposta tátil acelerada.',
      price: 10.00,
      icon: FontAwesomeIcons.satelliteDish,
      accentColor: AppColors.verdeVale,
    ),
    ArsenalToolItem(
      id: 'anti_decoy',
      title: 'Filtro Anti-Decoy',
      description: 'Neutraliza pistas falsas e marcadores de distração espalhados pelos criadores.',
      price: 4.00,
      icon: FontAwesomeIcons.shieldHalved,
      accentColor: Colors.cyanAccent,
    ),
    ArsenalToolItem(
      id: 'instant_skip',
      title: 'Desbloqueio de Cooldown',
      description: 'Zera instantaneamente qualquer penalidade de tempo por erro de tentativa de código.',
      price: 1.99,
      icon: FontAwesomeIcons.bolt,
      accentColor: Colors.amberAccent,
      isConsumableInstant: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final user = await ParseUser.currentUser() as ParseUser?;
      if (user != null) {
        await user.fetch();
        final rawBal = user.get('balance');
        if (mounted) {
          setState(() {
            _balance = (rawBal is num)
                ? rawBal.toDouble()
                : (double.tryParse(rawBal?.toString() ?? '0') ?? 0.0);
            _isLoadingBalance = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _purchaseTool(ArsenalToolItem item) async {
    if (_purchasingToolId != null) return;

    if (_balance < item.price) {
      SoundService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saldo insuficiente (R\$ ${_balance.toStringAsFixed(2).replaceAll('.', ',')}). Faça uma recarga via Pix.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _purchasingToolId = item.id);

    try {
      final function = ParseCloudFunction('handleEnigmaAction');
      final actionName = item.isConsumableInstant ? 'skipCooldown' : 'purchaseTool';
      final response = await function.execute(parameters: {
        'action': actionName,
        'eventId': widget.eventId,
        'enigmaId': widget.enigmaId,
        'toolType': item.id,
      });

      if (response.success && response.result != null) {
        final data = Map<String, dynamic>.from(response.result as Map);
        if (data['success'] == true) {
          SoundService.playReward();
          await _loadBalance();
          widget.onToolsUpdated();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚔️ ${item.title} adquirida com sucesso!'),
                backgroundColor: AppColors.verdeVale,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      final errorMsg = response.error?.message ?? 'Erro ao concluir compra da ferramenta.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha na transação: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasingToolId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F181D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.toolbox, color: AppColors.amareloVale, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'ARSENAL DO CAÇADOR',
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              // Saldo Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.verdeVale.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.wallet, size: 12, color: AppColors.verdeVale),
                    const SizedBox(width: 6),
                    Text(
                      _isLoadingBalance
                          ? '...'
                          : 'R\$ ${_balance.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.verdeVale,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lista de Ferramentas
          Expanded(
            child: ListView.separated(
              itemCount: _catalog.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _catalog[index];
                final isPurchased = widget.activeTools.contains(item.id);
                final remainingSec = widget.toolTimes[item.id] ?? 0;
                final isPurchasing = _purchasingToolId == item.id;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16252E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isPurchased
                          ? item.accentColor.withValues(alpha: 0.8)
                          : Colors.white12,
                      width: isPurchased ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: item.accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: item.accentColor.withValues(alpha: 0.5)),
                        ),
                        child: FaIcon(item.icon, color: item.accentColor, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'R\$ ${item.price.toStringAsFixed(2).replaceAll('.', ',')}',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: item.accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: Colors.white70,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: isPurchased && remainingSec > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.verdeVale.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.verdeVale),
                                      ),
                                      child: Text(
                                        'ATIVO (${(remainingSec ~/ 60).toString().padLeft(2, '0')}:${(remainingSec % 60).toString().padLeft(2, '0')})',
                                        style: GoogleFonts.orbitron(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.verdeVale,
                                        ),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: isPurchasing ? null : () => _purchaseTool(item),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: item.accentColor,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: isPurchasing
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                            )
                                          : Text(
                                              'DESBLOQUEAR',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
