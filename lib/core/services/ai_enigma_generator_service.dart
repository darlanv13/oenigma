import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oenigma/core/config/env_config.dart';

/// Resultado estruturado gerado pelo Co-Piloto IA
class GeneratedEnigmaResult {
  final String instruction;
  final List<String> hints;
  final int suggestedRadius;
  final String suggestedKeyword;
  final String theme;

  const GeneratedEnigmaResult({
    required this.instruction,
    required this.hints,
    required this.suggestedRadius,
    required this.suggestedKeyword,
    required this.theme,
  });

  factory GeneratedEnigmaResult.fromJson(Map<String, dynamic> json, String theme) {
    List<String> parsedHints = [];
    if (json['hints'] is List) {
      parsedHints = (json['hints'] as List).map((e) => e.toString()).toList();
    }
    while (parsedHints.length < 3) {
      parsedHints.add('Observe com atenção os detalhes arquitetônicos deste ponto.');
    }

    return GeneratedEnigmaResult(
      instruction: json['instruction']?.toString() ?? 'Siga os passos do enigma...',
      hints: parsedHints,
      suggestedRadius: (json['suggestedRadius'] is num) ? (json['suggestedRadius'] as num).toInt() : 50,
      suggestedKeyword: json['suggestedKeyword']?.toString() ?? 'ENIGMA',
      theme: theme,
    );
  }
}

/// Serviço de Geração de Enigmas por Inteligência Artificial (Google Gemini)
class AiEnigmaGeneratorService {
  static const String _prefApiKey = 'custom_gemini_api_key';

  /// Obtém a chave Gemini ativa (preferência local ou EnvConfig)
  static Future<String> getActiveApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final customKey = prefs.getString(_prefApiKey);
    if (customKey != null && customKey.trim().isNotEmpty) {
      return customKey.trim();
    }
    return EnvConfig.geminiApiKey;
  }

  /// Salva uma chave Gemini customizada pelo usuário no Creator Studio
  static Future<void> saveCustomApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefApiKey, key.trim());
  }

  /// Gera um enigma criativo completo com charada, 3 dicas e raio tático
  static Future<GeneratedEnigmaResult> generateEnigma({
    required String locationName,
    required String theme,
    required String difficulty,
    String? customApiKey,
  }) async {
    final apiKey = (customApiKey != null && customApiKey.trim().isNotEmpty)
        ? customApiKey.trim()
        : await getActiveApiKey();

    if (apiKey.isNotEmpty) {
      try {
        final result = await _callGeminiApi(
          apiKey: apiKey,
          locationName: locationName,
          theme: theme,
          difficulty: difficulty,
        );
        if (result != null) return result;
      } catch (e) {
        debugPrint('⚠️ [AiEnigmaGenerator] Falha na API Gemini: $e. Ativando fallback tático...');
      }
    }

    // Fallback dinâmico tático e contextualizado caso offline ou sem chave
    return _generateThematicFallback(
      locationName: locationName,
      theme: theme,
      difficulty: difficulty,
    );
  }

  static Future<GeneratedEnigmaResult?> _callGeminiApi({
    required String apiKey,
    required String locationName,
    required String theme,
    required String difficulty,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final prompt = '''
Você é o Mestre Tático do ecossistema de exploração urbana "O Enigma".
Crie um enigma tático para caça ao tesouro urbana real.

DADOS DE ENTRADA:
- Local de Referência ou Ponto Turístico: "$locationName"
- Atmosfera / Tema: "$theme"
- Nível de Dificuldade: "$difficulty"

REQUISITOS OBRIGATÓRIOS:
1. "instruction": Um enigma poético, misterioso e intrigante (entre 2 a 4 estrofes ou linhas imersivas) que conduza o jogador a descobrir o local ou uma marca escondida nele, sem falar o nome exato diretamente.
2. "hints": Exatamente 3 dicas progressivas:
   - Dica 1: Sutil e contextual sobre a história ou ambiente.
   - Dica 2: Direcional ou perspectiva tática (ex: para onde olhar).
   - Dica 3: Reveladora e precisa para quem estiver empacado.
3. "suggestedRadius": Raio tático em metros (inteiro entre 30 e 120) adequado para segurança do pedestre no local.
4. "suggestedKeyword": Uma palavra-chave curta em caixa alta relacionada à solução (ex: RELIQUIA, CHAVE, FAROL).

RESPONDA EXCLUSIVAMENTE EM FORMATO JSON VÁLIDO (sem markdown, sem blocos ```json):
{
  "instruction": "...",
  "hints": ["...", "...", "..."],
  "suggestedRadius": 50,
  "suggestedKeyword": "..."
}
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.75,
        'responseMimeType': 'application/json',
      }
    });

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final candidates = jsonResponse['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final text = candidates[0]['content']['parts'][0]['text'] as String?;
        if (text != null) {
          final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
          final parsed = jsonDecode(cleanJson);
          return GeneratedEnigmaResult.fromJson(parsed, theme);
        }
      }
    } else {
      debugPrint('⚠️ [AiEnigmaGenerator] Status Code ${response.statusCode}: ${response.body}');
    }

    return null;
  }

  /// Gerador de Enigmas Táticos Contextuais offline / sem chave
  static GeneratedEnigmaResult _generateThematicFallback({
    required String locationName,
    required String theme,
    required String difficulty,
  }) {
    final loc = locationName.trim().isNotEmpty ? locationName.trim() : 'o Ponto Misterioso';

    if (theme.contains('Pirata') || theme.contains('Tesouro')) {
      return GeneratedEnigmaResult(
        instruction: 'Onde as correntes do tempo descansam e o vento sussurra segredos antigos.\n'
            'Busque a sentinela de pedra próxima a "$loc", onde o baú dos navegadores aguarda o olhar atento dos caçadores.',
        hints: [
          'Grandes navegadores sempre procuram pontos elevados e sombras marcantes ao redor.',
          'Olhe para a base da estrutura de "$loc", onde os símbolos do passado costumam repousar.',
          'O alvo está a poucos passos da placa ou marco principal de "$loc". Procure o selo do enigma.'
        ],
        suggestedRadius: 40,
        suggestedKeyword: 'CORSAIR',
        theme: theme,
      );
    } else if (theme.contains('Cyberpunk') || theme.contains('Hacker')) {
      return GeneratedEnigmaResult(
        instruction: 'Sinal criptografado interceptado na malha urbana.\n'
            'Um nó de dados analógico foi ocultado nas imediações de "$loc".\n'
            'Decodifique a frequência e localize a interface física antes que o rastreador expire.',
        hints: [
          'Verifique as estruturas metálicas ou caixas de distribuição ao redor do perímetro.',
          'A perspectiva correta está alinhada à entrada principal de "$loc".',
          'O QR tático está fixado discretamente no suporte lateral de "$loc". Conecte-se.'
        ],
        suggestedRadius: 50,
        suggestedKeyword: 'CYBERLINK',
        theme: theme,
      );
    } else if (theme.contains('Noir') || theme.contains('Detetive')) {
      return GeneratedEnigmaResult(
        instruction: 'As luzes da cidade deixam sombras compridas ao cair da tarde.\n'
            'Uma testemunha deixou uma pista crucial gravada perto de "$loc".\n'
            'Siga o rastro dos passos que ninguém notou e encontre a verdade.',
        hints: [
          'Detetives prestam atenção no que está abaixo do nível dos olhos da multidão.',
          'Procure por inscrições ou detalhes discretos próximos aos degraus de "$loc".',
          'A pista foi marcada logo atrás da coluna frontal de "$loc". Inspecione com discrição.'
        ],
        suggestedRadius: 45,
        suggestedKeyword: 'VERDADE',
        theme: theme,
      );
    }

    // Tema padrão / Histórico
    return GeneratedEnigmaResult(
      instruction: 'As pedras guardam a memória dos que por aqui passaram.\n'
          'Em "$loc", o que antes era comum agora oculta a chave da próxima jornada.\n'
          'Abra os olhos para o monumento e reivindique seu legado.',
      hints: [
        'A história de "$loc" revela a direção exata por onde começar a busca.',
        'Mantenha-se no campo de visão central do monumento.',
        'O código do enigma está gravado próximo ao ponto de identificação de "$loc".'
      ],
      suggestedRadius: 50,
      suggestedKeyword: 'RELIQUIA',
      theme: theme,
    );
  }
}
