import 'package:flutter_test/flutter_test.dart';
import 'package:laundry28/core/utils/pin_hasher.dart';

void main() {
  group('PinHasher (bcrypt)', () {
    test('hash returns different result for same input (bcrypt auto-salt)', () {
      const pin = '1234';
      final hash1 = PinHasher.hash(pin);
      final hash2 = PinHasher.hash(pin);
      // bcrypt generates random salt each time, so hashes are different
      expect(hash1, isNot(equals(hash2)));
    });

    test('hash returns different result for different inputs', () {
      final hash1 = PinHasher.hash('1234');
      final hash2 = PinHasher.hash('5678');
      expect(hash1, isNot(equals(hash2)));
    });

    test('verify returns true for correct PIN', () {
      const pin = '1234';
      final hash = PinHasher.hash(pin);
      expect(PinHasher.verify(pin, hash), isTrue);
    });

    test('verify returns false for wrong PIN', () {
      const correctPin = '1234';
      const wrongPin = '5678';
      final hash = PinHasher.hash(correctPin);
      expect(PinHasher.verify(wrongPin, hash), isFalse);
    });

    test('verify works across multiple hash generations', () {
      const pin = '9999';
      final hash1 = PinHasher.hash(pin);
      final hash2 = PinHasher.hash(pin);
      final hash3 = PinHasher.hash(pin);
      // All hashes should verify against the same PIN
      expect(PinHasher.verify(pin, hash1), isTrue);
      expect(PinHasher.verify(pin, hash2), isTrue);
      expect(PinHasher.verify(pin, hash3), isTrue);
    });

    test('generateSalt returns empty string (deprecated, bcrypt handles salt)', () {
      final salt = PinHasher.generateSalt();
      expect(salt, isEmpty);
    });

    test('hashWithSalt and verifyWithSalt work correctly (deprecated)', () {
      const pin = '9999';
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hashWithSalt(pin, salt);
      expect(PinHasher.verifyWithSalt(pin, hash, salt), isTrue);
      expect(PinHasher.verifyWithSalt('0000', hash, salt), isFalse);
    });

    test('bcrypt hash is ~60 characters (not 64 like SHA-256)', () {
      const pin = '123456';
      final hash = PinHasher.hash(pin);
      // bcrypt hash format: $2a$10$<22 char salt><31 char hash> = ~60 chars
      expect(hash.length, greaterThan(50));
      expect(hash.length, lessThan(70));
    });

    test(r'bcrypt hash starts with $2a$', () {
      const pin = '123456';
      final hash = PinHasher.hash(pin);
      expect(hash, startsWith(r'$2a$'));
    });

    test('4-6 digit PINs all hash correctly', () {
      for (var pinLength = 4; pinLength <= 6; pinLength++) {
        final pin = '1' * pinLength;
        final hash = PinHasher.hash(pin);
        expect(PinHasher.verify(pin, hash), isTrue);
        expect(PinHasher.verify('${pin}0', hash), isFalse);
      }
    });
  });
}
