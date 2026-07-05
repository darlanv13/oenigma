#!/bin/bash
# Users Screen
sed -i "s/import 'package:cloud_functions\/cloud_functions.dart';/import 'package:parse_server_sdk_flutter\/parse_server_sdk_flutter.dart';/" lib/features/admin/screens/admin_users_screen.dart
sed -i "s/final result = await FirebaseFunctions.instanceFor(region: 'southamerica-east1').httpsCallable('listAllUsers').call();/final result = await ParseCloudFunction('listAllUsers').execute();/" lib/features/admin/screens/admin_users_screen.dart
sed -i "s/return result.data as List<dynamic>;/return result.result as List<dynamic>;/" lib/features/admin/screens/admin_users_screen.dart
sed -i "s/await FirebaseFunctions.instanceFor(region: 'southamerica-east1').httpsCallable(functionName).call({'uid': uid});/await ParseCloudFunction(functionName).execute(parameters: {'uid': uid});/" lib/features/admin/screens/admin_users_screen.dart

# Banners Screen
sed -i "s/import 'package:cloud_firestore\/cloud_firestore.dart';/import 'package:parse_server_sdk_flutter\/parse_server_sdk_flutter.dart';/" lib/features/admin/screens/admin_banners_screen.dart
sed -i "s/import 'package:cloud_functions\/cloud_functions.dart';//" lib/features/admin/screens/admin_banners_screen.dart
sed -i 's/StreamBuilder<QuerySnapshot>/FutureBuilder<ParseResponse>/' lib/features/admin/screens/admin_banners_screen.dart
sed -i "s/stream: FirebaseFirestore.instance.collection('banners').orderBy('order').snapshots(),/future: (QueryBuilder<ParseObject>(ParseObject('banners'))..orderByAscending('order')).query(),/" lib/features/admin/screens/admin_banners_screen.dart
sed -i "s/snapshot.data!.docs.isEmpty/snapshot.data!.results == null || snapshot.data!.results!.isEmpty/" lib/features/admin/screens/admin_banners_screen.dart
sed -i "s/final banners = snapshot.data!.docs;/final banners = snapshot.data!.results! as List<ParseObject>;/" lib/features/admin/screens/admin_banners_screen.dart
sed -i "s/final banner = banners\[index\].data() as Map<String, dynamic>;/final banner = banners\[index\];/" lib/features/admin/screens/admin_banners_screen.dart
sed -i "s/final bannerId = banners\[index\].id;/final bannerId = banner.objectId!;\n                  final imageUrl = banner.get<String>('imageUrl') ?? '';\n                  final actionUrl = banner.get<String>('actionUrl') ?? '';\n                  final isActive = banner.get<bool>('isActive') ?? false;\n                  final order = banner.get<int>('order') ?? 0;/" lib/features/admin/screens/admin_banners_screen.dart
sed -i '/final imageUrl = banner\['\''imageUrl'\''\] ?? '\'''\'';/d' lib/features/admin/screens/admin_banners_screen.dart
sed -i '/final actionUrl = banner\['\''actionUrl'\''\] ?? '\'''\'';/d' lib/features/admin/screens/admin_banners_screen.dart
sed -i '/final isActive = banner\['\''isActive'\''\] ?? false;/d' lib/features/admin/screens/admin_banners_screen.dart
sed -i '/final order = banner\['\''order'\''\] ?? 0;/d' lib/features/admin/screens/admin_banners_screen.dart
sed -i "s/await FirebaseFunctions.instanceFor(region: 'southamerica-east1').httpsCallable('deleteBanner').call({'bannerId': bannerId});/await ParseCloudFunction('deleteBanner').execute(parameters: {'bannerId': bannerId});/" lib/features/admin/screens/admin_banners_screen.dart
sed -i "s/await FirebaseFunctions.instanceFor(region: 'southamerica-east1').httpsCallable('createOrUpdateBanner').call/await ParseCloudFunction('createOrUpdateBanner').execute(parameters: /" lib/features/admin/screens/admin_banners_screen.dart
sed -i 's/_showBannerDialog(context, docId: bannerId, initialData: banner);/_showBannerDialog(context, docId: bannerId, initialData: null);/' lib/features/admin/screens/admin_banners_screen.dart

# Tools Screen
sed -i "s/import 'package:cloud_firestore\/cloud_firestore.dart';/import 'package:parse_server_sdk_flutter\/parse_server_sdk_flutter.dart';/" lib/features/admin/screens/admin_tools_screen.dart
sed -i "s/import 'package:cloud_functions\/cloud_functions.dart';//" lib/features/admin/screens/admin_tools_screen.dart
sed -i 's/StreamBuilder<QuerySnapshot>/FutureBuilder<ParseResponse>/' lib/features/admin/screens/admin_tools_screen.dart
sed -i "s/stream: FirebaseFirestore.instance.collection('hints_pool').orderBy('createdAt', descending: true).snapshots(),/future: (QueryBuilder<ParseObject>(ParseObject('hints_pool'))..orderByDescending('createdAt')).query(),/" lib/features/admin/screens/admin_tools_screen.dart
sed -i "s/snapshot.data!.docs.isEmpty/snapshot.data!.results == null || snapshot.data!.results!.isEmpty/" lib/features/admin/screens/admin_tools_screen.dart
sed -i "s/final hints = snapshot.data!.docs;/final hints = snapshot.data!.results! as List<ParseObject>;/" lib/features/admin/screens/admin_tools_screen.dart
sed -i "s/final hint = hints\[index\].data() as Map<String, dynamic>;/final hint = hints\[index\];/" lib/features/admin/screens/admin_tools_screen.dart
sed -i "s/final hintId = hints\[index\].id;/final hintId = hint.objectId!;\n                  final title = hint.get<String>('title') ?? 'Sem Título';\n                  final type = hint.get<String>('type') ?? 'text';\n                  final content = hint.get<String>('content') ?? '';/" lib/features/admin/screens/admin_tools_screen.dart
sed -i '/final title = hint\['\''title'\''\] ?? '\''Sem Título'\'';/d' lib/features/admin/screens/admin_tools_screen.dart
sed -i '/final type = hint\['\''type'\''\] ?? '\''text'\'';/d' lib/features/admin/screens/admin_tools_screen.dart
sed -i '/final content = hint\['\''content'\''\] ?? '\'''\'';/d' lib/features/admin/screens/admin_tools_screen.dart
sed -i "s/await FirebaseFunctions.instanceFor(region: 'southamerica-east1').httpsCallable('deleteHint').call({'hintId': hintId});/await ParseCloudFunction('deleteHint').execute(parameters: {'hintId': hintId});/" lib/features/admin/screens/admin_tools_screen.dart
sed -i "s/await FirebaseFunctions.instanceFor(region: 'southamerica-east1').httpsCallable('createOrUpdateHint').call/await ParseCloudFunction('createOrUpdateHint').execute(parameters: /" lib/features/admin/screens/admin_tools_screen.dart
sed -i 's/_showHintDialog(context, docId: hintId, initialData: hint);/_showHintDialog(context, docId: hintId, initialData: null);/' lib/features/admin/screens/admin_tools_screen.dart

# Finance Screen
sed -i "s/import 'package:cloud_firestore\/cloud_firestore.dart';/import 'package:parse_server_sdk_flutter\/parse_server_sdk_flutter.dart';/" lib/features/admin/screens/admin_finance_screen.dart
sed -i "s/import 'package:cloud_functions\/cloud_functions.dart';//" lib/features/admin/screens/admin_finance_screen.dart
sed -i 's/StreamBuilder<QuerySnapshot>/FutureBuilder<ParseResponse>/' lib/features/admin/screens/admin_finance_screen.dart
sed -i "s/stream: FirebaseFirestore.instance.collection('withdrawals').where('status', isEqualTo: 'pending').orderBy('createdAt', descending: false).snapshots(),/future: (QueryBuilder<ParseObject>(ParseObject('withdrawals'))..whereEqualTo('status', 'pending')..orderByAscending('createdAt')).query(),/" lib/features/admin/screens/admin_finance_screen.dart
sed -i "s/snapshot.data!.docs.isEmpty/snapshot.data!.results == null || snapshot.data!.results!.isEmpty/" lib/features/admin/screens/admin_finance_screen.dart
sed -i "s/final requests = snapshot.data!.docs;/final requests = snapshot.data!.results! as List<ParseObject>;/" lib/features/admin/screens/admin_finance_screen.dart
sed -i "s/final request = requests\[index\].data() as Map<String, dynamic>;/final request = requests\[index\];/" lib/features/admin/screens/admin_finance_screen.dart
sed -i "s/final requestId = requests\[index\].id;/final requestId = request.objectId!;\n                  final uid = request.get<String>('uid') ?? 'Desconhecido';\n                  final amount = request.get<num>('amount') ?? 0;\n                  final pixKey = request.get<String>('pixKey') ?? 'Chave não informada';\n                  final pixKeyType = request.get<String>('pixKeyType') ?? 'Desconhecido';\n                  final createdAt = request.createdAt;/" lib/features/admin/screens/admin_finance_screen.dart
sed -i '/final uid = request\['\''uid'\''\] ?? '\''Desconhecido'\'';/d' lib/features/admin/screens/admin_finance_screen.dart
sed -i '/final amount = request\['\''amount'\''\] ?? 0;/d' lib/features/admin/screens/admin_finance_screen.dart
sed -i '/final pixKey = request\['\''pixKey'\''\] ?? '\''Chave não informada'\'';/d' lib/features/admin/screens/admin_finance_screen.dart
sed -i '/final pixKeyType = request\['\''pixKeyType'\''\] ?? '\''Desconhecido'\'';/d' lib/features/admin/screens/admin_finance_screen.dart
sed -i '/final createdAt = request\['\''createdAt'\''\] as Timestamp?;/d' lib/features/admin/screens/admin_finance_screen.dart
sed -i "s/\${createdAt\.toDate().day}\/\${createdAt\.toDate().month}\/\${createdAt\.toDate().year} \${createdAt\.toDate().hour}:\${createdAt\.toDate().minute.toString().padLeft(2, '0')}/\${createdAt?.day}\/\${createdAt?.month}\/\${createdAt?.year} \${createdAt?.hour}:\${createdAt?.minute.toString().padLeft(2, '0')}/g" lib/features/admin/screens/admin_finance_screen.dart
sed -i "s/await FirebaseFunctions.instance.httpsCallable('processWithdrawal').call({/await ParseCloudFunction('processWithdrawal').execute(parameters: {/" lib/features/admin/screens/admin_finance_screen.dart

# Dashboard Screen
sed -i "s/import 'package:cloud_firestore\/cloud_firestore.dart';/import 'package:parse_server_sdk_flutter\/parse_server_sdk_flutter.dart';/" lib/features/admin/screens/admin_dashboard_screen.dart
sed -i "s/StreamBuilder<AggregateQuerySnapshot>/FutureBuilder<ParseResponse>/g" lib/features/admin/screens/admin_dashboard_screen.dart
sed -i "s/stream: FirebaseFirestore.instance.collection('users').count().get().asStream(),/future: QueryBuilder<ParseUser>(ParseUser.forQuery()).count(),/" lib/features/admin/screens/admin_dashboard_screen.dart
sed -i "s/stream: FirebaseFirestore.instance.collection('events').where('status', isEqualTo: 'published').count().get().asStream(),/future: (QueryBuilder<ParseObject>(ParseObject('events'))..whereEqualTo('status', 'published')).count(),/" lib/features/admin/screens/admin_dashboard_screen.dart
sed -i "s/stream: FirebaseFirestore.instance.collection('transactions').where('type', isEqualTo: 'deposit').count().get().asStream(),/future: (QueryBuilder<ParseObject>(ParseObject('transactions'))..whereEqualTo('type', 'deposit')).count(),/" lib/features/admin/screens/admin_dashboard_screen.dart
sed -i "s/stream: FirebaseFirestore.instance.collection('withdrawals').where('status', isEqualTo: 'pending').count().get().asStream(),/future: (QueryBuilder<ParseObject>(ParseObject('withdrawals'))..whereEqualTo('status', 'pending')).count(),/" lib/features/admin/screens/admin_dashboard_screen.dart
sed -i "s/final count = snapshot.data?.count?.toString() ?? '...';/final count = snapshot.data?.count?.toString() ?? '...';/g" lib/features/admin/screens/admin_dashboard_screen.dart

# Fraud Screen
sed -i "s/import 'package:cloud_firestore\/cloud_firestore.dart';/import 'package:parse_server_sdk_flutter\/parse_server_sdk_flutter.dart';/" lib/features/admin/screens/admin_fraud_screen.dart
sed -i "s/StreamBuilder<QuerySnapshot>/FutureBuilder<ParseResponse>/" lib/features/admin/screens/admin_fraud_screen.dart
sed -i "s/stream: FirebaseFirestore.instance.collection('fraud_logs').orderBy('timestamp', descending: true).limit(50).snapshots(),/future: (QueryBuilder<ParseObject>(ParseObject('fraud_logs'))..orderByDescending('timestamp')..setLimit(50)).query(),/" lib/features/admin/screens/admin_fraud_screen.dart
sed -i "s/snapshot.data!.docs.isEmpty/snapshot.data!.results == null || snapshot.data!.results!.isEmpty/" lib/features/admin/screens/admin_fraud_screen.dart
sed -i "s/final logs = snapshot.data!.docs;/final logs = snapshot.data!.results! as List<ParseObject>;/" lib/features/admin/screens/admin_fraud_screen.dart
sed -i "s/final log = logs\[index\].data() as Map<String, dynamic>;/final log = logs\[index\];/" lib/features/admin/screens/admin_fraud_screen.dart
sed -i "s/final uid = log\['uid'\] ?? 'Desconhecido';/final uid = log.get<String>('uid') ?? 'Desconhecido';/" lib/features/admin/screens/admin_fraud_screen.dart
sed -i "s/final reason = log\['reason'\] ?? 'Motivo desconhecido';/final reason = log.get<String>('reason') ?? 'Motivo desconhecido';/" lib/features/admin/screens/admin_fraud_screen.dart
sed -i "s/final eventId = log\['eventId'\] ?? '';/final eventId = log.get<String>('eventId') ?? '';/" lib/features/admin/screens/admin_fraud_screen.dart
sed -i "s/final timestamp = log\['timestamp'\] as Timestamp?;/final timestamp = log.createdAt;/" lib/features/admin/screens/admin_fraud_screen.dart
sed -i "s/\${timestamp\.toDate().day}\/\${timestamp\.toDate().month}\/\${timestamp\.toDate().year} \${timestamp\.toDate().hour}:\${timestamp\.toDate().minute.toString().padLeft(2, '0')}/\${timestamp?.day}\/\${timestamp?.month}\/\${timestamp?.year} \${timestamp?.hour}:\${timestamp?.minute.toString().padLeft(2, '0')}/g" lib/features/admin/screens/admin_fraud_screen.dart
