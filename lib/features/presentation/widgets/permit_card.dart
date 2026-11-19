import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/widgets/detail_row.dart';
import 'package:permission_app/features/presentation/widgets/status_chip.dart';
import 'package:permission_app/theme/app_theme.dart';
import 'package:permission_app/utils/format.dart';
import 'package:permission_app/models/permit_model.dart';

//get the last 4 digits of the permit ID for display, or "----" if the ID is empty
extension PermitDisplay on PermitModel {
  String get displayNumber {
    if (id.isEmpty) return '----';
    return id.length <= 4 ? id : id.substring(id.length - 4);
  }
}

//card that shows the details of a permit, with optional student info and action button
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
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(p.permitStatus, expanded: true),
            const SizedBox(height: AppSpacing.md),
            //header row with permit type and number, and expand/collapse icon if collapsible
            InkWell(
              onTap: widget.collapsible
                  ? () => setState(() => _open = !_open)
                  : null,
              //necessary info before the details are shown, so always show it even if the card is collapsed
              child: Row(
                children: [
                  Text(
                    '${p.permitType.value} PERMIT',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '#${p.displayNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (widget.collapsible)
                    Icon(_open ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            if (_open) ...[
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  right: AppSpacing.xs,
                ),
                //show the details of the permit in a column of DetailRow widgets
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showStudent) ...[
                      DetailRow('Student', p.fullName),
                      DetailRow('Room', p.roomNum),
                    ],
                    DetailRow('Purpose', p.purpose),
                    DetailRow('Destination', p.destination),
                    DetailRow('Filed at', formatDateTime(p.createdAt)),
                    DetailRow(
                      'Expected Return',
                      formatDateTime(p.expectedTimeIn),
                    ),
                    if (p.isLateFiling) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        //show the reason for late filing, or "No reason given" if none was provided
                        //text.rich to bold the "Late filing:" label and keep the reason normal weight
                        //yes it is that convuluted to bold text in dart, i hate it too
                        child: Text.rich(
                          TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Late filing: ',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(
                                text: (reason == null || reason.isEmpty)
                                    ? 'No reason given'
                                    : reason,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              //show the action button if provided
              if (widget.actionLabel != null && widget.onAction != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: ElevatedButton(
                      onPressed: widget.onAction,
                      child: Text(widget.actionLabel!),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}