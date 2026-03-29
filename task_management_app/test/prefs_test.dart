import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SharedPreferences test', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_title', 'test');
    final val = prefs.getString('draft_title');
    print('Saved value: \$val');
    await prefs.remove('draft_title');
  });
}
