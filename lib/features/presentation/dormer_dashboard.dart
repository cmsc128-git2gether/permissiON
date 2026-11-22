import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/widgets/app_dialog.dart';
import 'package:permission_app/features/presentation/widgets/detail_row.dart';
import 'package:permission_app/features/presentation/widgets/error_state.dart';
import 'package:permission_app/features/presentation/widgets/loading_state.dart';
import 'package:permission_app/features/presentation/widgets/permit_card.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/models/permit_model.dart';
import 'package:permission_app/router/app_router.dart';
import 'package:permission_app/services/permit_service.dart';
import 'package:permission_app/theme/app_theme.dart';
import 'package:permission_app/utils/format.dart';

/// Statuses shown under "Current Active Permit".
const _activeStatuses = {PermitStatus.active, PermitStatus.overdue};

/// The "(0/1)" counters in the section headings. Confirm the real dorm
/// rules with your team; change these two numbers if they differ.
const _maxActive = 1;
const _maxPending = 1;

/// Homepage for end_user (dormer) accounts.
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({
    super.key,
    required this.service,
    required this.userId,
    required this.displayName,
  });

  final PermitService service;
  final String userId;
  final String displayName;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  late final Stream<List<PermitModel>> _permits =
      widget.service.listenToUserPermits(widget.userId);

  void _fileNewPermit() => context.push(AppRoutes.newPermit);

  void _showPermitDialog(PermitModel p) => showAppDialog<void>(
        context,
        title: 'Permit details',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailRow('Purpose', p.purpose),
            DetailRow('Destination', p.destination),
            DetailRow('Filed at', formatDateTime(p.createdAt)),
            DetailRow('Expected Return', formatDateTime(p.expectedTimeIn)),
            DetailRow('Contact Person', p.emergencyContactPerson),
            DetailRow('Contact Number', p.emergencyContactNum),
          ],
        ),
      );

  /// A section that is always on screen. It shows its permits, or [empty]
  /// when there are none, with a "(count/limit)" next to the heading.
  Widget _section({
    required Key key,
    required String heading,
    required int limit,
    required List<PermitModel> permits,
    required Widget empty,
  }) =>
      Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: AppTheme.sectionHeading,
              children: [
                TextSpan(text: heading),
                TextSpan(
                  text: ' (${permits.length}/$limit)',
                  style: const TextStyle(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (permits.isEmpty)
            empty
          else
            for (final p in permits) ...[
              PermitCard(
                permit: p,
                actionLabel: 'View/Manage',
                onAction: () => _showPermitDialog(p),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PermitModel>>(
      stream: _permits,
      builder: (context, snap) {
        if (snap.hasError) {
          return const ErrorState(message: 'Could not load permits');
        }
        if (!snap.hasData) return const LoadingState();

        final all = snap.data!;
        final active =
            all.where((p) => _activeStatuses.contains(p.permitStatus)).toList();
        final pending =
            all.where((p) => p.permitStatus == PermitStatus.pending).toList();

        final greeting = Theme.of(context)
            .textTheme
            .headlineMedium
            ?.copyWith(color: AppColors.heading);

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // "Hello," light, the name bold, like the wireframe.
            Text.rich(
              TextSpan(
                style: greeting?.copyWith(fontWeight: FontWeight.w300),
                children: [
                  const TextSpan(text: 'Hello, '),
                  TextSpan(
                    text: '${widget.displayName}!',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _section(
              key: const Key('active_permit_card'),
              heading: 'Current Active Permit',
              limit: _maxActive,
              permits: active,
              empty: const _SectionEmpty(
                key: Key('active_empty_state'),
                title: 'No active permit yet',
                message: 'Accepted permits will appear here once their '
                    'scheduled time begins.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _section(
              key: const Key('pending_permit_card'),
              heading: 'Pending / Scheduled',
              limit: _maxPending,
              permits: pending,
              empty: _SectionEmpty(
                key: const Key('pending_empty_state'),
                title: 'Planning to head out?',
                message: "File a permit request using the '+' button below!",
                actionLabel: 'File a permit',
                onAction: _fileNewPermit,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Empty state for one dashboard section: icon, title, short message and an
/// optional button. Private to this screen because the shared EmptyState
/// only has a message and a button, and the wireframe also has a title.
class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}