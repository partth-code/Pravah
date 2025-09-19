import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/api_models.dart';

class CalendarDropdown extends StatefulWidget {
  final List<Task> tasks;
  final Function(DateTime) onDateSelected;
  final Function(String) onTaskComplete;

  const CalendarDropdown({
    super.key,
    required this.tasks,
    required this.onDateSelected,
    required this.onTaskComplete,
  });

  @override
  State<CalendarDropdown> createState() => _CalendarDropdownState();
}

class _CalendarDropdownState extends State<CalendarDropdown> {
  late DateTime _currentMonth;
  late DateTime _today;
  late DateTime _selectedDate;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(_today.year, _today.month, 1);
    _selectedDate = _today;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = 320.0; // narrower to prevent overflow on small screens
    return Container(
      width: width,
      constraints: const BoxConstraints(maxHeight: 380),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTopCard(),
            const SizedBox(height: 10),
            _buildTaskCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCard() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final totalDays = lastDay.day;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'calendar.previous_month'.tr(),
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
                    });
                    _jumpToStart();
                  },
                ),
                Text(
                  _formatMonthYear(_currentMonth),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  tooltip: 'calendar.next_month'.tr(),
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
                    });
                    _jumpToStart();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'calendar.scroll_left'.tr(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                    onPressed: () {
                      _scrollController.animateTo(
                        (_scrollController.offset - 180).clamp(0, _scrollController.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ListView.separated(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: totalDays,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
                        return _DateChip(
                          date: date,
                          today: _today,
                          selected: _isSameDay(date, _selectedDate),
                          tasks: widget.tasks,
                          onTap: () {
                            setState(() => _selectedDate = date);
                            widget.onDateSelected(date);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'calendar.scroll_right'.tr(),
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      _scrollController.animateTo(
                        (_scrollController.offset + 180).clamp(0, _scrollController.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard() {
    final tasksForSelected = widget.tasks.where((t) => _isSameDay(t.date, _selectedDate)).toList();
    final Task? task = tasksForSelected.isNotEmpty ? tasksForSelected.first : null;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
      child: SizedBox(
        height: 180,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    task == null ? Icons.event_available : _iconForTask(task.title),
                    size: 64,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: Text(
                  task == null ? 'calendar.no_task'.tr() : task.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (task != null && task.status == 'pending') ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onTaskComplete(task.taskId),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: Text('calendar.mark_done'.tr()),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatMonthYear(DateTime dt) {
    final monthKeys = [
      'calendar.months.january', 'calendar.months.february', 'calendar.months.march', 'calendar.months.april', 
      'calendar.months.may', 'calendar.months.june', 'calendar.months.july', 'calendar.months.august', 
      'calendar.months.september', 'calendar.months.october', 'calendar.months.november', 'calendar.months.december'
    ];
    return '${monthKeys[dt.month - 1].tr()}, ${dt.year}';
  }

  void _jumpToStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  IconData _iconForTask(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('irrigation') || lower.contains('water')) return Icons.water_drop;
    if (lower.contains('pest')) return Icons.bug_report;
    if (lower.contains('soil')) return Icons.grass;
    if (lower.contains('harvest')) return Icons.agriculture;
    return Icons.task_alt;
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final DateTime today;
  final bool selected;
  final List<Task> tasks;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.today,
    required this.selected,
    required this.tasks,
    required this.onTap,
  });

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(date, today);
    final isFuture = date.isAfter(today);
    final isPast = date.isBefore(today);

    final tasksOnDate = tasks.where((t) => _isSameDay(t.date, date)).toList();
    final hasDone = tasksOnDate.any((t) => t.status == 'done');
    final hasPending = tasksOnDate.any((t) => t.status != 'done');

    Color bg;
    Color fg;

    if (isToday) {
      bg = Colors.green.shade300; // light green
      fg = Colors.white;
    } else if (isFuture) {
      bg = Colors.white;
      fg = Colors.black54; // faded black
    } else {
      if (hasPending || (!hasDone && tasksOnDate.isNotEmpty)) {
        bg = Colors.black; // not completed
        fg = Colors.white;
      } else if (hasDone) {
        bg = Colors.green.shade900; // dark green
        fg = Colors.white;
      } else {
        bg = Colors.black; // treat no-task past as not completed per spec
        fg = Colors.white;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? Colors.green : Colors.transparent, width: 2),
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: fg,
              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
