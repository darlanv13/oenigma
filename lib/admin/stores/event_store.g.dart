// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$EventStore on _EventStore, Store {
  Computed<bool>? _$isValidComputed;

  @override
  bool get isValid => (_$isValidComputed ??= Computed<bool>(
    () => super.isValid,
    name: '_EventStore.isValid',
  )).value;

  late final _$nameAtom = Atom(name: '_EventStore.name', context: context);

  @override
  String get name {
    _$nameAtom.reportRead();
    return super.name;
  }

  @override
  set name(String value) {
    _$nameAtom.reportWrite(value, super.name, () {
      super.name = value;
    });
  }

  late final _$prizeAtom = Atom(name: '_EventStore.prize', context: context);

  @override
  String get prize {
    _$prizeAtom.reportRead();
    return super.prize;
  }

  @override
  set prize(String value) {
    _$prizeAtom.reportWrite(value, super.prize, () {
      super.prize = value;
    });
  }

  late final _$priceAtom = Atom(name: '_EventStore.price', context: context);

  @override
  double get price {
    _$priceAtom.reportRead();
    return super.price;
  }

  @override
  set price(double value) {
    _$priceAtom.reportWrite(value, super.price, () {
      super.price = value;
    });
  }

  late final _$iconUrlAtom = Atom(
    name: '_EventStore.iconUrl',
    context: context,
  );

  @override
  String get iconUrl {
    _$iconUrlAtom.reportRead();
    return super.iconUrl;
  }

  @override
  set iconUrl(String value) {
    _$iconUrlAtom.reportWrite(value, super.iconUrl, () {
      super.iconUrl = value;
    });
  }

  late final _$descriptionAtom = Atom(
    name: '_EventStore.description',
    context: context,
  );

  @override
  String get description {
    _$descriptionAtom.reportRead();
    return super.description;
  }

  @override
  set description(String value) {
    _$descriptionAtom.reportWrite(value, super.description, () {
      super.description = value;
    });
  }

  late final _$locationAtom = Atom(
    name: '_EventStore.location',
    context: context,
  );

  @override
  String get location {
    _$locationAtom.reportRead();
    return super.location;
  }

  @override
  set location(String value) {
    _$locationAtom.reportWrite(value, super.location, () {
      super.location = value;
    });
  }

  late final _$startDateAtom = Atom(
    name: '_EventStore.startDate',
    context: context,
  );

  @override
  String get startDate {
    _$startDateAtom.reportRead();
    return super.startDate;
  }

  @override
  set startDate(String value) {
    _$startDateAtom.reportWrite(value, super.startDate, () {
      super.startDate = value;
    });
  }

  late final _$eventTypeAtom = Atom(
    name: '_EventStore.eventType',
    context: context,
  );

  @override
  String get eventType {
    _$eventTypeAtom.reportRead();
    return super.eventType;
  }

  @override
  set eventType(String value) {
    _$eventTypeAtom.reportWrite(value, super.eventType, () {
      super.eventType = value;
    });
  }

  late final _$statusAtom = Atom(name: '_EventStore.status', context: context);

  @override
  String get status {
    _$statusAtom.reportRead();
    return super.status;
  }

  @override
  set status(String value) {
    _$statusAtom.reportWrite(value, super.status, () {
      super.status = value;
    });
  }

  late final _$isSavingAtom = Atom(
    name: '_EventStore.isSaving',
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

  late final _$saveEventAsyncAction = AsyncAction(
    '_EventStore.saveEvent',
    context: context,
  );

  @override
  Future<bool> saveEvent(String? eventId) {
    return _$saveEventAsyncAction.run(() => super.saveEvent(eventId));
  }

  late final _$_EventStoreActionController = ActionController(
    name: '_EventStore',
    context: context,
  );

  @override
  void setName(String val) {
    final _$actionInfo = _$_EventStoreActionController.startAction(
      name: '_EventStore.setName',
    );
    try {
      return super.setName(val);
    } finally {
      _$_EventStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPrize(String val) {
    final _$actionInfo = _$_EventStoreActionController.startAction(
      name: '_EventStore.setPrize',
    );
    try {
      return super.setPrize(val);
    } finally {
      _$_EventStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPrice(String val) {
    final _$actionInfo = _$_EventStoreActionController.startAction(
      name: '_EventStore.setPrice',
    );
    try {
      return super.setPrice(val);
    } finally {
      _$_EventStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setIconUrl(String val) {
    final _$actionInfo = _$_EventStoreActionController.startAction(
      name: '_EventStore.setIconUrl',
    );
    try {
      return super.setIconUrl(val);
    } finally {
      _$_EventStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDescription(String val) {
    final _$actionInfo = _$_EventStoreActionController.startAction(
      name: '_EventStore.setDescription',
    );
    try {
      return super.setDescription(val);
    } finally {
      _$_EventStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setLocation(String val) {
    final _$actionInfo = _$_EventStoreActionController.startAction(
      name: '_EventStore.setLocation',
    );
    try {
      return super.setLocation(val);
    } finally {
      _$_EventStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setStartDate(String val) {
    final _$actionInfo = _$_EventStoreActionController.startAction(
      name: '_EventStore.setStartDate',
    );
    try {
      return super.setStartDate(val);
    } finally {
      _$_EventStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEventType(String val) {
    final _$actionInfo = _$_EventStoreActionController.startAction(
      name: '_EventStore.setEventType',
    );
    try {
      return super.setEventType(val);
    } finally {
      _$_EventStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setStatus(String val) {
    final _$actionInfo = _$_EventStoreActionController.startAction(
      name: '_EventStore.setStatus',
    );
    try {
      return super.setStatus(val);
    } finally {
      _$_EventStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void loadFromModel(EventModel event) {
    final _$actionInfo = _$_EventStoreActionController.startAction(
      name: '_EventStore.loadFromModel',
    );
    try {
      return super.loadFromModel(event);
    } finally {
      _$_EventStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
name: ${name},
prize: ${prize},
price: ${price},
iconUrl: ${iconUrl},
description: ${description},
location: ${location},
startDate: ${startDate},
eventType: ${eventType},
status: ${status},
isSaving: ${isSaving},
errorMessage: ${errorMessage},
isValid: ${isValid}
    ''';
  }
}
