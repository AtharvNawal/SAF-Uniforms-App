import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/ar_engine/data/dtos/accessory_firestore.dart';
import 'package:saf_uniforms/features/checklist/domain/services/accessory_presentation.dart';
import 'package:saf_uniforms/features/profile/domain/entities/accessory.dart';
import 'package:saf_uniforms/features/profile/domain/entities/branch_id.dart';
import 'package:saf_uniforms/features/profile/domain/entities/dress_code.dart';
import 'package:saf_uniforms/features/profile/domain/entities/gender.dart';

/// Runs against the real seed snapshot so the uploaded No.4 pictures and
/// doctrine text are what the Wardrobe actually resolves.
late final Map<String, Accessory> _lib;

void main() {
  setUpAll(() {
    final json =
        jsonDecode(
              File('assets/data/accessory_library.v1.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    _lib = {
      for (final a
          in (json['accessories'] as List).cast<Map<String, dynamic>>())
        a['id'] as String: AccessoryFirestore.fromFirestore(
          docId: a['id'] as String,
          data: a,
        ),
    };
  });

  group('accessoryImagesFor', () {
    test('No.4 name tag uses the per-service No.4 pictures', () {
      final tag = _lib['name_tag_standard']!;
      for (final b in BranchId.values) {
        final img = accessoryImagesFor(tag, dress: DressCode.no4, branch: b);
        expect(img.imageUrl, contains('no4_${b.wireName}_image.png'));
        expect(
          img.placementDiagramUrl,
          contains('no4_${b.wireName}_placement.png'),
        );
      }
    });

    test('No.3 (and no dress) keep the base pictures', () {
      final tag = _lib['name_tag_standard']!;
      for (final dress in [DressCode.no3, null]) {
        final img = accessoryImagesFor(
          tag,
          dress: dress,
          branch: BranchId.rsaf,
        );
        expect(img.imageUrl, tag.imageUrl);
        expect(img.placementDiagramUrl, tag.placementDiagramUrl);
      }
    });

    test('branch-agnostic no4 variant + per-slot fallback', () {
      // army_beret has only a no4 placement: the photo stays the base one.
      final beret = _lib['army_beret']!;
      final img = accessoryImagesFor(
        beret,
        dress: DressCode.no4,
        branch: BranchId.army,
      );
      expect(img.placementDiagramUrl, contains('no4_placement.png'));
      expect(img.imageUrl, beret.imageUrl);
    });

    test('a service without its own variant falls back to the base', () {
      // RSAF has no tabs page in the PDF.
      final tabs = _lib['skill_tabs_sleeve']!;
      final img = accessoryImagesFor(
        tabs,
        dress: DressCode.no4,
        branch: BranchId.rsaf,
      );
      expect(img.placementDiagramUrl, tabs.placementDiagramUrl);
    });

    test('every dress_images URL in the seed data is a Storage URL', () {
      for (final a in _lib.values) {
        for (final urls in a.dressImages.values) {
          for (final url in urls.values) {
            expect(
              url,
              startsWith('https://firebasestorage.googleapis.com/'),
              reason: a.id,
            );
          }
        }
      }
    });
  });

  group('accessoryDoctrineText', () {
    test('No.4 name tag text beats the No.3 ladies blouse-button rule', () {
      final text = accessoryDoctrineText(
        _lib['name_tag_standard']!,
        gender: Gender.female,
        dress: DressCode.no4,
        branch: BranchId.rsaf,
      );
      expect(text, contains('right chest pocket'));
      expect(text, isNot(contains('button')));
    });

    test('No.3 keeps the gendered rule', () {
      final text = accessoryDoctrineText(
        _lib['name_tag_standard']!,
        gender: Gender.female,
        dress: DressCode.no3,
      );
      expect(text, contains('button'));
    });

    test('per-service No.4 text', () {
      String? chest(BranchId b) => accessoryDoctrineText(
        _lib['saf_badges_chest']!,
        gender: Gender.male,
        dress: DressCode.no4,
        branch: b,
      );
      expect(chest(BranchId.navy), contains('3 cm above'));
      expect(chest(BranchId.dis), contains('Singapore tag'));
    });

    test('no rule text → null (sheet shows its fallback)', () {
      const bare = Accessory(id: 'x', displayName: 'X');
      expect(
        accessoryDoctrineText(bare, gender: Gender.male, dress: DressCode.no4),
        isNull,
      );
    });
  });

  test('DTO drops malformed dress_images entries', () {
    final a = AccessoryFirestore.fromFirestore(
      docId: 'x',
      data: {
        'dress_images': {
          'no4': {'image_url': 'https://a', 'placement_diagram': ''},
          'bad': 'not a map',
          'no4_rsaf': {'image_url': 3},
        },
      },
    );
    expect(a.dressImages, {
      'no4': {'image_url': 'https://a'},
    });
  });
}
