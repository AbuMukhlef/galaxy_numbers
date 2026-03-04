import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/models.dart';
import 'adaptive_cubit.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// STATES
// ═══════════════════════════════════════════════════════════════════════════════

abstract class ChallengeState extends Equatable {
  const ChallengeState();
  @override
  List<Object?> get props => [];
}

class ChallengeInitial extends ChallengeState {}

class ChallengeActive extends ChallengeState {
  final QuestionModel question;
  final int questionIndex;
  final int totalQuestions;
  final int streak;
  final int? secondsLeft;
  final double currentEnergy;
  final int _ts;

  ChallengeActive({
    required this.question,
    required this.questionIndex,
    required this.totalQuestions,
    required this.streak,
    this.secondsLeft,
    required this.currentEnergy,
  }) : _ts = DateTime.now().microsecondsSinceEpoch;

  @override
  List<Object?> get props => [_ts];
}

class ChallengeAnswered extends ChallengeState {
  final QuestionModel question;
  final bool isCorrect;
  final String feedbackAr;
  final int streak;
  final double energyGained;
  final double currentEnergy;
  final int _ts;

  ChallengeAnswered({
    required this.question,
    required this.isCorrect,
    required this.feedbackAr,
    required this.streak,
    required this.energyGained,
    required this.currentEnergy,
  }) : _ts = DateTime.now().microsecondsSinceEpoch;

  @override
  List<Object?> get props => [_ts];
}

class ChallengeSessionComplete extends ChallengeState {
  final double totalEnergyGained;
  final int correctCount;
  final int totalCount;

  const ChallengeSessionComplete({
    required this.totalEnergyGained,
    required this.correctCount,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [totalEnergyGained, correctCount];
}

class ChallengeError extends ChallengeState {
  final String message;
  const ChallengeError(this.message);
  @override
  List<Object?> get props => [message];
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUBIT
// ═══════════════════════════════════════════════════════════════════════════════

class ChallengeCubit extends Cubit<ChallengeState> {
  final AdaptiveCubit adaptiveCubit;

  List<QuestionModel> _queue = [];
  int _currentIndex = 0;
  int _streak = 0;
  int _correctCount = 0;
  double _sessionEnergyGained = 0;
  double _currentEnergy = 0;
  bool _hasTimer = false;
  int _secondsLeft = 60;
  Timer? _timer;
  Timer? _autoAdvanceTimer;   // ← مؤقت التقدم التلقائي
  DateTime? _questionStartTime;

  ChallengeCubit({required this.adaptiveCubit}) : super(ChallengeInitial());

  // ── Start ──────────────────────────────────────────────────────────────────

  void startSession({
    required List<QuestionModel> questions,
    required double startEnergy,
    bool withTimer = false,
  }) {
    _cancelTimers();
    _queue = questions;
    _currentIndex = 0;
    _streak = 0;
    _correctCount = 0;
    _sessionEnergyGained = 0;
    _currentEnergy = startEnergy;
    _hasTimer = withTimer;
    if (withTimer) _startTimer();
    _showQuestion();
  }

  // ── Show question ──────────────────────────────────────────────────────────

  void _showQuestion() {
    if (isClosed) return;

    if (_currentIndex >= _queue.length) {
      _cancelTimers();
      emit(ChallengeSessionComplete(
        totalEnergyGained: _sessionEnergyGained,
        correctCount: _correctCount,
        totalCount: _queue.length,
      ));
      return;
    }

    _questionStartTime = DateTime.now();
    emit(ChallengeActive(
      question: _queue[_currentIndex],
      questionIndex: _currentIndex + 1,
      totalQuestions: _queue.length,
      streak: _streak,
      secondsLeft: _hasTimer ? _secondsLeft : null,
      currentEnergy: _currentEnergy,
    ));
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  //
  // ✅ الإصلاح الكامل:
  //   • صحيح  → ChallengeAnswered ثم بعد 900ms تلقائياً → السؤال التالي
  //   • خاطئ  → ChallengeAnswered ثم بعد 900ms تلقائياً → نفس السؤال مجدداً
  //   الشاشة لا تحتاج أي Future.delayed أو منطق يدوي

  void submitAnswer(String input) {
    if (state is! ChallengeActive) return;
    _autoAdvanceTimer?.cancel();

    final question = _queue[_currentIndex];
    final timeTaken = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds / 1000.0
        : 3.0;

    final isCorrect = question.checkAnswer(input);

    adaptiveCubit.recordAnswer(
      questionKey: question.key,
      isCorrect: isCorrect,
      timeTaken: timeTaken,
    );

    double energyGained = 0;
    if (isCorrect) {
      _correctCount++;
      _streak++;
      energyGained = 2.0;
      if (_streak >= 5) energyGained += 5.0;
      if (timeTaken < 3.0) energyGained += 3.0;
      _sessionEnergyGained += energyGained;
      _currentEnergy = (_currentEnergy + energyGained).clamp(0.0, 100.0);
    } else {
      _streak = 0;
    }

    emit(ChallengeAnswered(
      question: question,
      isCorrect: isCorrect,
      feedbackAr: isCorrect ? _positiveFeedback(_streak) : 'جربي مرة ثانية 👀',
      streak: _streak,
      energyGained: energyGained,
      currentEnergy: _currentEnergy,
    ));

    // ✅ التقدم التلقائي — الـ Cubit يتكفل بكل شيء
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 900), () {
      if (isClosed) return;
      if (isCorrect) _currentIndex++;   // صحيح → السؤال التالي
      _showQuestion();                   // خاطئ → نفس السؤال مجدداً
    });
  }

  // ── Timer (layer 3) ────────────────────────────────────────────────────────

  void _startTimer() {
    _secondsLeft = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed) return;
      _secondsLeft--;
      if (_secondsLeft <= 0) {
        _cancelTimers();
        emit(ChallengeSessionComplete(
          totalEnergyGained: _sessionEnergyGained,
          correctCount: _correctCount,
          totalCount: _queue.length,
        ));
      } else if (state is ChallengeActive) {
        final s = state as ChallengeActive;
        emit(ChallengeActive(
          question: s.question,
          questionIndex: s.questionIndex,
          totalQuestions: s.totalQuestions,
          streak: _streak,
          secondsLeft: _secondsLeft,
          currentEnergy: _currentEnergy,
        ));
      }
    });
  }

  void _cancelTimers() {
    _timer?.cancel();
    _autoAdvanceTimer?.cancel();
  }

  String _positiveFeedback(int s) {
    if (s >= 10) return '🔥 لا يُوقف! سلسلة $s';
    if (s >= 5)  return '⚡ سلسلة قوة! $s إجابات صح';
    if (s >= 3)  return '✨ رائع! $s متتالية';
    return '✅ صح!';
  }

  @override
  Future<void> close() {
    _cancelTimers();
    return super.close();
  }
}
