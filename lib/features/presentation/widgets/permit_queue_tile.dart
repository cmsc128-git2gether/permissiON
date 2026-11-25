import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/widgets/status_chip.dart';
import 'package:permission_app/models/permit_model.dart';

class PermitQueueTile extends StatelessWidget {
  const PermitQueueTile({super.key, required this.item, required this.onTap});
  final PermitModel item;
  final VoidCallback onTap; // parent calls context.push('/permits/${item.id}')

  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: item.isLateFiling ? Colors.amber.withValues(alpha: 0.12) : null,
    title: Text(item.fullName),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Room ${item.roomNum}'),
        if (item.isLateFiling) ...[
          const SizedBox(height: 4),
          Chip(
            label: const Text('Late filing'),
            backgroundColor: Colors.amber.shade200,
            visualDensity: VisualDensity.compact,
          ),
          Text(item.lateFilingReasonOrDefault),
        ],
      ],
    ),
    trailing: StatusChip(item.permitStatus),
    onTap: onTap,
  );
}
