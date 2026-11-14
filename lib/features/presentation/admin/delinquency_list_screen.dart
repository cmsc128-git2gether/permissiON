import 'package:material_ui/material_ui.dart';

class PermitModelDelinquencyLogModel {
  const PermitModelDelinquencyLogModel({
    required this.id,
    required this.userId,
    required this.studentName,
    required this.reason,
    required this.createdAt,
    this.resolved = false,
  });
  final String id, userId, studentName, reason;
  final DateTime createdAt;
  final bool resolved;
}

class DelinquencyListScreen extends StatelessWidget {
  const DelinquencyListScreen({
    super.key,
    required this.logs,
    required this.onResolve,
  });
  final Stream<List<PermitModelDelinquencyLogModel>> logs;
  final void Function(String logId, String? note) onResolve;

  Future<void> _resolve(BuildContext context, PermitModelDelinquencyLogModel item) async {
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve delinquency'),
        content: TextField(
          controller: note,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (ok == true) {
      final text = note.text.trim();
      onResolve(item.id, text.isEmpty ? null : text);
    }
    note.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Delinquencies')),
        body: StreamBuilder<List<PermitModelDelinquencyLogModel>>(
          stream: logs,
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(child: Text('Could not load delinquencies'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return const Center(child: Text('No delinquencies'));
            }
            final counts = <String, int>{};
            for (final i in items) {
              counts[i.userId] = (counts[i.userId] ?? 0) + 1;
            }
            return ListView(
              children: [
                for (final i in items)
                  ListTile(
                    title: Text('${i.studentName} (${counts[i.userId]} total)'),
                    subtitle: Text(i.reason),
                    trailing: i.resolved
                        ? const Text('Resolved')
                        : TextButton(
                            onPressed: () => _resolve(context, i),
                            child: const Text('Resolve')),
                  ),
              ],
            );
          },
        ),
      );
}