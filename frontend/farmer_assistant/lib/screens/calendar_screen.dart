import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/api_models.dart';
import '../services/state_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  late DateTime _today;
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(_today.year, _today.month);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StateService>(
      builder: (context, state, _) {
        final tasks = state.tasks;
        return Scaffold(
          appBar: AppBar(
            title: Text('calendar.title'.tr()),
            backgroundColor: Colors.white,
            elevation: 2,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTopCard(tasks),
                const SizedBox(height: 12),
                _buildTodayTaskCard(tasks),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopCard(List<Task> tasks) {
    final monthTitle = _formatMonthYear(_currentMonth);
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final totalDays = lastDay.day;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                    });
                    _jumpToStart();
                  },
                ),
                Text(
                  monthTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  tooltip: 'calendar.next_month'.tr(),
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                    });
                    _jumpToStart();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'calendar.scroll_left'.tr(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    onPressed: () {
                      _scrollController.animateTo(
                        (_scrollController.offset - 200).clamp(0, _scrollController.position.maxScrollExtent),
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
                          tasks: tasks,
                          onTap: () => setState(() => _selectedDate = date),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'calendar.scroll_right'.tr(),
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    onPressed: () {
                      _scrollController.animateTo(
                        (_scrollController.offset + 200).clamp(0, _scrollController.position.maxScrollExtent),
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

  Widget _buildTodayTaskCard(List<Task> tasks) {
    final selected = _selectedDate;
    final tasksForSelected = tasks.where((t) => _isSameDay(t.date, selected)).toList();
    final Task? task = tasksForSelected.isNotEmpty ? tasksForSelected.first : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            // Simple gradient background hinting vector graphic space
            Container(
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB2F7C1), Color(0xFFE8F5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Icon(
                      task == null
                          ? Icons.event_available
                          : _iconForTask(task.title),
                      size: 80,
                      color: const Color(0xFF2E7D32),
                    ),
                    const Spacer(),
                    Text(
                      task == null ? 'calendar.no_task'.tr() : task.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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

    // Determine task status for this date (if any)
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
      // Past dates
      if (hasPending || (!hasDone && tasksOnDate.isNotEmpty)) {
        bg = Colors.black; // not completed
        fg = Colors.white;
      } else if (hasDone) {
        bg = Colors.green.shade900; // dark green
        fg = Colors.white;
      } else {
        // No tasks that day, treat as not completed per spec
        bg = Colors.black;
        fg = Colors.white;
      }
    }

    if (selected) {
      // Emphasize selection with border
      bg = bg;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
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
