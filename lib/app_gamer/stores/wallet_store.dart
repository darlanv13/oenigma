import 'package:mobx/mobx.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';

part 'wallet_store.g.dart';

class WalletStore = _WalletStore with _$WalletStore;

abstract class _WalletStore with Store {
  @observable
  double balance = 0.0;

  StreamSubscription<DocumentSnapshot>? _balanceSubscription;

  // Payment state
  @observable
  bool paymentLoading = false;

  @observable
  String? paymentError;

  @observable
  String? qrCodeBase64;

  @observable
  String? copiaCola;

  @observable
  String? txid;

  @action
  void initBalanceStream(String uid) {
    _balanceSubscription?.cancel();
    _balanceSubscription = FirebaseFirestore.instance
        .collection('players')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>;
            if (data['balance'] != null) {
              setBalance((data['balance'] as num).toDouble());
            }
          }
        });
  }

  @action
  void setBalance(double value) {
    balance = value;
  }

  @action
  Future<void> initiatePayment(double amount) async {
    paymentLoading = true;
    paymentError = null;
    qrCodeBase64 = null;
    copiaCola = null;
    txid = null;

    try {
      final result = await FirebaseFunctions.instanceFor(
        region: 'southamerica-east1',
      ).httpsCallable('createPixCharge').call({'amount': amount});

      final data = result.data as Map<dynamic, dynamic>;
      qrCodeBase64 = data['qrCodeImage'];
      copiaCola = data['copiaCola'];
      txid = data['txid'];
    } catch (e) {
      paymentError = e.toString();
    } finally {
      paymentLoading = false;
    }
  }

  void dispose() {
    _balanceSubscription?.cancel();
  }
}
