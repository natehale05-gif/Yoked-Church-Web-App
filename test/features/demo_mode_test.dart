import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/features/auth/data/auth_repository.dart';
import 'package:yoked_church_app/features/auth/domain/app_user.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('demo mode', () {
    test('previewing as a role enrols that account in the congregation', () async {
      final users = FakeUserRepository()..seedInMemory([testMember(uid: 'existing')]);
      final auth = LocalAuthRepository(users);

      await auth.signInAsDemo(UserRole.admin);

      // Without this the previewing admin is not a member of their own
      // church: they never appear in the members list, and announcements
      // they send reach nobody they can see.
      final enrolled = await users.fetchById('demo-admin');
      expect(enrolled, isNotNull);
      expect(enrolled!.role, UserRole.admin);
      expect((await users.fetchAll()).map((u) => u.uid), containsAll(['existing', 'demo-admin']));
    });

    test('signing up in demo mode also enrols, as a plain member', () async {
      final users = FakeUserRepository();
      final auth = LocalAuthRepository(users);

      await auth.signUp(email: 'new@example.org', password: 'x', displayName: 'New Person');

      final enrolled = (await users.fetchAll()).single;
      expect(enrolled.displayName, 'New Person');
      expect(enrolled.role, UserRole.member);
    });

    test('demo mode offers no social sign-in, and says so rather than failing silently', () async {
      final auth = LocalAuthRepository();

      expect(auth.isDemo, isTrue);
      expect(auth.supportsSocialSignIn, isFalse);
      await expectLater(auth.signInWithGoogle(), throwsA(isA<AuthFailure>()));
    });

    test('works with no congregation attached at all', () async {
      final auth = LocalAuthRepository();
      await auth.signInAsDemo(UserRole.staff);
      expect(await auth.authStateChanges().first, isNotNull);
    });
  });
}
