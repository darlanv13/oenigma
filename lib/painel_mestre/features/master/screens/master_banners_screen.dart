import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/core/models/banner_model.dart';
import 'package:oenigma/core/widgets/banner_card_widget.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/admin_modal.dart';
import '../utils/admin_upload_util.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  late Future<List<BannerModel>> _bannersFuture;

  static const List<Map<String, dynamic>> _availableIcons = [
    {'id': '', 'name': 'Nenhum'},
    {'id': 'money', 'name': 'Dinheiro'},
    {'id': 'trophy', 'name': 'Troféu 🏆'},
    {'id': 'fire', 'name': 'Fogo / Destaque 🔥'},
    {'id': 'star', 'name': 'Estrela ⭐'},
    {'id': 'crown', 'name': 'Coroa 👑'},
    {'id': 'bolt', 'name': 'Raio / Energia ⚡'},
    {'id': 'gem', 'name': 'Diamante 💎'},
    {'id': 'gift', 'name': 'Presente 🎁'},
    {'id': 'gamepad', 'name': 'Gamepad 🎮'},
    {'id': 'playstation', 'name': 'Playstation 🕹️'},
    {'id': 'compass', 'name': 'Bússola 🧭'},
    {'id': 'rocket', 'name': 'Foguete 🚀'},
    {'id': 'bell', 'name': 'Sino 🔔'},
    {'id': 'wallet', 'name': 'Carteira 💰'},
    {'id': 'tag', 'name': 'Etiqueta 🏷️'},
    {'id': 'ticket', 'name': 'Ticket 🎟️'},
    {'id': 'clock', 'name': 'Tempo ⏱️'},
    {'id': 'shield', 'name': 'Escudo 🛡️'},
    {'id': 'mobile', 'name': 'Celular 📱'},
  ];

  static const List<Map<String, dynamic>> _presetGradients = [
    {
      'name': 'Verde Vale (Oficial)',
      'start': '#005861',
      'end': '#007D8A',
      'color1': Color(0xFF005861),
      'color2': Color(0xFF007D8A),
    },
    {
      'name': 'Ouro & Amarelo',
      'start': '#B87304',
      'end': '#F3A522',
      'color1': Color(0xFFB87304),
      'color2': Color(0xFFF3A522),
    },
    {
      'name': 'Cyber Sapphire',
      'start': '#0D324D',
      'end': '#1B4965',
      'color1': Color(0xFF0D324D),
      'color2': Color(0xFF1B4965),
    },
    {
      'name': 'Roxo Místico',
      'start': '#3A1C71',
      'end': '#6A0572',
      'color1': Color(0xFF3A1C71),
      'color2': Color(0xFF6A0572),
    },
    {
      'name': 'Rubi Aventura',
      'start': '#780206',
      'end': '#B22222',
      'color1': Color(0xFF780206),
      'color2': Color(0xFFB22222),
    },
    {
      'name': 'Dark Obsidian',
      'start': '#181920',
      'end': '#2C2D3A',
      'color1': Color(0xFF181920),
      'color2': Color(0xFF2C2D3A),
    },
    {
      'name': 'Esmeralda',
      'start': '#0A5C36',
      'end': '#149A57',
      'color1': Color(0xFF0A5C36),
      'color2': Color(0xFF149A57),
    },
  ];

  static const List<Map<String, dynamic>> _presetTemplates = [
    {
      'label': '🏆 Mega Prêmio',
      'title': 'Mega Prêmio Semanal',
      'desc': 'Dispute os prêmios acumulados da semana no app!',
      'tag': 'MEGA PRÊMIO',
      'tagIcon': 'trophy',
      'btn': 'PARTICIPAR',
      'bgIcon': 'trophy',
      'start': '#B87304',
      'end': '#F3A522',
    },
    {
      'label': '🔥 Novo Desafio',
      'title': 'Enigma de Fim de Semana',
      'desc': 'Novas pistas liberadas na cidade para caçar!',
      'tag': 'NOVIDADE',
      'tagIcon': 'fire',
      'btn': 'JOGAR AGORA',
      'bgIcon': 'gamepad',
      'start': '#005861',
      'end': '#007D8A',
    },
    {
      'label': '🎁 Bônus / Indique',
      'title': 'Indique um Amigo',
      'desc': 'Ganhe créditos na sua carteira a cada indicação.',
      'tag': 'BÔNUS',
      'tagIcon': 'gift',
      'btn': 'RESGATAR',
      'bgIcon': 'gift',
      'start': '#3A1C71',
      'end': '#6A0572',
    },
    {
      'label': '👑 Ranking',
      'title': 'Temporada de Mestres',
      'desc': 'Veja os líderes e prepare-se para o prêmio final.',
      'tag': 'DESTAQUE',
      'tagIcon': 'crown',
      'btn': 'VER RANKING',
      'bgIcon': 'crown',
      'start': '#0D324D',
      'end': '#1B4965',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  void _loadBanners() {
    setState(() {
      final query = QueryBuilder<ParseObject>(ParseObject('Banner'))
        ..orderByAscending('order');
      _bannersFuture = query.query().then((response) {
        if (response.success && response.results != null) {
          final list = response.results as List<ParseObject>;
          return list.map((doc) => BannerModel.fromParse(doc)).toList();
        }
        return [];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Gerenciar Banners do App',
          FontAwesomeIcons.image,
          onAddNew: () => _showAddEditBannerModal(context),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<BannerModel>>(
            future: _bannersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.verdeVale),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }

              final banners = snapshot.data ?? [];
              if (banners.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  return _buildBannerCardItem(banner);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildAddButton(
          'Criar Novo Banner Personalizado',
          () => _showAddEditBannerModal(context),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    dynamic icon, {
    required VoidCallback onAddNew,
  }) {
    return Row(
      children: [
        FaIcon(icon, color: AppColors.verdeVale, size: 14),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.orbitron(
            color: AppColors.verdeVale,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.verdeVale.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: onAddNew,
          icon: const FaIcon(FontAwesomeIcons.plus, size: 11),
          label: const Text('NOVO BANNER'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.verdeVale,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.verdeVale.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(
              FontAwesomeIcons.images,
              color: AppColors.cinzaMedio,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum banner cadastrado',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie banners personalizados com gradientes, tags, imagens ou botões para destacar no app do cliente.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.cinzaMedio,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showAddEditBannerModal(context),
              icon: const FaIcon(FontAwesomeIcons.plus, size: 13),
              label: const Text('Criar Primeiro Banner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeVale,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCardItem(BannerModel banner) {
    final statusColor = banner.isActive
        ? AppColors.success
        : AppColors.cinzaMedio;
    final statusLabel = banner.isActive ? 'Ativo' : 'Inativo';
    final isImage = banner.isImageOnly;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Visual Mini Preview Box
          Container(
            width: 60,
            height: 38,
            decoration: BoxDecoration(
              gradient: isImage ? null : banner.gradient,
              color: isImage ? AppColors.darkBackground : null,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isImage && banner.imageUrl.isNotEmpty
                  ? Image.network(
                      banner.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: FaIcon(
                              FontAwesomeIcons.image,
                              color: Colors.white38,
                              size: 14,
                            ),
                          ),
                    )
                  : Center(
                      child: FaIcon(
                        BannerModel.getIconData(
                              banner.tagIcon.isNotEmpty
                                  ? banner.tagIcon
                                  : banner.bgIcon,
                            ) ??
                            FontAwesomeIcons.image,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),

          // Content info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        banner.title.isNotEmpty
                            ? banner.title
                            : (banner.tagText.isNotEmpty
                                  ? banner.tagText
                                  : 'Banner de Imagem'),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isImage
                            ? Colors.purple.withValues(alpha: 0.25)
                            : AppColors.verdeVale.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isImage
                              ? Colors.purple.withValues(alpha: 0.5)
                              : AppColors.verdeVale.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        isImage ? 'ARTE GRÁFICA' : 'CARD',
                        style: GoogleFonts.inter(
                          color: isImage
                              ? Colors.purpleAccent
                              : AppColors.amareloVale,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${banner.description.isNotEmpty ? "${banner.description} · " : ""}'
                  'Ordem: ${banner.order}'
                  '${banner.actionUrl.isNotEmpty ? " · Ação: ${banner.actionUrl}" : ""}',
                  style: GoogleFonts.inter(
                    color: AppColors.cinzaMedio,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton(
                'Editar',
                isPrimary: true,
                onTap: () => _showAddEditBannerModal(context, banner: banner),
              ),
              const SizedBox(width: 6),
              _buildButton(
                banner.isActive ? 'Desativar' : 'Ativar',
                isDanger: banner.isActive,
                isSuccess: !banner.isActive,
                onTap: () => _toggleBannerStatus(banner, !banner.isActive),
              ),
              const SizedBox(width: 6),
              _buildButton(
                'Excluir',
                isDanger: true,
                onTap: () => _confirmDeleteBanner(banner),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.verdeVale.withValues(alpha: 0.06),
          border: Border.all(
            color: AppColors.verdeVale.withValues(alpha: 0.3),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.circlePlus,
              color: AppColors.verdeVale,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    String text, {
    bool isPrimary = false,
    bool isDanger = false,
    bool isSuccess = false,
    required VoidCallback onTap,
  }) {
    Color bgColor = Colors.transparent;
    Color textColorStr = AppColors.verdeVale;
    Color borderColor = AppColors.verdeVale.withValues(alpha: 0.3);

    if (isPrimary) {
      bgColor = AppColors.verdeVale;
      textColorStr = Colors.white;
      borderColor = Colors.transparent;
    } else if (isDanger) {
      textColorStr = AppColors.danger;
      borderColor = AppColors.danger.withValues(alpha: 0.4);
    } else if (isSuccess) {
      textColorStr = const Color(0xFF10B981);
      borderColor = const Color(0xFF10B981).withValues(alpha: 0.4);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.inter(
            color: textColorStr,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  void _showAddEditBannerModal(BuildContext context, {BannerModel? banner}) {
    final titleController = TextEditingController(text: banner?.title ?? '');
    final descController = TextEditingController(
      text: banner?.description ?? '',
    );
    final tagTextController = TextEditingController(
      text: banner?.tagText ?? '',
    );
    final buttonTextController = TextEditingController(
      text: banner?.buttonText ?? '',
    );
    final actionUrlController = TextEditingController(
      text: banner?.actionUrl ?? '',
    );
    final imageUrlController = TextEditingController(
      text: banner?.imageUrl ?? '',
    );
    final orderController = TextEditingController(
      text: (banner?.order ?? 1).toString(),
    );

    String bannerType = banner?.bannerType ?? 'card';
    String selectedTagIcon = banner?.tagIcon ?? 'trophy';
    String selectedBgIcon = banner?.bgIcon ?? 'trophy';
    String startHex = banner?.gradientStartHex ?? '#005861';
    String endHex = banner?.gradientEndHex ?? '#007D8A';
    bool isActive = banner?.isActive ?? true;
    bool isUploadingImage = false;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final previewBanner = BannerModel(
              id: banner?.id ?? 'preview',
              title: titleController.text,
              description: descController.text,
              imageUrl: imageUrlController.text,
              actionUrl: actionUrlController.text,
              tagText: tagTextController.text,
              tagIcon: selectedTagIcon,
              buttonText: buttonTextController.text,
              bgIcon: selectedBgIcon,
              order: int.tryParse(orderController.text) ?? 1,
              isActive: isActive,
              bannerType: bannerType,
              gradientStartHex: startHex,
              gradientEndHex: endHex,
            );

            return AdminModal(
              title: banner == null ? 'Criar Novo Banner' : 'Editar Banner',
              maxWidth: 950,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row with Controls + Live Preview
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth > 750;

                      Widget formSection = _buildFormSection(
                        setModalState: setModalState,
                        titleController: titleController,
                        descController: descController,
                        tagTextController: tagTextController,
                        buttonTextController: buttonTextController,
                        actionUrlController: actionUrlController,
                        imageUrlController: imageUrlController,
                        orderController: orderController,
                        bannerType: bannerType,
                        onTypeChanged: (type) =>
                            setModalState(() => bannerType = type),
                        selectedTagIcon: selectedTagIcon,
                        onTagIconChanged: (icon) =>
                            setModalState(() => selectedTagIcon = icon),
                        selectedBgIcon: selectedBgIcon,
                        onBgIconChanged: (icon) =>
                            setModalState(() => selectedBgIcon = icon),
                        startHex: startHex,
                        endHex: endHex,
                        onGradientChanged: (start, end) => setModalState(() {
                          startHex = start;
                          endHex = end;
                        }),
                        isActive: isActive,
                        onActiveChanged: (val) =>
                            setModalState(() => isActive = val),
                        isUploadingImage: isUploadingImage,
                        onUploadImage: () async {
                          setModalState(() => isUploadingImage = true);
                          final url =
                              await AdminUploadUtil.pickAndUploadPng(context) ??
                              (context.mounted
                                  ? await AdminUploadUtil.pickAndUploadImage(
                                      context,
                                    )
                                  : null);
                          setModalState(() {
                            isUploadingImage = false;
                            if (url != null) imageUrlController.text = url;
                          });
                        },
                      );

                      Widget previewSection = _buildPreviewSection(
                        previewBanner: previewBanner,
                        setModalState: setModalState,
                        onApplyTemplate: (tpl) {
                          setModalState(() {
                            titleController.text = tpl['title'] ?? '';
                            descController.text = tpl['desc'] ?? '';
                            tagTextController.text = tpl['tag'] ?? '';
                            buttonTextController.text = tpl['btn'] ?? '';
                            selectedTagIcon = tpl['tagIcon'] ?? 'trophy';
                            selectedBgIcon = tpl['bgIcon'] ?? 'trophy';
                            startHex = tpl['start'] ?? '#005861';
                            endHex = tpl['end'] ?? '#007D8A';
                            bannerType = 'card';
                          });
                        },
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: formSection),
                            const SizedBox(width: 24),
                            Expanded(flex: 4, child: previewSection),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            previewSection,
                            const SizedBox(height: 20),
                            formSection,
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Modal Actions
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.verdeVale.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.inter(
                              color: AppColors.cinzaMedio,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final title = titleController.text.trim();
                                  final img = imageUrlController.text.trim();

                                  if (bannerType == 'card' && title.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Informe um título para o card.',
                                        ),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                    return;
                                  }

                                  if (bannerType == 'image' && img.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Faça upload ou informe a URL da imagem.',
                                        ),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() => isSaving = true);

                                  final Map<String, dynamic> data = {
                                    'title': title,
                                    'description': descController.text.trim(),
                                    'imageUrl': img,
                                    'actionUrl': actionUrlController.text
                                        .trim(),
                                    'tagText': tagTextController.text.trim(),
                                    'tagIcon': selectedTagIcon,
                                    'buttonText': buttonTextController.text
                                        .trim(),
                                    'bgIcon': selectedBgIcon,
                                    'order':
                                        int.tryParse(
                                          orderController.text.trim(),
                                        ) ??
                                        1,
                                    'isActive': isActive,
                                    'active':
                                        isActive, // Double write for dual compatibility
                                    'bannerType': bannerType,
                                    'gradientStartHex': startHex,
                                    'gradientEndHex': endHex,
                                    'colorHex': startHex,
                                  };

                                  final Map<String, dynamic> params = {
                                    'data': data,
                                  };
                                  if (banner != null && banner.id.isNotEmpty) {
                                    params['bannerId'] = banner.id;
                                  }

                                  try {
                                    await ParseCloudFunction(
                                      'createOrUpdateBanner',
                                    ).execute(parameters: params);

                                    if (dialogCtx.mounted) {
                                      Navigator.of(dialogCtx).pop();
                                    }
                                    _loadBanners();
                                  } catch (e) {
                                    setModalState(() => isSaving = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Erro ao salvar: $e'),
                                          backgroundColor: AppColors.danger,
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const FaIcon(
                                  FontAwesomeIcons.floppyDisk,
                                  size: 14,
                                ),
                          label: Text(
                            isSaving ? 'Salvando...' : 'Salvar Banner',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.verdeVale,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormSection({
    required void Function(VoidCallback) setModalState,
    required TextEditingController titleController,
    required TextEditingController descController,
    required TextEditingController tagTextController,
    required TextEditingController buttonTextController,
    required TextEditingController actionUrlController,
    required TextEditingController imageUrlController,
    required TextEditingController orderController,
    required String bannerType,
    required ValueChanged<String> onTypeChanged,
    required String selectedTagIcon,
    required ValueChanged<String> onTagIconChanged,
    required String selectedBgIcon,
    required ValueChanged<String> onBgIconChanged,
    required String startHex,
    required String endHex,
    required void Function(String, String) onGradientChanged,
    required bool isActive,
    required ValueChanged<bool> onActiveChanged,
    required bool isUploadingImage,
    required VoidCallback onUploadImage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Tipo de Banner
        Text(
          'TIPO DE BANNER',
          style: GoogleFonts.inter(
            color: AppColors.amareloVale,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeSelectorButton(
                icon: FontAwesomeIcons.paintbrush,
                label: 'Card Estilizado',
                isSelected: bannerType == 'card',
                onTap: () => onTypeChanged('card'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTypeSelectorButton(
                icon: FontAwesomeIcons.image,
                label: 'Arte Gráfica (Imagem)',
                isSelected: bannerType == 'image',
                onTap: () => onTypeChanged('image'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 2. Form fields according to type
        if (bannerType == 'card') ...[
          // Title
          _buildInputForm(
            controller: titleController,
            label: 'Título Principal',
            hint: 'Ex: Mega Prêmio Semanal',
            onChanged: (_) => setModalState(() {}),
          ),
          const SizedBox(height: 12),

          // Description
          _buildInputForm(
            controller: descController,
            label: 'Descrição',
            hint: 'Ex: Dispute prêmios em dinheiro hoje mesmo!',
            maxLines: 2,
            onChanged: (_) => setModalState(() {}),
          ),
          const SizedBox(height: 12),

          // Tag Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildInputForm(
                  controller: tagTextController,
                  label: 'Texto da Tag',
                  hint: 'Ex: MEGA PRÊMIO',
                  onChanged: (_) => setModalState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ícone da Tag',
                      style: GoogleFonts.inter(
                        color: AppColors.cinzaMedio,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildIconDropdown(
                      value: selectedTagIcon,
                      onChanged: (val) {
                        if (val != null) onTagIconChanged(val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          // Quick Tag suggestions
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children:
                ['MEGA PRÊMIO', 'DESTAQUE', 'NOVIDADE', 'EXCLUSIVO', 'EVENTO']
                    .map(
                      (tag) => InkWell(
                        onTap: () {
                          tagTextController.text = tag;
                          setModalState(() {});
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.verdeVale.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.verdeVale.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.inter(
                              color: AppColors.amareloVale,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),

          const SizedBox(height: 12),

          // Button & Watermark Icon Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildInputForm(
                  controller: buttonTextController,
                  label: 'Texto do Botão',
                  hint: 'Ex: PARTICIPAR',
                  onChanged: (_) => setModalState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marca d\'Água Fundo',
                      style: GoogleFonts.inter(
                        color: AppColors.cinzaMedio,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildIconDropdown(
                      value: selectedBgIcon,
                      onChanged: (val) {
                        if (val != null) onBgIconChanged(val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Gradient Presets
          Text(
            'PALETAS DE CORES & GRADIENTE',
            style: GoogleFonts.inter(
              color: AppColors.cinzaMedio,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetGradients.map((g) {
              final isCurrent = startHex == g['start'] && endHex == g['end'];
              return InkWell(
                onTap: () => onGradientChanged(g['start'], g['end']),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.amareloVale
                          : Colors.white.withValues(alpha: 0.1),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              g['color1'] as Color,
                              g['color2'] as Color,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        g['name'] as String,
                        style: GoogleFonts.inter(
                          color: isCurrent
                              ? Colors.white
                              : AppColors.cinzaMedio,
                          fontSize: 11,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Optional Image Illustration in Card
          Row(
            children: [
              Expanded(
                child: _buildInputForm(
                  controller: imageUrlController,
                  label: 'Ilustração do Prêmio / Objeto (PNG transparente)',
                  hint: 'https://... (PNG transparente do objeto)',
                  onChanged: (_) => setModalState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: ElevatedButton.icon(
                  onPressed: isUploadingImage ? null : onUploadImage,
                  icon: isUploadingImage
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const FaIcon(FontAwesomeIcons.upload, size: 12),
                  label: const Text('ENVIAR PNG'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdeVale,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Banner de Imagem Completa
          Text(
            'ARTE GRÁFICA COMPLETA',
            style: GoogleFonts.inter(
              color: AppColors.cinzaMedio,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.verdeVale.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInputForm(
                        controller: imageUrlController,
                        label: 'URL da Arte / Flyer',
                        hint: 'https://...',
                        onChanged: (_) => setModalState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: ElevatedButton.icon(
                        onPressed: isUploadingImage ? null : onUploadImage,
                        icon: isUploadingImage
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const FaIcon(FontAwesomeIcons.upload, size: 12),
                        label: const Text('ENVIAR IMAGEM'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verdeVale,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '💡 Dica: Proporção recomendada de 16:7 ou 1200x520 px em JPG/PNG.',
                  style: GoogleFonts.inter(
                    color: AppColors.cinzaMedio,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildInputForm(
            controller: titleController,
            label: 'Legenda / Título Opcional',
            hint: 'Ex: Grande Inauguração (opcional)',
            onChanged: (_) => setModalState(() {}),
          ),
        ],

        const SizedBox(height: 16),

        // Action URL + Order + Active Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: _buildInputForm(
                controller: actionUrlController,
                label: 'Link de Ação ao Clicar (actionUrl)',
                hint: 'https://... ou screen:wallet ou screen:ranking',
                onChanged: (_) => setModalState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _buildInputForm(
                controller: orderController,
                label: 'Ordem',
                hint: '1',
                isNumeric: true,
                onChanged: (_) => setModalState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: GoogleFonts.inter(
                      color: AppColors.cinzaMedio,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.verdeVale.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isActive ? 'Ativo' : 'Inativo',
                          style: GoogleFonts.inter(
                            color: isActive
                                ? AppColors.success
                                : AppColors.cinzaMedio,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Switch(
                          value: isActive,
                          activeThumbColor: AppColors.verdeVale,
                          onChanged: onActiveChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        // Quick Action presets
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _buildActionChip(
              'Carteira',
              'screen:wallet',
              actionUrlController,
              setModalState,
            ),
            _buildActionChip(
              'Ranking',
              'screen:ranking',
              actionUrlController,
              setModalState,
            ),
            _buildActionChip(
              'Site Oficial',
              'https://oenigma.com.br',
              actionUrlController,
              setModalState,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(
    String label,
    String value,
    TextEditingController controller,
    void Function(VoidCallback) setModalState,
  ) {
    return InkWell(
      onTap: () {
        controller.text = value;
        setModalState(() {});
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          '+ $label',
          style: GoogleFonts.inter(
            color: AppColors.cinzaMedio,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection({
    required BannerModel previewBanner,
    required void Function(VoidCallback) setModalState,
    required ValueChanged<Map<String, dynamic>> onApplyTemplate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.mobileScreenButton,
                  color: AppColors.amareloVale,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  'PRÉVIA NO APP DO CLIENTE (1:1)',
                  style: GoogleFonts.inter(
                    color: AppColors.amareloVale,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.verdeVale.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Tempo Real',
                style: GoogleFonts.inter(
                  color: AppColors.verdeVale,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Live Simulated Banner Card (Pixel for pixel identical to client app!)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBackground,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: BannerCardWidget(
            banner: previewBanner,
            height: 155.0,
            showShadow: true,
            margin: EdgeInsets.zero,
          ),
        ),

        const SizedBox(height: 16),

        // Quick Preset Templates
        Text(
          'MODELOS PRONTOS (1 CLIQUE)',
          style: GoogleFonts.inter(
            color: AppColors.cinzaMedio,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: _presetTemplates.map((tpl) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => onApplyTemplate(tpl),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.verdeVale.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        tpl['label'] as String,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Aplicar Modelo',
                        style: GoogleFonts.inter(
                          color: AppColors.verdeVale,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const FaIcon(
                        FontAwesomeIcons.arrowRight,
                        size: 9,
                        color: AppColors.verdeVale,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeSelectorButton({
    required dynamic icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.verdeVale.withValues(alpha: 0.2)
              : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.verdeVale
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              size: 14,
              color: isSelected ? AppColors.amareloVale : AppColors.cinzaMedio,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : AppColors.cinzaMedio,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _availableIcons.any((i) => i['id'] == value) ? value : '',
          dropdownColor: AppColors.darkCardColor,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          isExpanded: true,
          items: _availableIcons.map((item) {
            final iconId = item['id'] as String;
            final iconData = BannerModel.getIconData(iconId);
            return DropdownMenuItem<String>(
              value: iconId,
              child: Row(
                children: [
                  if (iconData != null) ...[
                    FaIcon(iconData, size: 12, color: AppColors.amareloVale),
                    const SizedBox(width: 8),
                  ],
                  Text(item['name'] as String),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInputForm({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool isNumeric = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.cinzaMedio,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.cinzaMedio.withValues(alpha: 0.5),
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppColors.darkCardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.verdeVale.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.verdeVale),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleBannerStatus(BannerModel banner, bool isActive) async {
    await ParseCloudFunction('createOrUpdateBanner').execute(
      parameters: {
        'bannerId': banner.id,
        'data': {'isActive': isActive, 'active': isActive},
      },
    );
    _loadBanners();
  }

  void _confirmDeleteBanner(BannerModel banner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardColor,
        title: Text(
          'Confirmar Exclusão',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Deseja realmente excluir o banner "${banner.title.isNotEmpty ? banner.title : 'selecionado'}"?',
          style: GoogleFonts.inter(color: AppColors.cinzaMedio),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ParseCloudFunction(
                'deleteBanner',
              ).execute(parameters: {'bannerId': banner.id});
              _loadBanners();
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
