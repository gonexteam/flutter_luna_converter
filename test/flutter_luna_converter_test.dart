import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_luna_converter/flutter_luna_converter.dart';

void main() {
  test('Test Luna', () {
    final luna = FlutterLunaConverter();
    expect(luna.solarToLunar(2020, 12, 14, Timezone.vietnamese), [1, 11, 2020]);
  });
}
