import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/models/permit_model.dart';

// Admin-only screen (restricted to admins only by the router) listing every permit residents have filed, where newest ones are shown first
class AdminPermitHistoryScreen extends StatefulWidget {
  // Injected stream is used during widget tests; firestore lets tests
  // run the real query against a fake database.
  final Stream<List<PermitModel>>? permitsStream;
  final FirebaseFirestore? firestore;

  const AdminPermitHistoryScreen({
    super.key,
    this.permitsStream,
    this.firestore,
  });

  @override
  State<AdminPermitHistoryScreen> createState() =>
      _AdminPermitHistoryScreenState();
}

class _AdminPermitHistoryScreenState extends State<AdminPermitHistoryScreen> {
  // Created once so a rebuild doesn't open a new Firestore listener
  late final Stream<List<PermitModel>> _permits;

  @override
  void initState() {
    super.initState();
    _permits = listenToAllPermits();
  }

  // Listen to all permits, newest submissions first.
  Stream<List<PermitModel>> listenToAllPermits() {
    final injected = widget.permitsStream;
    if (injected != null) {
      return injected;
    }

    // each document is converted to a PermitModel
    // created_at is written on every permit so ordering on it never loses documents
    return PermitModel.collectionOf(
            widget.firestore ?? FirebaseFirestore.instance)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  //placeholder for now 
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
        stream: _permits,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return const Center(
              key: Key('permit-error-state'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  SizedBox(height: 12),
                  Text('Unable to load permit history.'),
                  SizedBox(height: 4),
                  Text('Please try again later'),
                ],
              ),
            );
          }

          final permits = snapshot.data ?? [];

          // Empty state
          if (permits.isEmpty) {
            return const Center(
              key: Key('permit-empty-state'),
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
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final permit = permits[index];

                    return _PermitHistoryCard(
                      key: Key('permit-row-${permit.id}'),
                      permit: permit,
                    );
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

  const _PermitHistoryCard({super.key, required this.permit});

//tbf
  Color _getStatusColor(PermitStatus status) {
    switch (status) {
      case PermitStatus.pending:
        return Colors.orange;
      case PermitStatus.active:
        return Colors.green;
      case PermitStatus.denied:
        return Colors.red;
      case PermitStatus.completed:
        return Colors.blue;
      case PermitStatus.overdue:
        return Colors.deepOrange;
      case PermitStatus.cancelled:
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
    final statusColor = _getStatusColor(permit.permitStatus);

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
                    color: statusColor.withAlpha(31),
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