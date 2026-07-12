import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/features/event/providers/event_repository_provider.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';

import 'package:oenigma/core/models/event_model.dart';
import '../screens/event_progress_screen.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'find_and_win_progress_screen.dart';
import 'package:oenigma/features/wallet/screens/wallet_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  late final Future<LottieComposition> _composition;
  Future<Map<String, int>>? _statsFuture;
  bool _isSubscribed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isSubscribed = widget.playerData['events']?[widget.event.id] != null;

    // Carrega a animação do header
    if (widget.event.icon.isNotEmpty &&
        Uri.tryParse(widget.event.icon)?.isAbsolute == true) {
      _composition = NetworkLottie(widget.event.icon).load();
    } else {
      _composition = AssetLottie('assets/animations/no_enigma.json').load();
    }

    // --- LÓGICA DE CARREGAMENTO CONDICIONAL ---
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
    return {
      'total': count,
      'solved': 0, // O progresso é individual no modo clássico
    };
  }

  // Função para lidar com a inscrição
  Future<void> _handleSubscription() async {
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
        if (e.message?.contains('saldo') == true) {
          _showInsufficientFundsDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? "Ocorreu um erro."),
              backgroundColor: Colors.red,
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

  // Dialog de confirmação
  Future<bool?> _showSubscriptionConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Confirmar Inscrição',
          style: TextStyle(color: primaryAmber),
        ),
        content: Text(
          'Confirma a sua inscrição no evento "${widget.event.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryAmber),
            child: const Text(
              'CONFIRMAR',
              style: TextStyle(color: darkBackground),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog de saldo insuficiente
  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Saldo Insuficiente',
          style: TextStyle(color: primaryAmber),
        ),
        content: const Text(
          'Você não tem saldo para se inscrever. Deseja adicionar créditos à sua carteira?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Depois',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (!mounted) return;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: primaryAmber),
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
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryAmber),
            child: const Text(
              'RECARREGAR',
              style: TextStyle(color: darkBackground),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320.0,
            floating: false,
            pinned: true,
            backgroundColor: darkBackground,
            elevation: 0,
            leading: _buildBackButton(context),
            flexibleSpace: FlexibleSpaceBar(background: _buildHeaderImage()),
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0.0, -30.0, 0.0),
              decoration: BoxDecoration(
                color: darkBackground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildTitleSection(),
                  const SizedBox(height: 24),
                  _buildInfoGrid(),
                  const SizedBox(height: 32),
                  _buildDescriptionSection(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: _buildBottomCtaButton(context),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES PARA O NOVO DESIGN ---

  Widget _buildHeaderImage() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 320,
        decoration: const BoxDecoration(color: cardColor),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.event.icon.isNotEmpty)
              FutureBuilder<LottieComposition>(
                future: _composition,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Lottie(
                      composition: snapshot.data!,
                      fit: BoxFit.scaleDown,
                    );
                  } else if (snapshot.hasError) {
                    return Lottie.asset('assets/animations/no_enigma.json');
                  }
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryAmber,
                    ),
                  );
                },
              )
            else
              const FaIcon(
                FontAwesomeIcons.circleQuestion,
                size: 150,
                color: primaryAmber,
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    darkBackground.withValues(alpha: 0.8),
                    darkBackground.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.event.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/trofel.json',
                height: 48,
                width: 48,
                repeat: true,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryAmber.withValues(alpha: 0.1),
                  border: Border.all(
                    color: primaryAmber.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Prêmio Total: ',
                      style: TextStyle(color: secondaryTextColor, fontSize: 14),
                    ),
                    Text(
                      widget.event.prize,
                      style: const TextStyle(
                        color: primaryAmber,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
        children: [
          _buildInfoPill(
            FontAwesomeIcons.locationDot,
            'Local',
            widget.event.location,
          ),
          _buildInfoPill(
            FontAwesomeIcons.users,
            'Jogadores',
            widget.event.playerCount.toString(),
          ),
          FutureBuilder<Map<String, int>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (widget.event.eventType == 'find_and_win') {
                final solved = snapshot.data?['solved'] ?? 0;
                final total = snapshot.data?['total'] ?? 0;
                return _buildInfoPill(
                  FontAwesomeIcons.bullseye,
                  'Resolvidos',
                  '$solved / $total',
                );
              } else {
                final total = snapshot.data?['total'] ?? 0;
                return _buildInfoPill(
                  FontAwesomeIcons.filter,
                  'Fases',
                  total.toString(),
                );
              }
            },
          ),
          _buildInfoPill(FontAwesomeIcons.coins, 'Inscrição', 'Grátis'),
        ],
      ),
    );
  }

  Widget _buildInfoPill(dynamic icon, String label, String value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(icon, color: primaryAmber, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: secondaryTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SOBRE O EVENTO',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: secondaryTextColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.event.fullDescription,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Padding(
                padding: EdgeInsets.only(right: 2.0),
                child: FaIcon(
                  FontAwesomeIcons.angleLeft,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: _isSubscribed
            ? const LinearGradient(colors: [Colors.green, Colors.lightGreen])
            : const LinearGradient(colors: [primaryAmber, Color(0xFFFFD54F)]),
        boxShadow: [
          BoxShadow(
            color: _isSubscribed
                ? Colors.green.withValues(alpha: 0.3)
                : primaryAmber.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: _isSubscribed ? Colors.white : Colors.black,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _isLoading
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
        icon: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: darkBackground,
                  strokeWidth: 2,
                ),
              )
            : FaIcon(
                _isSubscribed
                    ? FontAwesomeIcons.play
                    : FontAwesomeIcons.rightToBracket,
                size: 28,
              ),
        label: Text(
          _isSubscribed ? 'ENTRAR NA CAÇADA' : 'INICIAR CAÇADA (GRÁTIS)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledButton({required dynamic icon, required String label}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.grey.shade500,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: null,
        icon: FaIcon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
