import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/user.dart';

void main() {
  group('AuthState', () {
    test('Authenticated carries the user and token', () {
      const user = User(id: '1', name: 'Test User', email: 'test@example.com');
      const state = Authenticated(user: user, token: 'abc123');

      expect(state.user, user);
      expect(state.token, 'abc123');
      expect(state, isA<AuthState>());
    });

    test('AuthError carries the message', () {
      const state = AuthError('Invalid credentials');
      expect(state.message, 'Invalid credentials');
    });

    test('variants are distinct runtime types usable in pattern matching', () {
      const states = <AuthState>[
        AuthInitial(),
        AuthRestoring(),
        Unauthenticated(),
        Authenticating(),
      ];

      for (final state in states) {
        final label = switch (state) {
          AuthInitial() => 'initial',
          AuthRestoring() => 'restoring',
          Unauthenticated() => 'unauthenticated',
          Authenticating() => 'authenticating',
          Authenticated() => 'authenticated',
          AuthError() => 'error',
        };
        expect(label, isNotEmpty);
      }
    });
  });

  group('User', () {
    test('fromJson/toJson round-trip matches UserResource shape', () {
      final json = {'id': 1, 'name': 'Test User', 'email': 'test@example.com'};
      final user = User.fromJson(json);

      expect(user.id, '1');
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.toJson(), {'id': '1', 'name': 'Test User', 'email': 'test@example.com'});
    });
  });
}
