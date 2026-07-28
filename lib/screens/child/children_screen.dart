import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class ChildrenScreen extends ConsumerStatefulWidget {
  const ChildrenScreen({super.key});
  @override
  ConsumerState<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends ConsumerState<ChildrenScreen> {
  List<Map<String, dynamic>> _children = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) { if (mounted) context.go('/login'); return; }
    final list = await AppDatabase.instance.getChildren(user['id'] as String);
    if (mounted) setState(() { _children = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final ar   = ref.watch(langProvider) == 'ar';
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: PepperGradients.landing),
        child: SafeArea(child: Column(children: [

          // ── Top bar ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              border: Border(bottom: BorderSide(
                  color: PepperColors.purple.withValues(alpha: 0.15))),
            ),
            child: Row(children: [
              const Text('🤖', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ar ? 'بيبر كلينيكال V6' : 'Pepper Clinical V6',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                        color: PepperColors.dark)),
                if (user != null)
                  Text(user['full_name'] ?? '',
                      style: TextStyle(fontSize: 10, color: PepperColors.dark.withValues(alpha: 0.5))),
              ])),
              IconButton(
                icon: const Icon(Icons.logout, color: PepperColors.purple, size: 20),
                onPressed: () {
                  ref.read(authProvider.notifier).setAuth(null);
                  context.go('/');
                },
              ),
            ]),
          ),

          // ── Title ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ar ? '👶 اختر الطفل' : '👶 Select Child',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                        color: PepperColors.dark)),
                Text(ar ? 'اختر طفلاً لبدء جلسة العلاج أو مراجعة التقدم'
                         : 'Select a child to start a session or review progress',
                    style: TextStyle(fontSize: 11, color: PepperColors.dark.withValues(alpha: 0.52))),
              ])),
              ElevatedButton.icon(
                onPressed: () => _addChildDialog(ar),
                icon: const Icon(Icons.add, size: 16),
                label: Text(ar ? 'إضافة' : 'Add',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
              ),
            ]),
          ),

          // ── Children list ──────────────────────────────────────
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: PepperColors.purple))
            : _children.isEmpty
              ? _EmptyState(ar: ar, onAdd: () => _addChildDialog(ar))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _children.length,
                  itemBuilder: (_, i) => _ChildCard(
                    child:     _children[i],
                    ar:        ar,
                    index:     i,
                    onSession: (c) => context.go('/session/${c['id']}'),
                    onDash:    (c) => context.go('/dashboard/${c['id']}'),
                  ),
                ),
          ),

          // ── Plan info bar ──────────────────────────────────────
          if (user != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: PepperColors.purple.withValues(alpha: 0.06),
                border: Border(top: BorderSide(
                    color: PepperColors.purple.withValues(alpha: 0.15))),
              ),
              child: Row(children: [
                Text(
                  ar ? '📋 الخطة: ${user['plan'] ?? 'trial'}'
                     : '📋 Plan: ${user['plan'] ?? 'trial'}',
                  style: const TextStyle(fontSize: 11, color: PepperColors.purple,
                      fontWeight: FontWeight.w600)),
                const Spacer(),
                if (user['expires_at'] != null)
                  Text(
                    ar ? 'ينتهي: ${(user['expires_at'] as String).substring(0, 10)}'
                       : 'Expires: ${(user['expires_at'] as String).substring(0, 10)}',
                    style: TextStyle(fontSize: 10,
                        color: PepperColors.dark.withValues(alpha: 0.45))),
              ]),
            ),
        ])),
      ),
    );
  }

  Future<void> _addChildDialog(bool ar) async {
    final nameCtrl  = TextEditingController();
    int   age       = 6;
    final diagCtrl  = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(ar ? '👶 إضافة طفل' : '👶 Add Child',
              style: const TextStyle(fontWeight: FontWeight.w800, color: PepperColors.dark)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                  hintText: ar ? 'اسم الطفل' : "Child's name",
                  prefixIcon: const Icon(Icons.child_care, color: PepperColors.purple)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PepperColors.purple.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                Text(ar ? 'العمر:' : 'Age:', style: const TextStyle(
                    fontSize: 13, color: PepperColors.dark)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove, color: PepperColors.purple, size: 20),
                  onPressed: () => ss(() => age = (age - 1).clamp(2, 18))),
                Text('$age', style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w700, color: PepperColors.purple)),
                IconButton(
                  icon: const Icon(Icons.add, color: PepperColors.purple, size: 20),
                  onPressed: () => ss(() => age = (age + 1).clamp(2, 18))),
              ]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: diagCtrl,
              decoration: InputDecoration(
                  hintText: ar ? 'التشخيص (اختياري)' : 'Diagnosis (optional)',
                  prefixIcon: const Icon(Icons.medical_information_outlined,
                      color: PepperColors.purple)),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ar ? 'إلغاء' : 'Cancel',
                  style: TextStyle(color: PepperColors.dark.withValues(alpha: 0.5)))),
            ElevatedButton(
              onPressed: () async {
                final n = nameCtrl.text.trim();
                if (n.isEmpty) return;
                final user = ref.read(currentUserProvider);
                if (user == null) return;
                await AppDatabase.instance.addChild(
                  parentId:  user['id'] as String,
                  name:      n, age: age,
                  diagnosis: diagCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
              },
              child: Text(ar ? 'إضافة' : 'Add',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final bool ar;
  final int  index;
  final void Function(Map<String, dynamic>) onSession, onDash;

  const _ChildCard({
    required this.child, required this.ar, required this.index,
    required this.onSession, required this.onDash,
  });

  @override
  Widget build(BuildContext context) {
    final color  = _avatarColor(index);
    final name   = child['name'] as String? ?? '?';
    final age    = child['age']  as int?    ?? 0;
    final sess   = child['total_sessions'] as int? ?? 0;
    final score  = child['total_score']    as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PepperColors.purple.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: PepperColors.purple.withValues(alpha: 0.06),
            blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Top row
          Row(children: [
            // Avatar
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Center(child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white,
                    fontSize: 22, fontWeight: FontWeight.w900),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w800, color: PepperColors.dark)),
              const SizedBox(height: 3),
              Text(
                ar ? 'العمر: $age | الجلسات: $sess | النقاط: $score'
                   : 'Age: $age | Sessions: $sess | Score: $score',
                style: TextStyle(fontSize: 10, color: PepperColors.dark.withValues(alpha: 0.52))),
            ])),
          ]),

          const SizedBox(height: 14),

          // Skill bars (compact)
          Row(children: [
            for (final s in [
              (ar ? 'حركي'  : 'Motor',  child['skill_motor']     ?? 50.0, PepperColors.purple),
              (ar ? 'معرفي' : 'Cog.',   child['skill_cognitive'] ?? 50.0, PepperColors.teal),
              (ar ? 'لفظي'  : 'Verbal', child['skill_verbal']    ?? 50.0, PepperColors.green),
              (ar ? 'رياضي' : 'Math',   child['skill_math']      ?? 50.0, PepperColors.gold),
              (ar ? 'اجتماعي':'Social', child['skill_social']    ?? 50.0, PepperColors.red),
            ])
              Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(children: [
                  Text(s.$1, style: TextStyle(fontSize: 8,
                      color: PepperColors.dark.withValues(alpha: 0.5))),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (s.$2 as double) / 100,
                      backgroundColor: s.$3.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(s.$3),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${(s.$2 as double).toInt()}%',
                      style: TextStyle(fontSize: 8, color: s.$3,
                          fontWeight: FontWeight.w700)),
                ]),
              )),
          ]),

          const SizedBox(height: 14),

          // Action buttons
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => onDash(child),
              icon: const Icon(Icons.bar_chart, size: 16),
              label: Text(ar ? 'لوحة التحكم' : 'Dashboard',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: PepperColors.purple,
                side: const BorderSide(color: PepperColors.purple),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => onSession(child),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(ar ? 'ابدأ الجلسة' : 'Start Session',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10)),
            )),
          ]),
        ]),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.15);
  }

  Color _avatarColor(int i) {
    const colors = [
      PepperColors.purple, PepperColors.teal, PepperColors.green,
      PepperColors.gold,   PepperColors.red,
    ];
    return colors[i % colors.length];
  }
}

class _EmptyState extends StatelessWidget {
  final bool ar;
  final VoidCallback onAdd;
  const _EmptyState({required this.ar, required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('👶', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      Text(ar ? 'لا يوجد أطفال بعد' : 'No children yet',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
              color: PepperColors.dark)),
      const SizedBox(height: 6),
      Text(ar ? 'أضف طفلاً لبدء جلسة العلاج' : 'Add a child to start a therapy session',
          style: TextStyle(fontSize: 12, color: PepperColors.dark.withValues(alpha: 0.5))),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: Text(ar ? 'إضافة طفل' : 'Add Child',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  ));
}
