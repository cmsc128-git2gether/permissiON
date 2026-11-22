import 'package:material_ui/material_ui.dart';
import 'package:permission_app/theme/app_theme.dart';

/// Numbered circles joined by a line. The current step is filled.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.current, required this.labels})
      : assert(current >= 0 && current < labels.length);

  final int current; // zero-based
  final List<String> labels; // spoken by screen readers, not drawn

  static const _size = 32.0;
  static const _grey = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Step ${current + 1} of ${labels.length}: ${labels[current]}',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0)
                const Expanded(
                  child: SizedBox(height: 2, child: ColoredBox(color: _grey)),
                ),
              _circle(i),
            ],
          ]),
        ),
      );

  Widget _circle(int i) {
    final isCurrent = i == current;
    return Container(
      key: Key('step-$i'),
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent ? AppColors.flow : Colors.transparent,
        border: Border.all(color: isCurrent ? AppColors.flow : AppColors.ink, width: 2),
      ),
      child: Text(
        '${i + 1}',
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isCurrent ? Colors.white : AppColors.ink,
        ),
      ),
    );
  }
}