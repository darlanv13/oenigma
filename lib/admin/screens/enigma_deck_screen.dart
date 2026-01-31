import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/admin/screens/enigma_studio_screen.dart';
import 'package:oenigma/admin/stores/enigma_deck_store.dart';
import 'package:oenigma/models/enigma_model.dart'; //
import 'package:oenigma/utils/app_colors.dart'; //

class EnigmaDeckScreen extends StatefulWidget {
  final String eventId;
  final String? phaseId;
  final String eventType;
  final int? phaseOrder;

  const EnigmaDeckScreen({
    super.key,
    required this.eventId,
    required this.eventType,
    this.phaseId,
    this.phaseOrder,
  });

  @override
  State<EnigmaDeckScreen> createState() => _EnigmaDeckScreenState();
}

class _EnigmaDeckScreenState extends State<EnigmaDeckScreen> {
  // Instancia a Store que gerencia a lista
  final EnigmaDeckStore _store = EnigmaDeckStore();

  @override
  void initState() {
    super.initState();
    // Carrega os enigmas ao abrir a tela
    _store.loadEnigmas(widget.eventId, widget.phaseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.phaseId == null
                  ? "DECK DE ENIGMAS"
                  : "FASE ${widget.phaseOrder ?? '?'}",
              style: GoogleFonts.orbitron(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryAmber,
              ),
            ),
            const Text(
              "Gerenciamento de Cartas",
              style: TextStyle(fontSize: 10, color: secondaryTextColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _store.loadEnigmas(widget.eventId, widget.phaseId),
          ),
        ],
      ),
      // Observer redesenha a tela quando a lista muda na Store
      body: Observer(
        builder: (_) {
          if (_store.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }

          if (_store.enigmas.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 Cartas por linha
              childAspectRatio: 0.70, // Formato alongado tipo Carta de Tarot
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _store.enigmas.length,
            itemBuilder: (context, index) {
              final enigma = _store.enigmas[index];
              return _buildEnigmaCard(enigma);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryAmber,
        icon: const Icon(Icons.add_card, color: Colors.black),
        label: Text(
          "NOVA CARTA",
          style: GoogleFonts.orbitron(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () => _navigateToStudio(),
      ),
    );
  }

  Widget _buildEnigmaCard(EnigmaModel enigma) {
    // Define cores e ícones baseados no tipo do enigma
    IconData typeIcon;
    Color typeColor;
    String typeLabel;

    switch (enigma.type) {
      case 'qr_code_gps':
        typeIcon = Icons.qr_code_2;
        typeColor = Colors.purpleAccent;
        typeLabel = "GPS + QR";
        break;
      case 'photo_location':
        typeIcon = Icons.camera_alt;
        typeColor = Colors.blueAccent;
        typeLabel = "FOTO";
        break;
      default:
        typeIcon = Icons.text_fields;
        typeColor = Colors.greenAccent;
        typeLabel = "TEXTO";
    }

    return GestureDetector(
      onTap: () => _navigateToStudio(enigma: enigma),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: typeColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ícone de fundo (Marca d'água)
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                typeIcon,
                size: 90,
                color: Colors.white.withOpacity(0.03),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho: Ordem e Tipo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: typeColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          "#${enigma.order}",
                          style: GoogleFonts.orbitron(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Icon(typeIcon, color: typeColor, size: 16),
                    ],
                  ),

                  const Spacer(),

                  // Imagem de Capa (se houver)
                  if (enigma.imageUrl != null && enigma.imageUrl!.isNotEmpty)
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              enigma.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Expanded(
                      flex: 3,
                      child: Center(
                        child: Icon(
                          Icons.help_outline,
                          color: Colors.white12,
                          size: 40,
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Instrução (Pergunta)
                  Text(
                    enigma.instruction,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),

                  const Spacer(),
                  const Divider(color: Colors.white10, height: 16),

                  // Rodapé: Código e Delete
                  Row(
                    children: [
                      const Icon(
                        Icons.vpn_key,
                        size: 10,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          enigma.code,
                          style: GoogleFonts.robotoMono(
                            color: primaryAmber,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () => _confirmDelete(enigma),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.style_outlined, size: 60, color: Colors.white10),
          const SizedBox(height: 16),
          const Text(
            "Nenhuma carta no deck.",
            style: TextStyle(color: secondaryTextColor),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Adicionar Primeira Carta"),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryAmber,
              side: const BorderSide(color: primaryAmber),
            ),
            onPressed: () => _navigateToStudio(),
          ),
        ],
      ),
    );
  }

  // Navegação para o Studio (Criação ou Edição)
  Future<void> _navigateToStudio({EnigmaModel? enigma}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnigmaStudioScreen(
          eventId: widget.eventId,
          phaseId: widget.phaseId,
          eventType: widget.eventType,
          enigma: enigma, // Se for null, o Studio abre em modo "Novo Enigma"
        ),
      ),
    );
    // Ao voltar do Studio, recarrega a lista para mostrar as mudanças
    _store.loadEnigmas(widget.eventId, widget.phaseId);
  }

  void _confirmDelete(EnigmaModel enigma) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          "Queimar Carta?",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "O enigma #${enigma.order} será excluído permanentemente.",
          style: const TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            child: const Text(
              "CANCELAR",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              // Chama a Store para deletar
              await _store.deleteEnigma(
                widget.eventId,
                widget.phaseId,
                enigma.id,
              );
            },
            child: const Text("EXCLUIR"),
          ),
        ],
      ),
    );
  }
}
