// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'find_and_win_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$FindAndWinStore on _FindAndWinStore, Store {
  late final _$isLoadingAtom = Atom(
    name: '_FindAndWinStore.isLoading',
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

  late final _$isBlockedAtom = Atom(
    name: '_FindAndWinStore.isBlocked',
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

  late final _$eventDataAtom = Atom(
    name: '_FindAndWinStore.eventData',
    context: context,
  );

  @override
  Map<String, dynamic>? get eventData {
    _$eventDataAtom.reportRead();
    return super.eventData;
  }

  @override
  set eventData(Map<String, dynamic>? value) {
    _$eventDataAtom.reportWrite(value, super.eventData, () {
      super.eventData = value;
    });
  }

  late final _$currentEnigmaDataAtom = Atom(
    name: '_FindAndWinStore.currentEnigmaData',
    context: context,
  );

  @override
  Map<String, dynamic>? get currentEnigmaData {
    _$currentEnigmaDataAtom.reportRead();
    return super.currentEnigmaData;
  }

  @override
  set currentEnigmaData(Map<String, dynamic>? value) {
    _$currentEnigmaDataAtom.reportWrite(value, super.currentEnigmaData, () {
      super.currentEnigmaData = value;
    });
  }

  late final _$currentEnigmaIdAtom = Atom(
    name: '_FindAndWinStore.currentEnigmaId',
    context: context,
  );

  @override
  String? get currentEnigmaId {
    _$currentEnigmaIdAtom.reportRead();
    return super.currentEnigmaId;
  }

  @override
  set currentEnigmaId(String? value) {
    _$currentEnigmaIdAtom.reportWrite(value, super.currentEnigmaId, () {
      super.currentEnigmaId = value;
    });
  }

  late final _$eventStatusAtom = Atom(
    name: '_FindAndWinStore.eventStatus',
    context: context,
  );

  @override
  String? get eventStatus {
    _$eventStatusAtom.reportRead();
    return super.eventStatus;
  }

  @override
  set eventStatus(String? value) {
    _$eventStatusAtom.reportWrite(value, super.eventStatus, () {
      super.eventStatus = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_FindAndWinStore.errorMessage',
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

  late final _$cooldownUntilAtom = Atom(
    name: '_FindAndWinStore.cooldownUntil',
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

  late final _$successAtom = Atom(
    name: '_FindAndWinStore.success',
    context: context,
  );

  @override
  bool get success {
    _$successAtom.reportRead();
    return super.success;
  }

  @override
  set success(bool value) {
    _$successAtom.reportWrite(value, super.success, () {
      super.success = value;
    });
  }

  late final _$validateCodeAsyncAction = AsyncAction(
    '_FindAndWinStore.validateCode',
    context: context,
  );

  @override
  Future<void> validateCode(String eventId, String enigmaId, String code) {
    return _$validateCodeAsyncAction.run(
      () => super.validateCode(eventId, enigmaId, code),
    );
  }

  late final _$_FindAndWinStoreActionController = ActionController(
    name: '_FindAndWinStore',
    context: context,
  );

  @override
  void init(String eventId) {
    final _$actionInfo = _$_FindAndWinStoreActionController.startAction(
      name: '_FindAndWinStore.init',
    );
    try {
      return super.init(eventId);
    } finally {
      _$_FindAndWinStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setBlocked(bool value) {
    final _$actionInfo = _$_FindAndWinStoreActionController.startAction(
      name: '_FindAndWinStore.setBlocked',
    );
    try {
      return super.setBlocked(value);
    } finally {
      _$_FindAndWinStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetSuccess() {
    final _$actionInfo = _$_FindAndWinStoreActionController.startAction(
      name: '_FindAndWinStore.resetSuccess',
    );
    try {
      return super.resetSuccess();
    } finally {
      _$_FindAndWinStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetError() {
    final _$actionInfo = _$_FindAndWinStoreActionController.startAction(
      name: '_FindAndWinStore.resetError',
    );
    try {
      return super.resetError();
    } finally {
      _$_FindAndWinStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
isBlocked: ${isBlocked},
eventData: ${eventData},
currentEnigmaData: ${currentEnigmaData},
currentEnigmaId: ${currentEnigmaId},
eventStatus: ${eventStatus},
errorMessage: ${errorMessage},
cooldownUntil: ${cooldownUntil},
success: ${success}
    ''';
  }
}
