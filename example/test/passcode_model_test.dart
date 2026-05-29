import 'package:flutter_test/flutter_test.dart';
import 'package:yavuz_lock/services/passcode_model.dart';

void main() {
  group('Passcode.fromJson', () {
    test('parses valid JSON correctly', () {
      final json = {
        'keyboardPwdId': 42,
        'lockId': 7,
        'keyboardPwd': '1234',
        'keyboardPwdName': 'Test Code',
        'keyboardPwdType': 2,
        'startDate': 1700000000000,
        'endDate': 1800000000000,
        'senderUsername': 'alice',
      };
      final passcode = Passcode.fromJson(json);
      expect(passcode.keyboardPwdId, 42);
      expect(passcode.lockId, 7);
      expect(passcode.keyboardPwd, '1234');
      expect(passcode.keyboardPwdName, 'Test Code');
      expect(passcode.keyboardPwdType, 2);
      expect(passcode.startDate, 1700000000000);
      expect(passcode.endDate, 1800000000000);
      expect(passcode.senderUsername, 'alice');
    });

    test('handles keyboardPwdType as String', () {
      final json = {
        'keyboardPwdId': 1,
        'lockId': 1,
        'keyboardPwd': '9999',
        'keyboardPwdName': 'str type',
        'keyboardPwdType': '3',
      };
      final passcode = Passcode.fromJson(json);
      expect(passcode.keyboardPwdType, 3);
    });

    test('returns -1 for invalid keyboardPwdType string', () {
      final json = {
        'keyboardPwdId': 1,
        'lockId': 1,
        'keyboardPwd': '1111',
        'keyboardPwdName': 'bad type',
        'keyboardPwdType': 'not_a_number',
      };
      final passcode = Passcode.fromJson(json);
      expect(passcode.keyboardPwdType, -1);
    });

    test('returns -1 for null keyboardPwdType', () {
      final json = {
        'keyboardPwdId': 1,
        'lockId': 1,
        'keyboardPwd': '2222',
        'keyboardPwdName': 'null type',
        'keyboardPwdType': null,
      };
      final passcode = Passcode.fromJson(json);
      expect(passcode.keyboardPwdType, -1);
    });

    test('optional fields default to null', () {
      final json = {
        'keyboardPwdId': 5,
        'lockId': 3,
        'keyboardPwd': '5678',
        'keyboardPwdName': 'minimal',
        'keyboardPwdType': 1,
      };
      final passcode = Passcode.fromJson(json);
      expect(passcode.startDate, isNull);
      expect(passcode.endDate, isNull);
      expect(passcode.senderUsername, isNull);
    });
  });
}
