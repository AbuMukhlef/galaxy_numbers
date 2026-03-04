import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/cubits.dart';
import '../../models/models.dart';
import '../galaxy/galaxy_screen.dart' show GalaxyColors;

// ═══════════════════════════════════════════════════════════════════════════════
// ONBOARDING SCREEN  (4 pages)
// ═══════════════════════════════════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {

  final PageController _pageCtrl = PageController();
  int _page = 0; // 0=welcome 1=name 2=path 3=ready

  // Animations
  late AnimationController _floatCtrl;
  late AnimationController _starsCtrl;
  late AnimationController _burstCtrl;
  late AnimationController _ringCtrl;

  // Form state
  final TextEditingController _nameCtrl = TextEditingController();
  String _selectedPath = ''; // 'multiplication' | 'four_operations'
  bool _nameValid = false;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 3600))..repeat(reverse: true);
    _starsCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 60))..repeat();
    _ringCtrl  = AnimationController(vsync: this,
        duration: const Duration(seconds: 9))..repeat();
    _burstCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200));
    _nameCtrl.addListener(() {
      setState(() => _nameValid = _nameCtrl.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose(); _nameCtrl.dispose();
    _floatCtrl.dispose(); _starsCtrl.dispose();
    _burstCtrl.dispose(); _ringCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 3) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic);
    }
  }
  void _back() {
    if (_page > 0) _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GalaxyColors.darkBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Stars
          AnimatedBuilder(
            animation: _starsCtrl,
            builder: (_, __) => CustomPaint(
              painter: _OnboardStarPainter(_starsCtrl.value),
              size: Size.infinite,
            ),
          ),
          // Burst
          AnimatedBuilder(
            animation: _burstCtrl,
            builder: (_, __) => _burstCtrl.value > 0
                ? CustomPaint(
                    painter: _BurstPainter(_burstCtrl.value),
                    size: Size.infinite)
                : const SizedBox.shrink(),
          ),
          // Pages
          SafeArea(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _WelcomePage(
                  floatCtrl: _floatCtrl,
                  ringCtrl: _ringCtrl,
                  onStart: _next,
                ),
                _NamePage(
                  nameCtrl: _nameCtrl,
                  nameValid: _nameValid,
                  onBack: _back,
                  onNext: _next,
                ),
                _PathPage(
                  selectedPath: _selectedPath,
                  onSelect: (p) => setState(() => _selectedPath = p),
                  onBack: _back,
                  onNext: () {
                    _burstCtrl.forward(from: 0);
                    _next();
                  },
                ),
                _ReadyPage(
                  name: _nameCtrl.text.trim(),
                  selectedPath: _selectedPath,
                  floatCtrl: _floatCtrl,
                  onLaunch: _launch,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launch() async {
    HapticFeedback.mediumImpact();
    await context.read<AuthCubit>().createUser(
      name: _nameCtrl.text.trim(),
      selectedPath: _selectedPath,
    );
    // AuthCubit state change will trigger router to push GalaxyScreen
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE 1 – WELCOME
// ═══════════════════════════════════════════════════════════════════════════════

class _WelcomePage extends StatelessWidget {
  final AnimationController floatCtrl;
  final AnimationController ringCtrl;
  final VoidCallback onStart;
  const _WelcomePage({required this.floatCtrl, required this.ringCtrl, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Planet orb with rings
              AnimatedBuilder(
                animation: Listenable.merge([floatCtrl, ringCtrl]),
                builder: (_, __) {
                  final float = math.sin(floatCtrl.value * math.pi) * 10.0;
                  return Transform.translate(
                    offset: Offset(0, -float),
                    child: SizedBox(
                      width: 200, height: 200,
                      child: Stack(alignment: Alignment.center, children: [
                        // Outer ring
                        Transform.rotate(
                          angle: ringCtrl.value * math.pi * 2,
                          child: Container(width: 196, height: 196,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                              border: Border.all(color: GalaxyColors.neonCyan.withOpacity(.1)))),
                        ),
                        // Inner ring
                        Transform.rotate(
                          angle: -ringCtrl.value * math.pi * 2 * .65,
                          child: Container(width: 172, height: 172,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                              border: Border.all(
                                color: GalaxyColors.neonCyan.withOpacity(.18),
                                width: 1.5))),
                        ),
                        // Orb
                        Container(
                          width: 140, height: 140,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            gradient: RadialGradient(center: const Alignment(-.3,-.3), colors: [
                              GalaxyColors.neonCyan.withOpacity(.22),
                              GalaxyColors.neonCyan.withOpacity(.07),
                              Colors.transparent,
                            ]),
                            border: Border.all(color: GalaxyColors.neonCyan.withOpacity(.35), width:2),
                            boxShadow: [
                              BoxShadow(color: GalaxyColors.neonCyan.withOpacity(.18), blurRadius:50),
                              BoxShadow(color: GalaxyColors.neonCyan.withOpacity(.08), blurRadius:100),
                            ]),
                          child: const Center(child: Text('🌌', style: TextStyle(fontSize: 52))),
                        ),
                      ]),
                    ),
                  );
                },
              ),
              const SizedBox(height: 36),
              const Text('مجرة الأرقام',
                style: TextStyle(fontFamily:'Cairo', fontSize:32, fontWeight:FontWeight.w900,
                  color:Colors.white,
                  shadows:[Shadow(color:Color(0x40009FCC), blurRadius:20)])),
              const SizedBox(height: 12),
              Text(
                'رحلة فضائية تحوّل خوفك من الرياضيات\nإلى قوة وهوية 🚀',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily:'Cairo', fontSize:14,
                  color:Colors.white.withOpacity(.45), height:1.8)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
          child: GestureDetector(
            onTap: onStart,
            child: Container(
              width:double.infinity, height:60,
              decoration: BoxDecoration(
                borderRadius:BorderRadius.circular(20),
                border:Border.all(color:GalaxyColors.neonCyan.withOpacity(.5), width:1.5),
                gradient:LinearGradient(colors:[
                  GalaxyColors.neonCyan.withOpacity(.26),
                  GalaxyColors.neonCyan.withOpacity(.1)]),
                boxShadow:[BoxShadow(color:GalaxyColors.neonCyan.withOpacity(.12), blurRadius:28)]),
              child: const Row(mainAxisAlignment:MainAxisAlignment.center, children:[
                Text('ابدأ رحلتك', style:TextStyle(fontFamily:'Cairo', fontSize:18,
                  fontWeight:FontWeight.w800, color:GalaxyColors.neonCyan)),
                SizedBox(width:8),
                Icon(Icons.arrow_back_ios_new_rounded, color:GalaxyColors.neonCyan, size:16),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE 2 – NAME
// ═══════════════════════════════════════════════════════════════════════════════

class _NamePage extends StatelessWidget {
  final TextEditingController nameCtrl;
  final bool nameValid;
  final VoidCallback onBack, onNext;
  const _NamePage({required this.nameCtrl, required this.nameValid,
    required this.onBack, required this.onNext});

  static const _emojis = ['⭐','🌟','🚀','💫','⚡','🔥'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20,18,20,0),
          child: Row(children:[
            _backBtn(onBack),
            const Spacer(),
            Text('الخطوة 1 من 2', style:TextStyle(fontFamily:'Cairo', fontSize:12,
              color:Colors.white.withOpacity(.35))),
            const Spacer(),
            const SizedBox(width:36),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              const Text('ما اسمك البطولي؟ 🌟',
                style:TextStyle(fontFamily:'Cairo', fontSize:22, fontWeight:FontWeight.w900, color:Colors.white)),
              const SizedBox(height:6),
              Text('هذا الاسم سيظهر على شهاداتك وبطولاتك',
                style:TextStyle(fontFamily:'Cairo', fontSize:13, color:Colors.white.withOpacity(.4))),
              const SizedBox(height:28),
              // Input
              TextField(
                controller: nameCtrl,
                maxLength: 20,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(fontFamily:'Cairo', fontSize:22,
                  fontWeight:FontWeight.w800, color:Colors.white, letterSpacing:1),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'اكتبي اسمك هنا...',
                  hintStyle: TextStyle(fontFamily:'Cairo', fontSize:16,
                    color:Colors.white.withOpacity(.18), fontWeight:FontWeight.w400),
                  filled: true,
                  fillColor: const Color(0xFF001428).withOpacity(.7),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color:GalaxyColors.neonCyan.withOpacity(.2), width:2)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color:GalaxyColors.neonCyan.withOpacity(.55), width:2)),
                ),
              ),
              const SizedBox(height:16),
              // Preview
              AnimatedOpacity(
                opacity: nameValid ? 1.0 : 0.0,
                duration: const Duration(milliseconds:300),
                child: Container(
                  width:double.infinity, padding:const EdgeInsets.all(14),
                  decoration:BoxDecoration(
                    borderRadius:BorderRadius.circular(14),
                    color:GalaxyColors.neonCyan.withOpacity(.04),
                    border:Border.all(color:GalaxyColors.neonCyan.withOpacity(.12))),
                  child:Column(children:[
                    Text('ستظهر شهادتك هكذا',
                      style:TextStyle(fontFamily:'Cairo', fontSize:11, color:Colors.white.withOpacity(.3))),
                    const SizedBox(height:6),
                    Text('${nameCtrl.text.trim()} 🌟',
                      style:const TextStyle(fontFamily:'Cairo', fontSize:20,
                        fontWeight:FontWeight.w900, color:Colors.white)),
                  ]),
                ),
              ),
              const SizedBox(height:16),
              // Emoji row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _emojis.map((e) => GestureDetector(
                  onTap: () {
                    if (nameCtrl.text.length < 18) {
                      nameCtrl.text += e;
                      nameCtrl.selection = TextSelection.collapsed(offset:nameCtrl.text.length);
                    }
                  },
                  child: Container(
                    width:44, height:44, margin:const EdgeInsets.symmetric(horizontal:4),
                    decoration:BoxDecoration(
                      borderRadius:BorderRadius.circular(12),
                      color:Colors.white.withOpacity(.05),
                      border:Border.all(color:Colors.white.withOpacity(.1))),
                    child:Center(child:Text(e, style:const TextStyle(fontSize:20))),
                  ),
                )).toList(),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: _primaryBtn(
            label: 'التالي ← اختيار المسار',
            color: GalaxyColors.neonCyan,
            enabled: nameValid,
            onTap: onNext),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE 3 – PATH
// ═══════════════════════════════════════════════════════════════════════════════

class _PathPage extends StatelessWidget {
  final String selectedPath;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack, onNext;
  const _PathPage({required this.selectedPath, required this.onSelect,
    required this.onBack, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20,18,20,0),
          child: Row(children:[
            _backBtn(onBack),
            const Spacer(),
            Text('الخطوة 2 من 2', style:TextStyle(fontFamily:'Cairo', fontSize:12,
              color:Colors.white.withOpacity(.35))),
            const Spacer(),
            const SizedBox(width:36),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20,28,20,0),
            child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              const Text('اختاري مسارك 🛸',
                style:TextStyle(fontFamily:'Cairo', fontSize:22, fontWeight:FontWeight.w900, color:Colors.white)),
              const SizedBox(height:6),
              Text('كل مسار مصمم لمستوى مختلف',
                style:TextStyle(fontFamily:'Cairo', fontSize:13, color:Colors.white.withOpacity(.4))),
              const SizedBox(height:24),
              // Multiplication card
              _PathCard(
                icon: '✖️',
                title: 'مسار الضرب',
                description: 'جداول الضرب من 2 إلى 10\nبشكل خطي تدريجي',
                tags: ['9 جداول', 'مناسب للمبتدئين', 'منهجي ومتدرج'],
                color: GalaxyColors.neonCyan,
                recommended: true,
                selected: selectedPath == 'multiplication',
                onTap: () => onSelect('multiplication'),
              ),
              const SizedBox(height: 14),
              // Four ops card
              _PathCard(
                icon: '🔢',
                title: 'مسار العمليات الأربع',
                description: 'جمع، طرح، ضرب، قسمة\nتدريب شامل ومتكامل',
                tags: ['4 عمليات', 'للمتقدمين', 'تحدي أكبر'],
                color: GalaxyColors.neonPurple,
                recommended: false,
                selected: selectedPath == 'four_operations',
                onTap: () => onSelect('four_operations'),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: _primaryBtn(
            label: 'انطلقي! 🚀',
            color: GalaxyColors.neonCyan,
            enabled: selectedPath.isNotEmpty,
            onTap: onNext),
        ),
      ],
    );
  }
}

class _PathCard extends StatelessWidget {
  final String icon, title, description;
  final List<String> tags;
  final Color color;
  final bool recommended, selected;
  final VoidCallback onTap;
  const _PathCard({required this.icon, required this.title,
    required this.description, required this.tags, required this.color,
    required this.recommended, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: color.withOpacity(selected ? .65 : .28),
            width: selected ? 2 : 1.5),
          color: color.withOpacity(.06),
          boxShadow: [
            BoxShadow(color: color.withOpacity(selected ? .14 : .06), blurRadius: selected ? 28 : 16),
          ],
        ),
        child: Stack(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Row(children:[
                Container(
                  width:54, height:54,
                  decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),
                    color:color.withOpacity(.12)),
                  child:Center(child:Text(icon, style:const TextStyle(fontSize:26)))),
                const SizedBox(width:14),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(title, style:TextStyle(fontFamily:'Cairo', fontSize:17,
                    fontWeight:FontWeight.w900, color:Colors.white,
                    shadows:[Shadow(color:color.withOpacity(.3), blurRadius:10)])),
                  const SizedBox(height:4),
                  Text(description, style:TextStyle(fontFamily:'Cairo', fontSize:12,
                    color:Colors.white.withOpacity(.4), height:1.6)),
                ])),
              ]),
              const SizedBox(height:14),
              Wrap(spacing:7, runSpacing:6,
                children:tags.map((t)=>Container(
                  padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
                  decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),
                    color:color.withOpacity(.1)),
                  child:Text(t,style:TextStyle(fontFamily:'Cairo',fontSize:10,
                    fontWeight:FontWeight.w700,color:color.withOpacity(.8))))).toList()),
            ]),
            // Recommended badge
            if (recommended)
              Positioned(top:0, left:0,
                child:Container(
                  padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
                  decoration:BoxDecoration(borderRadius:BorderRadius.circular(10),
                    color:GalaxyColors.neonGold.withOpacity(.15),
                    border:Border.all(color:GalaxyColors.neonGold.withOpacity(.3))),
                  child:const Text('⭐ مُوصى به',style:TextStyle(fontFamily:'Cairo',
                    fontSize:9,fontWeight:FontWeight.w800,color:GalaxyColors.neonGold)))),
            // Check
            if (selected)
              Positioned(top:0, right:0,
                child:Container(
                  width:26, height:26, decoration:BoxDecoration(shape:BoxShape.circle, color:color),
                  child:const Center(child:Icon(Icons.check_rounded, color:Colors.black, size:16)))),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE 4 – READY
// ═══════════════════════════════════════════════════════════════════════════════

class _ReadyPage extends StatelessWidget {
  final String name, selectedPath;
  final AnimationController floatCtrl;
  final VoidCallback onLaunch;
  const _ReadyPage({required this.name, required this.selectedPath,
    required this.floatCtrl, required this.onLaunch});

  @override
  Widget build(BuildContext context) {
    final isMul = selectedPath == 'multiplication';
    return Column(
      children: [
        Expanded(
          child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[
            AnimatedBuilder(
              animation: floatCtrl,
              builder:(_, __){
                final f=math.sin(floatCtrl.value*math.pi)*10.0;
                return Transform.translate(
                  offset:Offset(0,-f),
                  child:Container(
                    width:120,height:120,
                    decoration:BoxDecoration(shape:BoxShape.circle,
                      gradient:RadialGradient(center:const Alignment(-.3,-.3),colors:[
                        GalaxyColors.neonGold.withOpacity(.24),
                        GalaxyColors.neonGold.withOpacity(.07),
                        Colors.transparent]),
                      border:Border.all(color:GalaxyColors.neonGold.withOpacity(.45),width:2),
                      boxShadow:[BoxShadow(color:GalaxyColors.neonGold.withOpacity(.2),blurRadius:50)]),
                    child:const Center(child:Text('🚀',style:TextStyle(fontSize:46)))));
              }),
            const SizedBox(height:28),
            const Text('جاهزة للانطلاق!',
              style:TextStyle(fontFamily:'Cairo',fontSize:28,fontWeight:FontWeight.w900,color:Colors.white,
                shadows:[Shadow(color:Color(0x40FFD740),blurRadius:20)])),
            const SizedBox(height:8),
            Text('$name 🌟',
              style:const TextStyle(fontFamily:'Cairo',fontSize:22,fontWeight:FontWeight.w900,
                color:GalaxyColors.neonGold)),
            const SizedBox(height:8),
            Text('مجرتك في انتظارك',
              style:TextStyle(fontFamily:'Cairo',fontSize:13,color:Colors.white.withOpacity(.4))),
            const SizedBox(height:18),
            Container(
              padding:const EdgeInsets.symmetric(horizontal:20,vertical:10),
              decoration:BoxDecoration(
                borderRadius:BorderRadius.circular(20),
                color:(isMul?GalaxyColors.neonCyan:GalaxyColors.neonPurple).withOpacity(.1),
                border:Border.all(
                  color:(isMul?GalaxyColors.neonCyan:GalaxyColors.neonPurple).withOpacity(.25))),
              child:Row(mainAxisSize:MainAxisSize.min,children:[
                Text(isMul?'✖️':'🔢',style:const TextStyle(fontSize:16)),
                const SizedBox(width:8),
                Text(isMul?'مسار الضرب':'مسار العمليات الأربع',
                  style:TextStyle(fontFamily:'Cairo',fontSize:13,fontWeight:FontWeight.w700,
                    color:isMul?GalaxyColors.neonCyan:GalaxyColors.neonPurple)),
              ])),
          ]),
        ),
        Padding(
          padding:const EdgeInsets.fromLTRB(24,0,24,28),
          child:_primaryBtn(
            label:'🌌 ادخلي المجرة',
            color:GalaxyColors.neonGold,
            enabled:true,
            onTap:onLaunch)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

Widget _backBtn(VoidCallback onTap) => GestureDetector(
  onTap: onTap,
  child:Container(width:36,height:36,
    decoration:BoxDecoration(shape:BoxShape.circle,
      color:Colors.white.withOpacity(.06),
      border:Border.all(color:Colors.white.withOpacity(.1))),
    child:const Icon(Icons.arrow_forward_ios_rounded,color:Colors.white70,size:15)));

Widget _primaryBtn({required String label, required Color color,
    required bool enabled, required VoidCallback onTap}) =>
  GestureDetector(
    onTap: enabled ? onTap : null,
    child:AnimatedOpacity(opacity:enabled?1.0:.35, duration:const Duration(milliseconds:200),
      child:Container(width:double.infinity,height:58,
        decoration:BoxDecoration(
          borderRadius:BorderRadius.circular(18),
          border:Border.all(color:color.withOpacity(.5),width:1.5),
          gradient:LinearGradient(colors:[color.withOpacity(.24),color.withOpacity(.1)]),
          boxShadow:[BoxShadow(color:color.withOpacity(.1),blurRadius:24)]),
        child:Center(child:Text(label,style:TextStyle(fontFamily:'Cairo',fontSize:17,
          fontWeight:FontWeight.w800,color:color))))));

// ═══════════════════════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════════════════════

class _OnboardStarPainter extends CustomPainter {
  final double t;
  static final _rng=math.Random(42);
  static final _s=List.generate(180,(_)=>[_rng.nextDouble(),_rng.nextDouble(),
    _rng.nextDouble()*1.7+.3,_rng.nextDouble()*.22+.04,_rng.nextDouble()*.65+.2,_rng.nextDouble()*math.pi*2]);
  _OnboardStarPainter(this.t);
  @override void paint(Canvas c,Size sz){final p=Paint();
    for(final s in _s){final tw=math.sin(t*s[3]*math.pi*2+s[5])*.38+.62;
      p.color=Colors.white.withOpacity(s[4]*tw);
      c.drawCircle(Offset(s[0]*sz.width,s[1]*sz.height),s[2],p);}
  }
  @override bool shouldRepaint(_OnboardStarPainter o)=>o.t!=t;
}

class _BurstPainter extends CustomPainter {
  final double p;
  static final _rng=math.Random(13);
  static final _pieces=List.generate(18,(_)=>[
    _rng.nextDouble()*.6+.2, _rng.nextDouble()*.6+.2, // x,y center
    (math.Random().nextDouble()-.5)*200,               // dx
    (math.Random().nextDouble()-.5)*300-100,           // dy
    _rng.nextDouble()*720,                             // spin
    _rng.nextDouble()*.5+.1,                           // delay
    _rng.nextInt(6).toDouble(),                        // color
  ]);
  static const _cols=[GalaxyColors.neonGold,GalaxyColors.neonCyan,GalaxyColors.neonPurple,
    GalaxyColors.neonGreen,GalaxyColors.neonPink,Colors.white];
  _BurstPainter(this.p);
  @override void paint(Canvas canvas,Size size){
    for(final piece in _pieces){
      final lp=((p-piece[5])/(1-piece[5])).clamp(0.0,1.0);
      if(lp<=0)continue;
      final op=(1-lp).clamp(0.0,1.0);
      canvas.save();
      canvas.translate(
        piece[0]*size.width+piece[2]*lp,
        piece[1]*size.height+piece[3]*lp);
      canvas.rotate(piece[4]*lp*math.pi/180);
      canvas.drawRect(
        const Rect.fromLTWH(-5,-3.5,10,7),
        Paint()..color=_cols[piece[6].toInt()].withOpacity(op*.85));
      canvas.restore();
    }
  }
  @override bool shouldRepaint(_BurstPainter o)=>o.p!=p;
}

// ignore_for_file: constant_identifier_names
