// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phase_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PhaseStore on _PhaseStore, Store {
  late final _$phasesAtom = Atom(name: '_PhaseStore.phases', context: context);

  @override
  ObservableList<PhaseModel> get phases {
    _$phasesAtom.reportRead();
    return super.phases;
  }

  @override
  set phases(ObservableList<PhaseModel> value) {
    _$phasesAtom.reportWrite(value, super.phases, () {
      super.phases = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: '_PhaseStore.isLoading',
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

  late final _$loadPhasesAsyncAction = AsyncAction(
    '_PhaseStore.loadPhases',
    context: context,
  );

  @override
  Future<void> loadPhases(String eventId) {
    return _$loadPhasesAsyncAction.run(() => super.loadPhases(eventId));
  }

  late final _$addPhaseAsyncAction = AsyncAction(
    '_PhaseStore.addPhase',
    context: context,
  );

  @override
  Future<void> addPhase(String eventId) {
    return _$addPhaseAsyncAction.run(() => super.addPhase(eventId));
  }

  late final _$deletePhaseAsyncAction = AsyncAction(
    '_PhaseStore.deletePhase',
    context: context,
  );

  @override
  Future<void> deletePhase(String eventId, String phaseId) {
    return _$deletePhaseAsyncAction.run(
      () => super.deletePhase(eventId, phaseId),
    );
  }

  late final _$reorderPhasesAsyncAction = AsyncAction(
    '_PhaseStore.reorderPhases',
    context: context,
  );

  @override
  Future<void> reorderPhases(String eventId, int oldIndex, int newIndex) {
    return _$reorderPhasesAsyncAction.run(
      () => super.reorderPhases(eventId, oldIndex, newIndex),
    );
  }

  @override
  String toString() {
    return '''
phases: ${phases},
isLoading: ${isLoading}
    ''';
  }
}
