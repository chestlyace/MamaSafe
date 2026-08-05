import 'package:flutter_test/flutter_test.dart';
import 'package:mamasafe/features/auth/user.dart';
import 'package:mamasafe/features/profile/profile_repository.dart';

void main() {
  group('User.fromJson', () {
    test('parses full profile payload', () {
      final u = User.fromJson(const {
        'id': 1,
        'username': 'jane',
        'full_name': 'Jane Doe',
        'role': 'chw',
        'facility': 'Bafoussam',
        'district': null,
        'region': null,
        'whatsapp_number': '+237 655 123 456',
        'is_active': true,
        'last_active': '2026-08-03T10:00:00Z',
        'created_at': '2026-01-01T08:00:00Z',
      });

      expect(u.id, 1);
      expect(u.username, 'jane');
      expect(u.name, 'Jane Doe');
      expect(u.role, UserRole.chw);
      expect(u.facility, 'Bafoussam');
      expect(u.whatsappNumber, '+237 655 123 456');
      expect(u.isActive, isTrue);
      expect(u.lastActive, isNotNull);
      expect(u.createdAt, isNotNull);
    });

    test('defaults missing optional fields', () {
      final u = User.fromJson(const {'username': 'jane', 'role': 'admin'});
      expect(u.id, 0);
      expect(u.name, '');
      expect(u.facility, isNull);
      expect(u.district, isNull);
      expect(u.region, isNull);
      expect(u.whatsappNumber, isNull);
      expect(u.isActive, isTrue);
      expect(u.lastActive, isNull);
      expect(u.createdAt, isNull);
    });

    test('tolerates name key from login payload', () {
      final u = User.fromJson(const {'username': 'jane', 'name': 'Jane'});
      expect(u.name, 'Jane');
    });
  });

  group('ProfileUpdate.toPayload', () {
    test('omits null fields', () {
      const p = ProfileUpdate(
        fullName: 'Jane Doe',
        whatsappNumber: null,
        facility: null,
        district: 'Mfoundi',
        region: 'Centre',
      );
      expect(p.toPayload(), {
        'full_name': 'Jane Doe',
        'district': 'Mfoundi',
        'region': 'Centre',
      });
    });

    test('includes present whatsapp number', () {
      const p = ProfileUpdate(
        fullName: 'Jane Doe',
        whatsappNumber: '+237 655 123 456',
        facility: null,
        district: null,
        region: null,
      );
      expect(p.toPayload(), {
        'full_name': 'Jane Doe',
        'whatsapp_number': '+237 655 123 456',
      });
    });

    test('copyWith replaces values', () {
      const p = ProfileUpdate(
        fullName: 'Jane Doe',
        whatsappNumber: null,
        facility: 'A',
        district: null,
        region: null,
      );
      final q = p.copyWith(fullName: 'Jane Smith', district: 'Mfoundi');
      expect(q.fullName, 'Jane Smith');
      expect(q.facility, 'A');
      expect(q.district, 'Mfoundi');
      expect(q.region, isNull);
    });
  });
}
