// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$WalletStore on _WalletStore, Store {
  late final _$balanceAtom = Atom(
    name: '_WalletStore.balance',
    context: context,
  );

  @override
  double get balance {
    _$balanceAtom.reportRead();
    return super.balance;
  }

  @override
  set balance(double value) {
    _$balanceAtom.reportWrite(value, super.balance, () {
      super.balance = value;
    });
  }

  late final _$paymentLoadingAtom = Atom(
    name: '_WalletStore.paymentLoading',
    context: context,
  );

  @override
  bool get paymentLoading {
    _$paymentLoadingAtom.reportRead();
    return super.paymentLoading;
  }

  @override
  set paymentLoading(bool value) {
    _$paymentLoadingAtom.reportWrite(value, super.paymentLoading, () {
      super.paymentLoading = value;
    });
  }

  late final _$paymentErrorAtom = Atom(
    name: '_WalletStore.paymentError',
    context: context,
  );

  @override
  String? get paymentError {
    _$paymentErrorAtom.reportRead();
    return super.paymentError;
  }

  @override
  set paymentError(String? value) {
    _$paymentErrorAtom.reportWrite(value, super.paymentError, () {
      super.paymentError = value;
    });
  }

  late final _$qrCodeBase64Atom = Atom(
    name: '_WalletStore.qrCodeBase64',
    context: context,
  );

  @override
  String? get qrCodeBase64 {
    _$qrCodeBase64Atom.reportRead();
    return super.qrCodeBase64;
  }

  @override
  set qrCodeBase64(String? value) {
    _$qrCodeBase64Atom.reportWrite(value, super.qrCodeBase64, () {
      super.qrCodeBase64 = value;
    });
  }

  late final _$copiaColaAtom = Atom(
    name: '_WalletStore.copiaCola',
    context: context,
  );

  @override
  String? get copiaCola {
    _$copiaColaAtom.reportRead();
    return super.copiaCola;
  }

  @override
  set copiaCola(String? value) {
    _$copiaColaAtom.reportWrite(value, super.copiaCola, () {
      super.copiaCola = value;
    });
  }

  late final _$txidAtom = Atom(name: '_WalletStore.txid', context: context);

  @override
  String? get txid {
    _$txidAtom.reportRead();
    return super.txid;
  }

  @override
  set txid(String? value) {
    _$txidAtom.reportWrite(value, super.txid, () {
      super.txid = value;
    });
  }

  late final _$initiatePaymentAsyncAction = AsyncAction(
    '_WalletStore.initiatePayment',
    context: context,
  );

  @override
  Future<void> initiatePayment(double amount) {
    return _$initiatePaymentAsyncAction.run(
      () => super.initiatePayment(amount),
    );
  }

  late final _$_WalletStoreActionController = ActionController(
    name: '_WalletStore',
    context: context,
  );

  @override
  void initBalanceStream(String uid) {
    final _$actionInfo = _$_WalletStoreActionController.startAction(
      name: '_WalletStore.initBalanceStream',
    );
    try {
      return super.initBalanceStream(uid);
    } finally {
      _$_WalletStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setBalance(double value) {
    final _$actionInfo = _$_WalletStoreActionController.startAction(
      name: '_WalletStore.setBalance',
    );
    try {
      return super.setBalance(value);
    } finally {
      _$_WalletStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
balance: ${balance},
paymentLoading: ${paymentLoading},
paymentError: ${paymentError},
qrCodeBase64: ${qrCodeBase64},
copiaCola: ${copiaCola},
txid: ${txid}
    ''';
  }
}
