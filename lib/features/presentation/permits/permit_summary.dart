import 'package:material_ui/material_ui.dart';
import 'package:permission_app/features/presentation/permits/permit_request.dart';
import 'package:permission_app/theme/app_theme.dart';
import 'package:permission_app/utils/format.dart' as utils;

/// Read-only summary. Used on step 3 and in the success dialog.
class PermitSummary extends StatelessWidget {
  const PermitSummary(this.request, {super.key});

  final NewPermitRequest request;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Type', request.type.label),
      ('Purpose', request.purpose),
      ('Destination', request.destination),
      ('Expected return', utils.formatNumericDate(request.expectedReturn)),
      ('Contact person', request.contactPerson),
      ('Contact number', request.contactNumber),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).disabledColor)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ),
      ],
    );
  }
}