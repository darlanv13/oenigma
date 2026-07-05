#!/bin/bash

# Fix Parse Cloud Function call syntax
sed -i "s/ParseCloudFunction(functionName).execute(parameters: {'uid': uid});/ParseCloudFunction(functionName).execute(parameters: {'uid': uid});/" lib/features/admin/screens/admin_users_screen.dart
sed -i "s/ParseCloudFunction('listAllUsers').execute();/ParseCloudFunction('listAllUsers').execute();/" lib/features/admin/screens/admin_users_screen.dart

# Fix dangling parenthesis/bracket errors on Fraud Screen
sed -i '42,43s/.*;//g' lib/features/admin/screens/admin_fraud_screen.dart
