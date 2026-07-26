import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/auth/domain/auth_repository.dart';
import 'package:saf_uniforms/features/auth/presentation/providers/auth_providers.dart';
import 'package:saf_uniforms/features/profile/domain/entities/branch_id.dart';
import 'package:saf_uniforms/features/profile/domain/entities/dress_code.dart';
import 'package:saf_uniforms/features/profile/domain/entities/gender.dart';
import 'package:saf_uniforms/features/profile/domain/entities/rank.dart';
import 'package:saf_uniforms/features/profile/presentation/providers/uniform_provider.dart';

/// End-to-end check on the wizard's persistence path:
///   user setters → notifier state → debounced/awaited write → Firestore doc
///
/// The wizard's "Build Ghost Model" handler awaits
/// [UniformProfileNotifier.persist] which goes through the same
/// `_profileRepositoryProvider` the rest of the app uses. By overriding
/// only [firebaseFirestoreProvider] + [authSessionProvider] we exercise
/// the real repo on top of `fake_cloud_firestore` — i.e. the same
/// `users/{uid}/profile/current` doc the production wizard would write.
void main() {
  late FakeFirebaseFirestore firestore;
  late ProviderContainer container;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    container = ProviderContainer(overrides: [
      firebaseFirestoreProvider.overrideWithValue(firestore),
    ]);
    addTearDown(container.dispose);
    // Simulate kickoffAuthFlow having landed before persist():
    container.read(authSessionProvider.notifier).set(
          const AuthSession(
            uid: 'wizard-test-uid',
            deviceId: 'wizard-test-device',
            profileComplete: false,
          ),
        );
  });

  test('full wizard flow writes branch/rank/gender/sikh + name/vocation/medals/badges',
      () async {
    final notifier = container.read(uniformProfileProvider.notifier);

    // Step 1 — Service Branch.
    notifier.setBranch(BranchId.navy);

    // Step 2 — Identity.
    notifier.setGender(Gender.female);
    notifier.setSikh(false);

    // Step 3 — Rank, Vocation, Full Name.
    notifier.setRank(Rank.cpt);
    notifier.setVocation('Signals');
    notifier.setFullName('CPT Lim');

    // Step 4 — Medal rows + badges.
    notifier.setMedalRowCount(4);
    notifier.toggleBadge('airborne');
    notifier.toggleBadge('ippt');

    // "Build Ghost Model" → cancel debounce + flush sync.
    await notifier.persist();

    final snap = await firestore
        .collection('users')
        .doc('wizard-test-uid')
        .collection('profile')
        .doc('current')
        .get();

    expect(snap.exists, isTrue, reason: 'persist() should write the doc');
    final data = snap.data()!;

    // Sanity: pre-existing fields still write.
    expect(data['branch'], BranchId.navy.wireName);
    expect(data['rank'], Rank.cpt.code);
    expect(data['gender'], Gender.female.wireName);
    expect(data['dressCode'], DressCode.no3.wireName);
    expect(data['isSikh'], false);

    // The four fields the user reported as missing from the wizard:
    expect(data['fullName'], 'CPT Lim',
        reason: 'fullName must be persisted from the wizard');
    expect(data['vocation'], 'Signals',
        reason: 'vocation must be persisted from the wizard');
    expect(data['medalRowCount'], 4,
        reason: 'medalRowCount must be persisted from the wizard');
    expect(
      data['selectedBadgeIds'],
      unorderedEquals(['airborne', 'ippt']),
      reason: 'selectedBadgeIds must be persisted from the wizard',
    );
  });

  test('persist() writes default values even when user skips Steps 3 & 4',
      () async {
    final notifier = container.read(uniformProfileProvider.notifier);
    // User only touches branch in Step 1, then taps Build Ghost Model.
    notifier.setBranch(BranchId.army);
    await notifier.persist();

    final snap = await firestore
        .collection('users')
        .doc('wizard-test-uid')
        .collection('profile')
        .doc('current')
        .get();

    expect(snap.exists, isTrue);
    final data = snap.data()!;
    // Defaults are written so the doc shape is stable.
    expect(data['fullName'], '');
    expect(data['vocation'], 'Infantry');
    expect(data['medalRowCount'], 0);
    expect(data['selectedBadgeIds'], isEmpty);
  });
}
