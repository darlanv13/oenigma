// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_progress_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$EventProgressStore on _EventProgressStore, Store {
  late final _$isLoadingAtom = Atom(
    name: '_EventProgressStore.isLoading',
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

  late final _$phasesAtom = Atom(
    name: '_EventProgressStore.phases',
    context: context,
  );

  @override
  List<PhaseModel> get phases {
    _$phasesAtom.reportRead();
    return super.phases;
  }

  @override
  set phases(List<PhaseModel> value) {
    _$phasesAtom.reportWrite(value, super.phases, () {
      super.phases = value;
    });
  }

  late final _$currentPhaseAtom = Atom(
    name: '_EventProgressStore.currentPhase',
    context: context,
  );

  @override
  int get currentPhase {
    _$currentPhaseAtom.reportRead();
    return super.currentPhase;
  }

  @override
  set currentPhase(int value) {
    _$currentPhaseAtom.reportWrite(value, super.currentPhase, () {
      super.currentPhase = value;
    });
  }

  late final _$currentEnigmaAtom = Atom(
    name: '_EventProgressStore.currentEnigma',
    context: context,
  );

  @override
  int get currentEnigma {
    _$currentEnigmaAtom.reportRead();
    return super.currentEnigma;
  }

  @override
  set currentEnigma(int value) {
    _$currentEnigmaAtom.reportWrite(value, super.currentEnigma, () {
      super.currentEnigma = value;
    });
  }

  late final _$markersAtom = Atom(
    name: '_EventProgressStore.markers',
    context: context,
  );

  @override
  Set<Marker> get markers {
    _$markersAtom.reportRead();
    return super.markers;
  }

  @override
  set markers(Set<Marker> value) {
    _$markersAtom.reportWrite(value, super.markers, () {
      super.markers = value;
    });
  }

  late final _$polylinesAtom = Atom(
    name: '_EventProgressStore.polylines',
    context: context,
  );

  @override
  Set<Polyline> get polylines {
    _$polylinesAtom.reportRead();
    return super.polylines;
  }

  @override
  set polylines(Set<Polyline> value) {
    _$polylinesAtom.reportWrite(value, super.polylines, () {
      super.polylines = value;
    });
  }

  late final _$userLocationAtom = Atom(
    name: '_EventProgressStore.userLocation',
    context: context,
  );

  @override
  LocationData? get userLocation {
    _$userLocationAtom.reportRead();
    return super.userLocation;
  }

  @override
  set userLocation(LocationData? value) {
    _$userLocationAtom.reportWrite(value, super.userLocation, () {
      super.userLocation = value;
    });
  }

  late final _$selectedPhaseToNavigateAtom = Atom(
    name: '_EventProgressStore.selectedPhaseToNavigate',
    context: context,
  );

  @override
  PhaseModel? get selectedPhaseToNavigate {
    _$selectedPhaseToNavigateAtom.reportRead();
    return super.selectedPhaseToNavigate;
  }

  @override
  set selectedPhaseToNavigate(PhaseModel? value) {
    _$selectedPhaseToNavigateAtom.reportWrite(
      value,
      super.selectedPhaseToNavigate,
      () {
        super.selectedPhaseToNavigate = value;
      },
    );
  }

  late final _$initDataAsyncAction = AsyncAction(
    '_EventProgressStore.initData',
    context: context,
  );

  @override
  Future<void> initData(String eventId) {
    return _$initDataAsyncAction.run(() => super.initData(eventId));
  }

  late final _$_EventProgressStoreActionController = ActionController(
    name: '_EventProgressStore',
    context: context,
  );

  @override
  void _buildMapElements() {
    final _$actionInfo = _$_EventProgressStoreActionController.startAction(
      name: '_EventProgressStore._buildMapElements',
    );
    try {
      return super._buildMapElements();
    } finally {
      _$_EventProgressStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectPhase(PhaseModel phase) {
    final _$actionInfo = _$_EventProgressStoreActionController.startAction(
      name: '_EventProgressStore.selectPhase',
    );
    try {
      return super.selectPhase(phase);
    } finally {
      _$_EventProgressStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearSelectedPhase() {
    final _$actionInfo = _$_EventProgressStoreActionController.startAction(
      name: '_EventProgressStore.clearSelectedPhase',
    );
    try {
      return super.clearSelectedPhase();
    } finally {
      _$_EventProgressStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
phases: ${phases},
currentPhase: ${currentPhase},
currentEnigma: ${currentEnigma},
markers: ${markers},
polylines: ${polylines},
userLocation: ${userLocation},
selectedPhaseToNavigate: ${selectedPhaseToNavigate}
    ''';
  }
}
