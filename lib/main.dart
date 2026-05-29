import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const BrainApp());
}

// ─────────────────────────────────────────────
// APP ROOT
// ─────────────────────────────────────────────
class BrainApp extends StatelessWidget {
  const BrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Brain – ADHD Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C6FCD),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

class SubTask {
  final String title;
  bool isDone;
  SubTask({required this.title, this.isDone = false});
}

class BigTask {
  final String title;
  final List<SubTask> subTasks;
  bool isMissed;
  BigTask({required this.title, required this.subTasks, this.isMissed = false});
}

enum EnergyLevel { high, medium, low }

// Lamp modes with associated colors
enum LampMode { focus, relax, energize, sleep, off }

// ─────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  EnergyLevel _energy = EnergyLevel.medium;
  final List<BigTask> _tasks = [];
  LampMode _lampMode = LampMode.off;

  late final List<Widget Function()> _pageBuilders;

  @override
  void initState() {
    super.initState();
  }

  void _onLampModeChanged(LampMode mode) {
    setState(() => _lampMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TaskBreakdownPage(
          tasks: _tasks, onTasksChanged: () => setState(() {})),
      FocusTimerPage(onFocusStarted: () {
        setState(() => _lampMode = LampMode.focus);
      }),
      EnergyPage(
        energy: _energy,
        onEnergyChanged: (e) => setState(() => _energy = e),
        tasks: _tasks,
      ),
      WaitingModePage(tasks: _tasks),
      LampPage(
        currentMode: _lampMode,
        onModeChanged: _onLampModeChanged,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1730),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF231F3E),
        indicatorColor: const Color(0xFF7C6FCD),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.auto_fix_high), label: 'Slice'),
          NavigationDestination(
              icon: Icon(Icons.hourglass_bottom), label: 'Focus'),
          NavigationDestination(
              icon: Icon(Icons.battery_charging_full), label: 'Energy'),
          NavigationDestination(
              icon: Icon(Icons.access_time), label: 'Waiting'),
          NavigationDestination(
              icon: Icon(Icons.lightbulb_outline), label: 'Lamp'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FEATURE 1 – TASK BREAKDOWN (Magic Slicer)
// ─────────────────────────────────────────────
class TaskBreakdownPage extends StatefulWidget {
  final List<BigTask> tasks;
  final VoidCallback onTasksChanged;

  const TaskBreakdownPage({
    super.key,
    required this.tasks,
    required this.onTasksChanged,
  });

  @override
  State<TaskBreakdownPage> createState() => _TaskBreakdownPageState();
}

class _TaskBreakdownPageState extends State<TaskBreakdownPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isSlicing = false;

  List<String> _sliceTask(String bigTask) {
    final templates = [
      'Open your notes and write down what you already know about "$bigTask"',
      'Set a 10-min timer and gather only the materials you need',
      'Do the very first physical action for "$bigTask" — just start',
      'Take a 2-min break, drink water, then continue with the next chunk',
      'Review what you did and mark it complete — you did it! 🎉',
    ];
    return templates;
  }

  void _handleSlice() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSlicing = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final steps = _sliceTask(text);
    final task = BigTask(
      title: text,
      subTasks: steps.map((s) => SubTask(title: s)).toList(),
    );

    setState(() {
      widget.tasks.insert(0, task);
      _isSlicing = false;
      _controller.clear();
    });
    widget.onTasksChanged();
  }

  void _resetMissedTask(BigTask task) {
    setState(() {
      task.isMissed = false;
      for (var s in task.subTasks) {
        s.isDone = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
        Text('💙 Reset! Missing a task is totally okay. Fresh start!'),
        backgroundColor: Color(0xFF5B8DEF),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // NEW: Delete a task with confirmation
  void _deleteTask(BigTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2750),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Task?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Remove "${task.title}"? This can\'t be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => widget.tasks.remove(task));
              widget.onTasksChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑 Task deleted'),
                  backgroundColor: Color(0xFF3D1F2F),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔪 Magic Slicer',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'Type a big scary task. We\'ll chop it into 5 tiny steps.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g. "Write my project report"',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF2D2750),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSlicing ? null : _handleSlice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6FCD),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSlicing
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Slice!',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: widget.tasks.isEmpty
                  ? const Center(
                child: Text(
                  'No tasks yet.\nType something above to get started!',
                  textAlign: TextAlign.center,
                  style:
                  TextStyle(color: Colors.white38, fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: widget.tasks.length,
                itemBuilder: (ctx, i) =>
                    _buildTaskCard(widget.tasks[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BigTask task) {
    final done = task.subTasks.where((s) => s.isDone).length;
    final total = task.subTasks.length;
    final isAllDone = done == total && total > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: task.isMissed
            ? const Color(0xFF3D1F2F)
            : isAllDone
            ? const Color(0xFF1D3D2F)
            : const Color(0xFF2D2750),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: task.isMissed
              ? Colors.redAccent.withOpacity(0.4)
              : isAllDone
              ? Colors.greenAccent.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: isAllDone ? Colors.greenAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    decoration:
                    isAllDone ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.greenAccent,
                  ),
                ),
              ),
              // NEW: Delete button (always visible)
              IconButton(
                onPressed: () => _deleteTask(task),
                icon: const Icon(Icons.delete_outline,
                    color: Colors.white24, size: 20),
                tooltip: 'Delete task',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (task.isMissed) ...[
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _resetMissedTask(task),
                  icon: const Icon(Icons.refresh,
                      color: Color(0xFF5B8DEF), size: 18),
                  label: const Text('Reset',
                      style: TextStyle(color: Color(0xFF5B8DEF))),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(total, (i) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: task.subTasks[i].isDone
                        ? isAllDone
                        ? Colors.greenAccent
                        : const Color(0xFF7C6FCD)
                        : Colors.white12,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAllDone
                    ? '✅ All done! Amazing work!'
                    : '$done / $total steps done',
                style: TextStyle(
                  color:
                  isAllDone ? Colors.greenAccent : Colors.white38,
                  fontSize: 12,
                  fontWeight: isAllDone ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...task.subTasks.map((sub) => CheckboxListTile(
            value: sub.isDone,
            onChanged: (val) {
              setState(() => sub.isDone = val ?? false);
              if (task.subTasks.every((s) => s.isDone)) {
                setState(() => task.isMissed = false);
              }
            },
            title: Text(
              sub.title,
              style: TextStyle(
                color: sub.isDone ? Colors.white38 : Colors.white70,
                decoration:
                sub.isDone ? TextDecoration.lineThrough : null,
                fontSize: 13,
              ),
            ),
            activeColor: const Color(0xFF7C6FCD),
            checkColor: Colors.white,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          )),
          if (!task.isMissed && done < total)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => task.isMissed = true),
                child: const Text(
                  'Mark as missed',
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FEATURE 2 – FOCUS TIMER (Visual Hourglass)
//   UPDATED: timer duration selector added
// ─────────────────────────────────────────────
class FocusTimerPage extends StatefulWidget {
  final VoidCallback? onFocusStarted;
  const FocusTimerPage({super.key, this.onFocusStarted});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage> {
  // Available durations in minutes
  static const List<int> _durations = [5, 10, 15, 20, 25, 45];
  int _selectedMinutes = 25;

  int get _totalSeconds => _selectedMinutes * 60;
  late int _secondsLeft = _totalSeconds;
  Timer? _timer;
  bool _isRunning = false;

  double get _progress => _secondsLeft / _totalSeconds;

  String get _timeLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _selectDuration(int minutes) {
    if (_isRunning) return; // don't change while running
    setState(() {
      _selectedMinutes = minutes;
      _secondsLeft = minutes * 60;
    });
  }

  void _startPause() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (_secondsLeft == 0) _secondsLeft = _totalSeconds;
      widget.onFocusStarted?.call();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          if (_secondsLeft > 0) {
            _secondsLeft--;
          } else {
            _timer?.cancel();
            _isRunning = false;
          }
        });
      });
      setState(() => _isRunning = true);
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = _totalSeconds;
      _isRunning = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              '⏳ Focus Session',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'One thing. You\'ve got this.',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 20),

            // ── NEW: Duration selector ──
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2750),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _durations.map((min) {
                  final isSelected = min == _selectedMinutes;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDuration(min),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF7C6FCD)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${min}m',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white38,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_isRunning)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Stop timer to change duration',
                  style: TextStyle(
                      color: Colors.white24, fontSize: 11),
                ),
              ),
            const SizedBox(height: 24),

            // Hourglass visual
            SizedBox(
              width: 180,
              height: 260,
              child: CustomPaint(
                painter: _HourglassPainter(progress: _progress),
                child: Center(
                  child: Text(
                    _timeLabel,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _startPause,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow,
                      color: Colors.white),
                  label: Text(_isRunning ? 'Pause' : 'Start',
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6FCD),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  label: const Text('Reset',
                      style: TextStyle(color: Colors.white54)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),

            if (_secondsLeft == 0)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4A2F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '🎉 Session complete! Take a break.\nYou earned it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HourglassPainter extends CustomPainter {
  final double progress;
  _HourglassPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xFF2D2750)
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7C6FCD), Color(0xFF3E8EDE)],
      ).createShader(Rect.fromLTWH(0, 0, 180, 260))
      ..style = PaintingStyle.fill;

    final rRect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(24));
    canvas.drawRRect(rRect, bgPaint);

    final fillHeight = size.height * progress;
    final fillTop = size.height - fillHeight;
    final fillRect = Rect.fromLTWH(0, fillTop, size.width, fillHeight);
    canvas.clipRRect(rRect);
    canvas.drawRect(fillRect, fillPaint);
  }

  @override
  bool shouldRepaint(_HourglassPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────
// FEATURE 3 – ENERGY MANAGEMENT
// ─────────────────────────────────────────────
class EnergyPage extends StatelessWidget {
  final EnergyLevel energy;
  final ValueChanged<EnergyLevel> onEnergyChanged;
  final List<BigTask> tasks;

  const EnergyPage({
    super.key,
    required this.energy,
    required this.onEnergyChanged,
    required this.tasks,
  });

  Color get _moodColor {
    switch (energy) {
      case EnergyLevel.high:
        return const Color(0xFF4CAF50);
      case EnergyLevel.medium:
        return const Color(0xFFFFB74D);
      case EnergyLevel.low:
        return const Color(0xFF9C6FCD);
    }
  }

  String get _moodLabel {
    switch (energy) {
      case EnergyLevel.high:
        return '⚡ Fully Charged';
      case EnergyLevel.medium:
        return '🌤 Doing Okay';
      case EnergyLevel.low:
        return '🌙 Fried Mode – No Pressure';
    }
  }

  String get _suggestion {
    switch (energy) {
      case EnergyLevel.high:
        return 'Great energy! Tackle your hardest task first.';
      case EnergyLevel.medium:
        return 'Solid. Work on medium-effort tasks and take breaks.';
      case EnergyLevel.low:
        return 'You\'re fried – and that\'s okay. Only do small, gentle tasks. Rest is productive too.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔋 Energy Check-In',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'How are you feeling right now?',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                _energyBtn(context, EnergyLevel.high, '⚡', 'High',
                    Colors.green),
                const SizedBox(width: 10),
                _energyBtn(context, EnergyLevel.medium, '🌤', 'Medium',
                    Colors.orange),
                const SizedBox(width: 10),
                _energyBtn(context, EnergyLevel.low, '🌙', 'Fried',
                    const Color(0xFF9C6FCD)),
              ],
            ),
            const SizedBox(height: 30),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _moodColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _moodColor.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _moodLabel,
                    style: TextStyle(
                        color: _moodColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _suggestion,
                    style:
                    const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (energy == EnergyLevel.low) ...[
              const Text(
                '💜 Low-Power Tasks for You',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...[
                'Drink a glass of water',
                'Reply to one short message',
                'Tidy one small area',
                'Take 5 deep breaths'
              ].map((t) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2750),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF9C6FCD), size: 20),
                    const SizedBox(width: 12),
                    Text(t,
                        style:
                        const TextStyle(color: Colors.white70)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _energyBtn(BuildContext context, EnergyLevel level, String emoji,
      String label, Color color) {
    final isSelected = energy == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => onEnergyChanged(level),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.25)
                : const Color(0xFF2D2750),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.white12,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? color : Colors.white54,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FEATURE 4 – WAITING MODE
// ─────────────────────────────────────────────
class WaitingModePage extends StatefulWidget {
  final List<BigTask> tasks;
  const WaitingModePage({super.key, required this.tasks});

  @override
  State<WaitingModePage> createState() => _WaitingModePageState();
}

class _WaitingModePageState extends State<WaitingModePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _meetingController = TextEditingController();
  TimeOfDay? _meetingTime;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _smallWins = [
    '📧 Reply to one email',
    '🗂 Organize your desktop',
    '💧 Drink water & stretch',
    '📝 Write tomorrow\'s 3 priorities',
    '🧹 Clear one surface around you',
    '📱 Delete 5 unused apps',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _meetingController.dispose();
    super.dispose();
  }

  int? get _minutesUntilMeeting {
    if (_meetingTime == null) return null;
    final now = TimeOfDay.now();
    final nowMins = now.hour * 60 + now.minute;
    final meetMins = _meetingTime!.hour * 60 + _meetingTime!.minute;
    final diff = meetMins - nowMins;
    return diff > 0 ? diff : null;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _meetingTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final mins = _minutesUntilMeeting;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💤 Waiting Mode',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Got a meeting coming up? Let\'s fill the gap wisely.',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2750),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Color(0xFF7C6FCD)),
                    const SizedBox(width: 12),
                    Text(
                      _meetingTime == null
                          ? 'Tap to set your meeting time'
                          : 'Meeting at ${_meetingTime!.format(context)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.white38),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_meetingTime != null) ...[
              Center(
                child: FadeTransition(
                  opacity: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E2D60),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite,
                            color: Color(0xFF7C6FCD), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          mins != null
                              ? '$mins minutes until your meeting'
                              : 'Meeting time has passed',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              '⚡ 15-Minute Small Wins',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _smallWins.length,
                itemBuilder: (ctx, i) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2750),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _smallWins[i],
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FEATURE 5 – LAMP (Smart Light Control)
//   NEW: Bluetooth/WiFi lamp with mood colors
// ─────────────────────────────────────────────

/// Each lamp mode's configuration
class LampModeConfig {
  final String emoji;
  final String label;
  final String description;
  final Color color;
  final Color ambientColor; // warmer glow for UI

  const LampModeConfig({
    required this.emoji,
    required this.label,
    required this.description,
    required this.color,
    required this.ambientColor,
  });
}

const Map<LampMode, LampModeConfig> lampModes = {
  LampMode.focus: LampModeConfig(
    emoji: '🎯',
    label: 'Focus',
    description: 'Cool white — sharp, alert, on-task.',
    color: Color(0xFFB8D4FF),
    ambientColor: Color(0xFF1A2A4A),
  ),
  LampMode.relax: LampModeConfig(
    emoji: '🌿',
    label: 'Relax',
    description: 'Warm amber — calm your nervous system.',
    color: Color(0xFFFFCC80),
    ambientColor: Color(0xFF3A2A10),
  ),
  LampMode.energize: LampModeConfig(
    emoji: '⚡',
    label: 'Energize',
    description: 'Bright daylight — get that boost going.',
    color: Color(0xFFFFFFCC),
    ambientColor: Color(0xFF2A2A10),
  ),
  LampMode.sleep: LampModeConfig(
    emoji: '🌙',
    label: 'Sleep',
    description: 'Deep red — wind down, no blue light.',
    color: Color(0xFFFF7070),
    ambientColor: Color(0xFF2A0A0A),
  ),
  LampMode.off: LampModeConfig(
    emoji: '💤',
    label: 'Off',
    description: 'Lamp is off.',
    color: Color(0xFF444466),
    ambientColor: Color(0xFF1A1730),
  ),
};

enum ConnectionType { bluetooth, wifi }

class LampPage extends StatefulWidget {
  final LampMode currentMode;
  final ValueChanged<LampMode> onModeChanged;

  const LampPage({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  State<LampPage> createState() => _LampPageState();
}

class _LampPageState extends State<LampPage>
    with SingleTickerProviderStateMixin {
  ConnectionType _connectionType = ConnectionType.bluetooth;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectedDeviceName;
  final TextEditingController _ipController =
  TextEditingController(text: '192.168.1.100');
  double _brightness = 0.8;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnimation = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    // Simulate connection handshake
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isConnecting = false;
      _isConnected = true;
      _connectedDeviceName = _connectionType == ConnectionType.bluetooth
          ? 'TheBrain-Lamp-BT'
          : _ipController.text;
    });
  }

  void _disconnect() {
    setState(() {
      _isConnected = false;
      _connectedDeviceName = null;
    });
  }

  void _setMode(LampMode mode) {
    widget.onModeChanged(mode);
    // In a real app: send HTTP/BLE command here
    // e.g. http.post('http://${_ipController.text}/color', body: {...})
  }

  @override
  Widget build(BuildContext context) {
    final config = lampModes[widget.currentMode]!;
    final lampColor = config.color;

    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        color: Color.lerp(
            const Color(0xFF1A1730), config.ambientColor, 0.6)!,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '💡 Smart Lamp',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Spacer(),
                  // Connection status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isConnected
                          ? Colors.green.withOpacity(0.2)
                          : Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isConnected
                            ? Colors.greenAccent
                            : Colors.white24,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isConnected
                              ? Icons.circle
                              : Icons.circle_outlined,
                          color: _isConnected
                              ? Colors.greenAccent
                              : Colors.white38,
                          size: 8,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isConnected ? 'Connected' : 'Not connected',
                          style: TextStyle(
                            color: _isConnected
                                ? Colors.greenAccent
                                : Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _isConnected
                    ? 'Controlling: $_connectedDeviceName'
                    : 'Connect your lamp via Bluetooth or WiFi',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // ── Lamp visual ──
              Center(
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (_, __) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow
                        if (_isConnected &&
                            widget.currentMode != LampMode.off)
                          Container(
                            width: 140 * _glowAnimation.value,
                            height: 140 * _glowAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: lampColor.withOpacity(
                                  0.15 * _glowAnimation.value),
                            ),
                          ),
                        // Inner lamp circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isConnected &&
                                widget.currentMode != LampMode.off
                                ? lampColor.withOpacity(0.9)
                                : const Color(0xFF2D2750),
                            boxShadow: _isConnected &&
                                widget.currentMode != LampMode.off
                                ? [
                              BoxShadow(
                                color: lampColor.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 10,
                              )
                            ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              config.emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    config.label,
                    key: ValueKey(widget.currentMode),
                    style: TextStyle(
                      color: _isConnected ? lampColor : Colors.white38,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  config.description,
                  style:
                  const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),

              // ── Mode selector ──
              const Text(
                'Choose Mode',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: LampMode.values.map((mode) {
                    final mc = lampModes[mode]!;
                    final isSelected = widget.currentMode == mode;
                    return GestureDetector(
                      onTap: () => _setMode(mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 80,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? mc.color.withOpacity(0.25)
                              : const Color(0xFF2D2750),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                            isSelected ? mc.color : Colors.white12,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(mc.emoji,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(
                              mc.label,
                              style: TextStyle(
                                color: isSelected
                                    ? mc.color
                                    : Colors.white54,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // ── Brightness slider ──
              if (_isConnected) ...[
                Row(
                  children: [
                    const Icon(Icons.brightness_low,
                        color: Colors.white38, size: 18),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: lampColor,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: lampColor,
                          overlayColor: lampColor.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: _brightness,
                          onChanged: (v) =>
                              setState(() => _brightness = v),
                          min: 0.1,
                          max: 1.0,
                        ),
                      ),
                    ),
                    const Icon(Icons.brightness_high,
                        color: Colors.white70, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // ── Connection panel ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2750).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Connection',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Toggle BT / WiFi
                    Row(
                      children: [
                        _connTypeBtn(ConnectionType.bluetooth,
                            Icons.bluetooth, 'Bluetooth'),
                        const SizedBox(width: 10),
                        _connTypeBtn(
                            ConnectionType.wifi, Icons.wifi, 'WiFi'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // WiFi IP input
                    if (_connectionType == ConnectionType.wifi)
                      TextField(
                        controller: _ipController,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Lamp IP Address',
                          labelStyle:
                          const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF1A1730),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixText: 'http://',
                          prefixStyle:
                          const TextStyle(color: Colors.white38),
                        ),
                      ),
                    if (_connectionType == ConnectionType.wifi)
                      const SizedBox(height: 12),

                    // Connect / Disconnect button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isConnecting
                            ? null
                            : _isConnected
                            ? _disconnect
                            : _connect,
                        icon: _isConnecting
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                            : Icon(
                          _isConnected
                              ? Icons.link_off
                              : _connectionType ==
                              ConnectionType.bluetooth
                              ? Icons.bluetooth_searching
                              : Icons.wifi_find,
                          color: Colors.white,
                        ),
                        label: Text(
                          _isConnecting
                              ? 'Connecting...'
                              : _isConnected
                              ? 'Disconnect'
                              : _connectionType ==
                              ConnectionType.bluetooth
                              ? 'Scan & Connect'
                              : 'Connect via WiFi',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isConnected
                              ? Colors.redAccent.withOpacity(0.7)
                              : const Color(0xFF7C6FCD),
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                    // Note about real integration
                    if (!_isConnected)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          '💡 Works with Govee, WLED, Home Assistant, or any REST/BLE lamp.',
                          style: const TextStyle(
                              color: Colors.white24, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _connTypeBtn(
      ConnectionType type, IconData icon, String label) {
    final isSelected = _connectionType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _connectionType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF7C6FCD).withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF7C6FCD)
                  : Colors.white12,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color:
                  isSelected ? Colors.white : Colors.white38,
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color:
                  isSelected ? Colors.white : Colors.white38,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}