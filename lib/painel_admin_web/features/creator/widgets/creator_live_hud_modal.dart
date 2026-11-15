import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class CreatorLiveHudModal extends StatefulWidget {
  final String challengeTitle;
  final String prize;
  final String challengeUrl;
  final int initialPlayers;

  const CreatorLiveHudModal({
    super.key,
    required this.challengeTitle,
    required this.prize,
    required this.challengeUrl,
    this.initialPlayers = 142,
  });

  @override
  State<CreatorLiveHudModal> createState() => _CreatorLiveHudModalState();
}

class _CreatorLiveHudModalState extends State<CreatorLiveHudModal> {
  late int _playersCount;
  late Timer _liveSimulationTimer;
  bool _isWinnerDeclared = false;
  String _winnerName = '';

  final List<Map<String, dynamic>> _liveFeed = [
    {'time': 'Agora', 'player': '@pedro_dev', 'action': 'Errou a Cifra de César', 'type': 'wrong'},
    {'time': 'Há 4s', 'player': '@carol_m', 'action': 'Avançou para a Fase 2! 🔥', 'type': 'advance'},
    {'time': 'Há 12s', 'player': '@lucas99', 'action': 'Desbloqueou Pista de Nível 2', 'type': 'hint'},
    {'time': 'Há 25s', 'player': '@felipe_br', 'action': 'Novo explorador entrou na sala', 'type': 'join'},
    {'time': 'Há 39s', 'player': '@ana_clara', 'action': 'Errou o Código Morse', 'type': 'wrong'},
  ];

  @override
  void initState() {
    super.initState();
    _playersCount = widget.initialPlayers;

    // Simula pulso dinâmico de participantes e feed na live
    _liveSimulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _isWinnerDeclared) return;
      setState(() {
        _playersCount += (timer.tick % 2 == 0) ? 3 : 1;
        _liveFeed.insert(0, {
          'time': 'Agora',
          'player': '@user_${DateTime.now().millisecond}',
          'action': (timer.tick % 3 == 0) ? 'Tentou validar chave secreta' : 'Avançou de fase no desafio!',
          'type': (timer.tick % 3 == 0) ? 'wrong' : 'advance',
        });
        if (_liveFeed.length > 8) _liveFeed.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _liveSimulationTimer.cancel();
    super.dispose();
  }

  void _triggerWinnerCelebration() {
    setState(() {
      _isWinnerDeclared = true;
      _winnerName = '@rodrigo_mestre';
      _liveFeed.insert(0, {
        'time': 'MOMENTO HISTÓRICO',
        'player': _winnerName,
        'action': '🏆 QUEBROU O COFRE! GANHADOR DO PIX!',
        'type': 'winner',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF070B0E),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0B1216),
          elevation: 0,
          leading: IconButton(
            icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.white70, size: 16),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'MODO LIVE STREAMER // HUD DE TRANSMISSÃO',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.redAccent, width: 0.8),
                ),
                child: Text(
                  'ON AIR (OBS)',
                  style: GoogleFonts.orbitron(
                    color: Colors.redAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isWinnerDeclared ? Colors.greenAccent : AppColors.amareloVale,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: FaIcon(
                _isWinnerDeclared ? FontAwesomeIcons.check : FontAwesomeIcons.trophy,
                size: 14,
              ),
              label: Text(
                _isWinnerDeclared ? 'GANHADOR CONSAGRADO' : 'CONCLUIR GANHADOR NA LIVE',
                style: GoogleFonts.orbitron(fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              onPressed: _isWinnerDeclared ? null : _triggerWinnerCelebration,
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lado Esquerdo: Placar, Cofre e Métricas de Audiência
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Banner do Desafio
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101B22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E3A45)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DESAFIO TRANSMITIDO:',
                                style: GoogleFonts.orbitron(
                                  color: AppColors.cinzaMedio,
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.challengeTitle,
                                style: GoogleFonts.cinzel(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.amareloVale.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'PRÊMIO PIX',
                                  style: GoogleFonts.orbitron(
                                    color: AppColors.amareloVale,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.prize,
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // KPIs de Transmissão (Exploradores Online, Palpites, Status do Cofre)
                    Row(
                      children: [
                        _buildLiveKpiCard(
                          title: 'EXPLORADORES CONECTADOS',
                          value: '$_playersCount',
                          icon: FontAwesomeIcons.users,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 14),
                        _buildLiveKpiCard(
                          title: 'STATUS DO COFRE',
                          value: _isWinnerDeclared ? 'DESTANCADO' : 'TRANCADO',
                          icon: _isWinnerDeclared ? FontAwesomeIcons.lockOpen : FontAwesomeIcons.vault,
                          color: _isWinnerDeclared ? Colors.greenAccent : Colors.redAccent,
                        ),
                        const SizedBox(width: 14),
                        _buildLiveKpiCard(
                          title: 'TENTATIVAS DE RESOLUÇÃO',
                          value: '${_playersCount * 4 + 87}',
                          icon: FontAwesomeIcons.bolt,
                          color: AppColors.amareloVale,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Cofre Gigante de Centro de Live
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isWinnerDeclared
                                ? [const Color(0xFF0F2B1D), const Color(0xFF0B1914)]
                                : [const Color(0xFF131D24), const Color(0xFF0C1318)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isWinnerDeclared ? Colors.greenAccent : const Color(0xFF1E3A45),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isWinnerDeclared ? Colors.greenAccent : AppColors.amareloVale)
                                  .withValues(alpha: 0.15),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(
                                _isWinnerDeclared ? FontAwesomeIcons.trophy : FontAwesomeIcons.vault,
                                size: 70,
                                color: _isWinnerDeclared ? Colors.greenAccent : AppColors.amareloVale,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                _isWinnerDeclared
                                    ? '🎉 COFRE QUEBRADO POR $_winnerName!'
                                    : 'AGUARDANDO O PRIMEIRO DECIFRADOR...',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isWinnerDeclared
                                    ? 'O prêmio Pix de ${widget.prize} foi liberado com sucesso!'
                                    : 'Aponte o celular para o QR Code ao lado para participar!',
                                style: GoogleFonts.inter(
                                  color: AppColors.cinzaMedio,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Lado Direito: Feed Ao Vivo e QR Code da Live
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Bloco do QR Code Gigante da Live (para captura direta no OBS)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101B22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: QrImageView(
                              data: widget.challengeUrl,
                              version: QrVersions.auto,
                              size: 110,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'JOGUE AO VIVO',
                                  style: GoogleFonts.orbitron(
                                    color: AppColors.amareloVale,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Aponte a câmera do seu celular para este QR Code e dispute o prêmio de ${widget.prize} agora!',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Feed Tático de Tentativas da Live
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F171D),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1E3A45)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const FaIcon(FontAwesomeIcons.satelliteDish, size: 12, color: Colors.greenAccent),
                                const SizedBox(width: 8),
                                Text(
                                  'FEED DE ATIVIDADE AO VIVO',
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.separated(
                                itemCount: _liveFeed.length,
                                separatorBuilder: (_, __) => const Divider(color: Color(0xFF1E3A45), height: 12),
                                itemBuilder: (context, index) {
                                  final item = _liveFeed[index];
                                  final type = item['type'];
                                  Color badgeCol = Colors.grey;
                                  if (type == 'wrong') badgeCol = Colors.redAccent;
                                  if (type == 'advance') badgeCol = Colors.greenAccent;
                                  if (type == 'hint') badgeCol = AppColors.amareloVale;
                                  if (type == 'winner') badgeCol = Colors.greenAccent;

                                  return Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(color: badgeCol, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['player'],
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              item['action'],
                                              style: GoogleFonts.inter(
                                                color: badgeCol,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        item['time'],
                                        style: GoogleFonts.inter(
                                          color: AppColors.cinzaMedio,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildLiveKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF101B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E3A45)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FaIcon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.orbitron(
                      color: AppColors.cinzaMedio,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
