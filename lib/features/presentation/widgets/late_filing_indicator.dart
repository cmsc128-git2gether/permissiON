import 'package:material_ui/material_ui.dart';

class LateFilingIndicator extends StatelessWidget {
  const LateFilingIndicator({
    super.key,
    required this.isLateFiling,
    required this.time,
    required this.lateFilingReasonText,
  });

  final bool isLateFiling;
  final String time;
  final String lateFilingReasonText;

  @override
  Widget build(BuildContext context) {
    if (!isLateFiling) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black87, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Filed past deadline',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text('Filed at $time', style: const TextStyle(fontSize: 14)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Colors.black87),
                ),
                const Text(
                  'Reason',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  lateFilingReasonText,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
