import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/enigma_model.dart';
import '../models/event_model.dart';
import '../models/phase_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../widgets/success_dialog.dart';

class EnigmaScreen extends StatefulWidget {
  final EventModel event;
  final PhaseModel phase;
  final EnigmaModel enigma;
  final VoidCallback onEnigmaSolved;

  const EnigmaScreen({
    super.key, required this.event, required this.phase, required this.enigma, required this.onEnigmaSolved,
  });

  @override
  State<EnigmaScreen> createState() => _EnigmaScreenState();
}

class _EnigmaScreenState extends State<EnigmaScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  
  late Future<Map<String, dynamic>> _stateFuture;
  bool _isLoading = false;
  Timer? _cooldownTimer;
  String _cooldownTimeLeft = '';

  @override
  void initState() {
    super.initState();
    _stateFuture = _fetchEnigmaStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchEnigmaStatus() async {
    try {
      final result = await _firebaseService.callEnigmaFunction('getStatus', {
        'eventId': widget.event.id,
        'phaseOrder': widget.phase.order,
        'enigmaId': widget.enigma.id,
      });
      final data = result.data as Map<String, dynamic>;
      if (data['isBlocked'] == true && data['cooldownUntil'] != null) {
        _startCooldownTimer(DateTime.parse(data['cooldownUntil']));
      }
      return data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  void _startCooldownTimer(DateTime cooldownUntil) {
    if (_cooldownTimer?.isActive ?? false) _cooldownTimer!.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final difference = cooldownUntil.difference(DateTime.now());
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (difference.isNegative) {
        timer.cancel();
        _refreshState();
      } else {
        setState(() => _cooldownTimeLeft = '${difference.inMinutes.toString().padLeft(2, '0')}:${(difference.inSeconds % 60).toString().padLeft(2, '0')}');
      }
    });
  }
  
  void _refreshState() {
      if(mounted) {
        setState(() {
            _cooldownTimeLeft = '';
            _stateFuture = _fetchEnigmaStatus();
        });
      }
  }

  Future<void> _handleAction(String action, {String? code}) async {
    setState(() => _isLoading = true);
    try {
      final result = await _firebaseService.callEnigmaFunction(action, {
        'eventId': widget.event.id,
        'phaseOrder': widget.phase.order,
        'enigmaId': widget.enigma.id,
        if (code != null) 'code': code,
      });

      final data = result.data as Map<String, dynamic>;
      final message = data['message'] ?? 'Ação concluída.';
      final success = data['success'] ?? false;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: success ? Colors.green : Colors.red));

      if (success && action == 'validateCode') {
        final nextStep = data['nextStep'] as Map<String, dynamic>?;

        if (nextStep != null && nextStep['type'] == 'next_enigma') {
          final nextEnigma = EnigmaModel.fromMap(nextStep['enigmaData'] as Map<String, dynamic>);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => EnigmaScreen(
              event: widget.event,
              phase: widget.phase,
              enigma: nextEnigma,
              onEnigmaSolved: widget.onEnigmaSolved,
            )),
          );
        } else { // 'phase_complete'
          showSuccessDialog(context, onOkPressed: () {
              Navigator.of(context).pop(); 
              Navigator.of(context).pop();
              widget.onEnigmaSolved();
          });
        }
      } else if (success && action == 'purchaseHint') {
        _refreshState();
      } else if (!success && action == 'validateCode'){
          _refreshState(); 
      }
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Ocorreu um erro.'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.name),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _stateFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _cooldownTimeLeft.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }
          if (snapshot.hasError || snapshot.data?['error'] != null) {
            return Center(
              child: Text(
                'Erro ao carregar dados do enigma: ${snapshot.error ?? snapshot.data?['error']}',
              ),
            );
          }

          final state = snapshot.data ?? {};
          final bool isHintVisible = state['isHintVisible'] ?? false;
          final bool canBuyHint = state['canBuyHint'] ?? false;
          final bool isBlocked =
              _cooldownTimeLeft.isNotEmpty || (state['isBlocked'] ?? false);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                _buildHeader("FASE ${widget.phase.order}", widget.event.name),
                const SizedBox(height: 24),
                _buildQuestionCard(),
                const SizedBox(height: 16),
                _buildHintSection(isHintVisible, canBuyHint),
                const SizedBox(height: 24),
                _buildCodeInputSection(isBlocked),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: primaryAmber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: secondaryTextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.help_outline, color: primaryAmber, size: 30),
          const SizedBox(height: 16),
          Text(
            widget.enigma.question,
            textAlign: TextAlign.center,
            style: const TextStyle(color: textColor, fontSize: 20, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildHintSection(bool isHintVisible, bool canBuyHint) {
    if (isHintVisible) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryAmber.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryAmber),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: primaryAmber, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Dica: ${widget.enigma.hint}',
                style: const TextStyle(color: textColor, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }
    if (canBuyHint && !_isLoading) {
      return TextButton.icon(
        onPressed: () => _handleAction('purchaseHint'),
        icon: const Icon(Icons.lightbulb, color: primaryAmber),
        label: const Text(
          'Comprar Dica',
          style: TextStyle(color: primaryAmber),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCodeInputSection(bool isBlocked) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          TextField(
            controller: _codeController,
            enabled: !isBlocked,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              letterSpacing: 8,
              color: isBlocked ? secondaryTextColor : textColor,
            ),
            decoration: InputDecoration(
              hintText: 'XXX-XXX-XXX',
              hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5)),
              filled: true,
              fillColor: isBlocked ? Colors.grey.shade800 : darkBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (isBlocked)
            Text(
              "Tente novamente em: $_cooldownTimeLeft",
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _handleAction(
                        'validateCode',
                        code: _codeController.text.trim(),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _isLoading
                    ? Container()
                    : const Icon(Icons.send, color: darkBackground),
                label: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: darkBackground),
                      )
                    : const Text(
                        'Verificar Código',
                        style: TextStyle(
                          color: darkBackground,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
