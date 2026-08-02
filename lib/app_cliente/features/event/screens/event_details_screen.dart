import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/app_cliente/features/event/providers/event_repository_provider.dart';

import 'package:oenigma/app_cliente/core/models/event_model.dart';
import '../screens/event_progress_screen.dart';
import 'package:oenigma/app_cliente/features/wallet/screens/wallet_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/app_cliente/features/auth/screens/login_screen.dart'
    as oenigma_login_screen;

import 'lobby_find_and_win_screen.dart';

class EventDetailsScreen extends ConsumerStatefulWidget {
  final EventModel event;
  final Map<String, dynamic> playerData;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.playerData,
  });

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  Future<Map<String, int>>? _statsFuture;
  bool _isSubscribed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isSubscribed = widget.playerData['events']?[widget.event.id] != null;

    // Lógica de carregamento condicional
    if (widget.event.eventType == 'find_and_win') {
      _statsFuture = _getFindAndWinStats();
    } else {
      _statsFuture = _getClassicEventStats();
    }
  }

  Future<Map<String, int>> _getFindAndWinStats() async {
    final stats = await ref
        .read(eventRepositoryProvider)
        .getFindAndWinStats(widget.event.id);
    return {
      'total': stats['totalEnigmas'] ?? 0,
      'solved': stats['solvedEnigmas'] ?? 0,
    };
  }

  Future<Map<String, int>> _getClassicEventStats() async {
    final count = await ref
        .read(eventRepositoryProvider)
        .getChallengeCountForEvent(widget.event.id);
    return {'total': count, 'solved': 0};
  }

  Future<void> _handleSubscription() async {
    // Verifica se é um usuário convidado (visitante)
    if (widget.playerData.isEmpty || widget.playerData['name'] == null) {
      _showLoginRequiredDialog();
      return;
    }

    final confirmed = await _showSubscriptionConfirmationDialog();
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(eventRepositoryProvider).subscribeToEvent(widget.event.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inscrição realizada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isSubscribed = true);
      }
    } on ParseError catch (e) {
      if (mounted) {
        if (e.message.contains('saldo')) {
          _showInsufficientFundsDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showSubscriptionConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirmar Inscrição',
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Confirma a sua inscrição no evento "${widget.event.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'CONFIRMAR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            FaIcon(
              FontAwesomeIcons.userLock,
              color: Color(0xFFFFD54F),
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Login Necessário',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Você precisa criar uma conta ou fazer login para iniciar a caçada.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const oenigma_login_screen.LoginScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'FAZER LOGIN',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.wallet, color: Color(0xFFFFD54F), size: 20),
            SizedBox(width: 10),
            Text(
              'Saldo Insuficiente',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Você não tem saldo para se inscrever. Deseja adicionar créditos à sua carteira?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Depois', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (!mounted) return;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
                ),
              );

              try {
                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WalletScreen(),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erro ao carregar carteira: $e"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'RECARREGAR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFindAndWin = widget.event.eventType == 'find_and_win';
    final eventTitle = isFindAndWin ? "Ache & Ganhe" : "Modo Clássico";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // HEADER CUSTOMIZADO
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFFC0A060).withValues(alpha: 0.10),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBackButton(context),
                        Text(
                          'Detalhes',
                          style: GoogleFonts.orbitron(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF0E6C5),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 36), // Balance space
                      ],
                    ),
                  ),
                ),
              ),

              // CORPO DA TELA (SEM BORDAS)
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.name,
                            style: GoogleFonts.orbitron(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF0E6C5),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            eventTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFB0A07A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 8, 18, 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC0A060).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.coins,
                                  color: Color(0xFFC0A060),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.event.prize.replaceAll('R\$ ', 'R\$'),
                                  style: GoogleFonts.orbitron(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFF0E6C5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildInfoGrid(),
                          const SizedBox(height: 32),
                          _buildDescriptionSection(),
                          const SizedBox(height: 32),
                          _buildBottomCtaButton(context),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              FaIcon(
                                FontAwesomeIcons.shieldHalved,
                                color: Color(0xFFD6B570),
                                size: 12,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Caçada segura",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF16181C).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 20,
            childAspectRatio: 2.5,
            children: [
              _buildEventStatus(),
              FutureBuilder<Map<String, int>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (widget.event.eventType == 'find_and_win') {
                    final solved = snapshot.data?['solved'] ?? 0;
                    final total = snapshot.data?['total'] ?? 0;
                    return _buildInfoItem(
                        FontAwesomeIcons.chartSimple, 'PROGRESSO', '$solved / $total');
                  } else {
                    final total = snapshot.data?['total'] ?? 0;
                    return _buildInfoItem(
                        FontAwesomeIcons.chartSimple, 'FASES', total.toString());
                  }
                },
              ),
              _buildInfoItem(
                FontAwesomeIcons.users,
                'JOGADORES',
                widget.event.playerCount.toString(),
              ),
              _buildInfoItem(
                FontAwesomeIcons.star,
                'DIFICULDADE',
                'Média',
                iconColor: const Color(0xFFC0A060),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 1,
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                const Color(0xFFC0A060).withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventStatus() {
    String statusText = 'Em andamento';
    Color statusColor = const Color(0xFF4CAF50);
    dynamic iconData = FontAwesomeIcons.circleCheck;

    if (widget.event.status == 'dev') {
      statusText = 'Em breve';
      statusColor = const Color(0xFFFF9800);
      iconData = FontAwesomeIcons.clock;
    } else if (widget.event.status == 'closed') {
      statusText = 'Finalizado';
      statusColor = const Color(0xFFF44336);
      iconData = FontAwesomeIcons.circleXmark;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(
              FontAwesomeIcons.circle,
              color: statusColor,
              size: 6,
            ),
            const SizedBox(width: 4),
            const Text(
              'STATUS DO EVENTO',
              style: TextStyle(
                color: Color(0xFF7A7A7A),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            FaIcon(iconData, color: statusColor, size: 12),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(dynamic icon, String label, String value, {Color iconColor = const Color(0xFFC0A060)}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7A7A7A),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (icon != null) ...[
              SizedBox(
                width: 18,
                child: FaIcon(icon, color: iconColor, size: 12),
              ),
            ],
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFF0E6C5),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sobre a caçada',
          style: GoogleFonts.orbitron(
            fontSize: 13, // 0.8rem
            fontWeight: FontWeight.w700,
            color: const Color(0xFFC0A060),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: const Color(0xFFC0A060).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
          ),
          child: Text(
            widget.event.fullDescription.isNotEmpty
                ? widget.event.fullDescription
                : 'Encontre pistas espalhadas pela cidade, escaneie QR codes e desvende o mistério. O primeiro a completar todas as etapas leva o prêmio de R\$ 5.000,00.',
            style: const TextStyle(
              color: Color(0xFFB0A07A),
              fontSize: 14, // ~0.9rem
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFC0A060).withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: FaIcon(
            FontAwesomeIcons.chevronLeft,
            color: Color(0xFFC0A060),
            size: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCtaButton(BuildContext context) {
    if (widget.event.status == 'closed') {
      return _buildDisabledButton(
        icon: FontAwesomeIcons.flag,
        label: 'Evento Finalizado',
      );
    }
    if (widget.event.status == 'dev') {
      return _buildDisabledButton(
        icon: FontAwesomeIcons.hourglassHalf,
        label: 'Em Breve',
      );
    }

    final bool isFree = widget.event.price == 0;

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () {
              if (_isSubscribed) {
                if (widget.event.eventType == 'find_and_win') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FindAndWinProgressScreen(event: widget.event),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EventProgressScreen(event: widget.event),
                    ),
                  );
                }
              } else {
                _handleSubscription();
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC0A060), Color(0xFFA8894A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC0A060).withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFF06080B),
                  strokeWidth: 2,
                ),
              )
            else ...[
              const FaIcon(
                FontAwesomeIcons.play,
                size: 16,
                color: Color(0xFF06080B),
              ),
              const SizedBox(width: 10),
              Text(
                _isSubscribed
                    ? 'ENTRAR NA CAÇADA'
                    : (isFree
                          ? 'INICIAR CAÇADA (GRÁTIS)'
                          : "INSCRIÇÃO: R\$ ${widget.event.price.toStringAsFixed(2).replaceAll('.', ',')}"),
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF06080B),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledButton({required dynamic icon, required String label}) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 10),
          FaIcon(icon, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
