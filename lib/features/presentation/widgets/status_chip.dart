import 'package:material_ui/material_ui.dart';
import 'package:permission_app/models/data_enums.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final PermitStatus status;

  Color get _color => switch (status) {
        PermitStatus.pending => Colors.orange,
        PermitStatus.active => Colors.green,
        PermitStatus.denied => Colors.red,
        PermitStatus.completed => Colors.blueGrey,
        PermitStatus.cancelled => Colors.grey,
        PermitStatus.overdue => Colors.deepOrange,
      };

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(status.value),
        backgroundColor: _color.withValues(alpha: 0.15),
        side: BorderSide(color: _color),
      );
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