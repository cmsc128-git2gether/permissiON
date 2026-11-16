import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/widgets/detail_row.dart';
import 'package:permission_app/features/presentation/widgets/status_chip.dart';
import 'package:permission_app/theme/app_theme.dart';
import 'package:permission_app/utils/format.dart';
import 'package:permission_app/models/permit_model.dart';

extension PermitDisplay on PermitModel {
  /// PLACEHOLDER FOR NOW
  /// Returns the last 4 characters of the permit id, or just 4
  String get displayNumber => id.length <= 4 ? id : id.substring(id.length - 4);
}

/// The permit card from the dashboard and archive frames.
/// - [collapsible]: archive style, tap header to expand.
/// - [showStudent]: admin view, name and room.
class PermitCard extends StatefulWidget {
  const PermitCard({
    super.key,
    required this.permit,
    this.showStudent = false,
    this.collapsible = false,
    this.actionLabel,
    this.onAction,
  });

  final PermitModel permit;
  final bool showStudent;
  final bool collapsible;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<PermitCard> createState() => _PermitCardState();
}

class _PermitCardState extends State<PermitCard> {
  late bool _open = !widget.collapsible;

  @override
  Widget build(BuildContext context) {
    final p = widget.permit;
    final reason = p.lateFilingReason?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          StatusChip(p.permitStatus, expanded: true),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: widget.collapsible ? () => setState(() => _open = !_open) : null,
            child: Row(children: [
              Text('${p.permitType.value} PERMIT',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(width: AppSpacing.sm),
              Text('#${p.displayNumber}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const Spacer(),
              if (widget.collapsible)
                Icon(_open ? Icons.expand_less : Icons.expand_more),
            ]),
          ),
          if (_open) ...[
            const SizedBox(height: AppSpacing.sm),
            if (widget.showStudent) ...[
              DetailRow('Student', p.fullName),
              DetailRow('Room', p.roomNum),
            ],
            DetailRow('Purpose', p.purpose),
            DetailRow('Destination', p.destination),
            DetailRow('Filed at', formatDateTime(p.createdAt)),
            DetailRow('Expected Return', formatDateTime(p.expectedTimeIn)),
            if (p.isLateFiling) ...[
              const SizedBox(height: AppSpacing.xs),
              const Chip(label: Text('Late filing'), visualDensity: VisualDensity.compact),
              Text('Reason: ${(reason == null || reason.isEmpty) ? 'No reason given' : reason}'),
            ],
            if (widget.actionLabel != null && widget.onAction != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: ElevatedButton(
                      onPressed: widget.onAction, child: Text(widget.actionLabel!)),
                ),
              ),
          ],
        ]),
      ),
    );
  }
}