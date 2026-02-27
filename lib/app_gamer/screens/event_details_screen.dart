import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/app_gamer/screens/find_and_win_progress_screen.dart';
import 'package:oenigma/app_gamer/screens/wallet_screen.dart';
import 'package:oenigma/app_gamer/widgets/event_details/header_image.dart';
import 'package:oenigma/app_gamer/widgets/event_details/info_grid.dart';
import 'package:oenigma/app_gamer/widgets/event_details/title_section.dart';
import 'dart:ui';
import '../../models/event_model.dart';
import 'event_progress_screen.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_colors.dart';
import '../stores/event_store.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;
  final Map<String, dynamic> playerData;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.playerData,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final EventStore _store = EventStore();
  late final Future<LottieComposition> _composition;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _store.checkSubscription(widget.playerData, widget.event.id);
    _store.loadStats(widget.event.id, widget.event.eventType);

    if (widget.event.icon.isNotEmpty &&
        Uri.tryParse(widget.event.icon)?.isAbsolute == true) {
      _composition = NetworkLottie(widget.event.icon).load();
    } else {
      _composition = AssetLottie('assets/animations/no_enigma.json').load();
    }
  }

  Future<void> _handleSubscription() async {
    final confirmed = await _showSubscriptionConfirmationDialog();
    if (confirmed != true) return;

    final success = await _store.subscribeToEvent(widget.event.id);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inscrição realizada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      } else if (_store.insufficientFunds) {
        _showInsufficientFundsDialog();
      } else if (_store.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_store.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
          'Confirma a sua inscrição no evento "${widget.event.name}" pelo valor de R\$ ${widget.event.price.toStringAsFixed(2)}?',
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
                final walletData = await _firebaseService.getUserWalletData();
                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WalletScreen(wallet: walletData),
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
      body: Stack(
        children: [
          HeaderImage(
            iconUrl: widget.event.icon,
            composition: _composition,
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 280),
                Container(
                  decoration: const BoxDecoration(
                    color: darkBackground,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TitleSection(event: widget.event),
                      const SizedBox(height: 24),
                      InfoGrid(event: widget.event, store: _store),
                      const SizedBox(height: 24),
                      _buildDescriptionSection(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildBackButton(context),
          _buildBottomCtaButton(context),
        ],
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
              color: textColor.withOpacity(0.8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: textColor,
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
        icon: Icons.flag_outlined,
        label: 'Evento Finalizado',
      );
    }
    if (widget.event.status == 'dev') {
      return _buildDisabledButton(
        icon: Icons.hourglass_top_rounded,
        label: 'Em Breve',
      );
    }

    return Observer(
      builder: (_) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [darkBackground, darkBackground.withOpacity(0.0)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _store.isSubscribed ? Colors.green : primaryAmber,
              foregroundColor: darkBackground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: _store.isLoading
                ? null
                : () {
                    if (_store.isSubscribed) {
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
            icon: _store.isLoading
                ? Container(
                    width: 24,
                    height: 24,
                    child: const CircularProgressIndicator(
                      color: darkBackground,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _store.isSubscribed
                        ? Icons.play_arrow_rounded
                        : Icons.login_rounded,
                    size: 28,
                  ),
            label: Text(
              _store.isSubscribed
                  ? 'Jogar'
                  : 'Inscreva-se (R\$ ${widget.event.price.toStringAsFixed(2)})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledButton({required IconData icon, required String label}) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBackground, darkBackground.withOpacity(0.0)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.grey.shade500,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: null,
          icon: Icon(icon, size: 28),
          label: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
