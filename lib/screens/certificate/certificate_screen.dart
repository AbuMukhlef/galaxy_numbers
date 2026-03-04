import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../cubits/cubits.dart';
import '../../models/models.dart';
import '../galaxy/galaxy_screen.dart' show GalaxyColors;

// ═══════════════════════════════════════════════════════════════════════════════
// CERTIFICATE SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class CertificateScreen extends StatefulWidget {
  final MoonDefinition moonDefinition;
  final String userName;
  final String userId;

  const CertificateScreen({
    super.key,
    required this.moonDefinition,
    required this.userName,
    required this.userId,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _starsController;
  late AnimationController _sealController;
  late AnimationController _burstController;

  final GlobalKey _certKey = GlobalKey();
  bool _saving = false;
  bool _saved  = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))..forward();

    _starsController = AnimationController(
      vsync: this, duration: const Duration(seconds: 60))..repeat();

    _sealController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse:true);

    _burstController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));

    // Trigger burst after card enters
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _burstController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _starsController.dispose();
    _sealController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  // ✅ الإصلاح: حدّث GalaxyCubit قبل الرجوع لضمان تحديث الشاشة فوراً
  void _goToGalaxy() {
    // حدّث GalaxyCubit بآخر بيانات من Hive
    context.read<GalaxyCubit>().refresh(widget.userId);
    // ارجع للشاشة الرئيسية
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GalaxyColors.darkBg,
      body: Stack(
        children: [
          // Starfield
          AnimatedBuilder(
            animation: _starsController,
            builder: (_, __) => CustomPaint(
              painter: _CertStarPainter(_starsController.value),
              size: Size.infinite,
            ),
          ),
          // Nebula
          _buildNebula(),
          // Confetti
          AnimatedBuilder(
            animation: _burstController,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(_burstController.value),
              size: Size.infinite,
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildCertCard(),
                  const SizedBox(height: 28),
                  _buildActions(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _entryController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _goToGalaxy(),
              child: Container(
                width:38, height:38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.06),
                  border: Border.all(color: Colors.white.withOpacity(.1)),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white70, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '🏆 شهادة الإنجاز',
              style: TextStyle(
                fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [Shadow(color: GalaxyColors.neonGold.withOpacity(.5), blurRadius: 12)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Certificate card ──────────────────────────────────────────────────────────

  Widget _buildCertCard() {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.1, 1.0, curve: Curves.elasticOut),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.0, 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RepaintBoundary(
            key: _certKey,
            child: _CertificateCard(
              userName: widget.userName,
              moonDefinition: widget.moonDefinition,
              sealController: _sealController,
            ),
          ),
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────────

  Widget _buildActions() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
          .animate(CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.4, 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Save button
              GestureDetector(
                onTap: _saveImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity, height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: GalaxyColors.neonGold.withOpacity(.5), width: 1.5),
                    gradient: LinearGradient(colors: [
                      GalaxyColors.neonGold.withOpacity(_saving ? .12 : .22),
                      GalaxyColors.neonGold.withOpacity(_saving ? .06 : .12),
                    ]),
                    boxShadow: [
                      BoxShadow(
                        color: GalaxyColors.neonGold.withOpacity(.1),
                        blurRadius: 20),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_saved ? '✅' : '📸',
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Text(
                        _saving ? 'جاري الحفظ...' : _saved ? 'تم الحفظ!' : 'حفظ كصورة',
                        style: const TextStyle(
                          fontFamily: 'Cairo', fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: GalaxyColors.neonGold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Next moon button
              GestureDetector(
                onTap: () => _goToGalaxy(),
                child: Container(
                  width: double.infinity, height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: GalaxyColors.neonCyan.withOpacity(.4), width: 1.5),
                    gradient: LinearGradient(colors: [
                      GalaxyColors.neonCyan.withOpacity(.18),
                      GalaxyColors.neonCyan.withOpacity(.08),
                    ]),
                    boxShadow: [
                      BoxShadow(
                        color: GalaxyColors.neonCyan.withOpacity(.08),
                        blurRadius: 20),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🚀 القمر التالي',
                          style: TextStyle(fontFamily:'Cairo', fontSize:16,
                              fontWeight:FontWeight.w800, color:GalaxyColors.neonCyan)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_back_ios_new_rounded,
                          color: GalaxyColors.neonCyan, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Save image ────────────────────────────────────────────────────────────────

  Future<void> _saveImage() async {
    if (_saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final boundary = _certKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: 'شهادة-\${widget.userName}',
      );

      setState(() { _saving = false; _saved = true; });
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(seconds: 3),
          () => { if (mounted) setState(() => _saved = false) });
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  Widget _buildNebula() => Positioned.fill(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.4,
          colors: [
            GalaxyColors.neonGold.withOpacity(.04),
            Colors.transparent,
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// CERTIFICATE CARD WIDGET (extracted for RepaintBoundary)
// ═══════════════════════════════════════════════════════════════════════════════

class _CertificateCard extends StatelessWidget {
  final String userName;
  final MoonDefinition moonDefinition;
  final AnimationController sealController;

  const _CertificateCard({
    required this.userName,
    required this.moonDefinition,
    required this.sealController,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.year}/${now.month.toString().padLeft(2,'0')}/${now.day.toString().padLeft(2,'0')}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: GalaxyColors.neonGold.withOpacity(.35), width: 2),
        color: const Color(0xFF020F1E),
        boxShadow: [
          BoxShadow(color: GalaxyColors.neonGold.withOpacity(.1), blurRadius: 60),
          BoxShadow(color: GalaxyColors.neonGold.withOpacity(.05), blurRadius: 120),
        ],
      ),
      child: Stack(
        children: [
          // Inner border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GalaxyColors.neonGold.withOpacity(.1)),
              ),
            ),
          ),
          // Corner decorations
          ..._buildCorners(),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Column(
              children: [
                // Stars
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('⭐', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Text('🌟', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  const Text('⭐', style: TextStyle(fontSize: 20)),
                ]),
                const SizedBox(height: 16),

                // Branding
                Text(
                  '✦ مجرة الأرقام ✦',
                  style: TextStyle(
                    fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700,
                    color: GalaxyColors.neonGold.withOpacity(.5),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 22),

                // Body text
                Text(
                  'تشهد مجرة الأرقام بأن',
                  style: TextStyle(
                    fontFamily: 'Cairo', fontSize: 13,
                    color: Colors.white.withOpacity(.45),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userName,
                  style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 32, fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(color: Color(0x66FFD740), blurRadius: 20)],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'أتقنت بكفاءة كاملة',
                  style: TextStyle(
                    fontFamily: 'Cairo', fontSize: 13,
                    color: Colors.white.withOpacity(.45),
                  ),
                ),
                const SizedBox(height: 14),

                // Divider
                Row(children: [
                  Expanded(child: _gradDivider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('✦',
                        style: TextStyle(
                            color: GalaxyColors.neonGold.withOpacity(.5))),
                  ),
                  Expanded(child: _gradDivider()),
                ]),
                const SizedBox(height: 14),

                // Subject
                Text(
                  _arabicTableName(moonDefinition.tableNumber),
                  style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w900,
                    color: GalaxyColors.neonGold,
                    shadows: [Shadow(color: Color(0x66FFD740), blurRadius: 16)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'جدول الضرب × ${moonDefinition.tableNumber}',
                  style: TextStyle(
                    fontFamily: 'Cairo', fontSize: 13,
                    color: GalaxyColors.neonGold.withOpacity(.55),
                  ),
                ),
                const SizedBox(height: 20),

                // Badge row
                Row(children: [
                  _badge('💯', 'إتقان كامل'),
                  const SizedBox(width: 10),
                  _badge('⚡', 'طاقة 100%'),
                  const SizedBox(width: 10),
                  _badge('🏆', 'خبيرة'),
                ]),
                const SizedBox(height: 20),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontFamily: 'Cairo', fontSize: 10,
                        color: Colors.white.withOpacity(.25),
                      ),
                    ),
                    // Animated seal
                    AnimatedBuilder(
                      animation: sealController,
                      builder: (_, __) => Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            GalaxyColors.neonGold.withOpacity(.2),
                            GalaxyColors.neonGold.withOpacity(.06),
                          ]),
                          border: Border.all(
                            color: GalaxyColors.neonGold.withOpacity(.4), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: GalaxyColors.neonGold
                                  .withOpacity(.1 + sealController.value * .2),
                              blurRadius: 16 + sealController.value * 12),
                          ],
                        ),
                        child: const Center(
                          child: Text('🌟', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    Widget corner(Alignment a, bool fx, bool fy) => Positioned(
      top:    a.y < 0 ? 14 : null,
      bottom: a.y > 0 ? 14 : null,
      right:  a.x > 0 ? 14 : null,
      left:   a.x < 0 ? 14 : null,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(fx ? -1 : 1, fy ? -1 : 1, 1),
        child: CustomPaint(painter: _CornerPainter(), size: const Size(34, 34)),
      ),
    );
    return [
      corner(const Alignment( 1, -1), false, false),
      corner(const Alignment(-1, -1), true,  false),
      corner(const Alignment( 1,  1), false, true),
      corner(const Alignment(-1,  1), true,  true),
    ];
  }

  Widget _gradDivider() => Container(
    height: 1,
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [
        Colors.transparent,
        Color(0x4DFFD740),
        Colors.transparent,
      ]),
    ),
  );

  Widget _badge(String emoji, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: GalaxyColors.neonGold.withOpacity(.05),
        border: Border.all(color: GalaxyColors.neonGold.withOpacity(.15)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 9,
                  color: GalaxyColors.neonGold.withOpacity(.55),
                  fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );

  String _arabicTableName(int n) {
    const m = {
      2:'جدول الاثنين', 3:'جدول الثلاثة', 4:'جدول الأربعة',
      5:'جدول الخمسة',  6:'جدول الستة',   7:'جدول السبعة',
      8:'جدول الثمانية',9:'جدول التسعة',  10:'جدول العشرة',
    };
    return m[n] ?? 'جدول $n';
  }
}

// ══════ CORNER PAINTER ══════════════════════════════════════════════════════════

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = GalaxyColors.neonGold.withOpacity(.45)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), p);
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), p);
    canvas.drawCircle(const Offset(5, 5), 2,
        Paint()..color = GalaxyColors.neonGold.withOpacity(.4));
  }
  @override bool shouldRepaint(_) => false;
}

// ══════ CONFETTI PAINTER ════════════════════════════════════════════════════════

class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final _rng = math.Random(77);
  static final _pieces = List.generate(50, (_) => [
    _rng.nextDouble(),                    // x start (0-1)
    _rng.nextDouble() * 0.8 + 0.2,       // y end (0.2-1)
    _rng.nextDouble() * 80 - 40,         // drift x
    _rng.nextDouble() * 720,             // spin degrees
    _rng.nextDouble() * 0.6 + 0.2,       // delay (0-0.6 of progress)
    6.0 + _rng.nextDouble() * 6,         // size
    _rng.nextInt(6).toDouble(),          // color index
  ]);

  static const _colors = [
    GalaxyColors.neonGold,
    GalaxyColors.neonCyan,
    GalaxyColors.neonPurple,
    GalaxyColors.neonGreen,
    GalaxyColors.neonPink,
    Colors.white,
  ];

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pieces) {
      final delay = p[4];
      final localProgress = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (localProgress <= 0) continue;

      final opacity = (1 - localProgress).clamp(0.0, 1.0);
      final x = p[0] * size.width + p[2] * localProgress;
      final y = -20 + localProgress * p[1] * size.height;
      final spin = p[3] * localProgress * math.pi / 180;
      final sz = p[5];
      final color = _colors[p[6].toInt()].withOpacity(opacity * 0.85);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin);
      final rect = Rect.fromCenter(
          center: Offset.zero, width: sz, height: sz * 0.6);
      canvas.drawRect(rect,
          Paint()..color = color..style = PaintingStyle.fill);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter o) => o.progress != progress;
}

// ══════ STAR PAINTER ════════════════════════════════════════════════════════════

class _CertStarPainter extends CustomPainter {
  final double t;
  static final _rng = math.Random(55);
  static final _s = List.generate(160, (_) => [
    _rng.nextDouble(), _rng.nextDouble(),
    _rng.nextDouble() * 1.6 + .3,
    _rng.nextDouble() * .2 + .04,
    _rng.nextDouble() * .6 + .2,
    _rng.nextDouble() * math.pi * 2,
  ]);
  _CertStarPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final s in _s) {
      final tw = math.sin(t * s[3] * math.pi * 2 + s[5]) * .35 + .65;
      p.color = Colors.white.withOpacity(s[4] * tw);
      canvas.drawCircle(
          Offset(s[0] * size.width, s[1] * size.height), s[2], p);
    }
  }
  @override bool shouldRepaint(_CertStarPainter o) => o.t != t;
}
