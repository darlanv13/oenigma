import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/painel_admin/core/utils/app_colors.dart';
import 'package:oenigma/painel_admin/core/widgets/admin_item_card.dart';
import 'package:oenigma/painel_admin/core/widgets/admin_modal.dart';

class AdminEnigmasScreen extends StatefulWidget {
  const AdminEnigmasScreen({super.key});

  @override
  State<AdminEnigmasScreen> createState() => _AdminEnigmasScreenState();
}

class _AdminEnigmasScreenState extends State<AdminEnigmasScreen> {
  late Future<List<ParseObject>> _enigmasFuture;
  List<ParseObject> _events = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    // Load events for the dropdown
    final eventsQuery = QueryBuilder<ParseObject>(ParseObject('Event'))..orderByDescending('createdAt');
    final eventsRes = await eventsQuery.query();
    if (eventsRes.success && eventsRes.results != null) {
      _events = eventsRes.results as List<ParseObject>;
    }

    setState(() {
      final query = QueryBuilder<ParseObject>(ParseObject('Enigma'))
        ..orderByDescending('createdAt')
        ..includeObject(['event']);
      _enigmasFuture = query.query().then((response) {
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
        _buildSectionTitle('Todos os Enigmas', FontAwesomeIcons.puzzlePiece),
        Expanded(
          child: FutureBuilder<List<ParseObject>>(
            future: _enigmasFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryAmber));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }

              final enigmas = snapshot.data ?? [];
              if (enigmas.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                itemCount: enigmas.length,
                itemBuilder: (context, index) {
                  final enigma = enigmas[index];
                  return _buildEnigmaCard(enigma);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildAddButton('Novo Enigma', () => _showAddEnigmaModal(context)),
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
      title: 'Nenhum enigma cadastrado',
      statusText: '',
      statusColor: Colors.transparent,
      subtitle: 'Crie enigmas dentro dos eventos.',
    );
  }

  Widget _buildEnigmaCard(ParseObject enigma) {
    final status = enigma.get<String>('status') ?? 'bloqueado';
    Color statusColor;
    String statusLabel;

    if (status == 'concluido' || status == 'closed') {
      statusColor = primaryAmber;
      statusLabel = 'Concluído';
    } else if (status == 'disponivel' || status == 'open') {
      statusColor = successColor;
      statusLabel = 'Disponível';
    } else {
      statusColor = secondaryTextColor;
      statusLabel = 'Bloqueado';
    }

    final tipo = enigma.get<String>('type') ?? 'charada';
    dynamic tipoIcon;
    if (tipo == 'charada' || tipo == 'text') {
      tipoIcon = FontAwesomeIcons.pencil;
    } else if (tipo == 'gps') {
      tipoIcon = FontAwesomeIcons.locationDot;
    } else {
      tipoIcon = FontAwesomeIcons.camera;
    }

    final eventObj = enigma.get<ParseObject>('event');
    final eventName = eventObj?.get<String>('title') ?? eventObj?.get<String>('name') ?? 'Evento Desconhecido';
    final dif = enigma.get<String>('difficulty') ?? 'Médio';
    final prize = enigma.get<String>('prize') ?? 'R\$ 0,00';

    return AdminItemCard(
      icon: tipoIcon,
      title: enigma.get<String>('instruction') ?? enigma.get<String>('name') ?? 'Sem Nome',
      statusText: statusLabel,
      statusColor: statusColor,
      subtitle: 'Evento: $eventName · Tipo: $tipo · Dificuldade: $dif · Prêmio: $prize',
      actions: [
        _buildButton('Gerenciar', isWarning: true, onTap: () => _showManageEnigmaModal(context, enigma)),
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

  Widget _buildButton(String text, {bool isPrimary = false, bool isDanger = false, bool isWarning = false, required VoidCallback onTap}) {
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
    } else if (isWarning) {
      textColorStr = warningColor;
      borderColor = warningColor.withValues(alpha: 0.3);
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

  void _showAddEnigmaModal(BuildContext context) {
    if (_events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crie um evento primeiro.')));
      return;
    }

    final nomeController = TextEditingController();
    final premioController = TextEditingController();
    String tipo = 'text';
    String dificuldade = 'Médio';
    String eventId = _events.first.objectId!;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AdminModal(
              title: 'Criar Novo Enigma',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildInputForm(controller: nomeController, hint: 'Nome/Instrução')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectForm(
                          value: tipo,
                          items: const [
                            DropdownMenuItem(value: 'text', child: Text('Charada')),
                            DropdownMenuItem(value: 'gps', child: Text('GPS')),
                            DropdownMenuItem(value: 'qrcode', child: Text('QR Code')),
                          ],
                          onChanged: (val) { if (val != null) setModalState(() => tipo = val); },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectForm(
                          value: dificuldade,
                          items: const [
                            DropdownMenuItem(value: 'Fácil', child: Text('Fácil')),
                            DropdownMenuItem(value: 'Médio', child: Text('Médio')),
                            DropdownMenuItem(value: 'Difícil', child: Text('Difícil')),
                            DropdownMenuItem(value: 'Lendário', child: Text('Lendário')),
                          ],
                          onChanged: (val) { if (val != null) setModalState(() => dificuldade = val); },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInputForm(controller: premioController, hint: 'Prêmio (R\$)')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Vincular ao Evento:', style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 12)),
                  const SizedBox(height: 4),
                  _buildSelectForm(
                    value: eventId,
                    items: _events.map((e) => DropdownMenuItem(value: e.objectId!, child: Text(e.get<String>('title') ?? e.get<String>('name') ?? ''))).toList(),
                    onChanged: (val) { if (val != null) setModalState(() => eventId = val); },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildButton('Cancelar', onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      _buildButton('Criar Enigma', isPrimary: true, onTap: () async {
                        await ParseCloudFunction('createOrUpdateEnigma').execute(
                          parameters: {
                            'eventId': eventId,
                            'data': {
                              'instruction': nomeController.text.trim(), // Assuming name maps to instruction
                              'type': tipo,
                              'difficulty': dificuldade,
                              'prize': premioController.text.trim(),
                              'status': 'open',
                            }
                          }
                        );
                        if (context.mounted) Navigator.of(context).pop();
                        _loadData();
                      }),
                    ],
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }



  void _showManageEnigmaModal(BuildContext context, ParseObject enigma) {
    Map<String, dynamic> tools = {};
    try {
      if (enigma.get<Map<String, dynamic>>('tools') != null) {
        tools = Map<String, dynamic>.from(enigma.get<Map<String, dynamic>>('tools')!);
      }
    } catch (_) {}

    bool hasRadar = tools['hasRadar'] ?? false;
    bool hasMap = tools['hasMap'] ?? false;
    bool hasScanner = tools['hasCompass'] ?? false; // Scanner maps to Compass
    double radarPrice = (tools['radarPrice'] as num?)?.toDouble() ?? 2.99;
    double mapPrice = (tools['mapPrice'] as num?)?.toDouble() ?? 4.99;
    double scannerPrice = (tools['compassPrice'] as num?)?.toDouble() ?? 1.99;

    showDialog(

      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AdminModal(
              title: 'Gerenciar: ${enigma.get<String>('instruction') ?? ''}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Ferramentas', FontAwesomeIcons.toolbox),
                  _buildToolToggle('Radar', 'Mostra QR codes num raio de 500m', hasRadar, radarPrice, (val) => setModalState(() => hasRadar = val), (val) => radarPrice = val),
                  _buildToolToggle('Maps', 'Caminho otimizado entre enigmas', hasMap, mapPrice, (val) => setModalState(() => hasMap = val), (val) => mapPrice = val),
                  _buildToolToggle('Scanner+', 'Lê QR codes à distância (100m)', hasScanner, scannerPrice, (val) => setModalState(() => hasScanner = val), (val) => scannerPrice = val),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Dicas', FontAwesomeIcons.lightbulb),
                  FutureBuilder<ParseResponse>(
                    future: (QueryBuilder<ParseObject>(ParseObject('Hint'))..whereEqualTo('linkedEnigmaId', enigma.objectId)).query(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
                      }
                      final hints = snapshot.data?.results as List<ParseObject>? ?? [];
                      if (hints.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Nenhuma dica cadastrada.', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                        );
                      }
                      return Column(
                        children: hints.map((hint) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: primaryAmber.withValues(alpha: 0.04)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(hint.get<String>('description') ?? hint.get<String>('title') ?? 'Sem texto', style: GoogleFonts.inter(color: primaryAmberLight, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text('Preço: R\$ ${hint.get<num>('price') ?? '0.00'}', style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 10)),
                                    ],
                                  ),
                                ),
                                _buildButton('Remover', isDanger: true, onTap: () async {
                                  await hint.delete();
                                  setModalState((){});
                                }),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      _showAddHintModal(context, enigma, () => setModalState((){}));
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: primaryAmber.withValues(alpha: 0.15), style: BorderStyle.solid), // Replacing dashed with solid for simplicity here
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(FontAwesomeIcons.circlePlus, color: primaryAmber, size: 14),
                          const SizedBox(width: 8),
                          Text('Adicionar Dica', style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildButton('Fechar', onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),

                      _buildButton('Salvar', isPrimary: true, onTap: () async {
                         final tools = {
                           'hasRadar': hasRadar,
                           'hasMap': hasMap,
                           'hasCompass': hasScanner,
                           'radarPrice': radarPrice,
                           'mapPrice': mapPrice,
                           'compassPrice': scannerPrice,
                         };
                         
                         await ParseCloudFunction('createOrUpdateEnigma').execute(
                            parameters: {
                               'eventId': enigma.get<String>('eventId') ?? '',
                               'data': {
                                  'enigmaId': enigma.objectId,
                                  'tools': tools,
                               }
                            }
                         );

                         if (context.mounted) Navigator.of(context).pop();
                         _loadData();
                      }),

                    ],
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showAddHintModal(BuildContext context, ParseObject enigma, VoidCallback onSuccess) {
    final textController = TextEditingController();
    final priceController = TextEditingController(text: '0.50');
    
    showDialog(
      context: context,
      builder: (context) {
        return AdminModal(
          title: 'Adicionar Dica',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _buildInputForm(controller: textController, hint: 'Escreva a dica...'),
               const SizedBox(height: 12),
               _buildInputForm(controller: priceController, hint: 'Preço (ex: 0.50)'),
               const SizedBox(height: 20),
               Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                    _buildButton('Cancelar', onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 12),
                    _buildButton('Salvar Dica', isPrimary: true, onTap: () async {
                       await ParseCloudFunction('createOrUpdateHint').execute(
                          parameters: {
                             'data': {
                                'description': textController.text.trim(),
                                'price': num.tryParse(priceController.text.trim()) ?? 0.0,
                                'linkedEnigmaId': enigma.objectId,
                             }
                          }
                       );
                       if (context.mounted) Navigator.of(context).pop();
                       onSuccess();
                    }),
                 ]
               )
            ]
          )
        );
      }
    );
  }

  Widget _buildToolToggle(String name, String desc, bool value, double price, ValueChanged<bool> onChanged, ValueChanged<double> onPriceChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryAmber.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(color: primaryAmberLight, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(desc, style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 10)),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: TextEditingController(text: price.toStringAsFixed(2)),
              onChanged: (val) => onPriceChanged(double.tryParse(val) ?? 0.0),
              style: GoogleFonts.orbitron(color: primaryAmberLight, fontSize: 10),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                filled: true,
                fillColor: cardColor.withValues(alpha: 0.8),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: primaryAmber.withValues(alpha: 0.15))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: primaryAmber)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: darkBackground,
            activeTrackColor: primaryAmber,
            inactiveTrackColor: const Color(0xFF3A3A3A),
            inactiveThumbColor: const Color(0xFF1A1A1A),
          ),
        ],
      ),
    );
  }
  Widget _buildInputForm({required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
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
