import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:oenigma/painel_admin/features/admin/utils/admin_upload_util.dart';

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
  String _selectedFilterType = 'Todos';
  String _selectedFilterEvent = 'Todos';

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildSectionTitle('Todos os Enigmas', FontAwesomeIcons.puzzlePiece)),
            _buildFilterDropdowns(),
          ],
        ),
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

              var enigmas = snapshot.data ?? [];

              if (_selectedFilterEvent != 'Todos') {
                enigmas = enigmas.where((e) => e.get<String>('eventId') == _selectedFilterEvent).toList();
              }
              if (_selectedFilterType != 'Todos') {
                enigmas = enigmas.where((e) => e.get<String>('type') == _selectedFilterType).toList();
              }

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

  Widget _buildFilterDropdowns() {
    return Row(
      children: [
        Container(
          width: 150,
          margin: const EdgeInsets.only(bottom: 14, right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: cardColor.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(8), border: Border.all(color: primaryAmber.withValues(alpha: 0.15))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilterEvent,
              dropdownColor: sidebarBackground,
              style: GoogleFonts.inter(color: primaryAmberLight, fontSize: 12),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: 'Todos', child: Text('Todos Eventos')),
                ..._events.map((e) => DropdownMenuItem(value: e.objectId!, child: Text(e.get<String>('title') ?? e.get<String>('name') ?? ''))),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedFilterEvent = val);
              },
            ),
          ),
        ),
        Container(
          width: 130,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: cardColor.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(8), border: Border.all(color: primaryAmber.withValues(alpha: 0.15))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilterType,
              dropdownColor: sidebarBackground,
              style: GoogleFonts.inter(color: primaryAmberLight, fontSize: 12),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Todos', child: Text('Todos Tipos')),
                DropdownMenuItem(value: 'text', child: Text('Texto')),
                DropdownMenuItem(value: 'photo', child: Text('Foto')),
                DropdownMenuItem(value: 'audio', child: Text('Áudio')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedFilterType = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, dynamic icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          FaIcon(icon as dynamic, color: primaryAmber, size: 14),
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
        _buildButton('Preview', isPrimary: false, onTap: () => _showPreviewModal(context, enigma)),
        const SizedBox(width: 8),
        _buildButton('Duplicar', isPrimary: false, onTap: () => _duplicateEnigma(context, enigma)),
        const SizedBox(width: 8),
        _buildButton('Gerenciar', isWarning: true, onTap: () => _showManageEnigmaModal(context, enigma)),
      ],
    );
  }

  void _showPreviewModal(BuildContext context, ParseObject enigma) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: 375, // Simulated mobile width
            height: 812, // Simulated mobile height
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  title: Text(enigma.get<String>('instruction') ?? 'Enigma', style: GoogleFonts.orbitron(fontSize: 16)),
                  leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(16)),
                        child: MarkdownBody(
                          data: enigma.get<String>('instruction') ?? 'Instrução vazia',
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.inter(color: Colors.white, fontSize: 16, height: 1.5),
                            strong: GoogleFonts.inter(color: primaryAmber, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (enigma.get<bool>('hasMap') == true)
                        _buildPreviewToolBtn(FontAwesomeIcons.mapLocationDot, 'Mapa', primaryAmber),
                      if (enigma.get<bool>('hasCompass') == true)
                        _buildPreviewToolBtn(FontAwesomeIcons.compass, 'Bússola', primaryAmber),
                      if (enigma.get<bool>('hasRadar') == true)
                        _buildPreviewToolBtn(FontAwesomeIcons.satelliteDish, 'Radar', primaryAmber),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: successColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () {},
                        child: Text('RESPONDER ENIGMA', style: GoogleFonts.orbitron(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildPreviewToolBtn(dynamic icon, String title, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.inter(color: color, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _duplicateEnigma
(BuildContext context, ParseObject enigma) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: primaryAmber)),
    );

    try {
      final String generatedHash = '${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}${DateTime.now().microsecond.toString().padLeft(3, '0')}';

      final queryOrder = QueryBuilder<ParseObject>(ParseObject('Enigma'))
        ..whereEqualTo('eventId', enigma.get<String>('eventId'))
        ..orderByDescending('order')
        ..setLimit(1);
      final resOrder = await queryOrder.query();
      int nextOrder = 1;
      if (resOrder.success && resOrder.results != null && resOrder.results!.isNotEmpty) {
        final lastEnigma = resOrder.results!.first as ParseObject;
        nextOrder = (lastEnigma.get<num>('order')?.toInt() ?? 0) + 1;
      }

      await ParseCloudFunction('createOrUpdateEnigma').execute(
        parameters: {
          'eventId': enigma.get<String>('eventId') ?? '',
          'data': {
            'instruction': '${enigma.get<String>("instruction") ?? "Enigma"} (Cópia)',
            'code': generatedHash,
            'order': nextOrder,
            'type': enigma.get<String>('type'),
            'difficulty': enigma.get<String>('difficulty'),
            'prize': enigma.get<dynamic>('prize')?.toString() ?? '0',
            'status': 'bloqueado', // Copied items start blocked
            'hasCompass': enigma.get<bool>('hasCompass') ?? false,
            'compassCoords': enigma.get<String>('compassCoords') ?? '',
            'compassPrice': enigma.get<num>('compassPrice')?.toDouble() ?? 15.0,
            'compassDuration': enigma.get<num>('compassDuration')?.toInt() ?? 0,
            'hasRadar': enigma.get<bool>('hasRadar') ?? false,
            'hasMap': enigma.get<bool>('hasMap') ?? false,
            'radarPrice': enigma.get<num>('radarPrice')?.toDouble() ?? 2.99,
            'mapPrice': enigma.get<num>('mapPrice')?.toDouble() ?? 4.99,
            'imageUrl': enigma.get<String>('imageUrl') ?? '',
            'audioUrl': enigma.get<String>('audioUrl') ?? '',
          }
        }
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enigma duplicado com sucesso!')));
        _loadData();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao duplicar: $e')));
      }
    }
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
    final compassCoordsCtrl = TextEditingController();
    final firstHintCtrl = TextEditingController();
    final firstHintPriceCtrl = TextEditingController(text: '0.50');
    final photoUrlCtrl = TextEditingController();
    final audioUrlCtrl = TextEditingController();
    String tipo = 'text';
    String dificuldade = 'Médio';
    String eventId = _events.first.objectId!;
    bool hasRadar = false;
    bool hasMap = false;
    bool hasCompass = false;
    double radarPrice = 2.99;
    double mapPrice = 4.99;
    double compassPrice = 1.99;

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
                      Expanded(flex: 2, child: _buildInputForm(controller: nomeController, hint: 'Instrução (Suporta Markdown)')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectForm(
                          value: tipo,
                          items: const [
                            DropdownMenuItem(value: 'text', child: Text('Charada (Texto)')),
                            DropdownMenuItem(value: 'photo', child: Text('Foto (Imagem)')),
                            DropdownMenuItem(value: 'audio', child: Text('Áudio (Mídia)')),
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
                  Text('Ferramentas:', style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 12)),
                  const SizedBox(height: 4),
                  _buildToolToggle('Radar', 'Mostra QR codes num raio de 500m', hasRadar, radarPrice, (val) => setModalState(() => hasRadar = val), (val) => radarPrice = val),
                  _buildToolToggle('Maps', 'Caminho otimizado entre enigmas', hasMap, mapPrice, (val) => setModalState(() => hasMap = val), (val) => mapPrice = val),
                  _buildToolToggle('Scanner+', 'Lê QR codes à distância (100m)', hasCompass, compassPrice, (val) => setModalState(() => hasCompass = val), (val) => compassPrice = val),
                  if (tipo == 'photo') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputForm(controller: photoUrlCtrl, hint: 'URL da Foto'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.upload, color: primaryAmber, size: 20),
                          onPressed: () async {
                            final url = await AdminUploadUtil.pickAndUploadImage(context);
                            if (url != null) {
                              setModalState(() => photoUrlCtrl.text = url);
                            }
                          }
                        ),
                      ],
                    ),
                  ] else if (tipo == 'audio') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputForm(controller: audioUrlCtrl, hint: 'URL do Áudio'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.upload, color: primaryAmber, size: 20),
                          onPressed: () async {
                            final url = await AdminUploadUtil.pickAndUploadAudio(context);
                            if (url != null) {
                              setModalState(() => audioUrlCtrl.text = url);
                            }
                          }
                        ),
                      ],
                    ),
                  ],
                  if (hasMap || hasCompass) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputForm(controller: compassCoordsCtrl, hint: 'Coordenadas (Lat, Lng)'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.locationCrosshairs, color: primaryAmber, size: 20),
                          onPressed: () async {
                            try {
                              bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                              if (!serviceEnabled) throw 'Serviço de localização desativado.';

                              LocationPermission permission = await Geolocator.checkPermission();
                              if (permission == LocationPermission.denied) {
                                permission = await Geolocator.requestPermission();
                                if (permission == LocationPermission.denied) throw 'Permissão negada.';
                              }
                              if (permission == LocationPermission.deniedForever) throw 'Permissão permanentemente negada.';

                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buscando localização...')));
                              Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                              setModalState(() {
                                compassCoordsCtrl.text = '${position.latitude}, ${position.longitude}';
                              });
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                            }
                          }
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text('Dica Inicial (Opcional):', style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(flex: 3, child: _buildInputForm(controller: firstHintCtrl, hint: 'Texto da 1ª Dica...')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildInputForm(controller: firstHintPriceCtrl, hint: 'Preço')),
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
                        if (tipo == 'photo' && photoUrlCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A URL da foto é obrigatória.')));
                          return;
                        }
                        if (tipo == 'audio' && audioUrlCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A URL do áudio é obrigatória.')));
                          return;
                        }

                        if (hasMap || hasCompass) {
                          if (compassCoordsCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coordenadas são obrigatórias para Mapa/Bússola.')));
                            return;
                          }
                          final latLngRegEx = RegExp(r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$');
                          if (!latLngRegEx.hasMatch(compassCoordsCtrl.text.trim())) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Formato inválido de coordenadas. Use: Latitude, Longitude (ex: -23.5, -46.6)')));
                            return;
                          }
                        }

                        final generatedHash = '${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}${DateTime.now().microsecond.toString().padLeft(3, '0')}';

                        // Check current max order for this event to auto-increment
                        final queryOrder = QueryBuilder<ParseObject>(ParseObject('Enigma'))
                          ..whereEqualTo('eventId', eventId)
                          ..orderByDescending('order')
                          ..setLimit(1);
                        final resOrder = await queryOrder.query();
                        int nextOrder = 1;
                        if (resOrder.success && resOrder.results != null && resOrder.results!.isNotEmpty) {
                          final lastEnigma = resOrder.results!.first as ParseObject;
                          nextOrder = (lastEnigma.get<num>('order')?.toInt() ?? 0) + 1;
                        }

                        final enigmaRes = await ParseCloudFunction('createOrUpdateEnigma').execute(
                          parameters: {
                            'eventId': eventId,
                            'data': {
                              'instruction': nomeController.text.trim(), // Assuming name maps to instruction
                              'code': generatedHash,
                              'order': nextOrder,
                              'type': tipo,
                              'difficulty': dificuldade,
                              'prize': premioController.text.trim(),
                              'status': 'open',
                              'hasCompass': hasCompass,
                              'compassCoords': compassCoordsCtrl.text.trim(),
                              'compassPrice': compassPrice,
                              'compassDuration': 0,
                              'hasRadar': hasRadar,
                              'hasMap': hasMap,
                              'radarPrice': radarPrice,
                              'mapPrice': mapPrice,
                              'imageUrl': tipo == 'photo' ? photoUrlCtrl.text.trim() : '',
                              'audioUrl': tipo == 'audio' ? audioUrlCtrl.text.trim() : '',
                            }
                          }
                        );

                        if (enigmaRes.success && enigmaRes.result != null && firstHintCtrl.text.trim().isNotEmpty) {
                          String newEnigmaId = enigmaRes.result is ParseObject
                              ? (enigmaRes.result as ParseObject).objectId!
                              : (enigmaRes.result is Map ? enigmaRes.result['objectId'] : '');

                          if (newEnigmaId.isNotEmpty) {
                            await ParseCloudFunction('createOrUpdateHint').execute(
                              parameters: {
                                'data': {
                                  'description': firstHintCtrl.text.trim(),
                                  'price': num.tryParse(firstHintPriceCtrl.text.trim()) ?? 0.0,
                                  'linkedEnigmaId': newEnigmaId,
                                }
                              }
                            );
                          }
                        }

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
    bool hasRadar = enigma.get<bool>('hasRadar') ?? false;
    bool hasMap = enigma.get<bool>('hasMap') ?? false;
    bool hasScanner = enigma.get<bool>('hasCompass') ?? false; // Scanner maps to Compass
    double radarPrice = (enigma.get<num>('radarPrice'))?.toDouble() ?? 2.99;
    double mapPrice = (enigma.get<num>('mapPrice'))?.toDouble() ?? 4.99;
    double scannerPrice = (enigma.get<num>('compassPrice'))?.toDouble() ?? 1.99;

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
                  if ((enigma.get<String>('code') ?? '').isNotEmpty) ...[
                    _buildSectionTitle('Código Hash (QR Code)', FontAwesomeIcons.qrcode),
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryAmber.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: QrImageView(
                              data: enigma.get<String>('code')!,
                              version: QrVersions.auto,
                              size: 100.0,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  enigma.get<String>('code')!,
                                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16, letterSpacing: 2),
                                ),
                                const SizedBox(height: 8),
                                Text('Você pode escanear ou digitar o código acima.', style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 10)),
                              ]
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                                _buildButton('Editar', isWarning: true, onTap: () {
                                  _showEditHintModal(context, hint, () => setModalState((){}));
                                }),
                                const SizedBox(width: 8),
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
                         await ParseCloudFunction('createOrUpdateEnigma').execute(
                            parameters: {
                               'eventId': enigma.get<String>('eventId') ?? '',
                               'data': {
                                  'enigmaId': enigma.objectId,
                                  'hasRadar': hasRadar,
                                  'hasMap': hasMap,
                                  'hasCompass': hasScanner,
                                  'radarPrice': radarPrice,
                                  'mapPrice': mapPrice,
                                  'compassPrice': scannerPrice,
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

  void _showEditHintModal(BuildContext context, ParseObject hint, VoidCallback onSuccess) {
    final textController = TextEditingController(text: hint.get<String>('description') ?? hint.get<String>('title') ?? '');
    final priceController = TextEditingController(text: hint.get<num>('price')?.toStringAsFixed(2) ?? '0.50');

    showDialog(
      context: context,
      builder: (context) {
        return AdminModal(
          title: 'Editar Dica',
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
                    _buildButton('Salvar Alterações', isPrimary: true, onTap: () async {
                       await ParseCloudFunction('createOrUpdateHint').execute(
                          parameters: {
                             'hintId': hint.objectId,
                             'data': {
                                'description': textController.text.trim(),
                                'price': num.tryParse(priceController.text.trim()) ?? 0.0,
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
