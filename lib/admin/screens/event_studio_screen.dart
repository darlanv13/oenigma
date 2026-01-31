import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/admin/stores/event_store.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/utils/app_colors.dart';
import 'package:oenigma/widgets/lottie_dialog.dart';
// Importe o seu widget de EventCard real se possível para o preview ser fiel
// import 'package:oenigma/app_gamer/widgets/event_card.dart';

class EventStudioScreen extends StatefulWidget {
  final EventModel? event;
  const EventStudioScreen({super.key, this.event});

  @override
  State<EventStudioScreen> createState() => _EventStudioScreenState();
}

class _EventStudioScreenState extends State<EventStudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventStore _store = EventStore();

  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _iconCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _dateCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.event != null) {
      _store.loadFromModel(widget.event!);
    }

    _nameCtrl = TextEditingController(text: _store.name)
      ..addListener(() => _store.setName(_nameCtrl.text));
    _iconCtrl = TextEditingController(text: _store.iconUrl)
      ..addListener(() => _store.setIconUrl(_iconCtrl.text));
    _descCtrl = TextEditingController(text: _store.description)
      ..addListener(() => _store.setDescription(_descCtrl.text));
    _dateCtrl = TextEditingController(text: _store.startDate)
      ..addListener(() => _store.setStartDate(_dateCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: Text(
          widget.event == null ? "NOVO EVENTO" : "EDITAR EVENTO",
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryAmber,
          labelColor: primaryAmber,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "DADOS & CONFIG"),
            Tab(text: "PREVIEW DO CARD"),
          ],
        ),
        actions: [
          Observer(
            builder: (_) => IconButton(
              icon: _store.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: primaryAmber),
                    )
                  : const Icon(Icons.save, color: primaryAmber),
              onPressed: _store.isSaving ? null : _handleSave,
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFormTab(), _buildPreviewTab()],
      ),
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Informações Básicas"),
          _cyberInput(_nameCtrl, "Nome do Evento", Icons.event),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _cyberInput(
                  null,
                  "Prêmio (Texto)",
                  Icons.emoji_events,
                  onChanged: _store.setPrize,
                  initVal: _store.prize,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _cyberInput(
                  null,
                  "Preço (R\$)",
                  Icons.attach_money,
                  isNumber: true,
                  onChanged: _store.setPrice,
                  initVal: _store.price.toString(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _sectionTitle("Visual & Detalhes"),
          _cyberInput(_iconCtrl, "URL da Animação (Lottie)", Icons.animation),
          const SizedBox(height: 16),
          _cyberInput(
            _descCtrl,
            "Descrição Completa",
            Icons.description,
            maxLines: 4,
          ),

          const SizedBox(height: 24),
          _sectionTitle("Logística"),
          _cyberInput(
            null,
            "Localização",
            Icons.location_on,
            onChanged: _store.setLocation,
            initVal: _store.location,
          ),
          const SizedBox(height: 16),
          _cyberInput(
            _dateCtrl,
            "Data de Início (dd/MM/yyyy)",
            Icons.calendar_today,
          ),

          const SizedBox(height: 24),
          _sectionTitle("Sistema"),
          Observer(
            builder: (_) => DropdownButtonFormField<String>(
              value: _store.eventType,
              dropdownColor: cardColor,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco("Tipo de Jogo", Icons.gamepad),
              items: const [
                DropdownMenuItem(
                  value: 'classic',
                  child: Text('Clássico (Fases)'),
                ),
                DropdownMenuItem(
                  value: 'find_and_win',
                  child: Text('Find & Win'),
                ),
              ],
              onChanged: (v) => _store.setEventType(v!),
            ),
          ),
          const SizedBox(height: 16),
          Observer(
            builder: (_) => DropdownButtonFormField<String>(
              value: _store.status,
              dropdownColor: cardColor,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco("Status", Icons.traffic),
              items: const [
                DropdownMenuItem(
                  value: 'dev',
                  child: Text('Em Desenvolvimento'),
                ),
                DropdownMenuItem(value: 'open', child: Text('Aberto')),
                DropdownMenuItem(value: 'closed', child: Text('Fechado')),
              ],
              onChanged: (v) => _store.setStatus(v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "Como o jogador verá na Home:",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            // Simulação do Card
            Observer(
              builder: (_) {
                return Container(
                  width: 350,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: primaryAmber.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header com Lottie
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: _store.iconUrl.isNotEmpty
                            ? Lottie.network(
                                _store.iconUrl,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.error,
                                  color: Colors.white12,
                                ),
                              )
                            : const Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.white12,
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _store.name.isEmpty
                                        ? "Nome do Evento"
                                        : _store.name,
                                    style: GoogleFonts.orbitron(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryAmber,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _store.status.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _store.description.isEmpty
                                  ? "Descrição..."
                                  : _store.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: secondaryTextColor),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  color: primaryAmber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _store.prize,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const Spacer(),
                                Text(
                                  "R\$ ${_store.price.toStringAsFixed(2)}",
                                  style: GoogleFonts.orbitron(
                                    color: Colors.greenAccent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helpers
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.orbitron(
          color: primaryAmber,
          fontSize: 12,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _cyberInput(
    TextEditingController? ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
    Function(String)? onChanged,
    String? initVal,
  }) {
    return TextFormField(
      controller: ctrl,
      initialValue: ctrl == null ? initVal : null,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDeco(label, icon),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: secondaryTextColor),
      prefixIcon: Icon(icon, color: primaryAmber),
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryAmber),
      ),
    );
  }

  Future<void> _handleSave() async {
    final success = await _store.saveEvent(widget.event?.id);
    if (success && mounted) {
      await LottieDialog.show(
        context,
        assetPath: 'assets/animations/check.json',
        message: 'Evento Salvo!',
      );
      Navigator.pop(context, true);
    }
  }
}
