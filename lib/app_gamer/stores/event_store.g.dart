// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$EventStore on _EventStore, Store {
  late final _$isLoadingAtom = Atom(
    name: '_EventStore.isLoading',
    context: context,
  );

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$isSubscribedAtom = Atom(
    name: '_EventStore.isSubscribed',
    context: context,
  );

  @override
  bool get isSubscribed {
    _$isSubscribedAtom.reportRead();
    return super.isSubscribed;
  }

  @override
  set isSubscribed(bool value) {
    _$isSubscribedAtom.reportWrite(value, super.isSubscribed, () {
      super.isSubscribed = value;
    });
  }

  late final _$statsAtom = Atom(name: '_EventStore.stats', context: context);

  @override
  Map<String, int>? get stats {
    _$statsAtom.reportRead();
    return super.stats;
  }

  @override
  set stats(Map<String, int>? value) {
    _$statsAtom.reportWrite(value, super.stats, () {
      super.stats = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_EventStore.errorMessage',
    context: context,
  );

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$insufficientFundsAtom = Atom(
    name: '_EventStore.insufficientFunds',
    context: context,
  );

  @override
  bool get insufficientFunds {
    _$insufficientFundsAtom.reportRead();
    return super.insufficientFunds;
  }

  @override
  set insufficientFunds(bool value) {
    _$insufficientFundsAtom.reportWrite(value, super.insufficientFunds, () {
      super.insufficientFunds = value;
    });
  }

  late final _$loadStatsAsyncAction = AsyncAction(
    '_EventStore.loadStats',
    context: context,
  );

  @override
  Future<void> loadStats(String eventId, String eventType) {
    return _$loadStatsAsyncAction.run(
      () => super.loadStats(eventId, eventType),
    );
  }

  late final _$subscribeToEventAsyncAction = AsyncAction(
    '_EventStore.subscribeToEvent',
    context: context,
  );

  @override
  Future<bool> subscribeToEvent(String eventId) {
    return _$subscribeToEventAsyncAction.run(
      () => super.subscribeToEvent(eventId),
    );
  }

  late final _$_EventStoreActionController = ActionController(
    name: '_EventStore',
    context: context,
  );

  @override
  void checkSubscription(Map<String, dynamic> playerData, String eventId) {
    final _$actionInfo = _$_EventStoreActionController.startAction(
      name: '_EventStore.checkSubscription',
    );
    try {
      return super.checkSubscription(playerData, eventId);
    } finally {
      _$_EventStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
isSubscribed: ${isSubscribed},
stats: ${stats},
errorMessage: ${errorMessage},
insufficientFunds: ${insufficientFunds}
    ''';
  }
}
