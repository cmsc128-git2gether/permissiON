import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/widgets/status_chip.dart';
import 'package:permission_app/models/data_enums.dart';



class PermitModel {
  const PermitModel({
    required this.id,
    required this.fullName,
    required this.roomNum,
    required this.status,
    this.isLateFiling = false,
    this.lateFilingReason,
  });
  final String id, fullName, roomNum;
  final PermitStatus status;
  final bool isLateFiling;
  final String? lateFilingReason;
}

class PermitQueueTile extends StatelessWidget {
  const PermitQueueTile({super.key, required this.item, required this.onTap});
  final PermitModel item;
  final VoidCallback onTap; // parent calls context.push('/permits/${item.id}')

  @override
  Widget build(BuildContext context) => ListTile(
        tileColor: item.isLateFiling ? Colors.amber.withValues(alpha: 0.12) : null,
        title: Text(item.fullName),
        subtitle: Text([
          'Room ${item.roomNum}',
          if (item.isLateFiling) 'Late filing: ${item.lateFilingReason ?? ''}',
        ].join(' · ')),
        trailing: StatusChip(item.status),
        onTap: onTap,
      );
}