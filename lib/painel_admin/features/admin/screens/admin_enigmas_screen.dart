import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/painel_admin/core/utils/app_colors.dart';
import '../providers/mock_admin_provider.dart';

class AdminEnigmasScreen extends ConsumerStatefulWidget {
  const AdminEnigmasScreen({super.key});

  @override
  ConsumerState<AdminEnigmasScreen> createState() => _AdminEnigmasScreenState();
}

class _AdminEnigmasScreenState extends ConsumerState<AdminEnigmasScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mockAdminProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const FaIcon(FontAwesomeIcons.puzzlePiece, color: primaryAmber, size: 16),
            const SizedBox(width: 10),
            Text(
              'Todos os Enigmas',
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primaryAmber,
                letterSpacing: 1.0,
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
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              for (var ev in state.eventos)
                for (var enig in ev.enigmas)
                  _buildEnigmaCard(enig, ev),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _showCreateEnigmaModal(context, ref),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: primaryAmber.withValues(alpha: 0.15),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(FontAwesomeIcons.circlePlus, color: primaryAmber, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Novo Enigma',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF7A7A7A),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnigmaCard(MockEnigma enig, MockEvent ev) {
    Color statusColor;
    String statusLabel;

    if (enig.status == 'concluido') {
      statusColor = primaryAmber;
      statusLabel = 'Concluído';
    } else if (enig.status == 'disponivel') {
      statusColor = Colors.green;
      statusLabel = 'Disponível';
    } else {
      statusColor = Colors.grey;
      statusLabel = 'Bloqueado';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: itemCardBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryAmber.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryAmber.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: primaryAmber.withValues(alpha: 0.06)),
            ),
            child: const Center(
              child: FaIcon(FontAwesomeIcons.puzzlePiece, color: primaryAmber, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      enig.nome,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: highlightTextColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Evento: ${ev.nome} · Dificuldade: ${enig.dificuldade} · Prêmio: ${enig.premio}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8A7A5A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.withValues(alpha: 0.05),
              foregroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              minimumSize: Size.zero,
            ),
            onPressed: () => _showManageEnigmaModal(context, ref, enig),
            child: Text(
              'GERENCIAR',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManageEnigmaModal(BuildContext context, WidgetRef ref, MockEnigma enigma) {
    showDialog(
      context: context,
      builder: (ctx) => _ManageEnigmaDialog(enigma: enigma),
    );
  }

  void _showCreateEnigmaModal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => const _CreateEnigmaDialog(),
    );
  }
}

class _ManageEnigmaDialog extends ConsumerStatefulWidget {
  final MockEnigma enigma;

  const _ManageEnigmaDialog({required this.enigma});

  @override
  ConsumerState<_ManageEnigmaDialog> createState() => _ManageEnigmaDialogState();
}

class _ManageEnigmaDialogState extends ConsumerState<_ManageEnigmaDialog> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mockAdminProvider);
    final ferramentas = state.ferramentasDisponiveis;
    final estadoFerramentas = state.ferramentasPorEnigma[widget.enigma.id] ?? {};
    final dicas = state.dicasPorEnigma[widget.enigma.id] ?? [];

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gerenciar: ${widget.enigma.nome}',
                  style: GoogleFonts.orbitron(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: highlightTextColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: secondaryTextColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Color(0x0FC0A060)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.toolbox, color: primaryAmber, size: 14),
                        const SizedBox(width: 10),
                        Text(
                          'Ferramentas',
                          style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryAmber,
                            letterSpacing: 1.0,
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
                    const SizedBox(height: 10),
                    for (var ferr in ferramentas)
                      _buildToolItem(ferr, estadoFerramentas[ferr.id] ?? false),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.lightbulb, color: primaryAmber, size: 14),
                        const SizedBox(width: 10),
                        Text(
                          'Dicas',
                          style: GoogleFonts.orbitron(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryAmber,
                            letterSpacing: 1.0,
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
                    const SizedBox(height: 10),
                    for (var i = 0; i < dicas.length; i++)
                      _buildHintItem(dicas[i], i),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _showAddHintDialog(context, ref, widget.enigma.id),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: primaryAmber.withValues(alpha: 0.15),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(FontAwesomeIcons.circlePlus, color: primaryAmber, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              'Adicionar Dica',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF7A7A7A),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'FECHAR',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAmber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'SALVAR ALTERAÇÕES',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolItem(MockTool tool, bool active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: itemCardBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryAmber.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FaFaIcon(_getIconData(tool.icone) as IconData, color: primaryAmber, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      tool.nome,
                      style: GoogleFonts.inter(
                        color: highlightTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tool.desc,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8A7A5A),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: itemCardBackground.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryAmber.withValues(alpha: 0.15)),
            ),
            child: TextField(
              controller: TextEditingController(text: tool.preco.toStringAsFixed(2)),
              style: GoogleFonts.orbitron(color: highlightTextColor, fontSize: 11),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onChanged: (val) {
                final p = double.tryParse(val);
                if (p != null) {
                  ref.read(mockAdminProvider.notifier).updateToolPrice(tool.id, p);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: active,
            activeColor: Colors.black,
            activeTrackColor: primaryAmber,
            inactiveThumbColor: const Color(0xFF1A1A1A),
            inactiveTrackColor: const Color(0xFF3A3A3A),
            onChanged: (val) {
              ref.read(mockAdminProvider.notifier).toggleEnigmaTool(widget.enigma.id, tool.id, val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHintItem(MockHint hint, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: itemCardBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryAmber.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hint.texto,
                  style: GoogleFonts.inter(
                    color: highlightTextColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Preço: ',
                      style: GoogleFonts.inter(color: const Color(0xFF8A7A5A), fontSize: 10),
                    ),
                    Text(
                      'R\$ ${hint.preco.toStringAsFixed(2)}',
                      style: GoogleFonts.orbitron(color: primaryAmber, fontSize: 10),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      hint.ativa ? 'Ativa' : 'Inativa',
                      style: GoogleFonts.inter(
                        color: hint.ativa ? Colors.green : Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: itemCardBackground.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryAmber.withValues(alpha: 0.15)),
            ),
            child: TextField(
              controller: TextEditingController(text: hint.preco.toStringAsFixed(2)),
              style: GoogleFonts.orbitron(color: highlightTextColor, fontSize: 11),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onChanged: (val) {
                 final p = double.tryParse(val);
                 if (p != null) {
                   ref.read(mockAdminProvider.notifier).updateHint(widget.enigma.id, index, preco: p);
                 }
              },
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: hint.ativa,
            activeColor: Colors.black,
            activeTrackColor: primaryAmber,
            inactiveThumbColor: const Color(0xFF1A1A1A),
            inactiveTrackColor: const Color(0xFF3A3A3A),
            onChanged: (val) {
              ref.read(mockAdminProvider.notifier).updateHint(widget.enigma.id, index, ativa: val);
            },
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.redAccent, size: 16),
            onPressed: () {
               ref.read(mockAdminProvider.notifier).removeHintFromEnigma(widget.enigma.id, index);
            },
          )
        ],
      ),
    );
  }
}

class _CreateEnigmaDialog extends ConsumerStatefulWidget {
  const _CreateEnigmaDialog();
  @override
  ConsumerState<_CreateEnigmaDialog> createState() => _CreateEnigmaDialogState();
}
class _CreateEnigmaDialogState extends ConsumerState<_CreateEnigmaDialog> {
  final nomeCtrl = TextEditingController();
  final premioCtrl = TextEditingController();
  String dificuldade = 'Médio';
  int? eventoId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mockAdminProvider);
    if (eventoId == null && state.eventos.isNotEmpty) {
      eventoId = state.eventos.first.id;
    }

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Criar Novo Enigma',
                  style: GoogleFonts.orbitron(fontSize: 19, fontWeight: FontWeight.w700, color: highlightTextColor),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: secondaryTextColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Color(0x0FC0A060)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildInput('Nome do enigma', nomeCtrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: itemCardBackground.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryAmber.withValues(alpha: 0.15)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: dificuldade,
                        dropdownColor: cardColor,
                        style: GoogleFonts.inter(color: highlightTextColor, fontSize: 15),
                        isExpanded: true,
                        items: ['Fácil', 'Médio', 'Difícil', 'Lendário'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (val) => setState(() => dificuldade = val!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildInput('Prêmio', premioCtrl),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Vincular ao Evento:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8A7A5A))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: itemCardBackground.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryAmber.withValues(alpha: 0.15)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: eventoId,
                  dropdownColor: cardColor,
                  style: GoogleFonts.inter(color: highlightTextColor, fontSize: 15),
                  isExpanded: true,
                  items: state.eventos.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.nome} (ID: ${e.id})'))).toList(),
                  onChanged: (val) => setState(() => eventoId = val),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('CANCELAR', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: secondaryTextColor)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryAmber, foregroundColor: Colors.black),
                  onPressed: () {
                     if (eventoId != null && nomeCtrl.text.isNotEmpty) {
                        ref.read(mockAdminProvider.notifier).addEnigma(eventoId!, nomeCtrl.text, dificuldade, premioCtrl.text, {}, []);
                        Navigator.of(context).pop();
                     }
                  },
                  child: Text('CRIAR ENIGMA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: itemCardBackground.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryAmber.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.inter(color: highlightTextColor, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: secondaryTextColor, fontSize: 15),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

void _showAddHintDialog(BuildContext context, WidgetRef ref, int enigmaId) {
  final textCtrl = TextEditingController();
  final priceCtrl = TextEditingController(text: '0.50');

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adicionar Dica', style: GoogleFonts.orbitron(fontSize: 19, fontWeight: FontWeight.w700, color: highlightTextColor)),
            const Divider(color: Color(0x0FC0A060)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: itemCardBackground.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryAmber.withValues(alpha: 0.15)),
              ),
              child: TextField(
                controller: textCtrl,
                maxLines: 3,
                style: GoogleFonts.inter(color: highlightTextColor, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Escreva o texto da dica aqui...', border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: itemCardBackground.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryAmber.withValues(alpha: 0.15)),
              ),
              child: TextField(
                controller: priceCtrl,
                style: GoogleFonts.inter(color: highlightTextColor, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Preço', border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('CANCELAR', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: secondaryTextColor)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryAmber, foregroundColor: Colors.black),
                  onPressed: () {
                     final price = double.tryParse(priceCtrl.text) ?? 0.0;
                     if (textCtrl.text.isNotEmpty) {
                        ref.read(mockAdminProvider.notifier).addHintToEnigma(enigmaId, textCtrl.text, price);
                        Navigator.of(context).pop();
                     }
                  },
                  child: Text('SALVAR DICA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            )
          ],
        ),
      )
    )
  );
}

dynamic _getIconData(String name) {
  if (name == 'faSatelliteDish') return FontAwesomeIcons.satelliteDish;
  if (name == 'faMap') return FontAwesomeIcons.map;
  if (name == 'faQrcode') return FontAwesomeIcons.qrcode;
  return FontAwesomeIcons.toolbox;
}
