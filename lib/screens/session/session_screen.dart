import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../../core/database.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/ai_service.dart';
import '../../services/task_service.dart';

class SessionScreen extends ConsumerStatefulWidget {
  final String childId;
  const SessionScreen({super.key, required this.childId});
  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen>
    with WidgetsBindingObserver {

  // Camera
  CameraController? _cam;
  bool _camReady = false;
  bool _analyzing = false;

  // AI result
  FrameResult _aiResult = FrameResult.empty;
  Timer? _analysisTimer;

  // Session state
  String?  _sessionId;
  DateTime? _startTime;
  bool     _running  = false;
  bool     _paused   = false;

  // Tasks
  List<Task> _taskPool = [];
  Task?      _currentTask;
  int        _taskIndex = 0;

  // Scores
  int    _score    = 0;
  int    _correct  = 0;
  int    _failed   = 0;
  int    _mastered = 0;
  double _totalAttn= 0;
  int    _attnCount= 0;

  // Feedback
  String _feedback     = '';
  Color  _feedbackColor= PepperColors.green;
  bool   _showFeedback = false;

  // TTS
  final _tts = FlutterTts();

  // Timer display
  Timer? _clockTimer;
  int    _elapsedSec = 0;

  // Child data
  Map<String, dynamic>? _child;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAll();
  }

  Future<void> _initAll() async {
    // Load child
    _child = await AppDatabase.instance.getChild(widget.childId);

    // Init AI
    await AIService.instance.init();

    // Init TTS
    final ar = ref.read(langProvider) == 'ar';
    await _tts.setLanguage(ar ? 'ar-SA' : 'en-US');
    await _tts.setSpeechRate(ar ? 0.45 : 0.50);
    await _tts.setVolume(1.0);

    // Init camera
    await _initCamera();

    // Generate initial task pool
    _taskPool = TaskService.generate(count: 60, lang: ar ? 'ar' : 'en', level: 1);

    if (mounted) setState(() {});
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Prefer front camera
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cam = CameraController(
        cam,
        ResolutionPreset.medium,   // balanced quality vs performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cam!.initialize();
      if (!mounted) return;

      setState(() => _camReady = true);

      // Start AI analysis every 300ms (≈3fps for AI, camera runs at full fps)
      _analysisTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
        if (!_paused && _running) _analyzeFrame();
      });
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _analyzeFrame() async {
    if (_analyzing || _cam == null || !_cam!.value.isInitialized) return;
    _analyzing = true;
    try {
      final image = await _cam!.takePicture();
      // Use AI service with saved path (lighter approach)
      // For real implementation, use camera.startImageStream instead
      _analyzing = false;
    } catch (_) {
      _analyzing = false;
    }
  }

  void _startSession() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final ar = ref.read(langProvider) == 'ar';

    _sessionId = await AppDatabase.instance.startSession(
      userId:   user['id'] as String,
      childId:  widget.childId,
      protocol: 'ABA-DTT',
    );

    setState(() {
      _running    = true;
      _startTime  = DateTime.now();
      _elapsedSec = 0;
    });

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_paused) setState(() => _elapsedSec++);
    });

    _nextTask();
  }

  void _nextTask() {
    if (_taskPool.isEmpty) {
      final ar = ref.read(langProvider) == 'ar';
      _taskPool = TaskService.generate(count: 30, lang: ar ? 'ar' : 'en',
          level: _mastered > 10 ? 2 : 1);
    }
    setState(() {
      _currentTask = _taskPool.removeAt(0);
      _taskIndex++;
      _showFeedback = false;
      _feedback     = '';
    });
    _speak(_currentTask!.instruction);
  }

  void _recordResult(String result) async {
    if (_currentTask == null || !_running) return;

    final tokens = result == 'success' ? _currentTask!.tokens : 0;
    if (result == 'success') {
      _correct++;
      _score += tokens;
      if (_correct % 10 == 0) _mastered++;
    } else {
      _failed++;
    }

    // Update attention history
    _totalAttn += _aiResult.attention;
    _attnCount++;

    // Update child skill
    AppDatabase.instance.updateChildSkill(
      widget.childId,
      _currentTask!.domain,
      result == 'success' ? 2.0 : -0.5,
    );

    // Save task record
    if (_sessionId != null) {
      await AppDatabase.instance.saveTaskRecord(_sessionId!, {
        'type':      _currentTask!.type,
        'name':      _currentTask!.name,
        'domain':    _currentTask!.domain,
        'protocol':  _currentTask!.protocol,
        'level':     _currentTask!.level,
        'result':    result,
        'tokens':    tokens,
        'attention': _aiResult.attention,
        'emotion':   _aiResult.emotion,
      });
    }

    // Show feedback
    final msg   = result == 'success' ? _currentTask!.successMsg : _currentTask!.failMsg;
    final color = result == 'success' ? PepperColors.green : PepperColors.red;
    setState(() { _feedback = msg; _feedbackColor = color; _showFeedback = true; });
    _speak(msg);

    // Auto-advance after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _running) _nextTask();
    });
  }

  Future<void> _endSession() async {
    final ar = ref.read(langProvider) == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(ar ? 'إنهاء الجلسة؟' : 'End Session?',
            style: const TextStyle(fontWeight: FontWeight.w800, color: PepperColors.dark)),
        content: Text(ar ? 'هل تريد إنهاء الجلسة وحفظ التقرير؟'
                         : 'Do you want to end the session and save the report?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text(ar ? 'إلغاء' : 'Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              child: Text(ar ? 'إنهاء وحفظ' : 'End & Save')),
        ],
      ),
    );
    if (confirmed != true) return;

    _clockTimer?.cancel();
    _analysisTimer?.cancel();
    await _tts.stop();

    if (_sessionId != null) {
      final avgAttn = _attnCount > 0 ? _totalAttn / _attnCount : 0.0;
      await AppDatabase.instance.endSession(_sessionId!, {
        'durationSec':     _elapsedSec,
        'score':           _score,
        'tasksTotal':      _correct + _failed,
        'tasksSuccess':    _correct,
        'tasksFail':       _failed,
        'tasksMastered':   _mastered,
        'avgAttention':    avgAttn,
        'dominantEmotion': _aiResult.emotion,
      });
    }

    if (mounted) context.go('/dashboard/${widget.childId}');
  }

  Future<void> _speak(String text) async {
    try { await _tts.speak(text); } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _analysisTimer?.cancel();
    _cam?.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) setState(() => _paused = true);
    if (state == AppLifecycleState.resumed) setState(() => _paused = false);
  }

  String get _elapsed {
    final m = _elapsedSec ~/ 60;
    final s = _elapsedSec % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(langProvider) == 'ar';
    return Scaffold(
      backgroundColor: PepperColors.sessionBg,
      body: SafeArea(child: Column(children: [

        // ── Session top bar ───────────────────────────────────────
        _SessionBar(
          ar:       ar,
          score:    _score,
          correct:  _correct,
          elapsed:  _elapsed,
          attention:_aiResult.attention,
          emotion:  ar ? _aiResult.emotionAr : _aiResult.emotion,
          running:  _running,
          onEnd:    _endSession,
          onPause:  () => setState(() => _paused = !_paused),
          paused:   _paused,
          childName:_child?['name'] as String? ?? '',
        ),

        // ── Main content ──────────────────────────────────────────
        Expanded(child: _running ? _buildSessionContent(ar) : _buildStartScreen(ar)),

        // ── PECS bar ──────────────────────────────────────────────
        if (_running) _PECSBar(ar: ar, onPECS: (phrase) => _speak(phrase)),
      ])),
    );
  }

  Widget _buildStartScreen(bool ar) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('🎯', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      Text(
        ar ? 'جلسة بيبر العلاجية' : 'Pepper Therapy Session',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      const SizedBox(height: 8),
      Text(
        ar ? 'مهام ABA تكيّفية مع تتبع ذكاء اصطناعي'
           : 'Adaptive ABA tasks with AI tracking',
        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55)),
      ),
      const SizedBox(height: 6),
      if (_child != null) Text(
        ar ? '👶 ${_child!['name']}' : '👶 ${_child!['name']}',
        style: const TextStyle(fontSize: 14, color: PepperColors.purpleLight,
            fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 32),
      GestureDetector(
        onTap: _startSession,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [PepperColors.purpleDark, PepperColors.purple]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: PepperColors.purple.withValues(alpha: 0.5),
                blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Text(ar ? '▶  ابدأ الجلسة' : '▶  Start Session',
              style: const TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w800)),
        ),
      ).animate().scale(delay: 200.ms),
      const SizedBox(height: 20),
      if (!_camReady)
        Text(ar ? '⚠️ لم يتم اكتشاف الكاميرا' : '⚠️ Camera not detected',
            style: TextStyle(color: Colors.orange.withValues(alpha: 0.8), fontSize: 11)),
    ],
  ));

  Widget _buildSessionContent(bool ar) => Row(children: [

    // ── Camera panel ──────────────────────────────────────────────
    if (_camReady && _cam != null) SizedBox(
      width: 180,
      child: Column(children: [
        Expanded(child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
          child: CameraPreview(_cam!),
        )),
        Container(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            _AIBadge('👁', '${_aiResult.attention.toInt()}%',
                _attentionColor(_aiResult.attention)),
            const SizedBox(height: 4),
            _AIBadge(ar ? _aiResult.emotionAr : _aiResult.emotion,
                '',  Colors.white70),
            if (_aiResult.eyeContact)
              _AIBadge('👀', ar ? 'تواصل' : 'Contact', Colors.greenAccent),
          ]),
        ),
      ]),
    ),

    // ── Task panel ────────────────────────────────────────────────
    Expanded(child: _currentTask == null
      ? const Center(child: CircularProgressIndicator(color: PepperColors.purple))
      : _TaskPanel(
          task:         _currentTask!,
          ar:           ar,
          showFeedback: _showFeedback,
          feedback:     _feedback,
          feedbackColor:_feedbackColor,
          onSuccess:    () => _recordResult('success'),
          onSkip:       () => _recordResult('skip'),
          onOptions:    _recordResult,
        ),
    ),
  ]);

  Color _attentionColor(double a) =>
      a >= 75 ? Colors.greenAccent :
      a >= 50 ? Colors.yellowAccent :
      a >= 25 ? Colors.orangeAccent : Colors.redAccent;
}

// ── Session Top Bar ───────────────────────────────────────────────
class _SessionBar extends StatelessWidget {
  final bool ar, running, paused;
  final int score, correct;
  final String elapsed, emotion, childName;
  final double attention;
  final VoidCallback onEnd, onPause;

  const _SessionBar({
    required this.ar, required this.score, required this.correct,
    required this.elapsed, required this.attention, required this.emotion,
    required this.running, required this.onEnd, required this.onPause,
    required this.paused, required this.childName,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.5),
      border: Border(bottom: BorderSide(color: PepperColors.purple.withValues(alpha: 0.3))),
    ),
    child: Row(children: [
      // Child name + score
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🧒 $childName',
            style: const TextStyle(color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.w700)),
        Text(ar ? '⭐ $score نقطة · ✅ $correct'
                : '⭐ $score pts · ✅ $correct',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
      ]),
      const Spacer(),
      // Timer
      Text('⏱ $elapsed', style: const TextStyle(
          color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
      const SizedBox(width: 10),
      // Attention
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: PepperColors.purple.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text('👁 ${attention.toInt()}%',
            style: const TextStyle(color: Colors.white, fontSize: 10,
                fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 6),
      if (running) IconButton(
        onPressed: onPause,
        icon: Icon(paused ? Icons.play_arrow : Icons.pause,
            color: Colors.white70, size: 22),
        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
      ),
      const SizedBox(width: 6),
      GestureDetector(
        onTap: onEnd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: PepperColors.red.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(ar ? 'إنهاء' : 'End',
              style: const TextStyle(color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    ]),
  );
}

// ── Task Panel ────────────────────────────────────────────────────
class _TaskPanel extends StatelessWidget {
  final Task task;
  final bool ar, showFeedback;
  final String feedback;
  final Color feedbackColor;
  final VoidCallback onSuccess, onSkip;
  final void Function(String) onOptions;

  const _TaskPanel({
    required this.task, required this.ar, required this.showFeedback,
    required this.feedback, required this.feedbackColor,
    required this.onSuccess, required this.onSkip, required this.onOptions,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      // Task counter + protocol badge
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: PepperColors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(task.protocol,
                style: const TextStyle(color: PepperColors.purpleLight,
                    fontSize: 9, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          Text(task.domain,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9)),
        ]),
      ),

      // Main task area
      Expanded(child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Emoji
          Text(task.em, style: const TextStyle(fontSize: 72))
              .animate().scale(duration: 300.ms, curve: Curves.elasticOut),

          const SizedBox(height: 16),

          // Instruction
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: PepperColors.sessionCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PepperColors.purple.withValues(alpha: 0.3)),
            ),
            child: Text(task.instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w700, height: 1.45),
            ),
          ),

          const SizedBox(height: 16),

          // Options grid (cognitive tasks)
          if (task.options.isNotEmpty)
            Wrap(
              spacing: 8, runSpacing: 8,
              alignment: WrapAlignment.center,
              children: task.options.asMap().entries.map((e) {
                final i   = e.key;
                final opt = e.value;
                return GestureDetector(
                  onTap: () => onOptions(i == task.correct ? 'success' : 'fail'),
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: PepperColors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PepperColors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(opt['em'] ?? '', style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(opt['label'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70,
                                fontSize: 9, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ).animate().scale(delay: (i * 60).ms),
                );
              }).toList(),
            ),

          // Feedback
          if (showFeedback) Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: feedbackColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: feedbackColor.withValues(alpha: 0.4)),
            ),
            child: Text(feedback,
                textAlign: TextAlign.center,
                style: TextStyle(color: feedbackColor, fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ).animate().fadeIn().scale(),
        ]),
      )),

      // Control buttons (motor / word tasks)
      if (task.options.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: onSkip,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: PepperColors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PepperColors.red.withValues(alpha: 0.4)),
                ),
                child: Center(child: Text(ar ? '⏭ تخطّ' : '⏭ Skip',
                    style: const TextStyle(color: Colors.redAccent,
                        fontWeight: FontWeight.w700))),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: GestureDetector(
              onTap: onSuccess,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF34D399)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: PepperColors.green.withValues(alpha: 0.35),
                      blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Center(child: Text(ar ? '✅  أحسنت!' : '✅  Correct!',
                    style: const TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w800))),
              ),
            )),
          ]),
        ),
    ],
  );
}

// ── PECS Bar ──────────────────────────────────────────────────────
class _PECSBar extends StatelessWidget {
  final bool ar;
  final void Function(String) onPECS;

  const _PECSBar({required this.ar, required this.onPECS});

  static const _cardsAr = [
    ('🤲','أريد','أريد هذا'),('➕','أكثر','أريد المزيد'),
    ('🆘','مساعدة','أحتاج مساعدة'),('💧','ماء','أريد ماءً'),
    ('🍎','طعام','أريد طعاماً'),('🚽','حمام','أحتاج الحمام'),
    ('😴','متعب','أنا متعب'),('🏠','بيت','أريد الذهاب للبيت'),
    ('🎮','ألعب','أريد اللعب'),('❌','لا','لا أريد هذا'),
    ('✅','نعم','نعم من فضلك'),('👋','وداع','مع السلامة'),
  ];
  static const _cardsEn = [
    ('🤲','Want','I want this'),('➕','More','I want more'),
    ('🆘','Help','I need help'),('💧','Water','I want water'),
    ('🍎','Food','I want food'),('🚽','Toilet','I need the toilet'),
    ('😴','Tired','I am tired'),('🏠','Home','I want to go home'),
    ('🎮','Play','I want to play'),('❌','No','I do not want this'),
    ('✅','Yes','Yes please'),('👋','Bye','Goodbye'),
  ];

  @override
  Widget build(BuildContext context) {
    final cards = ar ? _cardsAr : _cardsEn;
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: PepperColors.purple.withValues(alpha: 0.25))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: cards.length,
        itemBuilder: (_, i) {
          final c = cards[i];
          return GestureDetector(
            onTap: () => onPECS(c.$3),
            child: Container(
              width: 58,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: PepperColors.purple.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PepperColors.purple.withValues(alpha: 0.35)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(c.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 2),
                Text(c.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70,
                        fontSize: 8, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _AIBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AIBadge(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      if (value.isNotEmpty) ...[
        const SizedBox(width: 3),
        Text(value, style: TextStyle(color: color.withValues(alpha: 0.75), fontSize: 9)),
      ],
    ]),
  );
}
