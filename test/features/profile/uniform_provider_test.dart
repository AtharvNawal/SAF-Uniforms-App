import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/profile/domain/entities/branch_id.dart';
import 'package:saf_uniforms/features/profile/domain/entities/dress_code.dart';
import 'package:saf_uniforms/features/profile/domain/entities/gender.dart';
import 'package:saf_uniforms/features/profile/domain/entities/rank.dart';
import 'package:saf_uniforms/features/profile/presentation/providers/uniform_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('initial state defaults to Army / REC / male / No.3', () {
    final profile = container.read(uniformProfileProvider);
    expect(profile.branch, BranchId.army);
    expect(profile.rank, Rank.rec);
    expect(profile.gender, Gender.male);
    expect(profile.dressCode, DressCode.no3);
    expect(profile.isSikh, isFalse);
    expect(profile.fullName, '');
    expect(profile.vocation, 'Infantry');
    expect(profile.medalRowCount, 0);
    expect(profile.selectedBadgeIds, isEmpty);
    expect(profile.selectedAccessoryIds, isEmpty);
  });

  test('setBranch reactively updates currentBranchProvider', () {
    expect(container.read(currentBranchProvider), BranchId.army);
    container
        .read(uniformProfileProvider.notifier)
        .setBranch(BranchId.navy);
    expect(container.read(currentBranchProvider), BranchId.navy);
  });

  test('toggleAccessory adds then removes an accessory id', () {
    final notifier = container.read(uniformProfileProvider.notifier);
    notifier.toggleAccessory('rank-insignia');
    expect(
      container.read(uniformProfileProvider).selectedAccessoryIds,
      {'rank-insignia'},
    );
    notifier.toggleAccessory('rank-insignia');
    expect(
      container.read(uniformProfileProvider).selectedAccessoryIds,
      isEmpty,
    );
  });

  group('setFullName', () {
    test('updates state', () {
      final notifier = container.read(uniformProfileProvider.notifier);
      notifier.setFullName('CPT Tan');
      expect(container.read(uniformProfileProvider).fullName, 'CPT Tan');
    });

    test('is a no-op when value is unchanged', () {
      final notifier = container.read(uniformProfileProvider.notifier);
      notifier.setFullName('CPT Tan');
      final first = container.read(uniformProfileProvider);
      notifier.setFullName('CPT Tan');
      // Same identity is fine — what we want is no exceptions / no diverging state.
      expect(container.read(uniformProfileProvider).fullName, first.fullName);
    });
  });

  group('setVocation', () {
    test('updates state', () {
      final notifier = container.read(uniformProfileProvider.notifier);
      notifier.setVocation('Signals');
      expect(container.read(uniformProfileProvider).vocation, 'Signals');
    });

    test('is a no-op when value is unchanged', () {
      final notifier = container.read(uniformProfileProvider.notifier);
      notifier.setVocation('Armour');
      final first = container.read(uniformProfileProvider);
      notifier.setVocation('Armour');
      expect(container.read(uniformProfileProvider).vocation, first.vocation);
    });
  });

  group('setMedalRowCount', () {
    test('updates state', () {
      final notifier = container.read(uniformProfileProvider.notifier);
      notifier.setMedalRowCount(4);
      expect(container.read(uniformProfileProvider).medalRowCount, 4);
    });

    test('clamps to [0, 10]', () {
      final notifier = container.read(uniformProfileProvider.notifier);
      notifier.setMedalRowCount(-3);
      expect(container.read(uniformProfileProvider).medalRowCount, 0);
      notifier.setMedalRowCount(99);
      expect(container.read(uniformProfileProvider).medalRowCount, 10);
    });
  });

  group('toggleBadge', () {
    test('adds and removes', () {
      final notifier = container.read(uniformProfileProvider.notifier);
      notifier.toggleBadge('airborne');
      expect(
        container.read(uniformProfileProvider).selectedBadgeIds,
        {'airborne'},
      );
      notifier.toggleBadge('airborne');
      expect(
        container.read(uniformProfileProvider).selectedBadgeIds,
        isEmpty,
      );
    });

    test('marksman/sniper/fitness are mutually exclusive', () {
      final notifier = container.read(uniformProfileProvider.notifier);
      notifier.toggleBadge('marksman');
      expect(
        container.read(uniformProfileProvider).selectedBadgeIds,
        {'marksman'},
      );
      notifier.toggleBadge('sniper');
      expect(
        container.read(uniformProfileProvider).selectedBadgeIds,
        {'sniper'},
      );
      notifier.toggleBadge('fitness');
      expect(
        container.read(uniformProfileProvider).selectedBadgeIds,
        {'fitness'},
      );
    });

    test('non-mutex badges coexist with mutex picks', () {
      final notifier = container.read(uniformProfileProvider.notifier);
      notifier.toggleBadge('ippt');
      notifier.toggleBadge('marksman');
      notifier.toggleBadge('airborne');
      expect(
        container.read(uniformProfileProvider).selectedBadgeIds,
        {'ippt', 'marksman', 'airborne'},
      );
      // Switching mutex pick must keep ippt + airborne.
      notifier.toggleBadge('sniper');
      expect(
        container.read(uniformProfileProvider).selectedBadgeIds,
        {'ippt', 'airborne', 'sniper'},
      );
    });
  });

  test('clearBadges empties the set', () {
    final notifier = container.read(uniformProfileProvider.notifier);
    notifier.toggleBadge('ippt');
    notifier.toggleBadge('airborne');
    notifier.clearBadges();
    expect(
      container.read(uniformProfileProvider).selectedBadgeIds,
      isEmpty,
    );
  });

  group('toggleDressAccessory', () {
    test('adds then removes an accessory under the given dress', () {
      final notifier = container.read(uniformProfileProvider.notifier);
      notifier.toggleDressAccessory('no_3_dress_requirements', 'army_beret');
      expect(
        container.read(uniformProfileProvider).dressAccessoryChecks,
        {
          'no_3_dress_requirements': {'army_beret'},
        },
      );
      notifier.toggleDressAccessory('no_3_dress_requirements', 'army_beret');
      expect(
        container.read(uniformProfileProvider).dressAccessoryChecks,
        isEmpty,
      );
    });

    test('two dresses do not bleed', () {
      final notifier = container.read(uniformProfileProvider.notifier);
      notifier.toggleDressAccessory('no_3_dress_requirements', 'army_beret');
      notifier.toggleDressAccessory('no_5_dress_requirements', 'army_beret');
      expect(
        container.read(uniformProfileProvider).dressAccessoryChecks,
        {
          'no_3_dress_requirements': {'army_beret'},
          'no_5_dress_requirements': {'army_beret'},
        },
      );
      notifier.toggleDressAccessory('no_3_dress_requirements', 'army_beret');
      expect(
        container.read(uniformProfileProvider).dressAccessoryChecks,
        {
          'no_5_dress_requirements': {'army_beret'},
        },
      );
    });
  });

  group('setDressAccessoryChecked', () {
    test('idempotent — repeat checked=true is a no-op', () {
      final notifier = container.read(uniformProfileProvider.notifier);
      notifier.setDressAccessoryChecked(
        'no_3_dress_requirements',
        'a',
        checked: true,
      );
      final first = container.read(uniformProfileProvider);
      notifier.setDressAccessoryChecked(
        'no_3_dress_requirements',
        'a',
        checked: true,
      );
      expect(
        container.read(uniformProfileProvider).dressAccessoryChecks,
        first.dressAccessoryChecks,
      );
    });

    test('checked=false removes the id', () {
      final notifier = container.read(uniformProfileProvider.notifier);
      notifier.setDressAccessoryChecked(
        'no_3_dress_requirements',
        'a',
        checked: true,
      );
      notifier.setDressAccessoryChecked(
        'no_3_dress_requirements',
        'a',
        checked: false,
      );
      expect(
        container.read(uniformProfileProvider).dressAccessoryChecks,
        isEmpty,
      );
    });
  });

  test('clearDressAccessoryChecks drops every check on the given dress', () {
    final notifier = container.read(uniformProfileProvider.notifier);
    notifier.toggleDressAccessory('no_3_dress_requirements', 'a');
    notifier.toggleDressAccessory('no_3_dress_requirements', 'b');
    notifier.toggleDressAccessory('no_5_dress_requirements', 'c');
    notifier.clearDressAccessoryChecks('no_3_dress_requirements');
    expect(
      container.read(uniformProfileProvider).dressAccessoryChecks,
      {
        'no_5_dress_requirements': {'c'},
      },
    );
  });

  group('persist()', () {
    // See ChangeRequest/2026-08-11_config-profile-save-failure-fix.md —
    // persist() must report whether the write actually landed so
    // ConfigScreen can avoid silently completing onboarding against a
    // profile that was never saved.
    test('returns false when there is no auth session (write never attempted)',
        () async {
      // authSessionProvider defaults to null with no overrides — the
      // exact "kickoffAuthFlow not yet complete" case persist() must
      // report as a failure, not silently swallow.
      final result =
          await container.read(uniformProfileProvider.notifier).persist();
      expect(result, isFalse);
    });
  });
}
