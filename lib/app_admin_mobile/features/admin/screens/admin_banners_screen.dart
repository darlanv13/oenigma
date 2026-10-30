import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/core/models/banner_model.dart';
import 'package:oenigma/core/widgets/banner_card_widget.dart';
import 'package:oenigma/core/utils/app_colors.dart';
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
    {'id': 'trophy', 'name': 'Troféu 🏆'},
    {'id': 'fire', 'name': 'Fogo / Destaque 🔥'},
    {'id': 'star', 'name': 'Estrela ⭐'},
    {'id': 'crown', 'name': 'Coroa 👑'},
    {'id': 'bolt', 'name': 'Raio ⚡'},
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
      'desc': 'Dispute os prêmios acumulados no app!',
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
      'desc': 'Novas pistas liberadas para desvendar!',
      'tag': 'NOVIDADE',
      'tagIcon': 'fire',
      'btn': 'JOGAR AGORA',
      'bgIcon': 'gamepad',
      'start': '#005861',
      'end': '#007D8A',
    },
    {
      'label': '🎁 Bônus',
      'title': 'Indique um Amigo',
      'desc': 'Ganhe saldo na carteira a cada indicação.',
      'tag': 'BÔNUS',
      'tagIcon': 'gift',
      'btn': 'RESGATAR',
      'bgIcon': 'gift',
      'start': '#3A1C71',
      'end': '#6A0572',
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestão de Banners',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showBannerDialog(context),
                icon: const FaIcon(FontAwesomeIcons.plus, size: 12),
                label: const Text('Novo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdeVale,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
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
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.image,
                        size: 48,
                        color: AppColors.cinzaMedio,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum banner cadastrado.',
                        style: GoogleFonts.poppins(
                          color: AppColors.cinzaMedio,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showBannerDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verdeVale,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Criar Banner'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  final isImage = banner.isImageOnly;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.verdeVale.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Mini Preview
                          Container(
                            width: 72,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: isImage ? null : banner.gradient,
                              color: isImage ? AppColors.darkBackground : null,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: isImage && banner.imageUrl.isNotEmpty
                                  ? Image.network(
                                      banner.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Center(
                                        child: FaIcon(
                                          FontAwesomeIcons.image,
                                          color: Colors.white38,
                                          size: 16,
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
                                        size: 18,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  banner.title.isNotEmpty
                                      ? banner.title
                                      : (banner.tagText.isNotEmpty
                                          ? banner.tagText
                                          : 'Banner de Imagem'),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ordem: ${banner.order} · ${banner.isActive ? "Ativo" : "Inativo"}'
                                  ' · ${isImage ? "Imagem" : "Card"}',
                                  style: GoogleFonts.inter(
                                    color: banner.isActive
                                        ? AppColors.amareloVale
                                        : AppColors.cinzaMedio,
                                    fontSize: 11,
                                  ),
                                ),
                                if (banner.actionUrl.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    banner.actionUrl,
                                    style: GoogleFonts.inter(
                                      color: Colors.blueAccent,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Action Buttons
                          IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.penToSquare,
                              color: AppColors.verdeVale,
                              size: 16,
                            ),
                            onPressed: () => _showBannerDialog(
                              context,
                              banner: banner,
                            ),
                          ),
                          IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.trash,
                              color: AppColors.danger,
                              size: 16,
                            ),
                            onPressed: () => _confirmDeleteBanner(banner),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showBannerDialog(BuildContext context, {BannerModel? banner}) {
    final titleCtrl = TextEditingController(text: banner?.title ?? '');
    final imageUrlCtrl = TextEditingController(text: banner?.imageUrl ?? '');
    final actionUrlCtrl = TextEditingController(text: banner?.actionUrl ?? '');
    final tagTextCtrl = TextEditingController(text: banner?.tagText ?? '');
    final descCtrl = TextEditingController(text: banner?.description ?? '');
    final buttonTextCtrl = TextEditingController(text: banner?.buttonText ?? '');
    final orderCtrl = TextEditingController(
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final previewBanner = BannerModel(
              id: banner?.id ?? 'preview',
              title: titleCtrl.text,
              description: descCtrl.text,
              imageUrl: imageUrlCtrl.text,
              actionUrl: actionUrlCtrl.text,
              tagText: tagTextCtrl.text,
              tagIcon: selectedTagIcon,
              buttonText: buttonTextCtrl.text,
              bgIcon: selectedBgIcon,
              order: int.tryParse(orderCtrl.text) ?? 1,
              isActive: isActive,
              bannerType: bannerType,
              gradientStartHex: startHex,
              gradientEndHex: endHex,
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            banner == null ? 'Novo Banner' : 'Editar Banner',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Live Client Preview Card
                      Text(
                        'PRÉVIA NO APP DO CLIENTE',
                        style: GoogleFonts.inter(
                          color: AppColors.amareloVale,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      BannerCardWidget(
                        banner: previewBanner,
                        height: 145.0,
                        showShadow: true,
                        margin: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),

                      // Banner Type Selector
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeButton(
                              icon: FontAwesomeIcons.paintbrush,
                              label: 'Card Estilizado',
                              isSelected: bannerType == 'card',
                              onTap: () => setModalState(() => bannerType = 'card'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTypeButton(
                              icon: FontAwesomeIcons.image,
                              label: 'Arte Gráfica',
                              isSelected: bannerType == 'image',
                              onTap: () => setModalState(() => bannerType = 'image'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Quick Templates
                      Text(
                        'Modelos Prontos:',
                        style: GoogleFonts.inter(
                          color: AppColors.cinzaMedio,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _presetTemplates.map((tpl) {
                          return ActionChip(
                            backgroundColor: AppColors.darkCardColor,
                            label: Text(
                              tpl['label'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                            onPressed: () {
                              setModalState(() {
                                titleCtrl.text = tpl['title'] ?? '';
                                descCtrl.text = tpl['desc'] ?? '';
                                tagTextCtrl.text = tpl['tag'] ?? '';
                                buttonTextCtrl.text = tpl['btn'] ?? '';
                                selectedTagIcon = tpl['tagIcon'] ?? 'trophy';
                                selectedBgIcon = tpl['bgIcon'] ?? 'trophy';
                                startHex = tpl['start'] ?? '#005861';
                                endHex = tpl['end'] ?? '#007D8A';
                                bannerType = 'card';
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      if (bannerType == 'card') ...[
                        // Title
                        _buildInputField(
                          controller: titleCtrl,
                          label: 'Título',
                          onChanged: (_) => setModalState(() {}),
                        ),
                        const SizedBox(height: 10),

                        // Description
                        _buildInputField(
                          controller: descCtrl,
                          label: 'Descrição',
                          maxLines: 2,
                          onChanged: (_) => setModalState(() {}),
                        ),
                        const SizedBox(height: 10),

                        // Tag & Icon
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildInputField(
                                controller: tagTextCtrl,
                                label: 'Texto da Tag',
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _buildIconDropdown(
                                label: 'Ícone Tag',
                                value: selectedTagIcon,
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => selectedTagIcon = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Button & Bg Icon
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildInputField(
                                controller: buttonTextCtrl,
                                label: 'Texto do Botão',
                                onChanged: (_) => setModalState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _buildIconDropdown(
                                label: 'Ícone Fundo',
                                value: selectedBgIcon,
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => selectedBgIcon = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Gradients
                        Text(
                          'Cores do Gradiente:',
                          style: GoogleFonts.inter(
                            color: AppColors.cinzaMedio,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _presetGradients.map((g) {
                            final isCur = startHex == g['start'] && endHex == g['end'];
                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  startHex = g['start'] as String;
                                  endHex = g['end'] as String;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.darkCardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isCur
                                        ? AppColors.amareloVale
                                        : Colors.white24,
                                    width: isCur ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
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
                                    const SizedBox(width: 4),
                                    Text(
                                      g['name'] as String,
                                      style: TextStyle(
                                        color: isCur ? Colors.white : Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Image Upload/URL Field
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: imageUrlCtrl,
                              label: bannerType == 'image'
                                  ? 'URL da Arte / Flyer'
                                  : 'Ilustração Opcional (URL)',
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: ElevatedButton(
                              onPressed: isUploadingImage
                                  ? null
                                  : () async {
                                      setModalState(() => isUploadingImage = true);
                                      final url =
                                          await AdminUploadUtil.pickAndUploadImage(
                                        context,
                                      );
                                      setModalState(() {
                                        isUploadingImage = false;
                                        if (url != null) {
                                          imageUrlCtrl.text = url;
                                        }
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.verdeVale,
                                foregroundColor: Colors.white,
                              ),
                              child: isUploadingImage
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Upload'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Action URL
                      _buildInputField(
                        controller: actionUrlCtrl,
                        label: 'Link de Ação ao Clicar (actionUrl)',
                        onChanged: (_) => setModalState(() {}),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          ActionChip(
                            label: const Text('Carteira', style: TextStyle(fontSize: 10)),
                            onPressed: () {
                              actionUrlCtrl.text = 'screen:wallet';
                              setModalState(() {});
                            },
                          ),
                          ActionChip(
                            label: const Text('Ranking', style: TextStyle(fontSize: 10)),
                            onPressed: () {
                              actionUrlCtrl.text = 'screen:ranking';
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Order & Active
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: orderCtrl,
                              label: 'Ordem',
                              isNumeric: true,
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Ativo',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              value: isActive,
                              activeThumbColor: AppColors.verdeVale,
                              onChanged: (val) => setModalState(() => isActive = val),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final title = titleCtrl.text.trim();
                                  final img = imageUrlCtrl.text.trim();

                                  if (bannerType == 'card' && title.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Informe o título do banner'),
                                      ),
                                    );
                                    return;
                                  }

                                  if (bannerType == 'image' && img.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Informe ou envie uma imagem'),
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() => isSaving = true);

                                  final newData = {
                                    'title': title,
                                    'imageUrl': img,
                                    'actionUrl': actionUrlCtrl.text.trim(),
                                    'tagText': tagTextCtrl.text.trim(),
                                    'tagIcon': selectedTagIcon,
                                    'description': descCtrl.text.trim(),
                                    'buttonText': buttonTextCtrl.text.trim(),
                                    'bgIcon': selectedBgIcon,
                                    'order': int.tryParse(orderCtrl.text.trim()) ?? 1,
                                    'isActive': isActive,
                                    'active': isActive, // Double write for dual compatibility
                                    'bannerType': bannerType,
                                    'gradientStartHex': startHex,
                                    'gradientEndHex': endHex,
                                    'colorHex': startHex,
                                  };

                                  final Map<String, dynamic> params = {'data': newData};
                                  if (banner != null && banner.id.isNotEmpty) {
                                    params['bannerId'] = banner.id;
                                  }

                                  try {
                                    await ParseCloudFunction('createOrUpdateBanner')
                                        .execute(parameters: params);

                                    if (bottomSheetCtx.mounted) {
                                      Navigator.pop(bottomSheetCtx);
                                    }
                                    _loadBanners();
                                  } catch (e) {
                                    setModalState(() => isSaving = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Erro: $e')),
                                      );
                                    }
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const FaIcon(FontAwesomeIcons.floppyDisk, size: 14),
                          label: Text(isSaving ? 'Salvando...' : 'Salvar Banner'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.verdeVale,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeButton({
    required dynamic icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.verdeVale.withValues(alpha: 0.25)
              : AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.verdeVale : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              size: 13,
              color: isSelected ? AppColors.amareloVale : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.darkCardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _availableIcons.any((i) => i['id'] == value) ? value : '',
              dropdownColor: AppColors.darkCardColor,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              isExpanded: true,
              items: _availableIcons.map((i) {
                return DropdownMenuItem<String>(
                  value: i['id'] as String,
                  child: Text(
                    i['name'] as String,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool isNumeric = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 11),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.darkCardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.verdeVale),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteBanner(BannerModel banner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCardColor,
        title: const Text(
          'Confirmar exclusão',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja excluir o banner "${banner.title.isNotEmpty ? banner.title : 'selecionado'}"?',
          style: const TextStyle(color: AppColors.cinzaMedio),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ParseCloudFunction('deleteBanner').execute(
                  parameters: {'bannerId': banner.id},
                );
                _loadBanners();
              } catch (e) {
                debugPrint('Erro ao excluir: $e');
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
