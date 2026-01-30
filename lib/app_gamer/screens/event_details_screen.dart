import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/screens/find_and_win_progress_screen.dart';
import 'package:oenigma/screens/wallet_screen.dart';
import 'dart:ui';
import '../models/event_model.dart';
import '../screens/event_progress_screen.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

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
  final FirebaseService _firebaseService = FirebaseService();
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
    final stats = await _firebaseService.getFindAndWinStats(widget.event.id);
    return {
      'total': stats['totalEnigmas'] ?? 0,
      'solved': stats['solvedEnigmas'] ?? 0,
    };
  }

  Future<Map<String, int>> _getClassicEventStats() async {
    final count = await _firebaseService.getChallengeCountForEvent(
      widget.event.id,
    );
    return {
      'total': count,
      'solved': 0,
    }; // O progresso é individual no modo clássico
  }

  // Função para lidar com a inscrição
  Future<void> _handleSubscription() async {
    final confirmed = await _showSubscriptionConfirmationDialog();
    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _firebaseService.subscribeToEvent(widget.event.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inscrição realizada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isSubscribed = true);
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        if (e.code == 'failed-precondition') {
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

  // Dialog de saldo insuficiente CORRIGIDO
  void _showInsufficientFundsDialog() {
    showDialog(
      context: context, // Usa o contexto da TELA (State)
      builder: (dialogContext) => AlertDialog(
        // Renomeado para dialogContext
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
              // 1. Fecha o dialog de "Saldo Insuficiente" usando o contexto DELE
              Navigator.of(dialogContext).pop();

              if (!mounted) return;

              // 2. Mostra o loading usando o contexto da TELA (que ainda existe)
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: primaryAmber),
                ),
              );

              try {
                // 3. Busca os dados da carteira
                final walletData = await _firebaseService.getUserWalletData();

                if (mounted) {
                  // 4. Fecha o loading (usando context da tela, que é o pai do loading agora)
                  Navigator.of(context).pop();

                  // 5. Navega para a tela da carteira
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WalletScreen(wallet: walletData),
                    ),
                  );
                }
              } catch (e) {
                // Caso ocorra erro, fecha o loading e avisa
                if (mounted) {
                  Navigator.of(context).pop(); // Fecha loading
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
      // Usamos uma Stack para sobrepor o conteúdo sobre a imagem de header
      body: Stack(
        children: [
          // 1. HEADER IMERSIVO
          _buildHeaderImage(),

          // 2. CONTEÚDO ROLÁVEL
          SingleChildScrollView(
            child: Column(
              children: [
                // Espaçador para o conteúdo começar abaixo do header
                const SizedBox(height: 280),
                // Container principal com cantos arredondados
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
                      _buildTitleSection(),
                      const SizedBox(height: 24),
                      _buildInfoGrid(),
                      const SizedBox(height: 24),
                      _buildDescriptionSection(),
                      // Espaço extra para não ser coberto pelo botão fixo
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. BOTÃO DE VOLTAR E BOTÃO DE AÇÃO FIXO
          _buildBackButton(context),
          _buildBottomCtaButton(context),
        ],
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
              const Icon(Icons.help_outline, size: 150, color: primaryAmber),
            // O gradiente continua o mesmo
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    darkBackground.withOpacity(0.8),
                    darkBackground.withOpacity(0.4),
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
          const SizedBox(height: 8),
          Row(
            children: [
              // --- ÍCONE SUBSTITUÍDO PELA ANIMAÇÃO LOTTIE ---
              Lottie.asset(
                'assets/animations/trofel.json', // Animação de "check"
                height: 60,
                width: 60,
                repeat: true,
              ),
              const SizedBox(width: 4), // Espaçamento ajustado
              const Text(
                'Prêmio:',
                style: TextStyle(color: secondaryTextColor, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                widget.event.prize,
                style: const TextStyle(
                  color: primaryAmber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET DE INFORMAÇÕES ATUALIZADO ---
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
            Icons.location_on_outlined,
            'Local',
            widget.event.location,
          ),
          _buildInfoPill(
            Icons.calendar_today_outlined,
            'Data',
            widget.event.startDate,
          ),

          // --- WIDGET DE ESTATÍSTICAS CONDICIONAL ---
          FutureBuilder<Map<String, int>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (widget.event.eventType == 'find_and_win') {
                final solved = snapshot.data?['solved'] ?? 0;
                final total = snapshot.data?['total'] ?? 0;
                return _buildInfoPill(
                  Icons.track_changes,
                  'Enigmas Resolvidos',
                  '$solved / $total',
                );
              } else {
                // Modo Clássico
                final total = snapshot.data?['total'] ?? 0;
                return _buildInfoPill(
                  Icons.filter_alt_outlined,
                  'Fases',
                  total.toString(),
                );
              }
            },
          ),

          _buildInfoPill(
            Icons.monetization_on_outlined,
            'Inscrição',
            'R\$ ${widget.event.price.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: secondaryTextColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
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
            // A descrição completa do evento pode ser usada aqui
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

    // Lógica principal: Jogar ou Inscrever-se
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
            backgroundColor: _isSubscribed ? Colors.green : primaryAmber,
            foregroundColor: darkBackground,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: _isLoading
              ? null
              : () {
                  if (_isSubscribed) {
                    // Verifica o tipo de evento para decidir para onde navegar
                    if (widget.event.eventType == 'find_and_win') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FindAndWinProgressScreen(event: widget.event),
                        ),
                      );
                    } else {
                      // Navegação padrão para o modo clássico
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
              ? Container(
                  width: 24,
                  height: 24,
                  child: const CircularProgressIndicator(
                    color: darkBackground,
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  _isSubscribed
                      ? Icons.play_arrow_rounded
                      : Icons.login_rounded,
                  size: 28,
                ),
          label: Text(
            _isSubscribed
                ? 'Jogar'
                : 'Inscreva-se (R\$ ${widget.event.price.toStringAsFixed(2)})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para botões desabilitados
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
