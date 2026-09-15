import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry28/features/admin/cubit/auth_cubit.dart';

void main() {
  group('AuthCubit', () {
    late AuthCubit authCubit;

    setUp(() {
      authCubit = AuthCubit();
    });

    tearDown(() {
      authCubit.close();
    });

    test('initial state is AuthInitial', () {
      expect(authCubit.state, equals(AuthInitial()));
    });

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when login fails',
      build: () {
        return authCubit;
      },
      act: (cubit) => cubit.login('invalid@test.com', 'wrongpassword'),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<AuthUnauthenticated>());
        final authState = state as AuthUnauthenticated;
        expect(authState.message, isNotNull);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when register fails',
      build: () {
        return authCubit;
      },
      act: (cubit) => cubit.register('test@test.com', 'password', 'Test User'),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthUnauthenticated] when logout is called',
      setUp: () {
        // Mock state setup - in real test, we'd mock the repository
      },
      build: () => authCubit,
      act: (cubit) => cubit.logout(),
      expect: () => [isA<AuthUnauthenticated>()],
    );
  });
}
