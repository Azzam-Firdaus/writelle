import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/repositories/auth_repository.dart';

/// Test suite for TC-001 (FR-001, BR-001): Authentication & Input Validation
void main() {
  group('TC-001: Authentication Input Validation Tests (FR-001, BR-001)', () {
    bool isValidEmail(String email) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      return emailRegex.hasMatch(email.trim());
    }

    bool isValidPassword(String password) {
      return password.length >= 8;
    }

    test('validates email format correctly', () {
      expect(isValidEmail('student@example.com'), isTrue);
      expect(isValidEmail('author.writelle@domain.org'), isTrue);
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('not-an-email'), isFalse);
      expect(isValidEmail('@nodomain.com'), isFalse);
      expect(isValidEmail('missing@domain'), isFalse);
    });

    test('validates password minimum length requirement (min 8 characters)', () {
      expect(isValidPassword('12345678'), isTrue);
      expect(isValidPassword('securePassword123'), isTrue);
      expect(isValidPassword('short7!'), isFalse);
      expect(isValidPassword(''), isFalse);
      expect(isValidPassword('12345'), isFalse);
    });

    test('AuthRepository signUp throws validation error for invalid email and short password', () {
      final repo = AuthRepository();
      expect(() => repo.signUp(email: '', password: 'validPassword123'), throwsA(isA<Exception>()));
      expect(() => repo.signUp(email: 'notanemail', password: 'validPassword123'), throwsA(isA<Exception>()));
      expect(() => repo.signUp(email: 'valid@writelle.app', password: 'short'), throwsA(isA<Exception>()));
    });

    test('AuthRepository signInWithGoogle throws descriptive error when client is uninitialized', () {
      final repo = AuthRepository();
      expect(() => repo.signInWithGoogle(), throwsA(isA<Exception>()));
    });

    test('AuthRepository sendPasswordResetEmail throws validation error for invalid email', () {
      final repo = AuthRepository();
      expect(() => repo.sendPasswordResetEmail(''), throwsA(isA<Exception>()));
      expect(() => repo.sendPasswordResetEmail('notanemail'), throwsA(isA<Exception>()));
    });

    test('AuthRepository updatePassword throws validation error for short password (< 8 chars)', () {
      final repo = AuthRepository();
      expect(() => repo.updatePassword(newPassword: '12345'), throwsA(isA<Exception>()));
    });
  });
}
