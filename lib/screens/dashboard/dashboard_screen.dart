import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String childId;
  const DashboardScreen({super.key, required this.childId});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic> _analytics = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await AppDatabase.instance.getAnalytics(widget.childId);
    if (mounted) setState(() { _analytics = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final ar = ref.watch(langProvider) == 'ar';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: PepperGradients.landing),
        child: SafeArea(child: Column(children: [

          // ── App bar ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white.withValues(alpha: 0.9),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: PepperColors.purple, size: 18),
                onPressed: () => context.go('/children'),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Text('📊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                ar ? 'لوحة تحكم الوالدين' : 'Parent Dashboard',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: PepperColors.dark),
              )),
              GestureDetector(
                onTap: () => context.go('/session/${widget.childId}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [PepperColors.purpleDark, PepperColors.purple]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(ar ? '▶ جلسة جديدة' : '▶ New Session',
                      style: const TextStyle(color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),

          // ── Content ────────────────────────────────────────────
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: PepperColors.purple))
            : _buildContent(ar),
          ),
        ])),
      ),
    );
  }

  Widget _buildContent(bool ar) {
    final child    = _analytics['child']    as Map<String, dynamic>? ?? {};
    final sessions = _analytics['sessions'] as List<Map<String, dynamic>>? ?? [];
    final skills   = _analytics['skills']   as Map<String, dynamic>? ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Child header ──────────────────────────────────────────
        _ChildHeader(child: child, ar: ar).animate().fadeIn(),

        const SizedBox(height: 16),

        // ── Quick stats ───────────────────────────────────────────
        _QuickStats(child: child, ar: ar, sessions: sessions)
            .animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 16),

        // ── Skills radar / bars ───────────────────────────────────
        _SkillsCard(skills: skills, ar: ar).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 16),

        // ── Progress chart (last 5 sessions) ─────────────────────
        if (sessions.isNotEmpty)
          _ProgressChart(sessions: sessions, ar: ar).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 16),

        // ── Recent sessions table ─────────────────────────────────
        _SessionsTable(sessions: sessions, ar: ar).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Child Header ──────────────────────────────────────────────────
class _ChildHeader extends StatelessWidget {
  final Map<String, dynamic> child;
  final bool ar;
  const _ChildHeader({required this.child, required this.ar});

  @override
  Widget build(BuildContext context) {
    final name  = child['name']           as String? ?? '—';
    final age   = child['age']            as int?    ?? 0;
    final sess  = child['total_sessions'] as int?    ?? 0;
    final score = child['total_score']    as int?    ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PepperColors.purple.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: PepperColors.purple.withValues(alpha: 0.08),
            blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 60, height: 60,
          decoration: const BoxDecoration(
            gradient: PepperGradients.button, shape: BoxShape.circle),
          child: Center(child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontSize: 26,
                fontWeight: FontWeight.w900),
          )),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
              color: PepperColors.dark)),
          const SizedBox(height: 3),
          Text(
            ar ? 'العمر: $age سنوات · $sess جلسة · $score نقطة'
               : 'Age: $age yrs · $sess sessions · $score pts',
            style: TextStyle(fontSize: 11, color: PepperColors.dark.withValues(alpha: 0.52))),
        ])),
      ]),
    );
  }
}

// ── Quick Stats ───────────────────────────────────────────────────
class _QuickStats extends StatelessWidget {
  final Map<String, dynamic> child;
  final List<Map<String, dynamic>> sessions;
  final bool ar;
  const _QuickStats({required this.child, required this.sessions, required this.ar});

  @override
  Widget build(BuildContext context) {
    final totalSess  = child['total_sessions'] as int?    ?? 0;
    final totalScore = child['total_score']    as int?    ?? 0;
    final mastered   = child['total_score']    as int?    ?? 0;
    final avgAttn    = sessions.isEmpty ? 0.0
        : sessions.map((s) => (s['avg_attention'] as double? ?? 0)).reduce((a, b) => a + b)
              / sessions.length;

    final stats = [
      ('🎯', totalSess.toString(), ar ? 'جلسة' : 'Sessions', PepperColors.purple),
      ('⭐', totalScore.toString(), ar ? 'نقطة' : 'Points', PepperColors.gold),
      ('👁', '${avgAttn.toInt()}%', ar ? 'انتباه' : 'Attention', PepperColors.teal),
      ('🌟', mastered.toString(), ar ? 'إنجاز' : 'Mastered', PepperColors.green),
    ];

    return Row(children: stats.map((s) => Expanded(child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: s.$4.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.$4.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Text(s.$1, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(s.$2, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: s.$4)),
        Text(s.$3, style: TextStyle(fontSize: 9,
            color: PepperColors.dark.withValues(alpha: 0.5))),
      ]),
    ))).toList());
  }
}

// ── Skills Card ───────────────────────────────────────────────────
class _SkillsCard extends StatelessWidget {
  final Map<String, dynamic> skills;
  final bool ar;
  const _SkillsCard({required this.skills, required this.ar});

  @override
  Widget build(BuildContext context) {
    final bars = [
      (ar ? 'حركي'   : 'Motor',    skills['motor']     ?? 50.0, PepperColors.purple),
      (ar ? 'معرفي'  : 'Cognitive',skills['cognitive'] ?? 50.0, PepperColors.teal),
      (ar ? 'لفظي'   : 'Verbal',   skills['verbal']    ?? 50.0, PepperColors.green),
      (ar ? 'رياضي'  : 'Math',     skills['math']      ?? 50.0, PepperColors.gold),
      (ar ? 'اجتماعي': 'Social',   skills['social']    ?? 50.0, PepperColors.red),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PepperColors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ar ? '📈 مستوى المهارات' : '📈 Skills Profile',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                color: PepperColors.dark)),
        const SizedBox(height: 14),
        ...bars.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SizedBox(width: 80, child: Text(b.$1,
                  style: TextStyle(fontSize: 11, color: PepperColors.dark.withValues(alpha: 0.7)))),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (b.$2 as double) / 100,
                  backgroundColor: b.$3.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(b.$3),
                  minHeight: 10,
                ),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 36, child: Text(
                '${(b.$2 as double).toInt()}%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: b.$3),
              )),
            ]),
          ]),
        )),
      ]),
    );
  }
}

// ── Progress Chart ────────────────────────────────────────────────
class _ProgressChart extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final bool ar;
  const _ProgressChart({required this.sessions, required this.ar});

  @override
  Widget build(BuildContext context) {
    final recent = sessions.take(7).toList().reversed.toList();
    final spots  = recent.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), (e.value['score'] as int? ?? 0).toDouble())
    ).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PepperColors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ar ? '📊 تقدم النقاط (آخر الجلسات)' : '📊 Score Progress (Recent Sessions)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                color: PepperColors.dark)),
        const SizedBox(height: 14),
        SizedBox(
          height: 150,
          child: spots.length < 2
            ? Center(child: Text(ar ? 'تحتاج 2+ جلسات لعرض الرسم البياني'
                                    : 'Need 2+ sessions to show chart',
                style: TextStyle(color: PepperColors.dark.withValues(alpha: 0.45), fontSize: 12)))
            : LineChart(LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: PepperColors.purple.withValues(alpha: 0.08), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 32,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}',
                        style: TextStyle(fontSize: 9,
                            color: PepperColors.dark.withValues(alpha: 0.45))),
                  )),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text('S${v.toInt() + 1}',
                        style: TextStyle(fontSize: 9,
                            color: PepperColors.dark.withValues(alpha: 0.45))),
                  )),
                  topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots:    spots,
                    isCurved: true,
                    color:    PepperColors.purple,
                    barWidth: 3,
                    dotData:  FlDotData(getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(radius: 4, color: PepperColors.purple,
                            strokeWidth: 2, strokeColor: Colors.white)),
                    belowBarData: BarAreaData(
                      show:  true,
                      color: PepperColors.purple.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              )),
        ),
      ]),
    );
  }
}

// ── Sessions Table ────────────────────────────────────────────────
class _SessionsTable extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final bool ar;
  const _SessionsTable({required this.sessions, required this.ar});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: PepperColors.purple.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(ar ? '📋 الجلسات الأخيرة' : '📋 Recent Sessions',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
              color: PepperColors.dark)),
      const SizedBox(height: 12),
      if (sessions.isEmpty)
        Center(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(ar ? 'لا توجد جلسات بعد' : 'No sessions yet',
              style: TextStyle(color: PepperColors.dark.withValues(alpha: 0.45))),
        ))
      else
        ...sessions.take(8).map((s) => _SessionRow(session: s, ar: ar)),
    ]),
  );
}

class _SessionRow extends StatelessWidget {
  final Map<String, dynamic> session;
  final bool ar;
  const _SessionRow({required this.session, required this.ar});

  @override
  Widget build(BuildContext context) {
    final date   = (session['started_at'] as String? ?? '').split('T').first;
    final score  = session['score']          as int?    ?? 0;
    final ok     = session['tasks_success']  as int?    ?? 0;
    final fail   = session['tasks_fail']     as int?    ?? 0;
    final attn   = session['avg_attention']  as double? ?? 0.0;
    final dur    = session['duration_sec']   as int?    ?? 0;
    final durMin = dur ~/ 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PepperColors.bgGrad1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PepperColors.purple.withValues(alpha: 0.1)),
      ),
      child: Row(children: [
        // Date
        Text(date, style: TextStyle(fontSize: 10,
            color: PepperColors.dark.withValues(alpha: 0.5))),
        const Spacer(),
        // Score
        _Tag('⭐ $score', PepperColors.gold),
        const SizedBox(width: 4),
        _Tag('✅ $ok', PepperColors.green),
        const SizedBox(width: 4),
        _Tag('❌ $fail', PepperColors.red),
        const SizedBox(width: 4),
        _Tag('👁 ${attn.toInt()}%', PepperColors.teal),
        const SizedBox(width: 4),
        _Tag('⏱ ${durMin}m', PepperColors.purple.withValues(alpha: 0.6)),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text, style: TextStyle(fontSize: 9,
        color: color, fontWeight: FontWeight.w700)),
  );
}
