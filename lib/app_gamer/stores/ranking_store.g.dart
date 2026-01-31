// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$RankingStore on _RankingStore, Store {
  late final _$selectedEventIdAtom = Atom(
    name: '_RankingStore.selectedEventId',
    context: context,
  );

  @override
  String? get selectedEventId {
    _$selectedEventIdAtom.reportRead();
    return super.selectedEventId;
  }

  @override
  set selectedEventId(String? value) {
    _$selectedEventIdAtom.reportWrite(value, super.selectedEventId, () {
      super.selectedEventId = value;
    });
  }

  late final _$currentRankingAtom = Atom(
    name: '_RankingStore.currentRanking',
    context: context,
  );

  @override
  List<RankingPlayerModel> get currentRanking {
    _$currentRankingAtom.reportRead();
    return super.currentRanking;
  }

  @override
  set currentRanking(List<RankingPlayerModel> value) {
    _$currentRankingAtom.reportWrite(value, super.currentRanking, () {
      super.currentRanking = value;
    });
  }

  late final _$_RankingStoreActionController = ActionController(
    name: '_RankingStore',
    context: context,
  );

  @override
  void init(List<EventModel> events, List<dynamic> players) {
    final _$actionInfo = _$_RankingStoreActionController.startAction(
      name: '_RankingStore.init',
    );
    try {
      return super.init(events, players);
    } finally {
      _$_RankingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSelectedEventId(String? id) {
    final _$actionInfo = _$_RankingStoreActionController.startAction(
      name: '_RankingStore.setSelectedEventId',
    );
    try {
      return super.setSelectedEventId(id);
    } finally {
      _$_RankingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void calculateRanking() {
    final _$actionInfo = _$_RankingStoreActionController.startAction(
      name: '_RankingStore.calculateRanking',
    );
    try {
      return super.calculateRanking();
    } finally {
      _$_RankingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
selectedEventId: ${selectedEventId},
currentRanking: ${currentRanking}
    ''';
  }
}
