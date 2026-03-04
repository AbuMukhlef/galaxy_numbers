import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/cubits.dart';
import '../../models/models.dart';
import '../challenge/challenge_screen.dart';
import '../certificate/certificate_screen.dart';
import '../galaxy/galaxy_screen.dart' show GalaxyColors;

// ═══════════════════════════════════════════════════════════════════════════════
// MOON SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class MoonScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final MoonDefinition moonDefinition;

  const MoonScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.moonDefinition,
  });

  @override
  State<MoonScreen> createState() => _MoonScreenState();
}

class _MoonScreenState extends State<MoonScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _ringController;
  late AnimationController _entryController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    context.read<MoonCubit>().enterMoon(
          userId: widget.userId,
          definition: widget.moonDefinition,
        );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _ringController.dispose();
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MoonCubit, MoonState>(
      listener: (context, state) {
        if (state is MoonFullyComplete) {
          // ✅ حدّث GalaxyCubit قبل الانتقال للشهادة
          context.read<GalaxyCubit>().refresh(state.userId);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CertificateScreen(
                moonDefinition: state.definition,
                userName: state.userName,
                userId: state.userId,
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: GalaxyColors.darkBg,
        body: Stack(
          children: [
            // Stars
            AnimatedBuilder(
              animation: _ringController,
              builder: (_, __) => CustomPaint(
                painter: _SimpleStarPainter(_ringController.value),
                size: Size.infinite,
              ),
            ),
            // Nebula
            _buildNebula(),
            // Content
            SafeArea(
              child: BlocBuilder<MoonCubit, MoonState>(
                builder: (context, state) {
                  if (state is MoonLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: GalaxyColors.neonCyan),
                    );
                  }
                  if (state is MoonLayerActive) {
                    return _buildContent(state);
                  }
                  if (state is MoonError) {
                    return Center(
                      child: Text(state.message,
                          style: const TextStyle(color: Colors.redAccent)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Content ──────────────────────────────────────────────────────────────────

  Widget _buildContent(MoonLayerActive state) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildMoonHero(state)),
        SliverToBoxAdapter(child: _buildEnergyBar(state)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              'الطبقات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.45),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _LayerCard(
                layer: 1,
                title: 'الطبقة 1 — فهم بصري',
                description: 'تمثيل المجموعات • بدون وقت • 10 مسائل',
                emoji: '🔭',
                color: GalaxyColors.neonGreen,
                isDone: state.progress.layer1Done,
                isLocked: false,
                questionCount: widget.moonDefinition.layer1Count,
                entryAnimation: _entryController,
                delayFactor: 0,
                onTap: () => _startChallenge(state, layer: 1),
              ),
              const SizedBox(height: 12),
              _LayerCard(
                layer: 2,
                title: 'الطبقة 2 — تثبيت',
                description: 'مسائل مباشرة متدرجة • 20 مسألة',
                emoji: '⚡',
                color: GalaxyColors.neonCyan,
                isDone: state.progress.layer2Done,
                isLocked: !state.progress.layer1Done,
                questionCount: widget.moonDefinition.layer2Count,
                entryAnimation: _entryController,
                delayFactor: 0.12,
                onTap: () => _startChallenge(state, layer: 2),
              ),
              const SizedBox(height: 12),
              _LayerCard(
                layer: 3,
                title: 'الطبقة 3 — السرعة',
                description:
                    '${widget.moonDefinition.layer3Duration} ثانية • سلسلة انتصارات',
                emoji: '🔥',
                color: GalaxyColors.neonGold,
                isDone: state.progress.layer3Done,
                isLocked: !state.progress.layer2Done ||
                    state.progress.energy < 40,
                questionCount: 20,
                entryAnimation: _entryController,
                delayFactor: 0.22,
                lockReason: state.progress.energy < 40
                    ? 'تحتاجين 40% طاقة أولاً'
                    : null,
                onTap: () => _startChallenge(state, layer: 3, withTimer: true),
              ),
              const SizedBox(height: 20),
              _ChallengeBanner(
                isLocked: state.progress.energy < 40,
                pulseController: _pulseController,
                onTap: () => _startChallenge(state,
                    layer: state.progress.currentLayer, withTimer: true),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _entryController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white70, size: 16),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.moonDefinition.nameAr,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'مسار الضرب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Moon orb hero ─────────────────────────────────────────────────────────────

  Widget _buildMoonHero(MoonLayerActive state) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
          parent: _entryController, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _entryController,
        child: Column(
          children: [
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: Listenable.merge(
                  [_floatController, _ringController]),
              builder: (_, __) {
                final float = math.sin(
                        _floatController.value * math.pi) *
                    8.0;
                return Transform.translate(
                  offset: Offset(0, -float),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      Transform.rotate(
                        angle: _ringController.value * math.pi * 2,
                        child: Container(
                          width: 138,
                          height: 138,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: GalaxyColors.neonCyan
                                  .withOpacity(0.10),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      // Inner ring
                      Transform.rotate(
                        angle:
                            -_ringController.value * math.pi * 2 *
                                0.6,
                        child: Container(
                          width: 122,
                          height: 122,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: GalaxyColors.neonCyan
                                  .withOpacity(0.18),
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                      ),
                      // Orb
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(-0.3, -0.3),
                            colors: [
                              GalaxyColors.neonCyan
                                  .withOpacity(0.22),
                              GalaxyColors.neonCyan
                                  .withOpacity(0.07),
                              Colors.transparent,
                            ],
                          ),
                          border: Border.all(
                            color: GalaxyColors.neonCyan
                                .withOpacity(0.35),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: GalaxyColors.neonCyan
                                  .withOpacity(0.18),
                              blurRadius: 40,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: GalaxyColors.neonCyan
                                  .withOpacity(0.08),
                              blurRadius: 80,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${widget.moonDefinition.tableNumber}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: GalaxyColors.neonCyan,
                              shadows: [
                                Shadow(
                                  color: GalaxyColors.neonCyan
                                      .withOpacity(0.6),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Text(
              'جدول ${_arabicNumber(widget.moonDefinition.tableNumber)}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'أكملي الطبقات الثلاث لفتح القمر التالي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: Colors.white.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ── Energy bar ────────────────────────────────────────────────────────────────

  Widget _buildEnergyBar(MoonLayerActive state) {
    return FadeTransition(
      opacity: _entryController,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: GalaxyColors.neonCyan.withOpacity(0.14)),
          color: GalaxyColors.neonCyan.withOpacity(0.04),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '⚡ طاقة القمر',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '${state.progress.energy.toInt()}%',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: GalaxyColors.neonCyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    height: 10,
                    color: Colors.white.withOpacity(0.06),
                  ),
                  FractionallySizedBox(
                    widthFactor:
                        (state.progress.energy / 100).clamp(0.0, 1.0),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(colors: [
                          GalaxyColors.neonCyan.withOpacity(0.7),
                          GalaxyColors.neonCyan,
                        ]),
                        boxShadow: [
                          BoxShadow(
                            color: GalaxyColors.neonCyan
                                .withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تحتاجين 100% لفتح القمر التالي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: Colors.white.withOpacity(0.28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────────

  Future<void> _startChallenge(
    MoonLayerActive state, {
    required int layer,
    bool withTimer = false,
  }) async {
    // انتقل لشاشة التحدي وانتظر الرجوع
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: ChallengeScreen(
            userId: widget.userId,
            userName: widget.userName,
            moonDefinition: widget.moonDefinition,
            layer: layer,
            withTimer: withTimer,
            startEnergy: state.progress.energy,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    // ✅ الإصلاح: بعد الرجوع من ChallengeScreen → أعد تحميل بيانات القمر
    // هذا يضمن أن layer1Done/layer2Done/layer3Done تُحدَّث في الـ UI فوراً
    if (mounted) {
      context.read<MoonCubit>().reload(
        userId: widget.userId,
        definition: widget.moonDefinition,
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────────

  String _arabicNumber(int n) {
    const map = {
      2: 'الاثنين', 3: 'الثلاثة', 4: 'الأربعة', 5: 'الخمسة',
      6: 'الستة', 7: 'السبعة', 8: 'الثمانية', 9: 'التسعة', 10: 'العشرة',
    };
    return map[n] ?? '$n';
  }

  Widget _buildNebula() => Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.8, -0.6),
              radius: 1.2,
              colors: [
                GalaxyColors.neonCyan.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// LAYER CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _LayerCard extends StatelessWidget {
  final int layer;
  final String title;
  final String description;
  final String emoji;
  final Color color;
  final bool isDone;
  final bool isLocked;
  final int questionCount;
  final AnimationController entryAnimation;
  final double delayFactor;
  final String? lockReason;
  final VoidCallback onTap;

  const _LayerCard({
    required this.layer,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    required this.isDone,
    required this.isLocked,
    required this.questionCount,
    required this.entryAnimation,
    required this.delayFactor,
    required this.onTap,
    this.lockReason,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.4),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: entryAnimation,
        curve: Interval(delayFactor, (delayFactor + 0.5).clamp(0, 1),
            curve: Curves.easeOutCubic),
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: entryAnimation,
            curve: Interval(delayFactor, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: GestureDetector(
          onTap: isLocked ? null : onTap,
          child: AnimatedOpacity(
            opacity: isLocked ? 0.45 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isLocked
                      ? Colors.white.withOpacity(0.06)
                      : color.withOpacity(isDone ? 0.55 : 0.28),
                  width: 1.5,
                ),
                color: isLocked
                    ? const Color(0xFF0A0E1A).withOpacity(0.7)
                    : color.withOpacity(0.06),
                boxShadow: isLocked
                    ? []
                    : [
                        BoxShadow(
                          color: color.withOpacity(0.08),
                          blurRadius: 18,
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isLocked
                              ? Colors.white.withOpacity(0.04)
                              : color.withOpacity(0.12),
                        ),
                        child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isLocked
                                    ? const Color(0xFF3A4560)
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              description,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: isLocked
                                    ? const Color(0xFF2A3048)
                                    : Colors.white.withOpacity(0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$layer',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isLocked
                              ? const Color(0xFF3A4560)
                              : color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (isDone)
                        _pill('✓ مكتملة', GalaxyColors.neonGold)
                      else if (isLocked)
                        _pill(lockReason ?? '🔒 مقفل', const Color(0xFF3A4560))
                      else
                        _pill('جارية', color),
                      const SizedBox(width: 8),
                      _pill('$questionCount مسألة', color.withOpacity(0.7)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHALLENGE BANNER
// ═══════════════════════════════════════════════════════════════════════════════

class _ChallengeBanner extends StatelessWidget {
  final bool isLocked;
  final AnimationController pulseController;
  final VoidCallback onTap;

  const _ChallengeBanner({
    required this.isLocked,
    required this.pulseController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final glow = isLocked
            ? 0.0
            : 0.08 + pulseController.value * 0.1;
        return GestureDetector(
          onTap: isLocked ? null : onTap,
          child: AnimatedOpacity(
            opacity: isLocked ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFFF4081)
                      .withOpacity(isLocked ? 0.15 : 0.35),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF4081).withOpacity(0.08),
                    GalaxyColors.neonPurple.withOpacity(0.06),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4081).withOpacity(glow),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'وضع التحدي',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF4081),
                          ),
                        ),
                        Text(
                          isLocked
                              ? 'تحتاجين 40% طاقة'
                              : 'سرعة + دقة في وقت واحد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: const Color(0xFFFF4081).withOpacity(0.6),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMPLE STAR PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _SimpleStarPainter extends CustomPainter {
  final double t;
  static final _rng = math.Random(77);
  static final _stars = List.generate(
    150,
    (_) => [
      _rng.nextDouble(), // x
      _rng.nextDouble(), // y
      _rng.nextDouble() * 1.6 + 0.3, // size
      _rng.nextDouble() * 0.22 + 0.04, // speed
      _rng.nextDouble() * 0.6 + 0.2, // opacity
      _rng.nextDouble() * math.pi * 2, // phase
    ],
  );

  _SimpleStarPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final s in _stars) {
      final tw = math.sin(t * s[3] * math.pi * 2 + s[5]) * 0.35 + 0.65;
      paint.color = Colors.white.withOpacity(s[4] * tw);
      canvas.drawCircle(
          Offset(s[0] * size.width, s[1] * size.height), s[2], paint);
    }
  }

  @override
  bool shouldRepaint(_SimpleStarPainter o) => o.t != t;
}
