import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/cubits.dart';
import '../../models/models.dart';
import '../moon/moon_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GALAXY SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class GalaxyScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userPath;

  const GalaxyScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userPath,
  });

  @override
  State<GalaxyScreen> createState() => _GalaxyScreenState();
}

class _GalaxyScreenState extends State<GalaxyScreen>
    with TickerProviderStateMixin {
  late AnimationController _starsController;
  late AnimationController _pulseController;
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();

    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    context.read<GalaxyCubit>().loadGalaxy(widget.userId, widget.userPath);
    context.read<StreakCubit>().loadStreak(widget.userId);
  }

  @override
  void dispose() {
    _starsController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      body: Stack(
        children: [
          // ── Animated starfield ──────────────────────────────────────────────
          AnimatedBuilder(
            animation: _starsController,
            builder: (_, __) => CustomPaint(
              painter: StarFieldPainter(_starsController.value),
              size: Size.infinite,
            ),
          ),

          // ── Nebula background ───────────────────────────────────────────────
          _buildNebula(),

          // ── Main content ────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildGalaxyMap()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _entryController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            // Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مجرة الأرقام',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: GalaxyColors.neonCyan.withOpacity(0.8),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                Text(
                  'مرحباً ${widget.userName} 🚀',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: Color(0xFF8899BB),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Streak badge
            BlocBuilder<StreakCubit, StreakState>(
              builder: (context, state) {
                int streak = 0;
                if (state is StreakLoaded) streak = state.streak.currentStreak;
                if (state is StreakMilestone) streak = state.streak.currentStreak;
                return _StreakBadge(streak: streak, pulse: _pulseController);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Galaxy map ───────────────────────────────────────────────────────────────

  Widget _buildGalaxyMap() {
    return BlocBuilder<GalaxyCubit, GalaxyState>(
      builder: (context, state) {
        if (state is GalaxyLoading) {
          return const Center(
            child: CircularProgressIndicator(color: GalaxyColors.neonCyan),
          );
        }

        if (state is GalaxyError) {
          return Center(
            child: Text(state.message,
                style: const TextStyle(color: Colors.redAccent)),
          );
        }

        if (state is GalaxyLoaded) {
          return _buildMoonPath(state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMoonPath(GalaxyLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      itemCount: state.moons.length,
      itemBuilder: (context, index) {
        final moon = state.moons[index];
        final progress = state.progressFor(moon.key);
        final unlocked = progress?.isUnlocked ?? false;
        final completed = progress?.isCompleted ?? false;
        final energy = progress?.energy ?? 0.0;

        // Alternate left/right for winding path feel
        final isLeft = index.isEven;

        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(isLeft ? -0.5 : 0.5, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _entryController,
            curve: Interval(
              (index * 0.08).clamp(0.0, 0.8),
              ((index * 0.08) + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          )),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _entryController,
                curve: Interval(
                  (index * 0.08).clamp(0.0, 0.9),
                  1.0,
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: _MoonNode(
              moon: moon,
              index: index,
              energy: energy,
              isUnlocked: unlocked,
              isCompleted: completed,
              isLeft: isLeft,
              pulseController: _pulseController,
              onTap: unlocked
                  ? () => _enterMoon(moon)
                  : null,
            ),
          ),
        );
      },
    );
  }

  void _enterMoon(MoonDefinition moon) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: MoonScreen(
            userId: widget.userId,
            userName: widget.userName,
            moonDefinition: moon,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
    // ✅ بعد الرجوع → حدّث خريطة المجرة فوراً
    if (mounted) {
      context.read<GalaxyCubit>().refresh(widget.userId);
    }
  }

  // ── Nebula ──────────────────────────────────────────────────────────────────

  Widget _buildNebula() {
    return Positioned.fill(
      child: CustomPaint(painter: NebulaPainter()),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOON NODE WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _MoonNode extends StatelessWidget {
  final MoonDefinition moon;
  final int index;
  final double energy;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isLeft;
  final AnimationController pulseController;
  final VoidCallback? onTap;

  const _MoonNode({
    required this.moon,
    required this.index,
    required this.energy,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isLeft,
    required this.pulseController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment:
            isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isLeft) const Spacer(),
          GestureDetector(
            onTap: onTap,
            child: _buildCard(),
          ),
          if (isLeft) const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, child) {
        final glowIntensity = isUnlocked && !isCompleted
            ? 0.4 + (pulseController.value * 0.4)
            : isCompleted
                ? 1.0
                : 0.1;

        return Container(
          width: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _borderColor.withOpacity(glowIntensity),
              width: 1.5,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: _glowColor.withOpacity(glowIntensity * 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isUnlocked
                  ? [
                      _cardColor.withOpacity(0.85),
                      _cardColor.withOpacity(0.6),
                    ]
                  : [
                      const Color(0xFF0A0E1A).withOpacity(0.9),
                      const Color(0xFF080C15).withOpacity(0.9),
                    ],
            ),
          ),
          child: child,
        );
      },
      child: _buildCardContent(),
    );
  }

  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Moon icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _iconBg,
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: _glowColor.withOpacity(0.5),
                            blurRadius: 12,
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: isCompleted
                      ? const Text('✨', style: TextStyle(fontSize: 22))
                      : isUnlocked
                          ? Text(
                              '${moon.tableNumber}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _glowColor,
                              ),
                            )
                          : const Icon(Icons.lock_outline,
                              color: Color(0xFF3A4560), size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moon.nameAr,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isUnlocked
                            ? Colors.white
                            : const Color(0xFF3A4560),
                      ),
                    ),
                    Text(
                      isCompleted
                          ? 'مكتمل ✓'
                          : isUnlocked
                              ? 'جاهز للانطلاق'
                              : 'مقفل',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: isCompleted
                            ? GalaxyColors.neonGold
                            : isUnlocked
                                ? GalaxyColors.neonCyan.withOpacity(0.8)
                                : const Color(0xFF2A3048),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isUnlocked) ...[
            const SizedBox(height: 14),
            // Energy bar
            _EnergyBar(energy: energy, glowColor: _glowColor),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طاقة القمر',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
                Text(
                  '${energy.toInt()}%',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _glowColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color get _glowColor {
    if (isCompleted) return GalaxyColors.neonGold;
    final colors = [
      GalaxyColors.neonCyan,
      GalaxyColors.neonPurple,
      GalaxyColors.neonBlue,
      GalaxyColors.neonGreen,
      GalaxyColors.neonPink,
    ];
    return colors[index % colors.length];
  }

  Color get _borderColor => _glowColor;

  Color get _cardColor {
    final base = [
      const Color(0xFF061820),
      const Color(0xFF110820),
      const Color(0xFF060E22),
      const Color(0xFF061A10),
      const Color(0xFF1A0818),
    ];
    return base[index % base.length];
  }

  Color get _iconBg => _glowColor.withOpacity(0.12);
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENERGY BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _EnergyBar extends StatelessWidget {
  final double energy;
  final Color glowColor;

  const _EnergyBar({required this.energy, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          // Track
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          // Fill
          FractionallySizedBox(
            widthFactor: (energy / 100).clamp(0.0, 1.0),
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [
                    glowColor.withOpacity(0.7),
                    glowColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STREAK BADGE
// ═══════════════════════════════════════════════════════════════════════════════

class _StreakBadge extends StatelessWidget {
  final int streak;
  final AnimationController pulse;

  const _StreakBadge({required this.streak, required this.pulse});

  @override
  Widget build(BuildContext context) {
    if (streak == 0) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: GalaxyColors.neonGold
                .withOpacity(0.4 + pulse.value * 0.4),
            width: 1,
          ),
          color: GalaxyColors.neonGold.withOpacity(0.08),
          boxShadow: [
            BoxShadow(
              color: GalaxyColors.neonGold.withOpacity(0.15 + pulse.value * 0.1),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              '$streak يوم',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: GalaxyColors.neonGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════════

class StarFieldPainter extends CustomPainter {
  final double progress;
  static final _rng = math.Random(42);
  static late final List<_Star> _stars = List.generate(
    180,
    (_) => _Star(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      size: _rng.nextDouble() * 2 + 0.3,
      speed: _rng.nextDouble() * 0.3 + 0.05,
      opacity: _rng.nextDouble() * 0.7 + 0.2,
    ),
  );

  StarFieldPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final twinkle = (math.sin((progress * star.speed * math.pi * 2) +
                  star.x * math.pi * 4) *
              0.4 +
          0.6);
      final paint = Paint()
        ..color =
            Colors.white.withOpacity(star.opacity * twinkle);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarFieldPainter old) => old.progress != progress;
}

class _Star {
  final double x, y, size, speed, opacity;
  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class NebulaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;

    // Cyan nebula top-right
    paint.shader = RadialGradient(
      colors: [
        GalaxyColors.neonCyan.withOpacity(0.06),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.85, size.height * 0.1),
      radius: size.width * 0.5,
    ));
    canvas.drawRect(Offset.zero & size, paint);

    // Purple nebula bottom-left
    paint.shader = RadialGradient(
      colors: [
        GalaxyColors.neonPurple.withOpacity(0.05),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.15, size.height * 0.75),
      radius: size.width * 0.6,
    ));
    canvas.drawRect(Offset.zero & size, paint);

    // Gold nebula center
    paint.shader = RadialGradient(
      colors: [
        GalaxyColors.neonGold.withOpacity(0.03),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.45),
      radius: size.width * 0.4,
    ));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════════════════════════════════

class GalaxyColors {
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonPurple = Color(0xFFBB86FC);
  static const Color neonBlue = Color(0xFF448AFF);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonPink = Color(0xFFFF4081);
  static const Color neonGold = Color(0xFFFFD740);
  static const Color darkBg = Color(0xFF020818);
}
