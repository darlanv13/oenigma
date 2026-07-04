#!/bin/bash
sed -i 's/await FirebaseAuth.instance.signOut();/ref.read(authRepositoryProvider).signOut();/' lib/features/admin/screens/main_admin_screen.dart
sed -i '12i import '\''package:oenigma/features/auth/providers/auth_provider.dart'\'';' lib/features/admin/screens/main_admin_screen.dart
