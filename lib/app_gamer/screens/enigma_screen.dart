// lib/app_gamer/screens/enigma_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'dart:async';
import 'dart:math' show sin, pi;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart' hide Marker;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobx/mobx.dart';
import 'package:oenigma/app_gamer/screens/winner_certificate_screen.dart';
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
                _buildEnigmaCard(),
                const SizedBox(height: 24),
                _buildHintSection(),
                const SizedBox(height: 24),
                _buildActionArea(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: primaryAmber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEnigmaCard() {
    return _buildCard(title: 'DESAFIO ATUAL', child: _buildEnigmaContent());
  }

  Widget _buildEnigmaContent() {
    final enigma = _store.currentEnigma!;
    switch (enigma.type) {
      case 'photo_location':
      case 'text':
        return Column(
          children: [
            if (enigma.imageUrl != null && enigma.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(enigma.imageUrl!),
              )
            else if (enigma.type != 'text')
              Lottie.asset('assets/animations/no_enigma.json', height: 150),
            if (enigma.imageUrl != null) const SizedBox(height: 20),
            Text(
              enigma.instruction,
              style: const TextStyle(
                fontSize: 16,
                color: textColor,
                height: 1.6,
              ),
            ),
          ],
        );
      case 'qr_code_gps':
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionArea() {
    if (_store.currentEnigma!.type == 'qr_code_gps') {
      return _buildQrCodeGpsCard();
    }
    return _buildCodeInputSection();
  }

  Widget _buildQrCodeGpsCard() {
    return _buildCard(
      title: 'MISSÃO DE CAMPO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_store.currentEnigma!.imageUrl != null &&
              _store.currentEnigma!.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(_store.currentEnigma!.imageUrl!),
            )
          else
            Lottie.asset('assets/animations/no_enigma.json', height: 150),
          const SizedBox(height: 16),
          Text(
            _store.currentEnigma!.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: textColor, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: darkBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: _store.distance == null
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: secondaryTextColor,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Localizando alvo...",
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  )
                : Text(
                    "Distância: ${_store.distance!.toStringAsFixed(0)} metros",
                    style: const TextStyle(
                      fontSize: 14,
                      color: primaryAmber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _store.isNear && !_store.isBlocked
                  ? () {
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
                    }
                  : null,
              icon: Icon(
                _store.isBlocked
                    ? Icons.timer_off_outlined
                    : Icons.qr_code_scanner,
              ),
              label: Text(
                _store.isBlocked
                    ? 'Aguarde o Cooldown'
                    : (_store.isNear
                          ? 'ESCANEAR CÓDIGO'
                          : 'APROXIME-SE DO LOCAL'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _store.isNear && !_store.isBlocked
                    ? Colors.green
                    : cardColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                elevation: 0,
                side: BorderSide(
                  color: _store.isNear && !_store.isBlocked
                      ? Colors.transparent
                      : Colors.white10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintSection() {
    if (_store.isHintVisible) {
      if (_store.hintData != null) {
        return _buildCard(title: 'PISTA', child: _buildHintContent());
      }
      return const SizedBox.shrink();
    }

    if (_store.canBuyHint) {
      final hintCosts = {1: 5, 2: 10, 3: 15};
      final cost = hintCosts[widget.phase.order];

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: TextButton.icon(
          onPressed: _store.isLoading
              ? null
              : () async {
                  if (cost == null) return;
                  final bool? confirmed = await _showPurchaseConfirmationDialog(
                    cost,
                  );
                  if (confirmed == true) {
                    _store.handleAction(
                      'purchaseHint',
                      widget.event.id,
                      widget.phase.order,
                    );
                  }
                },
          icon: const Icon(Icons.lightbulb, color: primaryAmber),
          label: RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Precisa de ajuda? ',
                  style: TextStyle(color: Colors.white70),
                ),
                TextSpan(
                  text: 'Ver Dica (R\$ ${cost?.toStringAsFixed(2)})',
                  style: const TextStyle(
                    color: primaryAmber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: primaryAmber.withOpacity(0.08),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildHintContent() {
    final String type = _store.hintData!['type'];
    final String data = _store.hintData!['data'];
    Widget hintContent;
    Widget actionButton;

    if (type == 'photo') {
      hintContent = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(data),
      );
      actionButton = ElevatedButton.icon(
        onPressed: _store.isLoading ? null : () => _saveImageFromUrl(data),
        icon: const Icon(Icons.download_rounded),
        label: const Text('Salvar Imagem'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: Colors.white,
        ),
      );
    } else if (type == 'gps') {
      final coords = data.split(',');
      final lat = double.tryParse(coords[0]) ?? 0.0;
      final lng = double.tryParse(coords[1]) ?? 0.0;
      hintContent = SizedBox(
        height: 200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(lat, lng),
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('hintLocation'),
                position: LatLng(lat, lng),
              ),
            },
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
          ),
        ),
      );
      actionButton = ElevatedButton.icon(
        onPressed: () => _launchMapsUrl(data),
        icon: const Icon(Icons.map_rounded),
        label: const Text('Abrir no Maps'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: Colors.white,
        ),
      );
    } else {
      hintContent = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          data,
          style: const TextStyle(color: textColor, fontSize: 16, height: 1.5),
        ),
      );
      actionButton = ElevatedButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: data));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Copiado para a área de transferência!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        icon: const Icon(Icons.copy_rounded),
        label: const Text('Copiar Texto'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: Colors.white,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [hintContent, const SizedBox(height: 16), actionButton],
    );
  }

  Widget _buildCodeInputSection() {
    return _buildCard(
      title: 'SUA RESPOSTA',
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(sin(_shakeAnimation.value * pi) * 10, 0),
                child: child,
              );
            },
            child: TextField(
              controller: _codeController,
              enabled: !_store.isBlocked,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: _store.isBlocked ? secondaryTextColor : textColor,
              ),
              decoration: InputDecoration(
                hintText: 'CÓDIGO',
                hintStyle: TextStyle(
                  color: secondaryTextColor.withOpacity(0.3),
                  letterSpacing: 2,
                  fontFamily: 'Poppins',
                  fontSize: 24,
                ),
                filled: true,
                fillColor: darkBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryAmber, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _store.isLoading || _store.isBlocked
                  ? null
                  : () => _store.handleAction(
                      'validateCode',
                      widget.event.id,
                      widget.phase.order,
                      code: _codeController.text.trim(),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAmber,
                foregroundColor: darkBackground,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                shadowColor: primaryAmber.withOpacity(0.4),
              ),
              child: _store.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: darkBackground,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      _store.isBlocked ? 'Aguarde...' : 'ENVIAR RESPOSTA',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  final Function(String) onScan;
  const ScannerScreen({super.key, required this.onScan});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  String? _detectedQRCode;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aponte para o QR Code')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_detectedQRCode == null) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  setState(() {
                    _detectedQRCode = barcodes.first.rawValue;
                  });
                  _scannerController.stop();
                }
              }
            },
          ),
          if (_detectedQRCode != null) _buildConfirmationOverlay(),
        ],
      ),
    );
  }

  Widget _buildConfirmationOverlay() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: MediaQuery.of(context).size.width * 0.8,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryAmber),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Código Detectado',
                style: TextStyle(
                  color: primaryAmber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _detectedQRCode!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textColor, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  widget.onScan(_detectedQRCode!);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Confirmar'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _detectedQRCode = null;
                  });
                  _scannerController.start();
                },
                child: const Text(
                  'Escanear Novamente',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
