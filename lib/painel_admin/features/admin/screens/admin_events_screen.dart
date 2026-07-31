import 'package:oenigma/painel_admin/core/utils/app_colors.dart';
import 'package:oenigma/painel_admin/core/widgets/admin_item_card.dart';
import 'package:oenigma/painel_admin/core/widgets/admin_modal.dart';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';




class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  late Future<List<ParseObject>> _eventsFuture;

  // Added method to fetch enigmas for a specific event
  Future<List<ParseObject>> _fetchEventEnigmas(String eventId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Enigma'))
      ..whereEqualTo('eventId', eventId)
      ..orderByAscending('order');
    final response = await query.query();
    if (response.success && response.results != null) {
      return response.results as List<ParseObject>;
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      final query = QueryBuilder<ParseObject>(ParseObject('Event'))
        ..orderByDescending('createdAt');
      _eventsFuture = query.query().then((response) {
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
        _buildSectionTitle('Eventos', FontAwesomeIcons.calendar),
        Expanded(
          child: FutureBuilder<List<ParseObject>>(
            future: _eventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryAmber));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }

              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildEventCard(event);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildAddButton('Novo Evento', () => _showAddEventModal(context)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, dynamic icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          FaIcon(
            icon,
            color: primaryAmber,
            size: 14,
          ),
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
                  colors: [
                    primaryAmber.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AdminItemCard(
      icon: FontAwesomeIcons.circleInfo,
      title: 'Nenhum evento criado',
      statusText: '',
      statusColor: Colors.transparent,
      subtitle: 'Clique em "Novo Evento" para começar.',
    );
  }

  Widget _buildEventCard(ParseObject event) {
    final status = event.get<String>('status') ?? 'encerrado';
    Color statusColor;
    String statusLabel;

    if (status == 'open' || status == 'ativo') {
      statusColor = successColor;
      statusLabel = 'Ativo';
    } else if (status == 'em_breve') {
      statusColor = warningColor;
      statusLabel = 'Em breve';
    } else {
      statusColor = dangerColor;
      statusLabel = 'Encerrado';
    }

    final prize = event.get<num>('prizePool') != null
                  ? 'R\$ ${event.get<num>('prizePool')}'
                  : (event.get<String>('prize') ?? 'R\$ 0,00');

    return AdminItemCard(
      icon: FontAwesomeIcons.trophy,
      title: event.get<String>('title') ?? event.get<String>('name') ?? 'Sem Título',
      statusText: statusLabel,
      statusColor: statusColor,
      subtitle: '$prize',
      actions: [
        _buildButton('Editar', isPrimary: true, onTap: () => _showEditEventModal(context, event)),
        const SizedBox(width: 8),
        _buildButton('Excluir', isDanger: true, onTap: () => _deleteEvent(event)),
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
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, {bool isPrimary = false, bool isDanger = false, required VoidCallback onTap}) {
    Color bgColor = Colors.transparent;
    Color textColorStr = primaryAmberHover;
    Color borderColor = primaryAmber.withValues(alpha: 0.15);

    if (isPrimary) {
      bgColor = primaryAmber; // using linear gradient ideally, but solid for simplicity
      textColorStr = darkBackground;
      borderColor = Colors.transparent;
    } else if (isDanger) {
      textColorStr = dangerColor;
      borderColor = dangerColor.withValues(alpha: 0.3);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.inter(
            color: textColorStr,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  void _showAddEventModal(BuildContext context) {
    final nomeController = TextEditingController();
    final premioController = TextEditingController();
    String status = 'open'; // Using 'open' to match the activeEvents query
    String type = 'find_and_win'; // Default eventType

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AdminModal(
              title: 'Criar Novo Evento',
              maxWidth: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildInputForm(controller: nomeController, hint: 'Nome do evento (Ex: Find Win Centro)'),
                  const SizedBox(height: 12),
                  _buildInputForm(controller: premioController, hint: 'Prêmio (Ex: R\$ 5.000,00)'),
                  const SizedBox(height: 12),
                  _buildSelectForm(
                    value: type,
                    items: const [
                      DropdownMenuItem(value: 'find_and_win', child: Text('Find & Win (Enigmas Diretos)')),
                      DropdownMenuItem(value: 'classic', child: Text('Classic (Fases)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => type = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSelectForm(
                    value: status,
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('Ativo')),
                      DropdownMenuItem(value: 'em_breve', child: Text('Em breve')),
                      DropdownMenuItem(value: 'encerrado', child: Text('Encerrado')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => status = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildButton('Cancelar', onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      _buildButton('Criar Evento', isPrimary: true, onTap: () async {
                        final nome = nomeController.text.trim();
                        if (nome.isEmpty) return;

                        await ParseCloudFunction('createOrUpdateEvent').execute(
                          parameters: {
                            'data': {
                              'title': nome,
                              'prizePool': num.tryParse(premioController.text.trim().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
                              'status': status,
                              'eventType': type,
                            }
                          }
                        );
                        if (context.mounted) Navigator.of(context).pop();
                        _loadEvents();
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

  void _showEditEventModal(BuildContext context, ParseObject event) {
    final nomeController = TextEditingController(text: event.get<String>('title') ?? event.get<String>('name'));
    final premioController = TextEditingController(text: event.get<num>('prizePool')?.toString() ?? event.get<String>('prize'));
    String status = event.get<String>('status') ?? 'encerrado';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AdminModal(
              title: 'Editar Evento',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildInputForm(controller: nomeController, hint: 'Nome'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputForm(controller: premioController, hint: 'Prêmio'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectForm(
                          value: status,
                          items: const [
                            DropdownMenuItem(value: 'open', child: Text('Ativo')),
                            DropdownMenuItem(value: 'em_breve', child: Text('Em breve')),
                            DropdownMenuItem(value: 'encerrado', child: Text('Encerrado')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => status = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Enigmas deste evento', FontAwesomeIcons.puzzlePiece),

                  // FutureBuilder to load Enigmas dynamically
                  FutureBuilder<List<ParseObject>>(
                    future: _fetchEventEnigmas(event.objectId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Center(child: CircularProgressIndicator(color: primaryAmber)),
                        );
                      }
                      final enigmas = snapshot.data ?? [];
                      if (enigmas.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Center(child: Text('Nenhum enigma neste evento.', style: TextStyle(color: secondaryTextColor))),
                        );
                      }

                      return Column(
                        children: enigmas.map((enig) {
                          final status = enig.get<String>('status') ?? 'bloqueado';
                          Color statusColor = secondaryTextColor;
                          String statusLabel = 'Bloqueado';

                          if (status == 'concluido' || status == 'closed') {
                            statusColor = primaryAmber;
                            statusLabel = 'Concluído';
                          } else if (status == 'disponivel' || status == 'open') {
                            statusColor = successColor;
                            statusLabel = 'Disponível';
                          }

                          final tipo = enig.get<String>('type') ?? 'charada';
                          dynamic tipoIcon = FontAwesomeIcons.pencil;
                          if (tipo == 'gps') tipoIcon = FontAwesomeIcons.locationDot;
                          else if (tipo == 'qrcode') tipoIcon = FontAwesomeIcons.camera;

                          return AdminItemCard(
                            icon: tipoIcon,
                            title: enig.get<String>('instruction') ?? enig.get<String>('name') ?? 'Sem Nome',
                            statusText: statusLabel,
                            statusColor: statusColor,
                            subtitle: 'Tipo: $tipo · Prêmio: ${enig.get<num>('prize') != null ? 'R\$ ${enig.get<num>('prize')}' : 'R\$ 0,00'}',
                          );
                        }).toList().cast<Widget>(),
                      );
                    }
                  ),
                  const SizedBox(height: 12),
                  _buildAddButton('Adicionar Enigma ao Evento', () {
                    // Logic to add enigma would go here
                  }),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildButton('Cancelar', onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      _buildButton('Salvar Evento', isPrimary: true, onTap: () async {
                        await ParseCloudFunction('createOrUpdateEvent').execute(
                          parameters: {
                            'eventId': event.objectId,
                            'data': {
                              'title': nomeController.text.trim(),
                              'prizePool': num.tryParse(premioController.text.trim().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
                              'status': status,
                            }
                          }
                        );
                        if (context.mounted) Navigator.of(context).pop();
                        _loadEvents();
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

  Future<void> _deleteEvent(ParseObject event) async {
    // Safe delete via cloud function or parse direct
     final response = await event.delete();
     if (response.success) {
       _loadEvents();
     }
  }

  Widget _buildInputForm({required TextEditingController controller, required String hint, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: primaryAmberLight, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: secondaryTextColor.withValues(alpha: 0.5)),
        filled: true,
        fillColor: cardColor.withValues(alpha: 0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryAmber.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryAmber),
        ),
      ),
    );
  }

  Widget _buildSelectForm({required String value, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryAmber.withValues(alpha: 0.15)),
      ),
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

    // Draw top
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
    // Draw right
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width, startY), Offset(size.width, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
    // Draw bottom
    startX = size.width;
    while (startX > 0) {
      canvas.drawLine(Offset(startX, size.height), Offset(startX - dashWidth, size.height), paint);
      startX -= dashWidth + dashSpace;
    }
    // Draw left
    startY = size.height;
    while (startY > 0) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY - dashWidth), paint);
      startY -= dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
