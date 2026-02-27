// lib/app_gamer/screens/enigma_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart' hide Marker;
import 'package:mobx/mobx.dart';
import 'package:oenigma/app_gamer/screens/scanner_screen.dart';
import 'package:oenigma/app_gamer/screens/winner_certificate_screen.dart';
import 'package:oenigma/app_gamer/widgets/enigma/action_area.dart';
import 'package:oenigma/app_gamer/widgets/enigma/enigma_card.dart';
import 'package:oenigma/app_gamer/widgets/enigma/hint_section.dart';
import 'package:oenigma/app_gamer/widgets/enigma/qr_code_gps_card.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import 'package:oenigma/app_gamer/widgets/dialogs/completion_dialog.dart';
import 'package:oenigma/app_gamer/widgets/dialogs/cooldown_dialog.dart';
import 'package:permission_handler/permission_handler.dart'
    hide PermissionStatus;
import 'package:saver_gallery/saver_gallery.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/enigma_model.dart';
import '../../models/event_model.dart';
import '../../models/phase_model.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_colors.dart';
import 'wallet_screen.dart';
import '../stores/enigma_store.dart';

class EnigmaScreen extends StatefulWidget {
  final EventModel event;
  final PhaseModel phase;
  final EnigmaModel initialEnigma;
  final VoidCallback onEnigmaSolved;

  const EnigmaScreen({
    super.key,
    required this.event,
    required this.phase,
    required this.initialEnigma,
    required this.onEnigmaSolved,
  });

  @override
  State<EnigmaScreen> createState() => _EnigmaScreenState();
}

class _EnigmaScreenState extends State<EnigmaScreen>
    with SingleTickerProviderStateMixin {
  final EnigmaStore _store = EnigmaStore();
  final TextEditingController _codeController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  ReactionDisposer? _shakeDisposer;
  ReactionDisposer? _nextStepDisposer;
  ReactionDisposer? _cooldownDisposer;
  ReactionDisposer? _errorDisposer;
  ReactionDisposer? _fundsDisposer;

  @override
  void initState() {
    super.initState();
    _store.setCurrentEnigma(widget.initialEnigma);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
        _store.resetShake();
      }
    });

    _store.resetEnigmaState(widget.event.id, widget.phase.order);

    _shakeDisposer = reaction<bool>((_) => _store.shakeTrigger, (trigger) {
      if (trigger) _shakeController.forward();
    });

    _nextStepDisposer = reaction<Map<String, dynamic>?>(
      (_) => _store.nextStep,
      (nextStep) {
        if (nextStep != null) {
          _handleNextStep(nextStep);
        }
      },
    );

    _cooldownDisposer = reaction<String?>((_) => _store.cooldownUntil, (
      cooldownUntil,
    ) {
      if (cooldownUntil != null) {
        _handleCooldown(cooldownUntil);
      }
    });

    _errorDisposer = reaction<String?>((_) => _store.errorMessage, (message) {
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    _fundsDisposer = reaction<bool>((_) => _store.insufficientFunds, (funds) {
      if (funds) {
        _showInsufficientFundsDialog();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _shakeController.dispose();
    _store.dispose();
    _shakeDisposer?.call();
    _nextStepDisposer?.call();
    _cooldownDisposer?.call();
    _errorDisposer?.call();
    _fundsDisposer?.call();
    super.dispose();
  }

  void _handleCooldown(String cooldownUntilStr) {
    final cooldownUntil = DateTime.parse(cooldownUntilStr);
    if (cooldownUntil.isAfter(DateTime.now())) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CooldownDialog(
          cooldownUntil: cooldownUntil,
          onCooldownFinished: () {
            _store.fetchInitialStatus(widget.event.id, widget.phase.order);
          },
        ),
      );
    }
  }

  Future<void> _handleNextStep(Map<String, dynamic> nextStep) async {
    switch (nextStep['type']) {
      case 'event_complete':
        final double prizeWon =
            (nextStep['prizeWon'] as num?)?.toDouble() ?? 0.0;
        final List<PhaseModel> allPhases = await _firebaseService
            .getPhasesForEvent(widget.event.id);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => WinnerCertificateScreen(
                event: widget.event,
                prizeWon: prizeWon,
                allPhases: allPhases,
              ),
            ),
          );
        }
        break;

      case 'next_enigma':
        final nextEnigma = EnigmaModel.fromMap(
          Map<String, dynamic>.from(nextStep['enigmaData']),
        );

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/animations/check.json',
                    height: 130,
                    repeat: false,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enigma Resolvido!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Próximo Desafio',
                        style: TextStyle(fontSize: 18, color: textColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        _store.setCurrentEnigma(nextEnigma);
        _codeController.clear();
        await _store.resetEnigmaState(widget.event.id, widget.phase.order);
        break;

      case 'phase_complete':
        showCompletionDialog(
          context,
          isPhaseComplete: true,
          onOkPressed: () {
            Navigator.of(context).pop();
            widget.onEnigmaSolved();
            Navigator.of(context).pop();
          },
        );
        break;
    }
  }

  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Saldo Insuficiente',
          style: TextStyle(color: primaryAmber, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Você não tem saldo suficiente para comprar esta dica. Deseja adicionar créditos?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Agora Não',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                final UserWalletModel walletData = await _firebaseService
                    .getUserWalletData();
                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WalletScreen(wallet: walletData),
                  ),
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Erro ao carregar dados da carteira."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryAmber),
            child: const Text(
              'Recarregar',
              style: TextStyle(
                color: darkBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPurchaseConfirmationDialog(int cost) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirmar Compra',
          style: TextStyle(color: primaryAmber),
        ),
        content: Text(
          'Comprar dica por R\$ $cost,00?\n\nEste valor será deduzido do seu saldo.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryAmber),
            child: const Text(
              'SIM, COMPRAR',
              style: TextStyle(color: darkBackground),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveImageFromUrl(String url) async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        final response = await http.get(Uri.parse(url));
        final Uint8List imageBytes = response.bodyBytes;
        final result = await SaverGallery.saveImage(
          imageBytes,
          quality: 80,
          fileName: 'enigma_dica_${DateTime.now().millisecondsSinceEpoch}.jpg',
          skipIfExists: false,
        );
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagem salva na galeria!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Falha ao salvar a imagem: ${result.errorMessage}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar imagem.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão para salvar imagem foi negada.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _launchMapsUrl(String coordinates) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$coordinates',
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir o mapa.';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir o mapa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Observer(
          builder: (_) => Text(
            "Fase ${widget.phase.order} - Enigma ${_store.currentEnigma != null ? (widget.phase.enigmas.indexOf(_store.currentEnigma!) + 1) : 1}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: true,
        backgroundColor: darkBackground,
        elevation: 0,
      ),
      backgroundColor: darkBackground,
      body: Observer(
        builder: (_) {
          if (_store.isLoading && !_store.isHintVisible) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }
          if (_store.currentEnigma == null) {
            return const Center(child: Text("Carregando enigma..."));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EnigmaCard(enigma: _store.currentEnigma!),
                const SizedBox(height: 24),
                HintSection(
                  store: _store,
                  phaseOrder: widget.phase.order,
                  eventId: widget.event.id,
                  onSaveImage: _saveImageFromUrl,
                  onLaunchMaps: _launchMapsUrl,
                  onShowPurchaseDialog: (cost) async {
                    final bool? confirmed =
                        await _showPurchaseConfirmationDialog(cost);
                    if (confirmed == true) {
                      _store.handleAction(
                        'purchaseHint',
                        widget.event.id,
                        widget.phase.order,
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
                _buildActionArea(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionArea() {
    if (_store.currentEnigma!.type == 'qr_code_gps') {
      return QrCodeGpsCard(
        store: _store,
        enigma: _store.currentEnigma!,
        onScan: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ScannerScreen(
                onScan: (scannedCode) {
                  _store.handleAction(
                    'validateCode',
                    widget.event.id,
                    widget.phase.order,
                    code: scannedCode,
                  );
                },
              ),
            ),
          );
        },
      );
    }
    return ActionArea(
      store: _store,
      codeController: _codeController,
      shakeAnimation: _shakeAnimation,
      onSubmit: () => _store.handleAction(
        'validateCode',
        widget.event.id,
        widget.phase.order,
        code: _codeController.text.trim(),
      ),
    );
  }
}
