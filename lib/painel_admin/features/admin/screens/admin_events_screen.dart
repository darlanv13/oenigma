import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/painel_admin/core/utils/app_colors.dart';
import 'package:oenigma/painel_admin/core/widgets/admin_item_card.dart';
import 'package:oenigma/painel_admin/core/widgets/admin_modal.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  late Future<List<ParseObject>> _eventsFuture;

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
    return const AdminItemCard(
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

    final prize = event.get<dynamic>('prize')?.toString() ?? event.get<dynamic>('prizePool')?.toString() ?? 'R\$ 0,00';

    return AdminItemCard(
      icon: FontAwesomeIcons.trophy,
      title: event.get<String>('title') ?? event.get<String>('name') ?? 'Sem Nome',
      statusText: statusLabel,
      statusColor: statusColor,
      subtitle: '$prize',
      actions: [
        _buildButton('Publicar Enigmas', isPrimary: false, onTap: () => _publishAllEnigmas(context, event)),
        const SizedBox(width: 8),
        _buildButton('Exportar QRs', isPrimary: false, onTap: () => _exportQRs(context, event)),
        const SizedBox(width: 8),
        _buildButton('Editar', isPrimary: true, onTap: () => _showEditEventModal(context, event)),
        const SizedBox(width: 8),
        _buildButton('Duplicar', isPrimary: false, onTap: () => _duplicateEvent(context, event)),
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
    final descricaoController = TextEditingController();
    final localController = TextEditingController();
    String status = 'open'; // Using 'open' to match the activeEvents query
    String eventType = 'find_and_win';

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
                  _buildInputForm(controller: descricaoController, hint: 'Descrição', maxLines: 3),
                  const SizedBox(height: 12),
                  _buildInputForm(controller: localController, hint: 'Local do evento (Cidade)'),
                  const SizedBox(height: 12),
                  _buildInputForm(controller: premioController, hint: 'Prêmio (Ex: R\$ 5.000,00)'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectForm(
                          value: eventType,
                          items: const [
                            DropdownMenuItem(value: 'find_and_win', child: Text('Find Win')),
                            DropdownMenuItem(value: 'classic', child: Text('Classic')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => eventType = val);
                          },
                        ),
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
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildButton('Cancelar', onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      _buildButton('Criar Evento', isPrimary: true, onTap: () async {
                        final nome = nomeController.text.trim();
                        final local = localController.text.trim();
                        if (nome.isEmpty || local.isEmpty) return;

                        final resEvent = await ParseCloudFunction('createOrUpdateEvent').execute(
                          parameters: {
                            'data': {
                              'title': nome,
                              'description': descricaoController.text.trim(),
                              'location': local,
                              'prizePool': premioController.text.trim(),
                              'status': status,
                              'eventType': eventType,
                            }
                          }
                        );

                        if (resEvent.success && resEvent.result != null && eventType == 'classic') {
                          String newEventId = resEvent.result is ParseObject
                              ? (resEvent.result as ParseObject).objectId!
                              : (resEvent.result is Map ? resEvent.result['objectId'] : '');

                          if (newEventId.isNotEmpty) {
                            final futures = <Future>[];
                            for (int i = 1; i <= 3; i++) {
                              futures.add(ParseCloudFunction('createOrUpdatePhase').execute(
                                parameters: {
                                  'eventId': newEventId,
                                  'data': {
                                    'title': 'Fase $i',
                                    'order': i,
                                    'status': 'open',
                                  }
                                }
                              ));
                            }
                            await Future.wait(futures);
                          }
                        }
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
    final premioController = TextEditingController(text: event.get<dynamic>('prizePool')?.toString() ?? event.get<dynamic>('prize')?.toString());
    final descricaoController = TextEditingController(text: event.get<String>('description') ?? '');
    final localController = TextEditingController(text: event.get<String>('location') ?? '');
    String status = event.get<String>('status') ?? 'encerrado';
    String eventType = event.get<String>('eventType') ?? 'find_and_win';

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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildInputForm(controller: descricaoController, hint: 'Descrição', maxLines: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputForm(controller: localController, hint: 'Local do evento'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectForm(
                          value: eventType,
                          items: const [
                            DropdownMenuItem(value: 'find_and_win', child: Text('Find Win')),
                            DropdownMenuItem(value: 'classic', child: Text('Classic')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => eventType = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Enigmas deste evento', FontAwesomeIcons.puzzlePiece),
                  FutureBuilder<ParseResponse>(
                    future: (QueryBuilder<ParseObject>(ParseObject('Enigma'))..whereEqualTo('eventId', event.objectId)).query(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                      }
                      if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.success) {
                        return const Padding(padding: EdgeInsets.all(12), child: Text('Erro ao carregar enigmas.', style: TextStyle(color: secondaryTextColor)));
                      }
                      final enigmas = snapshot.data!.results as List<ParseObject>?;
                      if (enigmas == null || enigmas.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Center(child: Text('Nenhum enigma neste evento. Adicione um!', style: TextStyle(color: secondaryTextColor))),
                        );
                      }
                      // Ordenar localmente pelo campo order se existir
                      enigmas.sort((a, b) => (a.get<num>('order') ?? 0).compareTo(b.get<num>('order') ?? 0));

                      return SizedBox(
                        height: 300, // Limitar altura para o modal não explodir
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            canvasColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: ReorderableListView(
                            shrinkWrap: true,
                            buildDefaultDragHandles: false,
                            onReorder: (int oldIndex, int newIndex) async {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final ParseObject item = enigmas.removeAt(oldIndex);
                              enigmas.insert(newIndex, item);

                              // Update local state first to prevent UI snapback
                              for (int i = 0; i < enigmas.length; i++) {
                                enigmas[i].set('order', i + 1);
                              }
                              setModalState((){}); // Update UI instantly

                              final futures = <Future>[];
                              for (int i = 0; i < enigmas.length; i++) {
                                final e = enigmas[i];
                                futures.add(ParseCloudFunction('createOrUpdateEnigma').execute(
                                  parameters: {
                                    'enigmaId': e.objectId,
                                    'data': {'order': i + 1}
                                  }
                                ));
                              }
                              await Future.wait(futures);
                            },
                            children: enigmas.map((enigma) {
                              return Container(
                                key: ValueKey(enigma.objectId),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cardColor.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: primaryAmber.withValues(alpha: 0.04)),
                                ),
                                child: Row(
                                  children: [
                                    ReorderableDragStartListener(
                                      index: enigmas.indexOf(enigma),
                                      child: const MouseRegion(
                                        cursor: SystemMouseCursors.grab,
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 12),
                                          child: FaIcon(FontAwesomeIcons.gripVertical, color: secondaryTextColor, size: 16),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: primaryAmber.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: primaryAmber.withValues(alpha: 0.06)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          (enigma.get<num>('order') ?? 0).toString(),
                                          style: GoogleFonts.inter(color: primaryAmber, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            enigma.get<String>('instruction') ?? 'Sem nome',
                                            style: GoogleFonts.inter(color: primaryAmberLight, fontSize: 14, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tipo: ${enigma.get<String>('type')} · Prêmio: R\$ ${enigma.get<dynamic>('prize')}',
                                            style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildButton('Remover', isDanger: true, onTap: () async {
                                      // Cascade delete hints
                                      final hintsQuery = QueryBuilder<ParseObject>(ParseObject('Hint'))
                                        ..whereEqualTo('linkedEnigmaId', enigma.objectId);
                                      final hintsRes = await hintsQuery.query();
                                      if (hintsRes.success && hintsRes.results != null) {
                                        for (var h in hintsRes.results!) {
                                          await (h as ParseObject).delete();
                                        }
                                      }
                                      await enigma.delete();
                                      setModalState(() {});
                                    }),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vá para a tela de Enigmas para adicionar.')));
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: primaryAmber.withValues(alpha: 0.15), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(FontAwesomeIcons.circlePlus, color: primaryAmber, size: 14),
                          const SizedBox(width: 8),
                          Text('Adicionar Enigma ao Evento', style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
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
                              'description': descricaoController.text.trim(),
                              'location': localController.text.trim(),
                              'prizePool': premioController.text.trim(),
                              'status': status,
                              'eventType': eventType,
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

  Future<void> _exportQRs(BuildContext context, ParseObject event) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final query = QueryBuilder<ParseObject>(ParseObject('Enigma'))
        ..whereEqualTo('eventId', event.objectId);
      final response = await query.query();

      if (!response.success || response.results == null || response.results!.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum enigma encontrado para exportar.')));
        return;
      }

      final doc = pw.Document();
      final enigmas = response.results as List<ParseObject>;

      // Adicionando uma página por Enigma ou colocando múltiplos (Aqui 1 por página bem grande ou grid)
      // Vamos colocar em Grid
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(level: 0, child: pw.Text('QR Codes - ${event.get<String>("title") ?? "Evento"}')),
              pw.Wrap(
                spacing: 20,
                runSpacing: 20,
                children: enigmas.map((enigma) {
                  final code = enigma.get<String>('code') ?? '';
                  final name = enigma.get<String>('instruction') ?? 'Sem Nome';
                  if (code.isEmpty) return pw.SizedBox();

                  return pw.Container(
                    width: 150,
                    child: pw.Column(
                      children: [
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: code,
                          width: 120,
                          height: 120,
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(name, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(code, style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ];
          },
        ),
      );

      final bytes = await doc.save();

      // Save for Web
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'QRCodes_${event.get<String>("title") ?? "Evento"}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exportação concluída!')));
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
      }
    }
  }

  Future<void> _publishAllEnigmas(BuildContext context, ParseObject event) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final query = QueryBuilder<ParseObject>(ParseObject('Enigma'))
        ..whereEqualTo('eventId', event.objectId);
      final response = await query.query();

      if (!response.success || response.results == null || response.results!.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum enigma encontrado.')));
        return;
      }

      final enigmas = response.results as List<ParseObject>;
      final futures = <Future>[];

      for (var e in enigmas) {
        if (e.get<String>('status') != 'open') {
          futures.add(ParseCloudFunction('createOrUpdateEnigma').execute(
            parameters: {
              'enigmaId': e.objectId,
              'data': {'status': 'open'}
            }
          ));
        }
      }

      await Future.wait(futures);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enigmas publicados com sucesso!')));
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao publicar: $e')));
      }
    }
  }

  Future<void> _duplicateEvent(BuildContext context, ParseObject event) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Copy Event
      final resEvent = await ParseCloudFunction('createOrUpdateEvent').execute(
        parameters: {
          'data': {
            'title': '${event.get<String>("title") ?? "Evento"} (Cópia)',
            'description': event.get<String>('description') ?? '',
            'location': event.get<String>('location') ?? '',
            'prizePool': event.get<String>('prizePool') ?? '0',
            'status': 'em_breve', // Start as upcoming/disabled
            'eventType': event.get<String>('eventType') ?? 'find_and_win',
          }
        }
      );

      if (!resEvent.success || resEvent.result == null) {
        throw 'Falha ao duplicar o evento principal.';
      }

      final newEventId = resEvent.result is ParseObject
          ? (resEvent.result as ParseObject).objectId!
          : (resEvent.result is Map ? resEvent.result['objectId'] : '');

      if (newEventId.isEmpty) throw 'ID do novo evento inválido.';

      // 1.5 Copy Phases
      final queryPhases = QueryBuilder<ParseObject>(ParseObject('Phase'))..whereEqualTo('eventId', event.objectId);
      final phasesRes = await queryPhases.query();
      if (phasesRes.success && phasesRes.results != null) {
        final phaseFutures = <Future>[];
        for (var oldPhase in phasesRes.results!) {
          final p = oldPhase as ParseObject;
          phaseFutures.add(ParseCloudFunction('createOrUpdatePhase').execute(
            parameters: {
              'eventId': newEventId,
              'data': {
                'title': p.get<String>('title') ?? 'Fase',
                'order': p.get<num>('order')?.toInt() ?? 1,
                'status': 'bloqueado', // Copied phases start blocked
              }
            }
          ));
        }
        await Future.wait(phaseFutures);
      }

      // 2. Fetch and Copy Enigmas
      final queryEnigmas = QueryBuilder<ParseObject>(ParseObject('Enigma'))
        ..whereEqualTo('eventId', event.objectId);
      final enigmasRes = await queryEnigmas.query();

      if (enigmasRes.success && enigmasRes.results != null) {
        for (var oldEnigma in enigmasRes.results!) {
          final enigmaObj = oldEnigma as ParseObject;
          final generatedHash = '${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}${DateTime.now().microsecond.toString().padLeft(3, '0')}';

          final resNewEnigma = await ParseCloudFunction('createOrUpdateEnigma').execute(
            parameters: {
              'eventId': newEventId,
              'data': {
                'instruction': enigmaObj.get<String>('instruction'),
                'code': generatedHash,
                'order': enigmaObj.get<num>('order'),
                'type': enigmaObj.get<String>('type'),
                'difficulty': enigmaObj.get<String>('difficulty'),
                'prize': enigmaObj.get<dynamic>('prize')?.toString() ?? '0',
                'status': 'bloqueado', // Copy starts blocked
                'hasCompass': enigmaObj.get<bool>('hasCompass') ?? false,
                'compassCoords': enigmaObj.get<String>('compassCoords') ?? '',
                'compassPrice': enigmaObj.get<num>('compassPrice')?.toDouble() ?? 15.0,
                'compassDuration': enigmaObj.get<num>('compassDuration')?.toInt() ?? 0,
                'hasRadar': enigmaObj.get<bool>('hasRadar') ?? false,
                'hasMap': enigmaObj.get<bool>('hasMap') ?? false,
                'radarPrice': enigmaObj.get<num>('radarPrice')?.toDouble() ?? 2.99,
                'mapPrice': enigmaObj.get<num>('mapPrice')?.toDouble() ?? 4.99,
                'imageUrl': enigmaObj.get<String>('imageUrl') ?? '',
                'audioUrl': enigmaObj.get<String>('audioUrl') ?? '',
              }
            }
          );

          // 3. Copy Hints for each Enigma
          if (resNewEnigma.success && resNewEnigma.result != null) {
            String newEnigmaId = resNewEnigma.result is ParseObject ? (resNewEnigma.result as ParseObject).objectId! : (resNewEnigma.result is Map ? resNewEnigma.result['objectId'] : '');
            if (newEnigmaId.isNotEmpty) {
              final queryHints = QueryBuilder<ParseObject>(ParseObject('Hint'))..whereEqualTo('linkedEnigmaId', enigmaObj.objectId);
              final hintsRes = await queryHints.query();
              if (hintsRes.success && hintsRes.results != null) {
                final hintFutures = <Future>[];
                for (var oldHint in hintsRes.results!) {
                  final hintObj = oldHint as ParseObject;
                  hintFutures.add(ParseCloudFunction('createOrUpdateHint').execute(
                    parameters: {
                      'data': {
                        'description': hintObj.get<String>('description'),
                        'price': hintObj.get<num>('price')?.toDouble() ?? 0.0,
                        'linkedEnigmaId': newEnigmaId,
                        'type': hintObj.get<String>('type') ?? 'text',
                        'data': hintObj.get<String>('data') ?? '',
                      }
                    }
                  ));
                }
                await Future.wait(hintFutures);
              }
            }
          }
        }
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento duplicado com sucesso!')));
        _loadEvents();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao duplicar evento: $e')));
      }
    }
  }

  Future<void> _deleteEvent(ParseObject event) async {
    // Calling backend delete is not present in admin.js mock, using ParseObject.delete
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
