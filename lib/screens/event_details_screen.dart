import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import '../models/event_model.dart';
import '../screens/event_progress_screen.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<int> _challengeCountFuture;
  // Guarda a animação em memória
  late final Future<LottieComposition> _composition;

  @override
  void initState() {
    super.initState();
    _challengeCountFuture = _firebaseService.getChallengeCountForEvent(
      widget.event.id,
    );

    // --- LÓGICA ATUALIZADA ---
    // Verifica se o 'icon' é uma URL válida.
    if (widget.event.icon.isNotEmpty &&
        Uri.tryParse(widget.event.icon)?.isAbsolute == true) {
      // Se for, carrega da rede.
      _composition = NetworkLottie(widget.event.icon).load();
    } else {
      // Se não, carrega a animação padrão dos assets locais.
      _composition = AssetLottie('assets/animations/no_enigma.json').load();
    }
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
    // Adicione a importação do Lottie no início do seu arquivo, caso não tenha ainda.
    // import 'package:lottie/lottie.dart';

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
          FutureBuilder<int>(
            future: _challengeCountFuture,
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data.toString() : '...';
              return _buildInfoPill(Icons.filter_alt_outlined, 'Fases', count);
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

  // Em event_details_screen.dart
  Widget _buildBottomCtaButton(BuildContext context) {
    // Se o evento estiver fechado, mostra um botão desabilitado
    if (widget.event.status == 'closed') {
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
            onPressed: null, // onPressed: null desabilita o botão
            icon: const Icon(Icons.check, size: 28),
            label: const Text(
              'Evento Finalizado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }
    // --- NOVA CONDIÇÃO PARA "EM BREVE" ---
    else if (widget.event.status == 'dev') {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          // ... (decoração do container)
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              // Usamos um estilo diferente para o botão "Em Breve"
              backgroundColor: const Color(0xFF2a2a2a),
              foregroundColor: secondaryTextColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: null, // onPressed: null desabilita o botão
            icon: const Icon(Icons.hourglass_top_rounded, size: 28),
            label: const Text(
              'Em Breve',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }
    // Caso contrário, mostra o botão normal para iniciar o evento
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
            backgroundColor: primaryAmber,
            foregroundColor: darkBackground,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventProgressScreen(event: widget.event),
              ),
            );
          },
          icon: const Icon(Icons.explore_outlined, size: 28),
          label: const Text(
            'Iniciar Evento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
