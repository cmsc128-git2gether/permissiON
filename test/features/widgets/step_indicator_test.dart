import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/widgets/step_indicator.dart';
import 'package:permission_app/theme/app_theme.dart';

void main() {
  const labels = ['Type', 'Details', 'Confirm'];

  Widget buildSubject(int current) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StepIndicator(current: current, labels: labels),
        ),
      );

  group('StepIndicator', () {
    testWidgets('renders numbered circles for each label', (t) async {
      await t.pumpWidget(buildSubject(0));

      expect(find.byKey(const Key('step-0')), findsOneWidget);
      expect(find.byKey(const Key('step-1')), findsOneWidget);
      expect(find.byKey(const Key('step-2')), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('does not draw text labels visually', (t) async {
      await t.pumpWidget(buildSubject(0));

      for (final label in labels) {
        expect(find.text(label), findsNothing);
      }
    });

    testWidgets('highlights only the current step circle', (t) async {
      await t.pumpWidget(buildSubject(1));

      BoxDecoration decorationOf(int index) {
        final container = t.widget<Container>(find.byKey(Key('step-$index')));
        return container.decoration! as BoxDecoration;
      }

      TextStyle textStyleOf(String number) =>
          t.widget<Text>(find.text(number)).style!;

      expect(decorationOf(0).color, Colors.transparent);
      expect(textStyleOf('1').color, AppColors.ink);

      expect(decorationOf(1).color, AppColors.flow);
      expect(textStyleOf('2').color, Colors.white);

      expect(decorationOf(2).color, Colors.transparent);
      expect(textStyleOf('3').color, AppColors.ink);
    });

    testWidgets('exposes screen reader semantics for current step', (t) async {
      await t.pumpWidget(buildSubject(2));

      expect(
        find.bySemanticsLabel('Step 3 of 3: Confirm'),
        findsOneWidget,
      );
    });

    test('asserts when current index is out of bounds', () {
      expect(
        () => StepIndicator(current: -1, labels: labels),
        throwsAssertionError,
      );
      expect(
        () => StepIndicator(current: 3, labels: labels),
        throwsAssertionError,
      );
    });
  });
}
