import 'package:material_ui/material_ui.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.expanded = false, this.solid = false});

  final PermitStatus status;
  final bool expanded; // full-width banner, as on student cards
  final bool solid;    // strong pill, as in admin tables

  @override
  Widget build(BuildContext context) {
    final c = solid ? StatusColors.solid(status) : StatusColors.of(status);
    return Container(
      width: expanded ? double.infinity : null,
      alignment: expanded ? Alignment.center : null,
      padding: EdgeInsets.symmetric(horizontal: solid ? 14 : 12, vertical: solid ? 3 : 2),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(solid ? 999 : 4),
      ),
      child: Text(
        status.value,
        style: TextStyle(
            color: c.fg, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }
}

///shows "Returned Late" when time in is after expected time in
class ReturnedLateBadge extends StatelessWidget {
  const ReturnedLateBadge({
    super.key,
    required this.status,
    required this.expectedTimeIn,
    required this.actualTimeIn,
  });
  final PermitStatus status;
  final DateTime expectedTimeIn;
  final DateTime? actualTimeIn;

  bool get isLate =>
      status == PermitStatus.completed &&
      actualTimeIn != null &&
      actualTimeIn!.isAfter(expectedTimeIn);

  @override
  Widget build(BuildContext context) => isLate
      ? const Chip(label: Text('Returned late'))
      : const SizedBox.shrink();
}