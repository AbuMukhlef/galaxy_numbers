import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/cubits.dart';
import '../../models/models.dart';
import '../galaxy/galaxy_screen.dart' show GalaxyColors;

// ═══════════════════════════════════════════════════════════════════════════════
// CHALLENGE SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class ChallengeScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final MoonDefinition moonDefinition;
  final int layer;
  final bool withTimer;
  final double startEnergy;

  const ChallengeScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.moonDefinition,
    required this.layer,
    required this.withTimer,
    required this.startEnergy,
  });

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _starsController;
  late AnimationController _energyController;

  String _input = '';
  bool _answered = false;
  bool? _lastCorrect;
  String _feedbackText = '';
  String _formulaHint = '';

  int _streak = 0;
  int _bestStreak = 0;
  int _correctCount = 0;
  double _sessionEnergy = 0;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350));

    _starsController = AnimationController(
      vsync: this, duration: const Duration(seconds: 60))..repeat();

    _energyController = AnimationController(
      vsync: this,
      value: widget.startEnergy / 100,
      duration: const Duration(milliseconds: 600));

    final questions = context.read<AdaptiveCubit>().generateWithSpacedRepetition(
          moon: widget.moonDefinition,
          count: widget.layer == 1
              ? widget.moonDefinition.layer1Count
              : widget.layer == 2
                  ? widget.moonDefinition.layer2Count
                  : 20,
        );

    context.read<ChallengeCubit>().startSession(
          questions: questions,
          startEnergy: widget.startEnergy,
          withTimer: widget.withTimer,
        );
  }

  @override
  void dispose() {
    _cardController.dispose();
    _starsController.dispose();
    _energyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChallengeCubit, ChallengeState>(
      listener: _handleState,
      child: Scaffold(
        backgroundColor: GalaxyColors.darkBg,
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _starsController,
              builder: (_, __) => CustomPaint(
                painter: _StarPainter(_starsController.value),
                size: Size.infinite,
              ),
            ),
            SafeArea(
              child: KeyboardListener(
                focusNode: _focusNode,
                autofocus: true,
                onKeyEvent: _onKey,
                child: Column(
                  children: [
                    _topBar(),
                    _streakBar(),
                    Expanded(child: _questionCard()),
                    _feedback(),
                    _energyMini(),
                    _answerDisplay(),
                    const SizedBox(height: 10),
                    _numpad(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── State ──────────────────────────────────────────────────────────────────

  void _handleState(BuildContext ctx, ChallengeState state) {
    // ── إجابة مُقيَّمة ────────────────────────────────────────────────────────
    if (state is ChallengeAnswered) {
      setState(() {
        _answered    = true;
        _lastCorrect = state.isCorrect;
        _feedbackText = state.feedbackAr;
        _streak       = state.streak;
        if (_streak > _bestStreak) _bestStreak = _streak;
        if (state.isCorrect) _correctCount++;
        _sessionEnergy += state.energyGained;
        _formulaHint = state.isCorrect
            ? '\${state.question.operandA} × \${state.question.operandB} = \${state.question.answer}'
            : '';
      });
      _energyController.animateTo(
        (state.currentEnergy / 100).clamp(0.0, 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
      if (state.isCorrect) {
        _cardController.forward(from: 0).then((_) => _cardController.reverse());
        HapticFeedback.lightImpact();

        // حدّث MoonCubit بالطاقة الكاملة الحالية → شريط الطاقة يتحدث فوراً (UI فقط)
        ctx.read<MoonCubit>().addEnergyUI(
          userId:        widget.userId,
          moonKey:       widget.moonDefinition.key,
          currentEnergy: state.currentEnergy,
        );
      } else {
        _cardController.forward(from: 0);
        HapticFeedback.heavyImpact();
      }
    }

    // ✅ الإصلاح: Cubit يُعيد ChallengeActive تلقائياً (صحيح→التالي / خاطئ→نفس السؤال)
    // الشاشة فقط تُصفّر input وتُعيد الـ UI للوضع الأولي
    if (state is ChallengeActive && _answered) {
      setState(() {
        _input       = '';
        _answered    = false;
        _lastCorrect = null;
        _feedbackText = '';
        _formulaHint = '';
      });
      _cardController.reset();
    }

    // ── اكتمال الجلسة ─────────────────────────────────────────────────────────
    if (state is ChallengeSessionComplete) {
      // ✅ completeLayer هو المسؤول الوحيد:
      //   - يحدّث layerDone
      //   - يضيف الطاقة مرة واحدة فقط
      //   - إذا اكتملت الطبقات الثلاث: energy=100% + isCompleted + يفتح التالي
      //   - يُصدر الطاقة النهائية الصحيحة
      // completeLayer: يُضيف الطاقة + يحدّث layerDone + يفتح التالي عند الاكتمال
      ctx.read<MoonCubit>().completeLayer(
        userId:       widget.userId,
        moonKey:      widget.moonDefinition.key,
        layer:        widget.layer,
        energyGained: state.totalEnergyGained,
      );
      // syncFromHive: يقرأ Hive ويُحدّث GalaxyScreen
      ctx.read<GalaxyCubit>().syncFromHive(
        userId:  widget.userId,
        moonKey: widget.moonDefinition.key,
      );

      _showComplete(state);
    }
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _topBar() {
    return BlocBuilder<ChallengeCubit, ChallengeState>(
      builder: (_, state) {
        int cur = 1, tot = 20; int? sec;
        if (state is ChallengeActive) { cur=state.questionIndex; tot=state.totalQuestions; sec=state.secondsLeft; }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width:36, height:36,
                  decoration: BoxDecoration(shape:BoxShape.circle,
                    color:Colors.white.withOpacity(.06),
                    border:Border.all(color:Colors.white.withOpacity(.1))),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color:Colors.white70, size:15),
                ),
              ),
              const SizedBox(width:12),
              Expanded(
                child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                  Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
                    Text('السؤال $cur من $tot', style:TextStyle(fontFamily:'Cairo', fontSize:11, color:Colors.white.withOpacity(.4))),
                    Text(_layerLabel, style:TextStyle(fontFamily:'Cairo', fontSize:11, color:Colors.white.withOpacity(.4))),
                  ]),
                  const SizedBox(height:5),
                  ClipRRect(borderRadius:BorderRadius.circular(4),
                    child:LinearProgressIndicator(
                      value: tot>0?(cur-1)/tot:0,
                      backgroundColor:Colors.white.withOpacity(.07),
                      valueColor:AlwaysStoppedAnimation(GalaxyColors.neonCyan.withOpacity(.8)),
                      minHeight:6)),
                ]),
              ),
              if (sec != null) ...[const SizedBox(width:12), _TimerRing(secondsLeft:sec, total:60)],
            ],
          ),
        );
      },
    );
  }

  // ── Streak bar ─────────────────────────────────────────────────────────────

  Widget _streakBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(children:[
        Text('سلسلة', style:TextStyle(fontFamily:'Cairo', fontSize:12, color:Colors.white.withOpacity(.38))),
        const SizedBox(width:8),
        Expanded(child:Row(children:List.generate(5,(i){
          final lit=i<_streak;
          return Expanded(child:AnimatedContainer(
            duration:const Duration(milliseconds:250),
            margin:const EdgeInsets.only(right:4),
            height:8,
            decoration:BoxDecoration(
              borderRadius:BorderRadius.circular(4),
              color:lit?GalaxyColors.neonGold:Colors.white.withOpacity(.07),
              boxShadow:lit?[BoxShadow(color:GalaxyColors.neonGold.withOpacity(.5),blurRadius:6)]:[]),
          ));
        }))),
        const SizedBox(width:8),
        Text(_streak>0?'$_streak':'',
          style:const TextStyle(fontFamily:'Cairo',fontSize:13,fontWeight:FontWeight.w800,color:GalaxyColors.neonGold)),
      ]),
    );
  }

  // ── Question card ──────────────────────────────────────────────────────────

  Widget _questionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:20),
      child: Center(
        child: AnimatedBuilder(
          animation: _cardController,
          builder: (_, child) => Transform(
            alignment:Alignment.center,
            transform: _lastCorrect==true
              ? (Matrix4.diagonal3Values(1+_cardController.value*.04,1+_cardController.value*.04,1))
              : _lastCorrect==false
                ? (Matrix4.translationValues(math.sin(_cardController.value*math.pi*4)*7,0,0))
                : Matrix4.identity(),
            child: child),
          child: BlocBuilder<ChallengeCubit, ChallengeState>(
            builder: (_, state) {
              String q='';
              if (state is ChallengeActive)   q=state.question.displayAr;
              if (state is ChallengeAnswered) q=state.question.displayAr;
              final bc=_lastCorrect==null?GalaxyColors.neonCyan.withOpacity(.22)
                :_lastCorrect!?GalaxyColors.neonGreen.withOpacity(.6)
                :const Color(0xFFFF4081).withOpacity(.45);
              return AnimatedContainer(
                duration:const Duration(milliseconds:200),
                width:double.infinity,
                padding:const EdgeInsets.fromLTRB(28,30,28,26),
                decoration:BoxDecoration(
                  borderRadius:BorderRadius.circular(24),
                  border:Border.all(color:bc,width:1.5),
                  gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
                    colors:[const Color(0xFF001E32).withOpacity(.85),const Color(0xFF000F1E).withOpacity(.85)]),
                  boxShadow:[BoxShadow(color:(_lastCorrect==null?GalaxyColors.neonCyan
                    :_lastCorrect!?GalaxyColors.neonGreen:const Color(0xFFFF4081)).withOpacity(.08),blurRadius:40)]),
                child:Column(mainAxisSize:MainAxisSize.min, children:[
                  Text('كم ناتج؟', style:TextStyle(fontFamily:'Cairo',fontSize:13,color:Colors.white.withOpacity(.38),letterSpacing:.5)),
                  const SizedBox(height:12),
                  Text(q, style:const TextStyle(fontFamily:'Cairo',fontSize:46,fontWeight:FontWeight.w900,color:Colors.white,letterSpacing:2)),
                  const SizedBox(height:14),
                  AnimatedOpacity(opacity:_formulaHint.isNotEmpty?1:0, duration:const Duration(milliseconds:300),
                    child:Text(_formulaHint, style:TextStyle(fontFamily:'Cairo',fontSize:12,color:GalaxyColors.neonCyan.withOpacity(.55)))),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Feedback ───────────────────────────────────────────────────────────────

  Widget _feedback() => SizedBox(height:34, child:Center(
    child:AnimatedOpacity(opacity:_feedbackText.isNotEmpty?1:0, duration:const Duration(milliseconds:200),
      child:Text(_feedbackText, style:TextStyle(fontFamily:'Cairo',fontSize:15,fontWeight:FontWeight.w800,
        color:_lastCorrect==true?GalaxyColors.neonGreen:const Color(0xFFFF4081))))));

  // ── Energy mini ────────────────────────────────────────────────────────────

  Widget _energyMini() => Padding(
    padding:const EdgeInsets.fromLTRB(20,4,20,12),
    child:Row(children:[
      Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(4),
        child:AnimatedBuilder(animation:_energyController,
          builder:(_,__)=>LinearProgressIndicator(value:_energyController.value,
            backgroundColor:Colors.white.withOpacity(.06),
            valueColor:AlwaysStoppedAnimation(_energyController.value>=1?GalaxyColors.neonGold:GalaxyColors.neonCyan),
            minHeight:7)))),
      const SizedBox(width:10),
      AnimatedBuilder(animation:_energyController,
        builder:(_,__)=>Text('${(_energyController.value*100).toInt()}%',
          style:TextStyle(fontFamily:'Cairo',fontSize:12,fontWeight:FontWeight.w800,
            color:_energyController.value>=1?GalaxyColors.neonGold:GalaxyColors.neonCyan))),
    ]),
  );

  // ── Answer display ─────────────────────────────────────────────────────────

  Widget _answerDisplay() {
    final col=_lastCorrect==null?Colors.white:_lastCorrect!?GalaxyColors.neonGreen:const Color(0xFFFF4081);
    final bc=_lastCorrect==null?GalaxyColors.neonCyan.withOpacity(.35)
      :_lastCorrect!?GalaxyColors.neonGreen.withOpacity(.55):const Color(0xFFFF4081).withOpacity(.4);
    return Padding(padding:const EdgeInsets.fromLTRB(20,0,20,10),
      child:AnimatedContainer(duration:const Duration(milliseconds:200),
        width:double.infinity, height:66,
        decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),
          border:Border.all(color:bc,width:2),
          color:_lastCorrect==null?const Color(0xFF001428).withOpacity(.7)
            :_lastCorrect!?const Color(0xFF003C1E).withOpacity(.4):const Color(0xFF3C0014).withOpacity(.3),
          boxShadow:[BoxShadow(color:bc.withOpacity(.14),blurRadius:16)]),
        child:Center(child:_input.isEmpty
          ?Container(width:3,height:34,decoration:BoxDecoration(color:GalaxyColors.neonCyan,borderRadius:BorderRadius.circular(2)))
          :Text(_input,style:TextStyle(fontFamily:'Cairo',fontSize:34,fontWeight:FontWeight.w900,color:col,letterSpacing:4)))));
  }

  // ── Numpad ─────────────────────────────────────────────────────────────────

  Widget _numpad() => Padding(
    padding:const EdgeInsets.symmetric(horizontal:20),
    child:Column(children:[
      _row(['1','2','3']), const SizedBox(height:10),
      _row(['4','5','6']), const SizedBox(height:10),
      _row(['7','8','9']), const SizedBox(height:10),
      Row(children:[_key('⌫',del:true),const SizedBox(width:10),_key('0'),const SizedBox(width:10),_key('✓ تأكيد',sub:true)]),
    ]),
  );

  Widget _row(List<String> ks) => Row(children:[
    for(int i=0;i<ks.length;i++)...[if(i>0)const SizedBox(width:10),_key(ks[i])]]);

  Widget _key(String lbl,{bool del=false,bool sub=false}) => Expanded(
    child:GestureDetector(
      onTap:(){HapticFeedback.selectionClick(); del?_del():sub?_submit():_press(lbl);},
      child:Container(height:56,
        decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),
          border:Border.all(color:sub?GalaxyColors.neonCyan.withOpacity(.4)
            :del?const Color(0xFFFF4081).withOpacity(.2):Colors.white.withOpacity(.08)),
          color:sub?GalaxyColors.neonCyan.withOpacity(.14):Colors.white.withOpacity(.04)),
        child:Center(child:Text(lbl,style:TextStyle(fontFamily:'Cairo',
          fontSize:sub?16:22,fontWeight:FontWeight.w800,
          color:sub?GalaxyColors.neonCyan:del?const Color(0xFFFF4081).withOpacity(.7):Colors.white))))));

  // ── Input ──────────────────────────────────────────────────────────────────

  void _press(String d){ if(_answered||_input.length>=3)return; setState(()=>_input+=d); }
  void _del()  { if(_answered||_input.isEmpty)return; setState(()=>_input=_input.substring(0,_input.length-1)); }
  void _submit(){ if(_answered||_input.isEmpty)return; context.read<ChallengeCubit>().submitAnswer(_input); }
  void _onKey(KeyEvent e){
    if(e is KeyDownEvent){
      final k=e.logicalKey.keyLabel;
      if(RegExp(r'^[0-9]$').hasMatch(k))_press(k);
      if(k=='Backspace')_del();
      if(k=='Enter')_submit();
    }
  }

  // ── Complete ───────────────────────────────────────────────────────────────

  void _showComplete(ChallengeSessionComplete state){
    showDialog(context:context,barrierDismissible:false,barrierColor:const Color(0xEC020818),
      builder:(_)=>_CompleteDialog(state:state,bestStreak:_bestStreak,
        onContinue:()=>Navigator.of(context)..pop()..pop()));
  }

  String get _layerLabel => switch(widget.layer){1=>'طبقة 1 — فهم بصري',2=>'طبقة 2 — تثبيت',_=>'طبقة 3 — السرعة'};
}

// ══════ TIMER RING ══════════════════════════════════════════════════════════════

class _TimerRing extends StatelessWidget {
  final int secondsLeft, total;
  const _TimerRing({required this.secondsLeft,required this.total});
  @override
  Widget build(BuildContext context){
    final r=secondsLeft/total;
    final col=secondsLeft<=10?const Color(0xFFFF4081):GalaxyColors.neonGold;
    return SizedBox(width:46,height:46,child:Stack(alignment:Alignment.center,children:[
      CustomPaint(painter:_RingPainter(ratio:r,color:col),size:const Size(46,46)),
      Text('$secondsLeft',style:TextStyle(fontFamily:'Cairo',fontSize:12,fontWeight:FontWeight.w800,color:col)),
    ]));
  }
}

class _RingPainter extends CustomPainter {
  final double ratio; final Color color;
  _RingPainter({required this.ratio,required this.color});
  @override
  void paint(Canvas canvas,Size size){
    final c=Offset(size.width/2,size.height/2), r=size.width/2-3;
    canvas.drawCircle(c,r,Paint()..color=Colors.white.withOpacity(.08)..strokeWidth=3..style=PaintingStyle.stroke);
    canvas.drawArc(Rect.fromCircle(center:c,radius:r),-math.pi/2,ratio*2*math.pi,false,
      Paint()..color=color..strokeWidth=3..style=PaintingStyle.stroke..strokeCap=StrokeCap.round);
  }
  @override bool shouldRepaint(_RingPainter o)=>o.ratio!=ratio;
}

// ══════ COMPLETE DIALOG ═════════════════════════════════════════════════════════

class _CompleteDialog extends StatelessWidget {
  final ChallengeSessionComplete state; final int bestStreak; final VoidCallback onContinue;
  const _CompleteDialog({required this.state,required this.bestStreak,required this.onContinue});
  @override
  Widget build(BuildContext context){
    final pct=state.totalCount>0?(state.correctCount/state.totalCount*100).toInt():0;
    final (emoji,title)=pct>=90?('🏆','مذهل! أنتِ نجمة!'):pct>=70?('🌟','رائع جداً!'):pct>=50?('💪','استمري!'):('🚀','في الطريق الصح!');
    return Dialog(backgroundColor:Colors.transparent,child:Container(
      padding:const EdgeInsets.all(28),
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(28),
        border:Border.all(color:GalaxyColors.neonCyan.withOpacity(.3),width:2),
        gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
          colors:[Color(0xFF001932),Color(0xFF000C1C)]),
        boxShadow:[BoxShadow(color:GalaxyColors.neonCyan.withOpacity(.12),blurRadius:60)]),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        Text(emoji,style:const TextStyle(fontSize:52)),
        const SizedBox(height:12),
        Text(title,style:const TextStyle(fontFamily:'Cairo',fontSize:22,fontWeight:FontWeight.w900,color:Colors.white)),
        const SizedBox(height:6),
        Text('أجبتِ على ${state.correctCount} من ${state.totalCount} صح',
          style:TextStyle(fontFamily:'Cairo',fontSize:13,color:Colors.white.withOpacity(.45))),
        const SizedBox(height:20),
        Row(children:[
          _sb('${state.correctCount}','صحيح'),
          const SizedBox(width:10),
          _sb('+${state.totalEnergyGained.toInt()}%','طاقة'),
          const SizedBox(width:10),
          _sb('$bestStreak','أفضل سلسلة'),
        ]),
        const SizedBox(height:20),
        SizedBox(width:double.infinity,height:52,
          child:ElevatedButton(onPressed:onContinue,
            style:ElevatedButton.styleFrom(
              backgroundColor:GalaxyColors.neonCyan.withOpacity(.18),
              foregroundColor:GalaxyColors.neonCyan,
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),
                side:BorderSide(color:GalaxyColors.neonCyan.withOpacity(.5))),elevation:0),
            child:const Text('العودة للقمر ←',style:TextStyle(fontFamily:'Cairo',fontSize:16,fontWeight:FontWeight.w800)))),
      ]),
    ));
  }
  Widget _sb(String v,String l)=>Expanded(child:Container(
    padding:const EdgeInsets.symmetric(vertical:12),
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(14),
      color:Colors.white.withOpacity(.04),border:Border.all(color:Colors.white.withOpacity(.08))),
    child:Column(children:[
      Text(v,style:const TextStyle(fontFamily:'Cairo',fontSize:20,fontWeight:FontWeight.w900,color:GalaxyColors.neonCyan)),
      const SizedBox(height:3),
      Text(l,style:TextStyle(fontFamily:'Cairo',fontSize:10,color:Colors.white.withOpacity(.38))),
    ])));
}

// ══════ STAR PAINTER ════════════════════════════════════════════════════════════

class _StarPainter extends CustomPainter {
  final double t;
  static final _rng=math.Random(33);
  static final _s=List.generate(140,(_)=>[_rng.nextDouble(),_rng.nextDouble(),_rng.nextDouble()*1.5+.3,_rng.nextDouble()*.2+.04,_rng.nextDouble()*.55+.2,_rng.nextDouble()*math.pi*2]);
  _StarPainter(this.t);
  @override
  void paint(Canvas canvas,Size size){
    final p=Paint();
    for(final s in _s){
      final tw=math.sin(t*s[3]*math.pi*2+s[5])*.3+.7;
      p.color=Colors.white.withOpacity(s[4]*tw);
      canvas.drawCircle(Offset(s[0]*size.width,s[1]*size.height),s[2],p);
    }
  }
  @override bool shouldRepaint(_StarPainter o)=>o.t!=t;
}
