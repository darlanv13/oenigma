// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enigma_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$EnigmaStore on _EnigmaStore, Store {
  Computed<bool>? _$isValidComputed;

  @override
  bool get isValid => (_$isValidComputed ??= Computed<bool>(
    () => super.isValid,
    name: '_EnigmaStore.isValid',
  )).value;
  Computed<bool>? _$hasLocationComputed;

  @override
  bool get hasLocation => (_$hasLocationComputed ??= Computed<bool>(
    () => super.hasLocation,
    name: '_EnigmaStore.hasLocation',
  )).value;

  late final _$instructionAtom = Atom(
    name: '_EnigmaStore.instruction',
    context: context,
  );

  @override
  String get instruction {
    _$instructionAtom.reportRead();
    return super.instruction;
  }

  @override
  set instruction(String value) {
    _$instructionAtom.reportWrite(value, super.instruction, () {
      super.instruction = value;
    });
  }

  late final _$codeAtom = Atom(name: '_EnigmaStore.code', context: context);

  @override
  String get code {
    _$codeAtom.reportRead();
    return super.code;
  }

  @override
  set code(String value) {
    _$codeAtom.reportWrite(value, super.code, () {
      super.code = value;
    });
  }

  late final _$imageUrlAtom = Atom(
    name: '_EnigmaStore.imageUrl',
    context: context,
  );

  @override
  String get imageUrl {
    _$imageUrlAtom.reportRead();
    return super.imageUrl;
  }

  @override
  set imageUrl(String value) {
    _$imageUrlAtom.reportWrite(value, super.imageUrl, () {
      super.imageUrl = value;
    });
  }

  late final _$typeAtom = Atom(name: '_EnigmaStore.type', context: context);

  @override
  String get type {
    _$typeAtom.reportRead();
    return super.type;
  }

  @override
  set type(String value) {
    _$typeAtom.reportWrite(value, super.type, () {
      super.type = value;
    });
  }

  late final _$locationAtom = Atom(
    name: '_EnigmaStore.location',
    context: context,
  );

  @override
  LatLng? get location {
    _$locationAtom.reportRead();
    return super.location;
  }

  @override
  set location(LatLng? value) {
    _$locationAtom.reportWrite(value, super.location, () {
      super.location = value;
    });
  }

  late final _$hintTypeAtom = Atom(
    name: '_EnigmaStore.hintType',
    context: context,
  );

  @override
  String? get hintType {
    _$hintTypeAtom.reportRead();
    return super.hintType;
  }

  @override
  set hintType(String? value) {
    _$hintTypeAtom.reportWrite(value, super.hintType, () {
      super.hintType = value;
    });
  }

  late final _$hintDataAtom = Atom(
    name: '_EnigmaStore.hintData',
    context: context,
  );

  @override
  String get hintData {
    _$hintDataAtom.reportRead();
    return super.hintData;
  }

  @override
  set hintData(String value) {
    _$hintDataAtom.reportWrite(value, super.hintData, () {
      super.hintData = value;
    });
  }

  late final _$hintPriceAtom = Atom(
    name: '_EnigmaStore.hintPrice',
    context: context,
  );

  @override
  double get hintPrice {
    _$hintPriceAtom.reportRead();
    return super.hintPrice;
  }

  @override
  set hintPrice(double value) {
    _$hintPriceAtom.reportWrite(value, super.hintPrice, () {
      super.hintPrice = value;
    });
  }

  late final _$prizeAtom = Atom(name: '_EnigmaStore.prize', context: context);

  @override
  double get prize {
    _$prizeAtom.reportRead();
    return super.prize;
  }

  @override
  set prize(double value) {
    _$prizeAtom.reportWrite(value, super.prize, () {
      super.prize = value;
    });
  }

  late final _$orderAtom = Atom(name: '_EnigmaStore.order', context: context);

  @override
  int get order {
    _$orderAtom.reportRead();
    return super.order;
  }

  @override
  set order(int value) {
    _$orderAtom.reportWrite(value, super.order, () {
      super.order = value;
    });
  }

  late final _$isUploadingAtom = Atom(
    name: '_EnigmaStore.isUploading',
    context: context,
  );

  @override
  bool get isUploading {
    _$isUploadingAtom.reportRead();
    return super.isUploading;
  }

  @override
  set isUploading(bool value) {
    _$isUploadingAtom.reportWrite(value, super.isUploading, () {
      super.isUploading = value;
    });
  }

  late final _$isSavingAtom = Atom(
    name: '_EnigmaStore.isSaving',
    context: context,
  );

  @override
  bool get isSaving {
    _$isSavingAtom.reportRead();
    return super.isSaving;
  }

  @override
  set isSaving(bool value) {
    _$isSavingAtom.reportWrite(value, super.isSaving, () {
      super.isSaving = value;
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

  late final _$saveEnigmaAsyncAction = AsyncAction(
    '_EnigmaStore.saveEnigma',
    context: context,
  );

  @override
  Future<bool> saveEnigma(String eventId, String? phaseId, String? enigmaId) {
    return _$saveEnigmaAsyncAction.run(
      () => super.saveEnigma(eventId, phaseId, enigmaId),
    );
  }

  late final _$_EnigmaStoreActionController = ActionController(
    name: '_EnigmaStore',
    context: context,
  );

  @override
  void setInstruction(String value) {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.setInstruction',
    );
    try {
      return super.setInstruction(value);
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCode(String value) {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.setCode',
    );
    try {
      return super.setCode(value);
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setImageUrl(String value) {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.setImageUrl',
    );
    try {
      return super.setImageUrl(value);
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setType(String value) {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.setType',
    );
    try {
      return super.setType(value);
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setLocation(LatLng? value) {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.setLocation',
    );
    try {
      return super.setLocation(value);
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setHintType(String? value) {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.setHintType',
    );
    try {
      return super.setHintType(value);
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setHintData(String value) {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.setHintData',
    );
    try {
      return super.setHintData(value);
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setHintPrice(String value) {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.setHintPrice',
    );
    try {
      return super.setHintPrice(value);
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPrize(String value) {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.setPrize',
    );
    try {
      return super.setPrize(value);
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setOrder(String value) {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.setOrder',
    );
    try {
      return super.setOrder(value);
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setIsUploading(bool value) {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.setIsUploading',
    );
    try {
      return super.setIsUploading(value);
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void loadFromModel(EnigmaModel enigma) {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.loadFromModel',
    );
    try {
      return super.loadFromModel(enigma);
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clear() {
    final _$actionInfo = _$_EnigmaStoreActionController.startAction(
      name: '_EnigmaStore.clear',
    );
    try {
      return super.clear();
    } finally {
      _$_EnigmaStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
instruction: ${instruction},
code: ${code},
imageUrl: ${imageUrl},
type: ${type},
location: ${location},
hintType: ${hintType},
hintData: ${hintData},
hintPrice: ${hintPrice},
prize: ${prize},
order: ${order},
isUploading: ${isUploading},
isSaving: ${isSaving},
errorMessage: ${errorMessage},
isValid: ${isValid},
hasLocation: ${hasLocation}
    ''';
  }
}
