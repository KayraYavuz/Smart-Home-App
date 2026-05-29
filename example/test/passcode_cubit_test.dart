import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yavuz_lock/blocs/passcode/passcode_cubit.dart';
import 'package:yavuz_lock/repositories/ttlock_repository.dart';
import 'package:yavuz_lock/services/passcode_model.dart';

class MockTTLockRepository extends Mock implements TTLockRepository {}

const _clientId = 'test_client';
const _token = 'test_token';
const _lockId = 123;

void main() {
  late MockTTLockRepository repo;
  late PasscodeCubit cubit;

  setUp(() {
    repo = MockTTLockRepository();
    cubit = PasscodeCubit(repo);
  });

  tearDown(() => cubit.close());

  group('fetchPasscodes', () {
    final passcodes = [
      const Passcode(
        keyboardPwdId: 1,
        lockId: _lockId,
        keyboardPwd: '1234',
        keyboardPwdName: 'Home',
        keyboardPwdType: 2,
      ),
    ];

    blocTest<PasscodeCubit, PasscodeState>(
      'emits [Loading, LoadSuccess] on success',
      build: () {
        when(() => repo.getPasscodes(
              clientId: _clientId,
              accessToken: _token,
              lockId: _lockId,
            )).thenAnswer((_) async => passcodes);
        return PasscodeCubit(repo);
      },
      act: (c) => c.fetchPasscodes(_lockId, _clientId, _token),
      expect: () => [isA<PasscodeLoading>(), isA<PasscodeLoadSuccess>()],
    );

    blocTest<PasscodeCubit, PasscodeState>(
      'emits [Loading, LoadFailure] on error',
      build: () {
        when(() => repo.getPasscodes(
              clientId: any(named: 'clientId'),
              accessToken: any(named: 'accessToken'),
              lockId: any(named: 'lockId'),
            )).thenThrow(Exception('network error'));
        return PasscodeCubit(repo);
      },
      act: (c) => c.fetchPasscodes(_lockId, _clientId, _token),
      expect: () => [isA<PasscodeLoading>(), isA<PasscodeLoadFailure>()],
    );

    blocTest<PasscodeCubit, PasscodeState>(
      'LoadSuccess contains correct passcodes',
      build: () {
        when(() => repo.getPasscodes(
              clientId: _clientId,
              accessToken: _token,
              lockId: _lockId,
            )).thenAnswer((_) async => passcodes);
        return PasscodeCubit(repo);
      },
      act: (c) => c.fetchPasscodes(_lockId, _clientId, _token),
      expect: () => [
        isA<PasscodeLoading>(),
        isA<PasscodeLoadSuccess>().having(
          (s) => s.passcodes.length,
          'passcode count',
          1,
        ),
      ],
    );
  });

  group('deletePasscode', () {
    blocTest<PasscodeCubit, PasscodeState>(
      'deletes and refetches on success',
      build: () {
        when(() => repo.deletePasscode(
              clientId: _clientId,
              accessToken: _token,
              lockId: _lockId,
              keyboardPwdId: 1,
            )).thenAnswer((_) async => true);
        when(() => repo.getPasscodes(
              clientId: _clientId,
              accessToken: _token,
              lockId: _lockId,
            )).thenAnswer((_) async => []);
        return PasscodeCubit(repo);
      },
      act: (c) => c.deletePasscode(
        lockId: _lockId,
        keyboardPwdId: 1,
        clientId: _clientId,
        accessToken: _token,
      ),
      expect: () => [isA<PasscodeLoading>(), isA<PasscodeLoadSuccess>()],
    );

    blocTest<PasscodeCubit, PasscodeState>(
      'emits LoadFailure when delete returns false',
      build: () {
        when(() => repo.deletePasscode(
              clientId: any(named: 'clientId'),
              accessToken: any(named: 'accessToken'),
              lockId: any(named: 'lockId'),
              keyboardPwdId: any(named: 'keyboardPwdId'),
            )).thenAnswer((_) async => false);
        return PasscodeCubit(repo);
      },
      act: (c) => c.deletePasscode(
        lockId: _lockId,
        keyboardPwdId: 1,
        clientId: _clientId,
        accessToken: _token,
      ),
      expect: () => [isA<PasscodeLoadFailure>()],
    );

    blocTest<PasscodeCubit, PasscodeState>(
      'emits LoadFailure on exception',
      build: () {
        when(() => repo.deletePasscode(
              clientId: any(named: 'clientId'),
              accessToken: any(named: 'accessToken'),
              lockId: any(named: 'lockId'),
              keyboardPwdId: any(named: 'keyboardPwdId'),
            )).thenThrow(Exception('delete failed'));
        return PasscodeCubit(repo);
      },
      act: (c) => c.deletePasscode(
        lockId: _lockId,
        keyboardPwdId: 1,
        clientId: _clientId,
        accessToken: _token,
      ),
      expect: () => [isA<PasscodeLoadFailure>()],
    );
  });
}
