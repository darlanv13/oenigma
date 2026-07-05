#!/bin/bash
# Remove escape characters from string interpolation

sed -i "s/Text('\\\$email\\\${isAdmin ? \" • Admin\" : \"\"}'/Text('\$email\${isAdmin ? \" • Admin\" : \"\"}'/" lib/features/admin/screens/admin_users_screen.dart
sed -i "s/Text('Erro ao carregar usuários: \\\\\${snapshot.error}'/Text('Erro ao carregar usuários: \${snapshot.error}'/" lib/features/admin/screens/admin_users_screen.dart
sed -i "s/SnackBar(content: Text('Erro ao atualizar admin: \\\$e'))/SnackBar(content: Text('Erro ao atualizar admin: \$e'))/" lib/features/admin/screens/admin_users_screen.dart

sed -i "s/Text('Ordem: \\\$order - \\\\\${isActive ? \"Ativo\" : \"Inativo\"}'/Text('Ordem: \$order - \${isActive ? \"Ativo\" : \"Inativo\"}'/" lib/features/admin/screens/admin_banners_screen.dart
sed -i "s/Text('Link: \\\$actionUrl'/Text('Link: \$actionUrl'/" lib/features/admin/screens/admin_banners_screen.dart
sed -i "s/SnackBar(content: Text('Erro: \\\$e'))/SnackBar(content: Text('Erro: \$e'))/" lib/features/admin/screens/admin_banners_screen.dart

sed -i "s/Text('Tipo: \\\$type\\\nConteúdo: \\\$content'/Text('Tipo: \$type\\\nConteúdo: \$content'/" lib/features/admin/screens/admin_tools_screen.dart
sed -i "s/SnackBar(content: Text('Erro: \\\$e'))/SnackBar(content: Text('Erro: \$e'))/" lib/features/admin/screens/admin_tools_screen.dart

sed -i "s/Text('Valor: R\\\$ \\\$amount - Chave: \\\$pixKey (\\\$pixKeyType)'/Text('Valor: R\$ \$amount - Chave: \$pixKey (\$pixKeyType)'/" lib/features/admin/screens/admin_finance_screen.dart
sed -i "s/Text('UID: \\\$uid\\\nData da Solicitação: \\\$dateStr'/Text('UID: \$uid\\\nData da Solicitação: \$dateStr'/" lib/features/admin/screens/admin_finance_screen.dart
sed -i "s/SnackBar(content: Text('Saque processado com sucesso: \\\$action'))/SnackBar(content: Text('Saque processado com sucesso: \$action'))/" lib/features/admin/screens/admin_finance_screen.dart
sed -i "s/SnackBar(content: Text('Erro ao processar saque: \\\$e')/SnackBar(content: Text('Erro ao processar saque: \$e')/" lib/features/admin/screens/admin_finance_screen.dart

sed -i "s/Text('Usuário: \\\$uid'/Text('Usuário: \$uid'/" lib/features/admin/screens/admin_fraud_screen.dart
sed -i "s/Text('Alerta: \\\$reason'/Text('Alerta: \$reason'/" lib/features/admin/screens/admin_fraud_screen.dart
sed -i "s/Text('Evento ID: \\\$eventId'/Text('Evento ID: \$eventId'/" lib/features/admin/screens/admin_fraud_screen.dart
sed -i "s/Text('Data: \\\$dateStr'/Text('Data: \$dateStr'/" lib/features/admin/screens/admin_fraud_screen.dart
