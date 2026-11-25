import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/permits/permit_request.dart'; // PermitType.label
import 'package:permission_app/features/presentation/widgets/app_dialog.dart';
import 'package:permission_app/features/presentation/widgets/detail_row.dart';
import 'package:permission_app/features/presentation/widgets/error_state.dart';
import 'package:permission_app/features/presentation/widgets/loading_state.dart';
import 'package:permission_app/features/presentation/widgets/permit_queue_tile.dart';
import 'package:permission_app/models/permit_model.dart';
import 'package:permission_app/theme/app_theme.dart';
import 'package:permission_app/utils/format.dart';

/// Admin review queue: PENDING permits, oldest first, updating live.
/// Body only. AdminShell supplies the sidebar and the header.
class PendingPermitsPage extends StatefulWidget {
  const PendingPermitsPage({
    super.key,
    required this.listen,
    required this.onAccept,
    required this.onDeny,
  });

  /// Called once, and again on Retry.
  final Stream<List<PermitModel>> Function() listen;
  final Future<void> Function(PermitModel permit) onAccept;
  final Future<void> Function(PermitModel permit, String reason) onDeny;

  @override
  State<PendingPermitsPage> createState() => _PendingPermitsPageState();
}

class _PendingPermitsPageState extends State<PendingPermitsPage> {
  late Stream<List<PermitModel>> _stream = widget.listen();
  final _busy = <String>{}; // permit ids with a decision in flight

  /// Tap on a tile. TODO: push '/permits/<id>' instead once a detail page exists.
  Future<void> _review(PermitModel p) async {
    if (_busy.contains(p.id)) return;
    final decision = await showAppDialog<_Decision>(
      context,
      title: 'Review permit',
      child: _ReviewForm(permit: p),
    );
    if (decision == null || !mounted) return;
    await _run(
      p,
      decision.reason == null
          ? () => widget.onAccept(p)
          : () => widget.onDeny(p, decision.reason!),
      decision.reason == null
          ? 'Could not accept the permit. Please try again.'
          : 'Could not deny the permit. Please try again.',
    );
  }

  Future<void> _run(PermitModel p, Future<void> Function() action, String failure) async {
    if (!_busy.add(p.id)) return; // synchronous guard: a double click acts once
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure)));
    } finally {
      if (mounted) setState(() => _busy.remove(p.id));
    }
  }

  String _subtitle(int n) => n == 1
      ? '1 permit waiting for your review.'
      : '$n permits waiting for your review.';

  @override
  Widget build(BuildContext context) => StreamBuilder<List<PermitModel>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            debugPrint('PENDING STREAM ERROR: ${snap.error}');
            return ErrorState(
              message: "We couldn't load the pending permits.",
              onRetry: () => setState(() => _stream = widget.listen()),
            );
          }
          if (!snap.hasData) return const LoadingState();
          final rows = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const Text('Permit Logs',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.xs),
              Text(_subtitle(rows.length), style: const TextStyle(fontSize: 12)),
              const SizedBox(height: AppSpacing.md),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('No pending permits.'),
                )
              else
                Card(
                  child: Column(children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      PermitQueueTile(
                        key: Key('permit-${rows[i].id}'),
                        item: rows[i],
                        onTap: () => _review(rows[i]),
                      ),
                    ],
                  ]),
                ),
            ],
          );
        },
      );
}

/// The admin's choice. A null reason means accepted.
class _Decision {
  const _Decision.accept() : reason = null;
  const _Decision.deny(String this.reason);

  final String? reason;
}

/// Details, then Accept or Deny. Deny asks for a reason first.
class _ReviewForm extends StatefulWidget {
  const _ReviewForm({required this.permit});

  final PermitModel permit;

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  final _reason = TextEditingController();
  bool _denying = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirmDeny() {
    final text = _reason.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Reason is required');
      return;
    }
    Navigator.of(context).pop(_Decision.deny(text));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.permit;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailRow('Type', p.permitType.label),
        DetailRow('Purpose', p.purpose),
        DetailRow('Destination', p.destination),
        DetailRow('Filed at', formatDateTime(p.createdAt)),
        DetailRow('Expected Return', formatDateTime(p.expectedTimeIn)),
        DetailRow('Contact Person', p.emergencyContactPerson),
        DetailRow('Contact Number', p.emergencyContactNum),
        if (p.isLateFiling) DetailRow('Late filing reason', p.lateFilingReasonOrDefault),
        const SizedBox(height: AppSpacing.md),
        if (!_denying)
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton(
              key: const Key('deny-permit'),
              onPressed: () => setState(() => _denying = true),
              child: const Text('Deny'),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton(
              key: const Key('accept-permit'),
              onPressed: () => Navigator.of(context).pop(const _Decision.accept()),
              child: const Text('Accept'),
            ),
          ])
        else ...[
          TextField(
            key: const Key('deny-reason'),
            controller: _reason,
            maxLines: 3,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(labelText: 'Reason for denying', errorText: _error),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: () => setState(() => _denying = false),
              child: const Text('Back'),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton(
              key: const Key('confirm-deny'),
              onPressed: _confirmDeny,
              child: const Text('Deny permit'),
            ),
          ]),
        ],
      ],
    );
  }
}