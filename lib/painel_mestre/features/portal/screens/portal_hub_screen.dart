import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/oenigma_admin_logo.dart';

/// Portal Hub Central do O Enigma
///
/// Apresenta os três módulos centrais da plataforma de forma visual e intuitiva:
/// 1. Painel Super Admin (Gestão da Plataforma & Multi-Tenancy)
/// 2. Creator Studio (Painel do Influenciador / Criador de Conteúdo)
/// 3. Web Player Público (Experiência do Seguidor / Jogador com Pix e Ferramentas)
class PortalHubScreen extends StatelessWidget {
  const PortalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 980;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                children: [
                  // 1. Header & Badge
                  _buildHeader(),
                  const SizedBox(height: 36),

                  // 2. Grid de Módulos (3 Cards Principais)
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildAdminCard(context)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildCreatorCard(context)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildPlayerCard(context)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildAdminCard(context),
                        const SizedBox(height: 20),
                        _buildCreatorCard(context),
                        const SizedBox(height: 20),
                        _buildPlayerCard(context),
                      ],
                    ),

                  const SizedBox(height: 48),

                  // 3. Rodapé com Atalho de Login e Informações
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const OEnigmaAdminLogo(size: LogoSize.hero, isVertical: true),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.verdeVale.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.verdeVale,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PLATAFORMA CREATOR ECONOMY • VERSÃO WEB 2.0',
                style: GoogleFonts.inter(
                  color: AppColors.verdeVale,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Selecione o Módulo para Acessar',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            'Explore as diferentes perspectivas da plataforma: administração master de tenants, criação de desafios pelos influencers e a experiência de jogo do seguidor.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.cinzaMedio,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // === CARD 1: PAINEL MESTRE ===
  Widget _buildAdminCard(BuildContext context) {
    return _buildModuleCard(
      badgeTitle: 'MASTER PLATFORM',
      badgeColor: AppColors.info,
      icon: FontAwesomeIcons.shieldHalved,
      iconColor: AppColors.info,
      title: 'Painel Mestre',
      subtitle: 'Super Admin & Multi-Tenancy',
      description:
          'Controle de todos os influenciadores parceiros, acompanhamento de GMV total, retenção da taxa de serviço de 15%, moderação de desafios, aprovação de saques Pix e segurança global.',
      features: [
        'Dashboard de GMV & Lucro da Plataforma',
        'Gestão de Criadores & Tenants',
        'Taxas de Serviço Configuráveis (15%)',
        'Auditoria de Gateways & Saques Pix',
      ],
      routeButtonText: 'Acessar Painel Mestre',
      routeButtonColor: AppColors.info,
      routeUrl: '/admin',
      onPressed: () => Navigator.pushNamed(context, '/admin'),
    );
  }

  // === CARD 2: CREATOR STUDIO ===
  Widget _buildCreatorCard(BuildContext context) {
    return _buildModuleCard(
      badgeTitle: 'INFLUENCER STUDIO',
      badgeColor: AppColors.amareloVale,
      icon: FontAwesomeIcons.wandMagicSparkles,
      iconColor: AppColors.amareloVale,
      title: 'Creator Studio',
      subtitle: 'Espaço do Influenciador',
      description:
          'Painel exclusivo para o criador lançar seus desafios em 4 etapas, configurar ingressos Pay-to-Play (R\$ 5 a R\$ 20), ativar Super Dicas pagas (R\$ 1,99), gerar links e solicitar saques Pix.',
      features: [
        'Wizard de Criação de Desafios em 4 Etapas',
        'Monetização Pay-to-Play & Super Dicas Pix',
        'Hub de Divulgação: Links & QR Codes',
        'Relatório Financeiro & Solicitação de Saque',
      ],
      routeButtonText: 'Acessar Creator Studio',
      routeButtonColor: AppColors.amareloVale,
      routeUrl: '/studio',
      isPrimary: true,
      onPressed: () => Navigator.pushNamed(context, '/studio'),
    );
  }

  // === CARD 3: WEB PLAYER PÚBLICO ===
  Widget _buildPlayerCard(BuildContext context) {
    return _buildModuleCard(
      badgeTitle: 'AUDIENCE & FOLLOWERS',
      badgeColor: AppColors.verdeVale,
      icon: FontAwesomeIcons.gamepad,
      iconColor: AppColors.verdeVale,
      title: 'Web Player Público',
      subtitle: 'Experiência do Seguidor',
      description:
          'Interface web responsiva e pública acessada pelos seguidores via link (/e/:slug). Suporta checkout Pix de ingresso, resolução de enigmas, ferramentas de decodificação e compra de Super Dicas.',
      features: [
        'Landing Page com Teaser em Vídeo',
        'Checkout Pix Instantâneo (QR Code + Copia/Cola)',
        'Decodificador Cifra de César & Código Morse',
        'Desbloqueio de Super Dicas por R\$ 1,99',
      ],
      routeButtonText: 'Jogar Desafio Demo',
      routeButtonColor: AppColors.verdeVale,
      routeUrl: '/player',
      onPressed: () => Navigator.pushNamed(context, '/player'),
    );
  }

  Widget _buildModuleCard({
    required String badgeTitle,
    required Color badgeColor,
    required dynamic icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String description,
    required List<String> features,
    required String routeButtonText,
    required Color routeButtonColor,
    required String routeUrl,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPrimary
              ? AppColors.amareloVale.withValues(alpha: 0.6)
              : AppColors.darkCardBorder,
          width: isPrimary ? 1.5 : 1.0,
        ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppColors.amareloVale.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Superior
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeTitle,
                  style: GoogleFonts.inter(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(icon, color: iconColor, size: 16),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Título e Subtítulo
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: AppColors.cinzaMedio,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),

          // Descrição
          Text(
            description,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          // Lista de Recursos
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1216),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: features
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: iconColor, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 22),

          // Botão de Ação
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: routeButtonColor,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    routeButtonText,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Rota direta: #$routeUrl',
              style: GoogleFonts.robotoMono(
                color: AppColors.cinzaMedio.withValues(alpha: 0.7),
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/studio'),
              icon: const FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 13, color: AppColors.amareloVale),
              label: Text(
                'Criador? Cadastre-se ou Entre no Studio',
                style: GoogleFonts.inter(color: AppColors.amareloVale, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(color: AppColors.cinzaMedio, shape: BoxShape.circle),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const FaIcon(FontAwesomeIcons.shieldHalved, size: 13, color: AppColors.cinzaMedio),
              label: Text(
                'Acesso Super Admin',
                style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 12.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'O Enigma Platform • Desenvolvido com Flutter Web & Parse Server • © 2026',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
