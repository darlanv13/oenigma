// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enigma_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$EnigmaStore on _EnigmaStore, Store {
  late final _$isLoadingAtom = Atom(
    name: '_EnigmaStore.isLoading',
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

  late final _$canBuyHintAtom = Atom(
    name: '_EnigmaStore.canBuyHint',
    context: context,
  );

  @override
  bool get canBuyHint {
    _$canBuyHintAtom.reportRead();
    return super.canBuyHint;
  }

  @override
  set canBuyHint(bool value) {
    _$canBuyHintAtom.reportWrite(value, super.canBuyHint, () {
      super.canBuyHint = value;
    });
  }

  late final _$isHintVisibleAtom = Atom(
    name: '_EnigmaStore.isHintVisible',
    context: context,
  );

  @override
  bool get isHintVisible {
    _$isHintVisibleAtom.reportRead();
    return super.isHintVisible;
  }

  @override
  set isHintVisible(bool value) {
    _$isHintVisibleAtom.reportWrite(value, super.isHintVisible, () {
      super.isHintVisible = value;
    });
  }

  late final _$isBlockedAtom = Atom(
    name: '_EnigmaStore.isBlocked',
    context: context,
  );

  @override
  bool get isBlocked {
    _$isBlockedAtom.reportRead();
    return super.isBlocked;
  }

  @override
  set isBlocked(bool value) {
    _$isBlockedAtom.reportWrite(value, super.isBlocked, () {
      super.isBlocked = value;
    });
  }

  late final _$hintDataAtom = Atom(
    name: '_EnigmaStore.hintData',
    context: context,
  );

  @override
  Map<String, dynamic>? get hintData {
    _$hintDataAtom.reportRead();
    return super.hintData;
  }

  @override
  set hintData(Map<String, dynamic>? value) {
    _$hintDataAtom.reportWrite(value, super.hintData, () {
      super.hintData = value;
    });
  }

  late final _$distanceAtom = Atom(
    name: '_EnigmaStore.distance',
    context: context,
  );

  @override
  double? get distance {
    _$distanceAtom.reportRead();
    return super.distance;
  }

  @override
  set distance(double? value) {
    _$distanceAtom.reportWrite(value, super.distance, () {
      super.distance = value;
    });
  }

  late final _$isNearAtom = Atom(name: '_EnigmaStore.isNear', context: context);

  @override
  bool get isNear {
    _$isNearAtom.reportRead();
    return super.isNear;
  }

  @override
  set isNear(bool value) {
    _$isNearAtom.reportWrite(value, super.isNear, () {
      super.isNear = value;
    });
  }

  late final _$cooldownUntilAtom = Atom(
    name: '_EnigmaStore.cooldownUntil',
    context: context,
  );

  @override
  String? get cooldownUntil {
    _$cooldownUntilAtom.reportRead();
    return super.cooldownUntil;
  }

  @override
  set cooldownUntil(String? value) {
    _$cooldownUntilAtom.reportWrite(value, super.cooldownUntil, () {
      super.cooldownUntil = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_EnigmaStore.errorMessage',
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

  late final _$shakeTriggerAtom = Atom(
    name: '_EnigmaStore.shakeTrigger',
    context: context,
  );

  @override
  bool get shakeTrigger {
    _$shakeTriggerAtom.reportRead();
    return super.shakeTrigger;
  }

  @override
  set shakeTrigger(bool value) {
    _$shakeTriggerAtom.reportWrite(value, super.shakeTrigger, () {
      super.shakeTrigger = value;
    });
  }

  late final _$nextStepAtom = Atom(
    name: '_EnigmaStore.nextStep',
    context: context,
  );

  @override
  Map<String, dynamic>? get nextStep {
    _$nextStepAtom.reportRead();
    return super.nextStep;
  }

  @override
  set nextStep(Map<String, dynamic>? value) {
    _$nextStepAtom.reportWrite(value, super.nextStep, () {
      super.nextStep = value;
    });
  }

  late final _$insufficientFundsAtom = Atom(
    name: '_EnigmaStore.insufficientFunds',
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

  late final _$currentEnigmaAtom = Atom(
    name: '_EnigmaStore.currentEnigma',
    context: context,
  );

  @override
  EnigmaModel? get currentEnigma {
    _$currentEnigmaAtom.reportRead();
    return super.currentEnigma;
  }

  @override
  set currentEnigma(EnigmaModel? value) {
    _$currentEnigmaAtom.reportWrite(value, super.currentEnigma, () {
      super.currentEnigma = value;
    });
  }

  late final _$resetEnigmaStateAsyncAction = AsyncAction(
    '_EnigmaStore.resetEnigmaState',
    context: context,
  );

  @override
  Future<void> resetEnigmaState(String eventId, int phaseOrder) {
    return _$resetEnigmaStateAsyncAction.run(
      () => super.resetEnigmaState(eventId, phaseOrder),
    );
  }

  late final _$fetchInitialStatusAsyncAction = AsyncAction(
    '_EnigmaStore.fetchInitialStatus',
    context: context,
  );

  @override
  Future<void> fetchInitialStatus(String eventId, int phaseOrder) {
    return _$fetchInitialStatusAsyncAction.run(
      () => super.fetchInitialStatus(eventId, phaseOrder),
    );
  }

  late final _$handleActionAsyncAction = AsyncAction(
    '_EnigmaStore.handleAction',
    context: context,
  );

  @override
  Future<void> handleAction(
    String action,
    String eventId,
    int phaseOrder, {
    String? code,
  }) {
    return _$handleActionAsyncAction.run(
      () => super.handleAction(action, eventId, phaseOrder, code: code),
    );
  }

  late final _$initializeGpsListenerAsyncAction = AsyncAction(
    '_EnigmaStore.initializeGpsListener',
    context: context,
  );

  @override
  Future<void> initializeGpsListener() {
    return _$initializeGpsListenerAsyncAction.run(
      () => super.initializeGpsListener(),
    );
  }

  late final _$_EnigmaStoreActionController = ActionController(
    name: '_EnigmaStore',
    context: context,
  );

  @override
  void setCurrentEnigma(EnigmaModel enigma) {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.setCurrentEnigma',
    );
    try {
      return super.setCurrentEnigma(enigma);
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetShake() {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.resetShake',
    );
    try {
      return super.resetShake();
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
canBuyHint: ${canBuyHint},
isHintVisible: ${isHintVisible},
isBlocked: ${isBlocked},
hintData: ${hintData},
distance: ${distance},
isNear: ${isNear},
cooldownUntil: ${cooldownUntil},
errorMessage: ${errorMessage},
shakeTrigger: ${shakeTrigger},
nextStep: ${nextStep},
insufficientFunds: ${insufficientFunds},
currentEnigma: ${currentEnigma}
    ''';
  }
}
