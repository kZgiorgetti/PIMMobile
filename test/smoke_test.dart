import 'package:flutter_test/flutter_test.dart';
import 'package:pim_mobile/features/screens.dart';

void main() {
  test('status and priority labels match the web contract', () {
    expect(labelStatus('EmAndamento'), 'Em andamento');
    expect(labelStatus('Concluida'), 'Concluída');
    expect(labelPriority('Media'), 'Média');
    expect(labelPriority('Urgente'), 'Urgente');
  });
}
