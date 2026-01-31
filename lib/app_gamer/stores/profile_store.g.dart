// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ProfileStore on _ProfileStore, Store {
  late final _$isLoadingAtom = Atom(
    name: '_ProfileStore.isLoading',
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

  late final _$playerDataAtom = Atom(
    name: '_ProfileStore.playerData',
    context: context,
  );

  @override
  Map<String, dynamic>? get playerData {
    _$playerDataAtom.reportRead();
    return super.playerData;
  }

  @override
  set playerData(Map<String, dynamic>? value) {
    _$playerDataAtom.reportWrite(value, super.playerData, () {
      super.playerData = value;
    });
  }

  late final _$walletDataAtom = Atom(
    name: '_ProfileStore.walletData',
    context: context,
  );

  @override
  UserWalletModel? get walletData {
    _$walletDataAtom.reportRead();
    return super.walletData;
  }

  @override
  set walletData(UserWalletModel? value) {
    _$walletDataAtom.reportWrite(value, super.walletData, () {
      super.walletData = value;
    });
  }

  late final _$fetchMissingDataAsyncAction = AsyncAction(
    '_ProfileStore.fetchMissingData',
    context: context,
  );

  @override
  Future<void> fetchMissingData() {
    return _$fetchMissingDataAsyncAction.run(() => super.fetchMissingData());
  }

  late final _$_ProfileStoreActionController = ActionController(
    name: '_ProfileStore',
    context: context,
  );

  @override
  void setInitialData({Map<String, dynamic>? player, UserWalletModel? wallet}) {
    final _$actionInfo = _$_ProfileStoreActionController.startAction(
      name: '_ProfileStore.setInitialData',
    );
    try {
      return super.setInitialData(player: player, wallet: wallet);
    } finally {
      _$_ProfileStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
playerData: ${playerData},
walletData: ${walletData}
    ''';
  }
}
