import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockEnigma {
  int id; String nome; String dificuldade; String premio; String status;
  MockEnigma({required this.id, required this.nome, required this.dificuldade, required this.premio, required this.status});
}

class MockEvent {
  int id; String nome; String premio; String status; List<MockEnigma> enigmas;
  MockEvent({required this.id, required this.nome, required this.premio, required this.status, required this.enigmas});
}

class MockBanner {
  int id; String titulo; String descricao; int ordem; bool ativo;
  MockBanner({required this.id, required this.titulo, required this.descricao, required this.ordem, required this.ativo});
}

class MockTool {
  String id; String nome; String icone; String desc; double preco;
  MockTool({required this.id, required this.nome, required this.icone, required this.desc, required this.preco});
}

class MockHint {
  String texto; double preco; bool ativa;
  MockHint({required this.texto, required this.preco, required this.ativa});
}

class MockAdminState {
  final List<MockEvent> eventos; final List<MockBanner> banners; final List<MockTool> ferramentasDisponiveis;
  final Map<int, Map<String, bool>> ferramentasPorEnigma; final Map<int, List<MockHint>> dicasPorEnigma;
  final int nextEventoId; final int nextEnigmaId; final int nextBannerId;

  MockAdminState({
    required this.eventos, required this.banners, required this.ferramentasDisponiveis,
    required this.ferramentasPorEnigma, required this.dicasPorEnigma,
    required this.nextEventoId, required this.nextEnigmaId, required this.nextBannerId,
  });

  MockAdminState copyWith({
    List<MockEvent>? eventos, List<MockBanner>? banners, List<MockTool>? ferramentasDisponiveis,
    Map<int, Map<String, bool>>? ferramentasPorEnigma, Map<int, List<MockHint>>? dicasPorEnigma,
    int? nextEventoId, int? nextEnigmaId, int? nextBannerId,
  }) {
    return MockAdminState(
      eventos: eventos ?? this.eventos, banners: banners ?? this.banners, ferramentasDisponiveis: ferramentasDisponiveis ?? this.ferramentasDisponiveis,
      ferramentasPorEnigma: ferramentasPorEnigma ?? this.ferramentasPorEnigma, dicasPorEnigma: dicasPorEnigma ?? this.dicasPorEnigma,
      nextEventoId: nextEventoId ?? this.nextEventoId, nextEnigmaId: nextEnigmaId ?? this.nextEnigmaId, nextBannerId: nextBannerId ?? this.nextBannerId,
    );
  }
}

class MockAdminNotifier extends StateNotifier<MockAdminState> {
  MockAdminNotifier() : super(_initialState());

  static MockAdminState _initialState() {
    return MockAdminState(
      eventos: [
        MockEvent(id: 1, nome: 'Find Win Canaã', premio: 'R\$ 5.000', status: 'ativo', enigmas: [
          MockEnigma(id: 101, nome: 'QR Relógio', dificuldade: 'Fácil', premio: 'R\$ 100', status: 'concluido'),
        ]),
      ],
      banners: [MockBanner(id: 1, titulo: 'Promo', descricao: 'Desc', ordem: 1, ativo: true)],
      ferramentasDisponiveis: [MockTool(id: 'radar', nome: 'Radar', icone: 'faSatelliteDish', desc: 'Desc', preco: 2.99)],
      ferramentasPorEnigma: {101: {'radar': true}},
      dicasPorEnigma: {101: [MockHint(texto: 'Dica', preco: 0.50, ativa: true)]},
      nextEventoId: 2, nextEnigmaId: 102, nextBannerId: 2,
    );
  }

  void addEvent(String nome, String premio, String status) {
    final ev = MockEvent(id: state.nextEventoId, nome: nome, premio: premio, status: status, enigmas: []);
    state = state.copyWith(eventos: [...state.eventos, ev], nextEventoId: state.nextEventoId + 1);
  }

  void updateEvent(int id, String nome, String premio, String status) {
    final index = state.eventos.indexWhere((e) => e.id == id);
    if (index != -1) {
      final list = List<MockEvent>.from(state.eventos);
      list[index].nome = nome; list[index].premio = premio; list[index].status = status;
      state = state.copyWith(eventos: list);
    }
  }

  void removeEvent(int id) {
    state = state.copyWith(eventos: state.eventos.where((e) => e.id != id).toList());
  }

  void addEnigma(int eventId, String nome, String dificuldade, String premio, Map<String, bool> tools, List<MockHint> hints) {
    final index = state.eventos.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final list = List<MockEvent>.from(state.eventos);
      final newId = state.nextEnigmaId;
      list[index].enigmas = [...list[index].enigmas, MockEnigma(id: newId, nome: nome, dificuldade: dificuldade, premio: premio, status: 'disponivel')];
      final t = Map<int, Map<String, bool>>.from(state.ferramentasPorEnigma); t[newId] = tools;
      final h = Map<int, List<MockHint>>.from(state.dicasPorEnigma); h[newId] = hints;
      state = state.copyWith(eventos: list, nextEnigmaId: newId + 1, ferramentasPorEnigma: t, dicasPorEnigma: h);
    }
  }

  void removeEnigmaFromEvent(int eventId, int enigmaId) {
    final index = state.eventos.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final list = List<MockEvent>.from(state.eventos);
      list[index].enigmas = list[index].enigmas.where((e) => e.id != enigmaId).toList();
      state = state.copyWith(eventos: list);
    }
  }

  void updateToolPrice(String toolId, double newPrice) {
    final list = List<MockTool>.from(state.ferramentasDisponiveis);
    final idx = list.indexWhere((t) => t.id == toolId);
    if (idx != -1) { list[idx].preco = newPrice; state = state.copyWith(ferramentasDisponiveis: list); }
  }

  void toggleEnigmaTool(int enigmaId, String toolId, bool value) {
    final t = Map<int, Map<String, bool>>.from(state.ferramentasPorEnigma);
    if (!t.containsKey(enigmaId)) t[enigmaId] = {};
    t[enigmaId]![toolId] = value;
    state = state.copyWith(ferramentasPorEnigma: t);
  }

  void addHintToEnigma(int enigmaId, String texto, double preco) {
    final h = Map<int, List<MockHint>>.from(state.dicasPorEnigma);
    if (!h.containsKey(enigmaId)) h[enigmaId] = [];
    final l = List<MockHint>.from(h[enigmaId]!);
    l.add(MockHint(texto: texto, preco: preco, ativa: true));
    h[enigmaId] = l;
    state = state.copyWith(dicasPorEnigma: h);
  }

  void removeHintFromEnigma(int enigmaId, int hintIndex) {
    final h = Map<int, List<MockHint>>.from(state.dicasPorEnigma);
    if (h.containsKey(enigmaId) && h[enigmaId]!.length > hintIndex) {
      final l = List<MockHint>.from(h[enigmaId]!);
      l.removeAt(hintIndex);
      h[enigmaId] = l;
      state = state.copyWith(dicasPorEnigma: h);
    }
  }

  void updateHint(int enigmaId, int hintIndex, {double? preco, bool? ativa}) {
    final h = Map<int, List<MockHint>>.from(state.dicasPorEnigma);
    if (h.containsKey(enigmaId) && h[enigmaId]!.length > hintIndex) {
      final l = List<MockHint>.from(h[enigmaId]!);
      if (preco != null) l[hintIndex].preco = preco;
      if (ativa != null) l[hintIndex].ativa = ativa;
      h[enigmaId] = l;
      state = state.copyWith(dicasPorEnigma: h);
    }
  }

  void toggleBanner(int id) {
    final list = List<MockBanner>.from(state.banners);
    final idx = list.indexWhere((b) => b.id == id);
    if (idx != -1) { list[idx].ativo = !list[idx].ativo; state = state.copyWith(banners: list); }
  }

  int getTotalEnigmas() => state.eventos.fold(0, (acc, ev) => acc + ev.enigmas.length);
  int getTotalHints() => state.dicasPorEnigma.values.fold(0, (acc, list) => acc + list.length);
}

final mockAdminProvider = StateNotifierProvider<MockAdminNotifier, MockAdminState>((ref) => MockAdminNotifier());
