// Pepper Clinical — Landing Screen
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../main.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});
  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen>
    with TickerProviderStateMixin {

  late AnimationController _heroCtrl;
  late AnimationController _orbitCtrl;
  late AnimationController _puzzleCtrl;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _heroCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _orbitCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 7))
      ..repeat();
    _puzzleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _orbitCtrl.dispose();
    _puzzleCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    final ar   = lang == 'ar';
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated puzzle background
          _PuzzleBackground(controller: _puzzleCtrl),

          // Main content
          Container(
            decoration: const BoxDecoration(gradient: PepperGradients.landing),
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                // ── NAV ────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: const Color(0xF0EDE9FE),
                  title: Text(
                    '🤖  ${ar ? 'بيبر كلينيكال' : 'Pepper Clinical'}  V6',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: PepperColors.dark,
                    ),
                  ),
                  actions: [
                    _NavBtn(
                      label: ar ? 'دخول' : 'Login',
                      icon: '🔑',
                      outlined: true,
                      onTap: () => context.go('/login'),
                    ),
                    const SizedBox(width: 8),
                    _NavBtn(
                      label: ar ? 'تجربة مجانية' : 'Free Trial',
                      icon: '🆓',
                      onTap: () => context.go('/trial'),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),

                // ── HERO ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: size.height * 0.90,
                    child: _HeroSection(
                      ar: ar,
                      heroCtrl:  _heroCtrl,
                      orbitCtrl: _orbitCtrl,
                      onTrial: () => context.go('/trial'),
                      onSub:   () => context.go('/trial'),
                    ),
                  ),
                ),

                // ── STATS BAR ──────────────────────────────────────
                SliverToBoxAdapter(child: _StatsBar(ar: ar)),

                // ── LOVE SECTION ───────────────────────────────────
                SliverToBoxAdapter(child: _LoveSection(ar: ar)),

                // ── ASD INFO ───────────────────────────────────────
                SliverToBoxAdapter(child: _ASDSection(ar: ar)),

                // ── FEATURES ───────────────────────────────────────
                SliverToBoxAdapter(child: _FeaturesSection(ar: ar)),

                // ── LETTER ─────────────────────────────────────────
                SliverToBoxAdapter(child: _LetterSection(ar: ar)),

                // ── SUPPORT WORDS ──────────────────────────────────
                SliverToBoxAdapter(child: _SupportWords(ar: ar)),

                // ── PRICING ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _PricingSection(
                    ar: ar,
                    onTrial: () => context.go('/trial'),
                    onSub:   () => context.go('/trial'),
                  ),
                ),

                // ── FOOTER ─────────────────────────────────────────
                SliverToBoxAdapter(child: _Footer(ar: ar)),

                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ),
          ),

          // Language toggle
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: ar ? null : 16,
            right: ar ? 16 : null,
            child: _LangToggle(ar: ar, ref: ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSupport(context, ar),
        backgroundColor: PepperColors.purple,
        icon: const Text('💬', style: TextStyle(fontSize: 16)),
        label: Text(ar ? 'الدعم' : 'Support',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showSupport(BuildContext ctx, bool ar) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SupportSheet(ar: ar),
    );
  }
}

// ── Puzzle Background ─────────────────────────────────────────────
class _PuzzleBackground extends StatelessWidget {
  final AnimationController controller;
  const _PuzzleBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    final emojis = ['🧩','💙','💜','💛','🩷','🧩','💚'];
    final rng = Random(42); // fixed seed for consistent layout

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Stack(
        children: List.generate(20, (i) {
          final x = rng.nextDouble();
          final baseY = rng.nextDouble();
          final speed = 0.4 + rng.nextDouble() * 0.6;
          final y = (baseY + controller.value * speed) % 1.2 - 0.1;
          final size = 16.0 + rng.nextDouble() * 20;

          return Positioned(
            left: x * MediaQuery.of(context).size.width,
            top:  y * MediaQuery.of(context).size.height,
            child: Opacity(
              opacity: 0.07,
              child: Text(
                emojis[i % emojis.length],
                style: TextStyle(fontSize: size),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Hero Section ──────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final bool ar;
  final AnimationController heroCtrl, orbitCtrl;
  final VoidCallback onTrial, onSub;

  const _HeroSection({
    required this.ar, required this.heroCtrl, required this.orbitCtrl,
    required this.onTrial, required this.onSub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated child with orbiting hearts
        SizedBox(
          width: 200, height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer orbit ring
              AnimatedBuilder(
                animation: orbitCtrl,
                builder: (_, __) => Transform.rotate(
                  angle: orbitCtrl.value * 2 * pi,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (int i = 0; i < 4; i++)
                        Transform.translate(
                          offset: Offset(
                            85 * cos(i * pi / 2),
                            85 * sin(i * pi / 2),
                          ),
                          child: Transform.rotate(
                            angle: -orbitCtrl.value * 2 * pi,
                            child: Text(['💙','💜','💛','🩷'][i],
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Inner orbit (slower, reverse)
              AnimatedBuilder(
                animation: orbitCtrl,
                builder: (_, __) => Transform.rotate(
                  angle: -orbitCtrl.value * pi,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(60, 0),
                        child: Transform.rotate(
                          angle: orbitCtrl.value * pi,
                          child: const Text('🤝', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(-60, 0),
                        child: Transform.rotate(
                          angle: orbitCtrl.value * pi,
                          child: const Text('⭐', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Pulsing rings
              AnimatedBuilder(
                animation: heroCtrl,
                builder: (_, __) => Container(
                  width: 130 + heroCtrl.value * 8,
                  height: 130 + heroCtrl.value * 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: PepperColors.purple.withValues(alpha: 0.25 - heroCtrl.value * 0.1),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: PepperColors.purple.withValues(alpha: 0.15),
                    width: 1,
                    style: BorderStyle.none,
                  ),
                ),
              ),
              // Child emoji
              AnimatedBuilder(
                animation: heroCtrl,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, -6 * heroCtrl.value),
                  child: const Text('🧒', style: TextStyle(fontSize: 60)),
                ),
              ),
              // Floating hearts
              ..._FloatingHearts.build(heroCtrl),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: PepperColors.purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: PepperColors.purple.withValues(alpha: 0.35)),
          ),
          child: Text(
            ar ? '🤖 ذكاء اصطناعي سريري · ABA · TEACCH · ESDM'
               : '🤖 AI Clinical System · ABA · TEACCH · ESDM',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: PepperColors.purpleDark, letterSpacing: 0.5),
          ),
        ),

        const SizedBox(height: 16),

        // Title
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 36,
                fontWeight: FontWeight.w900, height: 1.1),
            children: [
              WidgetSpan(
                child: ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [PepperColors.purpleDark, PepperColors.purple],
                  ).createShader(b),
                  child: Text(
                    ar ? 'بيبر كلينيكال\n' : 'Pepper Clinical\n',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ),
              ),
              TextSpan(
                text: ar ? 'إنفينيتي V6' : 'Infinity V6',
                style: const TextStyle(color: Color(0xFF9333EA), fontSize: 32),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            ar ? 'نظام ذكاء اصطناعي متكامل لدعم علاج طيف التوحد —\nتتبع مباشر، 100K+ مهمة، وتقارير سريرية فورية.'
               : 'Complete AI clinical support for ASD —\nreal-time tracking, 100K+ adaptive tasks, instant reports.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: PepperColors.dark.withValues(alpha: 0.65),
                height: 1.6),
          ),
        ),

        const SizedBox(height: 28),

        // CTA Buttons
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            _GradientButton(
              label: ar ? '🆓 ابدأ تجربة مجانية 15 يوماً' : '🆓 Start 15-Day Free Trial',
              onTap: onTrial,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
            _OutlineButton(
              label: ar ? '💎 اشترك الآن' : '💎 Subscribe Now',
              onTap: onSub,
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.3),
          ],
        ),

        const SizedBox(height: 16),
        Text(
          ar ? '🔒 بدون بطاقة · ✅ يعمل بلا إنترنت · 🌐 عربي وإنجليزي'
             : '🔒 No credit card · ✅ Works offline · 🌐 Arabic & English',
          style: TextStyle(fontSize: 10, color: PepperColors.dark.withValues(alpha: 0.45)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FloatingHearts {
  static List<Widget> build(AnimationController ctrl) {
    final data = [
      (0.28, 0.12, 2.6, 0.0,  '💙'),
      (0.58, 0.16, 3.0, 0.9,  '💜'),
      (0.72, 0.08, 2.3, 1.7,  '🧩'),
      (0.18, 0.20, 2.8, 2.4,  '💛'),
    ];
    return data.map((d) => AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final progress = ((ctrl.value + d.$4 / d.$3) % 1.0);
        return Positioned(
          left: 100 * d.$1,
          bottom: 100 * d.$2 + 80 * progress,
          child: Opacity(
            opacity: progress < 0.9 ? (1 - progress) * 0.9 : 0,
            child: Text(d.$5, style: const TextStyle(fontSize: 14)),
          ),
        );
      },
    )).toList();
  }
}

// ── Stats Bar ─────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final bool ar;
  const _StatsBar({required this.ar});

  @override
  Widget build(BuildContext context) {
    final items = ar
      ? [('100K+','مهمة'),('25+','مهارة'),('32','PECS'),('13','مزاج'),('AI','مستشار')]
      : [('100K+','Tasks'),('25+','Skills'),('32','PECS'),('13','Moods'),('AI','Advisor')];

    return Container(
      color: Colors.white.withValues(alpha: 0.62),
      child: Row(
        children: items.map((item) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: PepperColors.purple.withValues(alpha: 0.09)),
              ),
            ),
            child: Column(
              children: [
                Text(item.$1, style: const TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w900, color: PepperColors.purple)),
                const SizedBox(height: 2),
                Text(item.$2, style: TextStyle(fontSize: 9,
                    color: PepperColors.dark.withValues(alpha: 0.55),
                    letterSpacing: 0.5)),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}

// ── Love Section ──────────────────────────────────────────────────
class _LoveSection extends StatelessWidget {
  final bool ar;
  const _LoveSection({required this.ar});

  @override
  Widget build(BuildContext context) {
    final cards = ar
      ? [('💙','أنت مقبول','بكل اختلافاتك الرائعة'),
         ('🌟','أنت نجم','مواهبك تنتظر من يكتشفها'),
         ('🤝','لستَ وحدك','بيبر معك في كل خطوة'),
         ('🧩','أنت مكتمل','لا تحتاج إصلاحاً')]
      : [('💙','You Are Accepted','With all your differences'),
         ('🌟','You Are a Star','Your talents await'),
         ('🤝','You Are Not Alone','Pepper is with you'),
         ('🧩','You Are Complete',"You don't need fixing")];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Column(
        children: [
          _SectionTitle(ar ? '💙 معاً نصنع فرقاً' : '💙 Together We Make a Difference'),
          _SectionSub(ar ? 'كل طفل يستحق أن يُرى ويُحتفى به'
                         : 'Every child deserves to be seen and celebrated'),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: cards.map((c) => _LoveCard(em: c.$1, title: c.$2, desc: c.$3))
                .toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PepperColors.purple.withValues(alpha: 0.16)),
            ),
            child: Column(
              children: [
                Text(
                  ar ? '"التوحد ليس نهاية — إنه بداية رحلة رائعة. كل طفل في الطيف له بصمة فريدة على هذا العالم."'
                     : '"Autism is not an ending — it is the beginning of a wonderful journey. Every child has a unique imprint on this world."',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic,
                      color: PepperColors.dark.withValues(alpha: 0.8), height: 1.7),
                ),
                const SizedBox(height: 8),
                Text(
                  ar ? '— لمياء فضل المولى حامد علي · مصممة بيبر كلينيكال'
                     : '— Lamya Fadlulmola Hamed Ali · Designer of Pepper Clinical',
                  style: TextStyle(fontSize: 10,
                      color: PepperColors.dark.withValues(alpha: 0.45)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoveCard extends StatelessWidget {
  final String em, title, desc;
  const _LoveCard({required this.em, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: PepperColors.purple.withValues(alpha: 0.16)),
      boxShadow: [BoxShadow(color: PepperColors.purple.withValues(alpha: 0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(em, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 11,
            fontWeight: FontWeight.w700, color: PepperColors.darkMid)),
        const SizedBox(height: 3),
        Text(desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 9,
            color: PepperColors.dark.withValues(alpha: 0.58))),
      ],
    ),
  );
}

// ── ASD Info ──────────────────────────────────────────────────────
class _ASDSection extends StatelessWidget {
  final bool ar;
  const _ASDSection({required this.ar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final c in [
              (Color(0xFFE74C3C),'🧩'),(Color(0xFF3498DB),'💙'),
              (Color(0xFFF1C40F),'🧩'),(Color(0xFF2ECC71),'💙'),
              (Color(0xFF9B59B6),'🧩'),
            ])
              Container(
                width: 26, height: 26,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(color: c.$1, borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text(c.$2, style: const TextStyle(fontSize: 14))),
              ),
          ]),
          const SizedBox(height: 12),
          _SectionTitle(ar ? 'ما هو طيف التوحد؟' : 'About Autism Spectrum Disorder'),
          _SectionSub(ar ? 'معلومات علمية لكل أسرة ومعالج'
                         : 'Science-based information for every family'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PepperColors.purple.withValues(alpha: 0.15)),
            ),
            child: Text(
              ar ? 'اضطراب طيف التوحد (ASD) حالة تطورية عصبية تؤثر على التواصل والتفاعل الاجتماعي. الدعم المبكر يُحدث فرقاً هائلاً — 1 من كل 36 طفلاً يُشخَّص عالمياً (CDC 2023). كل طفل في الطيف مميز بطريقته الخاصة.'
                 : 'Autism Spectrum Disorder (ASD) is a developmental neurological condition affecting communication and social interaction. Early support makes a huge difference — 1 in 36 children diagnosed globally (CDC 2023). Every child on the spectrum is unique.',
              style: TextStyle(fontSize: 12, color: PepperColors.dark.withValues(alpha: 0.78),
                  height: 1.7),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Features Section ──────────────────────────────────────────────
class _FeaturesSection extends StatelessWidget {
  final bool ar;
  const _FeaturesSection({required this.ar});

  @override
  Widget build(BuildContext context) {
    final feats = ar
      ? [('🎯','ABA تكيّفي','مهام DTT مع تعزيز فوري'),
         ('📹','تتبع حي','تحليل مشاعر 100% محلي'),
         ('🤖','روبوت بيبر','يتكلم بصوت عربي طبيعي'),
         ('📊','تقارير PDF','تقرير بعد كل جلسة'),
         ('🎭','فلتر AR','احتفال بعد 10 مهام'),
         ('🌈','لوحة المزاج','13 حالة مع استراتيجيات')]
      : [('🎯','Adaptive ABA','DTT tasks with reinforcement'),
         ('📹','Live AI Tracking','100% on-device analysis'),
         ('🤖','Pepper AI Robot','Speaks naturally'),
         ('📊','Clinical Reports','PDF after every session'),
         ('🎭','AR Celebration','After 10 correct tasks'),
         ('🌈','Mood Board','13 moods + strategies')];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Column(
        children: [
          _SectionTitle(ar ? 'المميزات الرئيسية' : 'Key Features'),
          _SectionSub(ar ? 'تقنية متقدمة تعمل بلا إنترنت'
                         : 'Advanced technology — works offline'),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: feats.map((f) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PepperColors.purple.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.$1, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 6),
                  Text(f.$2, style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w700, color: PepperColors.darkMid)),
                  const SizedBox(height: 3),
                  Text(f.$3, style: TextStyle(fontSize: 9,
                      color: PepperColors.dark.withValues(alpha: 0.56))),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Letter From Designer ──────────────────────────────────────────
class _LetterSection extends StatelessWidget {
  final bool ar;
  const _LetterSection({required this.ar});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
    child: Column(children: [
      _SectionTitle(ar ? '💌 رسالة من المصممة' : '💌 A Message from the Designer'),
      _SectionSub('Lamya Fadlulmola Hamed Ali'),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PepperColors.purple.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: PepperColors.purple.withValues(alpha: 0.07),
              blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(
                gradient: PepperGradients.button,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('لم',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 14))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lamya Fadlulmola Hamed Ali',
                    style: TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 12, color: PepperColors.dark)),
                Text(ar ? 'مصممة بيبر كلينيكال إنفينيتي V6'
                         : 'Designer of Pepper Clinical Infinity V6',
                  style: TextStyle(fontSize: 10,
                      color: PepperColors.dark.withValues(alpha: 0.5))),
              ],
            )),
          ]),
          const SizedBox(height: 14),
          Text(
            ar ? 'إلى أطفال طيف التوحد وأسرهم — أنتم لستم بحاجة إلى التغيير، أنتم بحاجة إلى عالم يفهمكم. كل طفل في الطيف مليء بالمواهب التي تنتظر من يراها.\n\nبنيت بيبر لأن التقنية يمكن أن تكون جسراً بين الطفل وعالمه.\n\nوإلى كل طفل سيستخدم بيبر: أنت رائع ومميز وقادر على أكثر مما تتخيل. 💙🧩'
               : "To children with autism and their families — you don't need to change, you need a world that understands you. Every child on the spectrum is full of talents waiting to be seen.\n\nI built Pepper because technology can be a real bridge between the child and their world.\n\nTo every child who will use Pepper: you are amazing, special, and capable of more than you imagine. 💙🧩",
            style: TextStyle(fontSize: 12, color: PepperColors.dark.withValues(alpha: 0.78),
                height: 1.8),
            textAlign: ar ? TextAlign.right : TextAlign.left,
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0x22A78BFA)),
          const SizedBox(height: 8),
          const Text('lamyafadlulmolahamedali1@gmail.com',
              style: TextStyle(fontSize: 10, color: PepperColors.purple)),
        ]),
      ),
    ]),
  );
}

// ── Support Words ─────────────────────────────────────────────────
class _SupportWords extends StatelessWidget {
  final bool ar;
  const _SupportWords({required this.ar});

  @override
  Widget build(BuildContext context) {
    final words = ar
      ? [(Color(0xFFDC2626),'🌹 للطفل','أنت لستَ مكسوراً. عقلك يرى بطريقة فريدة — هذه قوة.'),
         (Color(0xFF2563EB),'💙 للأسرة','التعب الذي تشعر به هو دليل حجم الحب. لستم وحدكم.'),
         (Color(0xFF16A34A),'🌿 للمعالجين','كل جلسة وكل مهارة تعلّمونها — نقطة ضوء في حياة عائلة.')]
      : [(Color(0xFFDC2626),'🌹 For the Child','You are not broken. Your mind sees uniquely — that is strength.'),
         (Color(0xFF2563EB),'💙 For Families','The tiredness you feel is proof of your love. You are not alone.'),
         (Color(0xFF16A34A),'🌿 For Therapists',"Every session, every skill you teach — a point of light in a family's life.")];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Column(
        children: [
          _SectionTitle(ar ? '🌟 كلمات دعم وتشجيع' : '🌟 Words of Support'),
          _SectionSub(ar ? 'لكل شخص في رحلة طيف التوحد'
                         : 'For everyone on the autism journey'),
          ...words.map((w) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: w.$1.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.$2, style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700, color: w.$1)),
                const SizedBox(height: 5),
                Text(w.$3, style: TextStyle(fontSize: 11,
                    color: PepperColors.dark.withValues(alpha: 0.7), height: 1.65)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── Pricing Section ───────────────────────────────────────────────
class _PricingSection extends StatelessWidget {
  final bool ar;
  final VoidCallback onTrial, onSub;
  const _PricingSection({required this.ar, required this.onTrial, required this.onSub});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
    child: Column(children: [
      _SectionTitle(ar ? 'الأسعار' : 'Pricing'),
      _SectionSub(ar ? 'ابدأ مجاناً — لا تحتاج بطاقة' : 'Start free — no credit card'),
      Row(children: [
        Expanded(child: _PlanCard(
          name: ar ? 'شهري' : 'Monthly',
          price: '£49',
          sub:   ar ? 'في الشهر' : 'per month',
          features: ar
            ? ['وصول كامل','تقارير غير محدودة','دعم فني']
            : ['Full access','Unlimited reports','Support'],
          onTap: onSub,
          label: ar ? 'اشترك' : 'Subscribe',
        )),
        const SizedBox(width: 10),
        Expanded(child: _PlanCard(
          name: ar ? 'سنوي' : 'Annual',
          price: '£399',
          sub:   ar ? 'وفّر 32%' : 'Save 32%',
          badge: ar ? '⭐ الأوفر' : '⭐ Best Value',
          features: ar
            ? ['وصول كامل','أولوية الدعم','جميع التحديثات']
            : ['Full access','Priority support','All updates'],
          onTap: onSub,
          label: ar ? 'اشترك سنوياً' : 'Subscribe Annually',
          highlighted: true,
        )),
      ]),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTrial,
          style: OutlinedButton.styleFrom(
            foregroundColor: PepperColors.purple,
            side: const BorderSide(color: PepperColors.purple),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(ar ? '🆓 ابدأ تجربة مجانية 15 يوماً — بدون بطاقة'
                         : '🆓 Start 15-Day Free Trial — No Card Required',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
    ]),
  );
}

class _PlanCard extends StatelessWidget {
  final String name, price, sub, label;
  final String? badge;
  final List<String> features;
  final VoidCallback onTap;
  final bool highlighted;

  const _PlanCard({
    required this.name, required this.price, required this.sub,
    required this.features, required this.onTap, required this.label,
    this.badge, this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlighted ? PepperColors.purple.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlighted ? PepperColors.purple : PepperColors.purple.withValues(alpha: 0.18),
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Column(children: [
          if (badge != null) const SizedBox(height: 8),
          Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: PepperColors.dark.withValues(alpha: 0.55),
              letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(price, style: const TextStyle(fontSize: 28,
              fontWeight: FontWeight.w900, color: PepperColors.dark)),
          Text(sub, style: TextStyle(fontSize: 10,
              color: PepperColors.dark.withValues(alpha: 0.5))),
          const SizedBox(height: 10),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('✅ $f', style: TextStyle(fontSize: 10,
                color: PepperColors.dark.withValues(alpha: 0.65))),
          )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: highlighted ? PepperColors.purple : PepperColors.purple.withValues(alpha: 0.1),
                foregroundColor: highlighted ? Colors.white : PepperColors.purple,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(label, style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
      if (badge != null)
        Positioned(
          top: -10,
          left: 0, right: 0,
          child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [PepperColors.purpleDark, PepperColors.purple]),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(badge!, style: const TextStyle(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
          )),
        ),
    ],
  );
}

// ── Footer ────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final bool ar;
  const _Footer({required this.ar});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
    child: Column(children: [
      const Divider(color: Color(0x22A78BFA)),
      const SizedBox(height: 12),
      Text(
        '© 2026 ${ar ? 'لمياء فضل المولى حامد علي · جميع الحقوق محفوظة' : 'Lamya Fadlulmola Hamed Ali · All Rights Reserved'}',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: PepperColors.dark.withValues(alpha: 0.38)),
      ),
      Text('Pepper Clinical Infinity V6 · HIPAA/GDPR',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 9, color: PepperColors.dark.withValues(alpha: 0.3))),
    ]),
  );
}

// ── Support Sheet ─────────────────────────────────────────────────
class _SupportSheet extends StatelessWidget {
  final bool ar;
  const _SupportSheet({required this.ar});

  @override
  Widget build(BuildContext context) {
    final nameCtrl  = TextEditingController();
    final emailCtrl = TextEditingController();
    final msgCtrl   = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(ar ? '💬 الدعم الفني' : '💬 Technical Support',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                color: PepperColors.dark)),
        const SizedBox(height: 4),
        Text(ar ? 'فريق بيبر يرد خلال 24 ساعة.' : 'Our team responds within 24 hours.',
            style: TextStyle(fontSize: 11, color: PepperColors.dark.withValues(alpha: 0.55))),
        const SizedBox(height: 16),
        TextField(controller: nameCtrl,
            decoration: InputDecoration(hintText: ar ? 'اسمك' : 'Your name')),
        const SizedBox(height: 8),
        TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Email')),
        const SizedBox(height: 8),
        TextField(controller: msgCtrl, maxLines: 3,
            decoration: InputDecoration(
                hintText: ar ? 'اشرح مشكلتك…' : 'Describe your issue…')),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final email = emailCtrl.text.trim();
              final msg   = msgCtrl.text.trim();
              final name  = nameCtrl.text.trim();
              if (email.isNotEmpty && msg.isNotEmpty) {
                // Open email client
                Navigator.pop(context);
              }
            },
            child: Text(ar ? '📧 إرسال' : '📧 Send',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(text, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
          color: PepperColors.dark, fontFamily: 'Cairo')),
  );
}

class _SectionSub extends StatelessWidget {
  final String text;
  const _SectionSub(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(text, textAlign: TextAlign.center,
      style: TextStyle(fontSize: 11, color: PepperColors.dark.withValues(alpha: 0.52))),
  );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [PepperColors.purpleDark, PepperColors.purple]),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [BoxShadow(color: PepperColors.purple.withValues(alpha: 0.35),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Text(label, style: const TextStyle(color: Colors.white,
          fontSize: 14, fontWeight: FontWeight.w700)),
    ),
  );
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: BoxDecoration(
        color: PepperColors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: PepperColors.purple.withValues(alpha: 0.38), width: 1.5),
      ),
      child: Text(label, style: const TextStyle(color: PepperColors.purpleDark,
          fontSize: 14, fontWeight: FontWeight.w700)),
    ),
  );
}

class _NavBtn extends StatelessWidget {
  final String label, icon;
  final bool outlined;
  final VoidCallback onTap;
  const _NavBtn({required this.label, required this.icon,
      this.outlined = false, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: outlined ? PepperColors.purple.withValues(alpha: 0.1) : PepperColors.purple,
        borderRadius: BorderRadius.circular(8),
        border: outlined ? Border.all(color: PepperColors.purple.withValues(alpha: 0.35)) : null,
      ),
      child: Text('$icon $label',
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: outlined ? PepperColors.purple : Colors.white,
        )),
    ),
  );
}

class _LangToggle extends StatelessWidget {
  final bool ar;
  final WidgetRef ref;
  const _LangToggle({required this.ar, required this.ref});

  @override
  Widget build(BuildContext context) => GestureDetector(
      ref.read(langProvider.notifier).toggleLanguage();
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PepperColors.purple.withValues(alpha: 0.2)),
      ),
      child: Text(ar ? 'EN' : 'عر',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: PepperColors.purple)),
    ),
  );
}
