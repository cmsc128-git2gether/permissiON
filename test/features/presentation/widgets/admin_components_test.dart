import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/widgets/app_dialog.dart';
import 'package:permission_app/features/presentation/widgets/search_field.dart';
import 'package:permission_app/features/presentation/widgets/status_chip.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/theme/app_theme.dart';

Widget wrap(Widget w) =>
    MaterialApp(theme: AppTheme.admin(), home: Scaffold(body: w));

void main() {

//currently use shared components for the tests. add respective tests for admin-specific components when they are created.
  group('StatusChip solid', () {
    Color? bg(WidgetTester t) => (t
            .widget<DecoratedBox>(find.descendant(
                of: find.byType(StatusChip), matching: find.byType(DecoratedBox)))
            .decoration as BoxDecoration)
        .color;

    testWidgets('solid uses a different background than the banner', (t) async {
      await t.pumpWidget(wrap(const StatusChip(PermitStatus.active)));
      final soft = bg(t);
      await t.pumpWidget(wrap(const StatusChip(PermitStatus.active, solid: true)));
      expect(bg(t), isNot(soft));
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('every status has a distinct solid color', (t) async {
      final colors = PermitStatus.values.map((s) => StatusColors.solid(s).bg).toSet();
      expect(colors.length, PermitStatus.values.length);
    });
  });

  group('AppDialog', () {
    Widget host() => wrap(Builder(
          builder: (c) => ElevatedButton(
            onPressed: () => showAppDialog(c, title: 'Permit Details', child: const Text('Body')),
            child: const Text('Open'),
          ),
        ));

    testWidgets('shows title and content', (t) async {
      await t.pumpWidget(host());
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      expect(find.text('Permit Details'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('X closes it', (t) async {
      await t.pumpWidget(host());
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.close));
      await t.pumpAndSettle();
      expect(find.text('Permit Details'), findsNothing);
    });
  });



  group('SearchField', () {
    testWidgets('shows the hint and the magnifier', (t) async {
      await t.pumpWidget(wrap(SearchField(hint: 'Type a name or room number to search..', onChanged: (_) {})));
      expect(find.text('Type a name or room number to search..'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('typing calls onChanged', (t) async {
      String? value;
      await t.pumpWidget(wrap(SearchField(hint: 'Search', onChanged: (v) => value = v)));
      await t.enterText(find.byType(TextField), 'carreon');
      expect(value, 'carreon');
    });

    testWidgets('Enter and the magnifier call onSubmitted', (t) async {
      final submitted = <String>[];
      await t.pumpWidget(wrap(SearchField(hint: 'Search', onChanged: (_) {}, onSubmitted: submitted.add)));
      await t.enterText(find.byType(TextField), 'room 1');
      await t.testTextInput.receiveAction(TextInputAction.search);
      await t.tap(find.byIcon(Icons.search));
      expect(submitted, ['room 1', 'room 1']);
    });
  });
}