import 'package:clock/clock.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
// TODO: point these two at wherever they live.
// import 'package:permission_app/features/presentation/permits/late_filing_dialog.dart';
// import 'package:permission_app/services/permit_service.dart';
import 'package:permission_app/features/presentation/permits/permit_request.dart';
import 'package:permission_app/features/presentation/permits/permit_summary.dart';
import 'package:permission_app/features/presentation/permits/permit_validators.dart';
import 'package:permission_app/features/presentation/widgets/error_state.dart';
import 'package:permission_app/features/presentation/widgets/loading_state.dart';
import 'package:permission_app/features/presentation/widgets/range_calendar.dart';
import 'package:permission_app/features/presentation/widgets/step_indicator.dart';
import 'package:permission_app/models/data_enums.dart';
import 'package:permission_app/router/app_router.dart';
import 'package:permission_app/theme/app_theme.dart';
import 'package:permission_app/utils/format.dart' as utils;

typedef PickTime = Future<TimeOfDay?> Function(BuildContext context, TimeOfDay initial);
typedef PickDateRange = Future<DateTimeRange?> Function(
    BuildContext context, DateTime first, DateTime last);

DateTime _systemNow() => clock.now();

Future<TimeOfDay?> _systemPickTime(BuildContext c, TimeOfDay initial) =>
    showTimePicker(context: c, initialTime: initial);

const _headingStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.w800);

class PermitWizardScreen extends StatefulWidget {
  const PermitWizardScreen({
    super.key,
    required this.userId,
    required this.loadFiler,
    required this.createPermit,
    this.now = _systemNow,
    this.pickTime = _systemPickTime,
    this.pickDateRange = showRangeCalendar,
  });

  /// Null when nobody is signed in. Filing is blocked.
  final String? userId;
  final Future<PermitFiler> Function() loadFiler;
  final Future<void> Function(NewPermitRequest request, {String? lateReason}) createPermit;
  final DateTime Function() now;
  final PickTime pickTime;
  final PickDateRange pickDateRange;

  @override
  State<PermitWizardScreen> createState() => _PermitWizardScreenState();
}

class _PermitWizardScreenState extends State<PermitWizardScreen> {
  static const _stepLabels = ['Type', 'Details', 'Confirm'];

  final _detailsKey = GlobalKey<FormState>();
  // Owned here (not in the step widgets) so Prev keeps what was typed.
  final _purpose = TextEditingController();
  final _destination = TextEditingController();
  final _contactPerson = TextEditingController();
  final _contactNumber = TextEditingController();

  int _step = 0;
  PermitType? _type;
  TimeOfDay? _time;
  DateTimeRange? _range;
  PermitFiler? _filer;
  bool _loadingFiler = true;
  bool _loadFailed = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadFiler();
  }

  @override
  void dispose() {
    _purpose.dispose();
    _destination.dispose();
    _contactPerson.dispose();
    _contactNumber.dispose();
    super.dispose();
  }

  Future<void> _loadFiler() async {
    try {
      final filer = await widget.loadFiler();
      if (!mounted) return;
      setState(() {
        _filer = filer;
        _loadingFiler = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingFiler = false;
        _loadFailed = true;
      });
    }
  }

  void _retry() {
    setState(() {
      _loadingFiler = true;
      _loadFailed = false;
    });
    _loadFiler();
  }

  DateTime get _today {
    final n = PermitValidators.manilaWall(widget.now());
    return DateTime(n.year, n.month, n.day);
  }

  DateTime? get _returnAt => _type == null
      ? null
      : PermitSchedule.returnAt(
          _type!,
          now: widget.now(),
          hour: _time?.hour,
          minute: _time?.minute,
          endDate: _range?.end,
        );

  NewPermitRequest _buildRequest() => NewPermitRequest(
        userId: widget.userId!,
        filer: _filer!,
        type: _type!,
        purpose: _purpose.text.trim(),
        destination: _destination.text.trim(),
        expectedReturn: _returnAt!,
        startDate: _type == PermitType.weekend ? _range!.start : null,
        contactPerson: _contactPerson.text.trim(),
        contactNumber: _contactNumber.text.trim(),
      );

  void _chooseType(PermitType? v) => setState(() {
        if (v == _type) return;
        _type = v;
        _time = null; // the old time and dates may not fit the new type
        _range = null;
      });

  void _next() {
    if (_step == 1 && !_detailsKey.currentState!.validate()) return;
    setState(() => _step++);
  }

Future<void> _confirm() async {
  if (_submitting) return; // synchronous guard: a fast double tap creates one permit
  _submitting = true;
  setState(() {});
  final request = _buildRequest();
  try {
    // TODO(late-filing): replace this direct call with the late check:
    //
    // final submitted = await submitWithLateCheck(
    //   context: context,
    //   now: widget.now(),
    //   isAfterCutoff: PermitService.isAfterFilingCutoff,
    //   onSubmit: (lateReason) =>
    //       widget.createPermit(request, lateReason: lateReason),
    // );
    // if (!mounted || !submitted) return; // the student cancelled the dialog
    await widget.createPermit(request);
    if (!mounted) return;
    await _showSuccess(request);
  } catch (_) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not submit your request. Please try again.')),
    );
  } finally {
    if (mounted) setState(() => _submitting = false);
  }
}

  Future<void> _showSuccess(NewPermitRequest request) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Permit request submitted'),
        content: SingleChildScrollView(child: PermitSummary(request)),
        actions: [
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Okay')),
        ],
      ),
    );
    if (mounted) context.go(AppRoutes.home);
  }

  // ---- layout ----

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // the "back to home page" link replaces it
          // TODO: replace with the logo image.
          title: const Text('permissiON',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        ),
        body: Column(children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.action),
              onPressed: _submitting ? null : () => context.go(AppRoutes.home),
              icon: const Icon(Icons.chevron_left),
              label: const Text('back to home page'),
            ),
          ),
          Expanded(child: _content()),
        ]),
      );

  Widget _content() {
    if (widget.userId == null) {
      return const ErrorState(message: 'You need to be signed in to file a permit.');
    }
    if (_loadingFiler) return const LoadingState();
    if (_loadFailed || _filer == null) {
      return ErrorState(
        message: "We couldn't load your profile, so you can't file a permit right now.",
        onRetry: _retry,
      );
    }
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('File a New Permit',
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.flow)),
            const SizedBox(height: AppSpacing.md),
            StepIndicator(current: _step, labels: _stepLabels),
            const SizedBox(height: AppSpacing.lg),
            switch (_step) {
              0 => _typeStep(),
              1 => _detailsStep(),
              _ => _confirmStep(),
            },
          ]),
        ),
      ),
      _buttons(),
    ]);
  }

  Widget _heading(Widget title, String subtitle) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        title,
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: TextStyle(color: AppColors.ink.withValues(alpha: 0.55))),
      ]);

  Widget _typeStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heading(const Text('Type of permit', style: _headingStyle),
            'What type of permit would you like to get?'),
        RadioGroup<PermitType>(
          groupValue: _type,
          onChanged: _chooseType,
          child: Column(children: [
            for (final t in PermitType.values)
              RadioListTile<PermitType>(
                contentPadding: EdgeInsets.zero,
                value: t,
                title: Text(t.label),
              ),
          ]),
        ),
      ]);

  Widget _detailsStep() {
    final type = _type!;
    return Form(
      key: _detailsKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heading(
          Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: type.label,
                  style: const TextStyle(decoration: TextDecoration.underline)),
              const TextSpan(text: ' details'),
            ]),
            style: _headingStyle,
          ),
          'Enter details for your ${type.name} permit.',
        ),
        const SizedBox(height: AppSpacing.md),
        _Labeled(
          'Purpose',
          TextFormField(
            key: const Key('purpose'),
            controller: _purpose,
            decoration: const InputDecoration(hintText: 'Go home'),
            validator: (v) => PermitValidators.notBlank(v, 'Purpose is required'),
          ),
        ),
        _Labeled(
          'Destination',
          TextFormField(
            key: const Key('destination'),
            controller: _destination,
            decoration: const InputDecoration(hintText: 'Iloilo City'),
            validator: (v) => PermitValidators.notBlank(v, 'Destination is required'),
          ),
        ),
        if (type == PermitType.weekend) _datesField(),
        _timeField(type),
        _Labeled(
          'Contact Person',
          TextFormField(
            key: const Key('contact-person'),
            controller: _contactPerson,
            decoration: const InputDecoration(hintText: 'Juan Dela Cruz'),
            validator: (v) => PermitValidators.notBlank(v, 'Contact person is required'),
          ),
        ),
        _Labeled(
          'Contact Person Number',
          TextFormField(
            key: const Key('contact-number'),
            controller: _contactNumber,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '09XXXXXXXXX'),
            validator: PermitValidators.phone,
          ),
        ),
      ]),
    );
  }

  TextStyle get _hint => TextStyle(color: Theme.of(context).hintColor);

  Widget _datesField() => _Labeled(
        'Out of Dorm Duration',
        FormField<DateTimeRange>(
          validator: (_) => PermitValidators.dates(_range?.start, _range?.end),
          builder: (field) {
            final r = _range;
            return InkWell(
              key: const Key('dates'),
              onTap: () async {
                final picked = await widget.pickDateRange(
                    context, _today, _today.add(const Duration(days: 365)));
                if (picked == null || !mounted) return;
                setState(() => _range = DateTimeRange(
                      start: DateUtils.dateOnly(picked.start),
                      end: DateUtils.dateOnly(picked.end),
                    ));
                field.didChange(_range);
                field.validate();
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  errorText: field.errorText,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                    r == null
                      ? 'MM/DD/YYYY - MM/DD/YYYY'
                      : '${utils.formatNumericDate(r.start)} - ${utils.formatNumericDate(r.end)}',
                  style: r == null ? _hint : null,
                ),
              ),
            );
          },
        ),
      );

  Widget _timeField(PermitType type) {
    final (label, helper) = switch (type) {
      PermitType.late => ('Return by', 'Today, ${utils.formatNumericDate(_today)}'),
      PermitType.overnight => (
          'Return time',
          'Tomorrow, ${utils.formatNumericDate(_today.add(const Duration(days: 1)))}'
        ),
      PermitType.weekend => (
          'Return time',
          _range == null ? 'On your last day' : 'On ${utils.formatNumericDate(_range!.end)}'
        ),
    };
    return _Labeled(
      label,
      FormField<TimeOfDay>(
        validator: (_) {
          if (_time == null) return 'Return time is required';
          final r = _returnAt; // null for weekend until the dates are picked
          return r == null ? null : PermitValidators.returnBy(r, widget.now());
        },
        builder: (field) => InkWell(
          key: const Key('return-time'),
          onTap: () async {
            final picked =
                await widget.pickTime(context, _time ?? const TimeOfDay(hour: 20, minute: 0));
            if (picked == null || !mounted) return;
            setState(() => _time = picked);
            field.didChange(picked);
            field.validate();
          },
          child: InputDecorator(
            decoration: InputDecoration(
              helperText: helper,
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.schedule),
            ),
            child: Text(
              _time == null ? 'Select time' : _time!.format(context),
              style: _time == null ? _hint : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _confirmStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heading(const Text('Confirm Form Details', style: _headingStyle),
            'Ensure the details you input is correct.'),
        const SizedBox(height: AppSpacing.md),
        PermitSummary(_buildRequest()),
      ]);

  Widget _buttons() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(children: [
            if (_step > 0)
              OutlinedButton(
                style: AppTheme.flowOutlineButton,
                onPressed: _submitting ? null : () => setState(() => _step--),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chevron_left),
                  Text('Prev'),
                ]),
              ),
            const Spacer(),
            if (_step < 2)
              ElevatedButton(
                style: AppTheme.flowButton,
                onPressed: (_step == 0 && _type == null) ? null : _next,
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Next'),
                  Icon(Icons.chevron_right),
                ]),
              )
            else
              ElevatedButton(
                style: AppTheme.flowButton,
                onPressed: _submitting ? null : _confirm,
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Submit'),
                  Icon(Icons.chevron_right),
                ]),
              ),
          ]),
        ),
      );
}

/// A label above a field, as in Figma.
class _Labeled extends StatelessWidget {
  const _Labeled(this.label, this.child);

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          child,
        ]),
      );
}