import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';


import 'package:oenigma/painel_admin/core/utils/app_colors.dart';
import 'package:oenigma/painel_admin/core/widgets/admin_item_card.dart';
import 'package:oenigma/painel_admin/core/widgets/admin_modal.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  late Future<List<ParseObject>> _bannersFuture;

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
          return response.results as List<ParseObject>;
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
        _buildSectionTitle('Gerenciar Banners', FontAwesomeIcons.image),
        Expanded(
          child: FutureBuilder<List<ParseObject>>(
            future: _bannersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryAmber));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }

              final banners = snapshot.data ?? [];
              if (banners.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  return _buildBannerCard(banner);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildAddButton('Novo Banner', () => _showAddEditBannerModal(context)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, dynamic icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          FaIcon(icon, color: primaryAmber, size: 14),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.orbitron(
              color: primaryAmber,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryAmber.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const AdminItemCard(
      icon: FontAwesomeIcons.circleInfo,
      title: 'Nenhum banner',
      statusText: '',
      statusColor: Colors.transparent,
      subtitle: 'Crie banners promocionais para o app.',
    );
  }

  Widget _buildBannerCard(ParseObject banner) {
    final ativo = banner.get<bool>('active') ?? true;
    final statusColor = ativo ? successColor : secondaryTextColor;
    final statusLabel = ativo ? 'Ativo' : 'Inativo';
    final ordem = banner.get<int>('order') ?? 0;

    return AdminItemCard(
      icon: FontAwesomeIcons.image,
      title: banner.get<String>('title') ?? 'Sem Título',
      statusText: statusLabel,
      statusColor: statusColor,
      subtitle: '${banner.get<String>('description') ?? ''} · Ordem: $ordem',
      actions: [
        _buildButton('Editar', isPrimary: true, onTap: () => _showAddEditBannerModal(context, banner: banner)),
        const SizedBox(width: 8),
        _buildButton(ativo ? 'Desativar' : 'Ativar', isDanger: ativo, isSuccess: !ativo, onTap: () => _toggleBannerStatus(banner, !ativo)),
        const SizedBox(width: 8),
        _buildButton('Excluir', isDanger: true, onTap: () => _deleteBanner(banner)),
      ],
    );
  }

  Widget _buildAddButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: primaryAmber.withValues(alpha: 0.15), width: 1.5, style: BorderStyle.none),
          borderRadius: BorderRadius.circular(16),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.circlePlus, color: primaryAmber, size: 14),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, {bool isPrimary = false, bool isDanger = false, bool isSuccess = false, required VoidCallback onTap}) {
    Color bgColor = Colors.transparent;
    Color textColorStr = primaryAmberHover;
    Color borderColor = primaryAmber.withValues(alpha: 0.15);

    if (isPrimary) {
      bgColor = primaryAmber;
      textColorStr = darkBackground;
      borderColor = Colors.transparent;
    } else if (isDanger) {
      textColorStr = dangerColor;
      borderColor = dangerColor.withValues(alpha: 0.3);
    } else if (isSuccess) {
      textColorStr = successColor;
      borderColor = successColor.withValues(alpha: 0.3);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(30), border: Border.all(color: borderColor)),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.inter(color: textColorStr, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
    );
  }

  void _showAddEditBannerModal(BuildContext context, {ParseObject? banner}) {
    final titleController = TextEditingController(text: banner?.get<String>('title') ?? '');
    final descController = TextEditingController(text: banner?.get<String>('description') ?? '');
    final orderController = TextEditingController(text: (banner?.get<int>('order') ?? 1).toString());

    String status = (banner?.get<bool>('active') ?? true) ? 'true' : 'false';
    Color bgColor = _parseColor(banner?.get<String>('colorHex') ?? '#C0A060');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AdminModal(
              title: banner == null ? 'Criar Novo Banner' : 'Editar Banner',
              maxWidth: 850,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Dados', FontAwesomeIcons.penToSquare),
                            _buildInputForm(
                              controller: titleController,
                              hint: 'Título',
                              onChanged: (_) => setModalState((){})
                            ),
                            const SizedBox(height: 14),
                            _buildInputForm(
                              controller: descController,
                              hint: 'Descrição',
                              maxLines: 3,
                              onChanged: (_) => setModalState((){})
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: _buildInputForm(controller: orderController, hint: 'Ordem', isNumeric: true)
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSelectForm(
                                    value: status,
                                    items: const [
                                      DropdownMenuItem(value: 'true', child: Text('Ativo')),
                                      DropdownMenuItem(value: 'false', child: Text('Inativo')),
                                    ],
                                    onChanged: (val) { if (val != null) setModalState(() => status = val); },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    _showColorPicker(context, bgColor, (color) {
                                      setModalState(() => bgColor = color);
                                    });
                                  },
                                  child: Container(
                                    width: 60,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: primaryAmber.withValues(alpha: 0.15)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('Cor de fundo', style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 30),
                      // Preview Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Preview', FontAwesomeIcons.mobileScreenButton),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [bgColor, const Color(0xFF1A1C23)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryAmber.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titleController.text.isEmpty ? 'Mega Prêmio' : titleController.text,
                                    style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0,2), blurRadius: 10)]
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    descController.text.isEmpty ? 'R\$ 50.000,00 acumulado' : descController.text,
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Saiba Mais', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 4),
                                        const FaIcon(FontAwesomeIcons.arrowRight, color: Colors.white, size: 12),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryAmber.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: primaryAmber.withValues(alpha: 0.2), style: BorderStyle.none),
                              ),
                              child: CustomPaint(
                                painter: _DashedBorderPainter(),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const FaIcon(FontAwesomeIcons.circleInfo, color: Color(0xFF8A7A5A), size: 12),
                                      const SizedBox(width: 8),
                                      Text('Visualização aproximada do card no app.', style: GoogleFonts.inter(color: const Color(0xFF8A7A5A), fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: primaryAmber.withValues(alpha: 0.1)))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildButton('Cancelar', onTap: () => Navigator.of(context).pop()),
                        const SizedBox(width: 12),
                        _buildButton('Salvar Banner', isPrimary: true, onTap: () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          final hexColor = '#${bgColor.value.toRadixString(16).substring(2, 8).toUpperCase()}';

                          Map<String, dynamic> params = {
                            'data': {
                              'title': title,
                              'description': descController.text.trim(),
                              'order': int.tryParse(orderController.text) ?? 1,
                              'active': status == 'true',
                              'colorHex': hexColor,
                            }
                          };

                          if (banner != null) {
                            params['bannerId'] = banner.objectId;
                          }

                          await ParseCloudFunction('createOrUpdateBanner').execute(parameters: params);

                          if (context.mounted) Navigator.of(context).pop();
                          _loadBanners();
                        }),
                      ],
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showColorPicker(BuildContext context, Color currentColor, ValueChanged<Color> onColorChanged) {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = currentColor;
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Selecione uma cor', style: TextStyle(color: textColor)),
          content: SingleChildScrollView(
            child: Text('Note: Color picker is not available right now. We will use the selected color.')
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: secondaryTextColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Selecionar', style: TextStyle(color: primaryAmber)),
              onPressed: () {
                onColorChanged(tempColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleBannerStatus(ParseObject banner, bool isActive) async {
    await ParseCloudFunction('createOrUpdateBanner').execute(
      parameters: {
        'bannerId': banner.objectId,
        'data': {
          'active': isActive,
        }
      }
    );
    _loadBanners();
  }

  Future<void> _deleteBanner(ParseObject banner) async {
    await ParseCloudFunction('deleteBanner').execute(
      parameters: { 'bannerId': banner.objectId }
    );
    _loadBanners();
  }

  Widget _buildInputForm({required TextEditingController controller, required String hint, int maxLines = 1, bool isNumeric = false, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
      style: GoogleFonts.inter(color: primaryAmberLight, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: secondaryTextColor.withValues(alpha: 0.5)),
        filled: true,
        fillColor: cardColor.withValues(alpha: 0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryAmber.withValues(alpha: 0.15))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryAmber)),
      ),
    );
  }

  Widget _buildSelectForm({required String value, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: cardColor.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryAmber.withValues(alpha: 0.15))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: sidebarBackground,
          style: GoogleFonts.inter(color: primaryAmberLight, fontSize: 15),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryAmber.withValues(alpha: 0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 5.0;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width, startY), Offset(size.width, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
    startX = size.width;
    while (startX > 0) {
      canvas.drawLine(Offset(startX, size.height), Offset(startX - dashWidth, size.height), paint);
      startX -= dashWidth + dashSpace;
    }
    startY = size.height;
    while (startY > 0) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY - dashWidth), paint);
      startY -= dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
