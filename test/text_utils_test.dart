import 'package:buslink/utils/text_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('firstChars never throws on a short id', () {
    expect(firstChars('abcdef', 4), 'abcd');
    expect(firstChars('t1', 4), 't1');
    expect(firstChars('', 4), '');
  });
}
