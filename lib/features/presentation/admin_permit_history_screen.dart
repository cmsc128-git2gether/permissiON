import 'package:flutter/material.dart';
import 'package:permission_app/models/permit_model.dart';

class AdminPermitHistoryScreen extends StatelessWidget {
  final Stream<List<PermitModel>>? permitsStream;

  const AdminPermitHistoryScreen({
    super.key,
    this.permitsStream,
  });

  // Listen to all permits, newest submissions first.
  // An injected stream is used during widget tests.
  Stream<List<PermitModel>> listenToAllPermits() {
    if (permitsStream != null) {
      return permitsStream!;
    }

    return PermitModel.collection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Permit History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<List<PermitModel>>(
        stream: listenToAllPermits(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  const Text('Unable to load permit history.'),
                  const SizedBox(height: 4),
                  const Text('Please try again later'),
                ],
              ),
            );
          }

          final permits = snapshot.data ?? [];

          // Empty state
          if (permits.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 72,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Permit History Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Submitted permits will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text(
                  'All Permits (${permits.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: permits.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final permit = permits[index];

                    return _PermitHistoryCard(permit: permit);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PermitHistoryCard extends StatelessWidget {
  final PermitModel permit;

  const _PermitHistoryCard({required this.permit});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final date = dateTime.toLocal();

    final month = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][date.month - 1];

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$month ${date.day}, ${date.year} • '
        '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final status = permit.permitStatus.value;
    final statusColor = _getStatusColor(status);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    permit.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Permit type
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 17,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  permit.permitType.value.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Submission date and time
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 17,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(permit.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
