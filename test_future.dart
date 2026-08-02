import 'dart:async';

void main() async {
  Future<String> myFuture;
  void _load() async {
    // simulate async work before assigning future
    await Future.delayed(Duration(milliseconds: 10));
    myFuture = Future.value("test");
  }
  _load();

  try {
    print(myFuture);
  } catch (e) {
    print(e);
  }
}
