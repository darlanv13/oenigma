// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SignUpStore on _SignUpStore, Store {
  late final _$nameAtom = Atom(name: '_SignUpStore.name', context: context);

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

  late final _$emailAtom = Atom(name: '_SignUpStore.email', context: context);

  @override
  String get email {
    _$emailAtom.reportRead();
    return super.email;
  }

  @override
  set email(String value) {
    _$emailAtom.reportWrite(value, super.email, () {
      super.email = value;
    });
  }

  late final _$passwordAtom = Atom(
    name: '_SignUpStore.password',
    context: context,
  );

  @override
  String get password {
    _$passwordAtom.reportRead();
    return super.password;
  }

  @override
  set password(String value) {
    _$passwordAtom.reportWrite(value, super.password, () {
      super.password = value;
    });
  }

  late final _$confirmPasswordAtom = Atom(
    name: '_SignUpStore.confirmPassword',
    context: context,
  );

  @override
  String get confirmPassword {
    _$confirmPasswordAtom.reportRead();
    return super.confirmPassword;
  }

  @override
  set confirmPassword(String value) {
    _$confirmPasswordAtom.reportWrite(value, super.confirmPassword, () {
      super.confirmPassword = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: '_SignUpStore.isLoading',
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

  late final _$isPasswordVisibleAtom = Atom(
    name: '_SignUpStore.isPasswordVisible',
    context: context,
  );

  @override
  bool get isPasswordVisible {
    _$isPasswordVisibleAtom.reportRead();
    return super.isPasswordVisible;
  }

  @override
  set isPasswordVisible(bool value) {
    _$isPasswordVisibleAtom.reportWrite(value, super.isPasswordVisible, () {
      super.isPasswordVisible = value;
    });
  }

  late final _$isConfirmPasswordVisibleAtom = Atom(
    name: '_SignUpStore.isConfirmPasswordVisible',
    context: context,
  );

  @override
  bool get isConfirmPasswordVisible {
    _$isConfirmPasswordVisibleAtom.reportRead();
    return super.isConfirmPasswordVisible;
  }

  @override
  set isConfirmPasswordVisible(bool value) {
    _$isConfirmPasswordVisibleAtom.reportWrite(
      value,
      super.isConfirmPasswordVisible,
      () {
        super.isConfirmPasswordVisible = value;
      },
    );
  }

  late final _$errorMessageAtom = Atom(
    name: '_SignUpStore.errorMessage',
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

  late final _$successAtom = Atom(
    name: '_SignUpStore.success',
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

  late final _$signUpAsyncAction = AsyncAction(
    '_SignUpStore.signUp',
    context: context,
  );

  @override
  Future<void> signUp() {
    return _$signUpAsyncAction.run(() => super.signUp());
  }

  late final _$_SignUpStoreActionController = ActionController(
    name: '_SignUpStore',
    context: context,
  );

  @override
  void setName(String value) {
    final _$actionInfo = _$_SignUpStoreActionController.startAction(
      name: '_SignUpStore.setName',
    );
    try {
      return super.setName(value);
    } finally {
      _$_SignUpStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEmail(String value) {
    final _$actionInfo = _$_SignUpStoreActionController.startAction(
      name: '_SignUpStore.setEmail',
    );
    try {
      return super.setEmail(value);
    } finally {
      _$_SignUpStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPassword(String value) {
    final _$actionInfo = _$_SignUpStoreActionController.startAction(
      name: '_SignUpStore.setPassword',
    );
    try {
      return super.setPassword(value);
    } finally {
      _$_SignUpStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setConfirmPassword(String value) {
    final _$actionInfo = _$_SignUpStoreActionController.startAction(
      name: '_SignUpStore.setConfirmPassword',
    );
    try {
      return super.setConfirmPassword(value);
    } finally {
      _$_SignUpStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void togglePasswordVisibility() {
    final _$actionInfo = _$_SignUpStoreActionController.startAction(
      name: '_SignUpStore.togglePasswordVisibility',
    );
    try {
      return super.togglePasswordVisibility();
    } finally {
      _$_SignUpStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleConfirmPasswordVisibility() {
    final _$actionInfo = _$_SignUpStoreActionController.startAction(
      name: '_SignUpStore.toggleConfirmPasswordVisibility',
    );
    try {
      return super.toggleConfirmPasswordVisibility();
    } finally {
      _$_SignUpStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
name: ${name},
email: ${email},
password: ${password},
confirmPassword: ${confirmPassword},
isLoading: ${isLoading},
isPasswordVisible: ${isPasswordVisible},
isConfirmPasswordVisible: ${isConfirmPasswordVisible},
errorMessage: ${errorMessage},
success: ${success}
    ''';
  }
}
