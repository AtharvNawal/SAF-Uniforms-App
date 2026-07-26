import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/core/design/widgets/check_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
      );

  testWidgets('renders the icon fallback when imageUrl is null',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        CheckCard(
          title: 'Army Beret',
          subtitle: 'TAP TO VIEW',
          icon: Icons.military_tech,
          checked: false,
          onTap: () {},
          onToggle: () {},
        ),
      ),
    );
    expect(find.byIcon(Icons.military_tech), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('renders the icon fallback when imageUrl is empty',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        CheckCard(
          title: 'Army Beret',
          subtitle: 'TAP TO VIEW',
          icon: Icons.military_tech,
          checked: false,
          imageUrl: '',
          onTap: () {},
          onToggle: () {},
        ),
      ),
    );
    expect(find.byIcon(Icons.military_tech), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets(
      'inserts a CachedNetworkImage thumbnail when a non-empty URL is passed',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        CheckCard(
          title: 'Army Beret',
          subtitle: 'TAP TO VIEW',
          icon: Icons.military_tech,
          checked: false,
          imageUrl:
              'https://firebasestorage.googleapis.com/v0/b/saf-uniforms.appspot.com/o/accessories%2Farmy_beret%2Fimage.png',
          onTap: () {},
          onToggle: () {},
        ),
      ),
    );
    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });
}
