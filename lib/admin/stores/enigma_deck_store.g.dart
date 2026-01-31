// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enigma_deck_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$EnigmaDeckStore on _EnigmaDeckStore, Store {
  late final _$enigmasAtom = Atom(
    name: '_EnigmaDeckStore.enigmas',
    context: context,
  );

  @override
  ObservableList<EnigmaModel> get enigmas {
    _$enigmasAtom.reportRead();
    return super.enigmas;
  }

  @override
  set enigmas(ObservableList<EnigmaModel> value) {
    _$enigmasAtom.reportWrite(value, super.enigmas, () {
      super.enigmas = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: '_EnigmaDeckStore.isLoading',
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

  late final _$loadEnigmasAsyncAction = AsyncAction(
    '_EnigmaDeckStore.loadEnigmas',
    context: context,
  );

  @override
  Future<void> loadEnigmas(String eventId, String? phaseId) {
    return _$loadEnigmasAsyncAction.run(
      () => super.loadEnigmas(eventId, phaseId),
    );
  }

  late final _$deleteEnigmaAsyncAction = AsyncAction(
    '_EnigmaDeckStore.deleteEnigma',
    context: context,
  );

  @override
  Future<void> deleteEnigma(String eventId, String? phaseId, String enigmaId) {
    return _$deleteEnigmaAsyncAction.run(
      () => super.deleteEnigma(eventId, phaseId, enigmaId),
    );
  }

  @override
  String toString() {
    return '''
enigmas: ${enigmas},
isLoading: ${isLoading}
    ''';
  }
}
