import 'dart:io';

void main() {
  final file = File('lib/app_cliente/main.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll(
    "import 'package:oenigma/core/widgets/app_background.dart';\n",
    "",
  );

  file.writeAsStringSync(content);
}
