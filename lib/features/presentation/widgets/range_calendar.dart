import 'package:material_ui/material_ui.dart';
import 'package:permission_app/theme/app_theme.dart';

Future<DateTimeRange?> showRangeCalendar(BuildContext context, DateTime first, DateTime last) =>
    showDialog<DateTimeRange>(
      context: context,
      builder: (_) => RangeCalendarDialog(firstDate: first, lastDate: last),
    );

/// Month grid. Tap a start day, then an end day. Confirm returns the range.
class RangeCalendarDialog extends StatefulWidget {
  const RangeCalendarDialog({super.key, required this.firstDate, required this.lastDate});

  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<RangeCalendarDialog> createState() => _RangeCalendarDialogState();
}

class _RangeCalendarDialogState extends State<RangeCalendarDialog> {
  late DateTime _first, _last, _month;
  DateTime? _start, _end;

  @override
  void initState() {
    super.initState();
    _first = DateUtils.dateOnly(widget.firstDate);
    _last = DateUtils.dateOnly(widget.lastDate);
    _month = DateTime(_first.year, _first.month);
  }

  bool get _canGoBack => _month.isAfter(DateTime(_first.year, _first.month));
  bool get _canGoNext => _month.isBefore(DateTime(_last.year, _last.month));

  void _goTo(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  bool _enabled(DateTime d) => !d.isBefore(_first) && !d.isAfter(_last);

  void _tap(DateTime day) => setState(() {
        if (_start == null || _end != null || day.isBefore(_start!)) {
          _start = day; // first tap, or starting over
          _end = null;
        } else {
          _end = day;
        }
      });

  bool _isEnd(DateTime d) => d == _start || d == _end;
  bool _inRange(DateTime d) =>
      _start != null && _end != null && d.isAfter(_start!) && d.isBefore(_end!);

  Widget _cell(DateTime day) {
    final enabled = _enabled(day);
    final isEnd = _isEnd(day);
    return InkWell(
      key: Key('day-${day.toIso8601String().substring(0, 10)}'),
      onTap: enabled ? () => _tap(day) : null,
      child: Container(
        color: _inRange(day) ? AppColors.fieldBg : Colors.transparent,
        alignment: Alignment.center,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnd ? AppColors.flow : Colors.transparent,
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isEnd
                  ? Colors.white
                  : enabled
                      ? AppColors.flow
                      : AppColors.ink.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blanks = _month.weekday % 7; // weeks start on Sunday
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.flow),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              IconButton(
                key: const Key('prev-month'),
                tooltip: 'Previous month',
                icon: const Icon(Icons.chevron_left),
                onPressed: _canGoBack ? () => _goTo(-1) : null,
              ),
              Expanded(
                child: Text(
                  MaterialLocalizations.of(context).formatMonthYear(_month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.flow),
                ),
              ),
              IconButton(
                key: const Key('next-month'),
                tooltip: 'Next month',
                icon: const Icon(Icons.chevron_right),
                onPressed: _canGoNext ? () => _goTo(1) : null,
              ),
            ]),
            Row(children: [
              for (final l in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                Expanded(child: Center(child: Text(l, style: const TextStyle(fontSize: 12)))),
            ]),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < blanks; i++) const SizedBox.shrink(),
                for (var d = 1; d <= days; d++) _cell(DateTime(_month.year, _month.month, d)),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: AppTheme.flowButton,
                onPressed: _start == null
                    ? null
                    : () => Navigator.of(context)
                        .pop(DateTimeRange(start: _start!, end: _end ?? _start!)),
                child: const Text('Confirm'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}