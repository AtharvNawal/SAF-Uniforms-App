import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';

/// View-model for an accessory row in the checklist UI.
class AccessoryItem {
  const AccessoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.mono,
    required this.reference,
    required this.icon,
  });

  final String id;
  final String title;
  final String body;
  final String mono;
  final String reference;
  final IconData icon;

  static List<AccessoryItem> all(AppLocalizations l) => [
        AccessoryItem(
          id: 'collar',
          title: l.accCollarTitle,
          body: l.accCollarBody,
          mono: l.accCollarMono,
          reference: l.accCollarRef,
          icon: Icons.star_border,
        ),
        AccessoryItem(
          id: 'badges',
          title: l.accBadgesTitle,
          body: l.accBadgesBody,
          mono: l.accBadgesMono,
          reference: l.accBadgesRef,
          icon: Icons.shield_outlined,
        ),
        AccessoryItem(
          id: 'medals',
          title: l.accMedalsTitle,
          body: l.accMedalsBody,
          mono: l.accMedalsMono,
          reference: l.accMedalsRef,
          icon: Icons.workspace_premium_outlined,
        ),
        AccessoryItem(
          id: 'name',
          title: l.accNameTitle,
          body: l.accNameBody,
          mono: l.accNameMono,
          reference: l.accNameRef,
          icon: Icons.badge_outlined,
        ),
        AccessoryItem(
          id: 'belt',
          title: l.accBeltTitle,
          body: l.accBeltBody,
          mono: l.accBeltMono,
          reference: l.accBeltRef,
          icon: Icons.horizontal_rule,
        ),
        AccessoryItem(
          id: 'lanyard',
          title: l.accLanyardTitle,
          body: l.accLanyardBody,
          mono: l.accLanyardMono,
          reference: l.accLanyardRef,
          icon: Icons.airline_stops,
        ),
      ];
}
