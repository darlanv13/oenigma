import 'dart:io';

void main() {
  final file = File('lib/app_cliente/features/event/widgets/event_card.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll(
    'child: CustomPaint(painter: _MapBackgroundPainter()),',
    'child: const SizedBox(),',
  );

  file.writeAsStringSync(content);
}
