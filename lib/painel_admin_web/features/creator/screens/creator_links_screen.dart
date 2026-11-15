import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/config/env_config.dart';

class CreatorLinksScreen extends StatefulWidget {
  const CreatorLinksScreen({super.key});

  @override
  State<CreatorLinksScreen> createState() => _CreatorLinksScreenState();
}

class _CreatorLinksScreenState extends State<CreatorLinksScreen> {
  bool _isLoading = true;
  List<ParseObject> _myEvents = [];
  ParseObject? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final user = await ParseUser.currentUser() as ParseUser?;
      if (user != null) {
        final query = QueryBuilder<ParseObject>(ParseObject('Event'))
          ..orderByDescending('createdAt');

        final role = user.get<String>('role') ?? 'player';
        final isAdmin = user.get<bool>('isAdmin') ?? false;

        if (role == 'creator' || !isAdmin) {
          query.whereEqualTo('creatorId', user.objectId);
        }

        final res = await query.query();
        if (res.success && res.results != null) {
          _myEvents = List<ParseObject>.from(res.results!);
          if (_myEvents.isNotEmpty) {
            _selectedEvent = _myEvents.first;
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar desafios para links: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.verdeVale,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.verdeVale));
    }

    if (_myEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(FontAwesomeIcons.linkSlash, color: AppColors.cinzaMedio, size: 36),
            const SizedBox(height: 14),
            Text(
              'Nenhum desafio ativo encontrado',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Crie seu primeiro desafio para gerar links de divulgação e QR Codes.',
              style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final slug = _selectedEvent?.get<String>('slug') ?? _selectedEvent?.objectId ?? '';
    final publicLink = EnvConfig.buildChallengeUrl(slug);
    final title = _selectedEvent?.get<String>('name') ?? 'Desafio do Criador';
    final prize = _selectedEvent?.get<String>('prize') ?? 'R\$ 1.000,00';
    final price = (_selectedEvent?.get<num>('price') ?? 0.0).toDouble();
    final isFree = price <= 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seletor de Desafio
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkCardBorder),
            ),
            child: Row(
              children: [
                Text(
                  'Selecione o Desafio:',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedEvent?.objectId,
                      dropdownColor: AppColors.darkCardColor,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                      items: _myEvents.map((ev) {
                        return DropdownMenuItem<String>(
                          value: ev.objectId,
                          child: Text(ev.get<String>('name') ?? 'Sem título'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedEvent = _myEvents.firstWhere((e) => e.objectId == val);
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grid com Link/QR Code e Previa do Story
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 850;

              final leftColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Box do Link
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.darkCardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LINK OFICIAL DE DIVULGAÇÃO',
                          style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.darkBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  publicLink,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.amareloVale,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.copy, color: Colors.white, size: 14),
                                onPressed: () => _copyToClipboard(publicLink, 'Link copiado para a área de transferência!'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Coloque este link na bio do Instagram, na figurinha de Link dos Stories ou na descrição dos seus vídeos.',
                          style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Modelos de Copy Prontos
                  _buildCopyTemplatesSection(title, prize, isFree, price, publicLink),
                ],
              );

              final rightColumn = Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: _buildStoryCardPreview(title, prize, isFree, price, publicLink),
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: leftColumn),
                    const SizedBox(width: 18),
                    Expanded(flex: 4, child: rightColumn),
                  ],
                );
              }

              return Column(
                children: [
                  leftColumn,
                  const SizedBox(height: 20),
                  rightColumn,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCopyTemplatesSection(String title, String prize, bool isFree, double price, String link) {
    final copyInstagram = '🔥 Lancei o enigma "$title"! Quem decifrar o mistério primeiro ganha $prize no Pix! Clica no link e vem tentar: $link';
    final copyYoutube = '🏆 CAÇA AO TESOURO DO CANAL: "$title"\nParticipe pelo link: $link\nPrêmio de $prize para quem resolver o enigma primeiro!';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.penNib, color: AppColors.amareloVale, size: 14),
              const SizedBox(width: 10),
              Text(
                'Modelos de Textos Prontos para Postar',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Template Instagram
          _buildCopyItem('Para Stories & Legenda do Instagram', copyInstagram),
          const SizedBox(height: 12),

          // Template YouTube
          _buildCopyItem('Para Descrição / Comentário Fixado do YouTube', copyYoutube),
        ],
      ),
    );
  }

  Widget _buildCopyItem(String label, String copyText) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11, fontWeight: FontWeight.w600)),
              InkWell(
                onTap: () => _copyToClipboard(copyText, 'Texto copiado com sucesso!'),
                child: Text(
                  'Copiar Texto',
                  style: GoogleFonts.poppins(color: AppColors.verdeVale, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(copyText, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStoryCardPreview(String title, String prize, bool isFree, double price, String link) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A151C), Color(0xFF0F262F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo / Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.compass, color: AppColors.amareloVale, size: 16),
              const SizedBox(width: 8),
              Text(
                'O ENIGMA',
                style: GoogleFonts.cinzel(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Título do Desafio
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          // Badge de Prêmio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.amareloVale.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.amareloVale),
            ),
            child: Text(
              '🏆 PRÊMIO: $prize',
              style: GoogleFonts.poppins(color: AppColors.amareloVale, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 20),

          // QR Code em Cartão Branco
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: QrImageView(
              data: link,
              version: QrVersions.auto,
              size: 160.0,
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'APONTE A CÂMERA E JOGUE AGORA',
            style: GoogleFonts.poppins(
              color: AppColors.cinzaMedio,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFree ? 'Entrada Gratuita' : 'Entrada: R\$ ${price.toStringAsFixed(2)} no Pix',
            style: GoogleFonts.poppins(
              color: Colors.greenAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
