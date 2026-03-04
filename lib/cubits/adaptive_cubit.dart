import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../models/models.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AdaptiveState extends Equatable {
  const AdaptiveState();
  @override
  List<Object?> get props => [];
}

class AdaptiveInitial extends AdaptiveState {}

class AdaptiveReady extends AdaptiveState {
  final Map<String, QuestionPerformance> performanceMap;
  const AdaptiveReady(this.performanceMap);
  @override
  List<Object?> get props => [performanceMap.length];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class AdaptiveCubit extends Cubit<AdaptiveState> {
  static const _boxName = 'performance';
  static const _weaknessThreshold = 0.35;
  static const _masteryThreshold = 0.15;
  static const _weaknessRatio = 0.30; // 30% weakness questions

  String? _currentUserId;
  final _rng = Random();

  AdaptiveCubit() : super(AdaptiveInitial());

  Future<void> loadPerformance(String userId) async {
    _currentUserId = userId;
    final box = await Hive.openBox<QuestionPerformance>(_boxName);
    final map = <String, QuestionPerformance>{};
    for (final entry in box.values) {
      if (entry.userId == userId) {
        map[entry.questionKey] = entry;
      }
    }
    emit(AdaptiveReady(map));
  }

  // ── Record answer ──────────────────────────────────────────────────────────

  Future<void> recordAnswer({
    required String questionKey,
    required bool isCorrect,
    required double timeTaken,
  }) async {
    if (_currentUserId == null) return;
    final box = await Hive.openBox<QuestionPerformance>(_boxName);
    final hiveKey = '${_currentUserId}_$questionKey';

    var perf = box.get(hiveKey);
    if (perf == null) {
      perf = QuestionPerformance(
        userId: _currentUserId!,
        questionKey: questionKey,
        lastSeen: DateTime.now(),
      );
    }

    perf.recordAnswer(isCorrect: isCorrect, timeTaken: timeTaken);
    await box.put(hiveKey, perf);

    // Update state
    if (state is AdaptiveReady) {
      final current = state as AdaptiveReady;
      final updated = Map<String, QuestionPerformance>.from(current.performanceMap);
      updated[questionKey] = perf;
      emit(AdaptiveReady(updated));
    }
  }

  // ── Generate question list ─────────────────────────────────────────────────

  /// Generates a mixed question list: 70% normal + 30% weakness
  List<QuestionModel> generateQuestions({
    required MoonDefinition moon,
    required int count,
  }) {
    final allQuestions = _generateAllForMoon(moon);
    final weakList = _getWeakQuestions(moon);

    final int weakCount = (count * _weaknessRatio).round();
    final int normalCount = count - weakCount;

    final normalQuestions = _pickRandom(allQuestions, normalCount);
    final weakQuestions = weakList.isNotEmpty
        ? _pickRandom(weakList, min(weakCount, weakList.length))
        : _pickRandom(allQuestions, weakCount);

    final combined = [...normalQuestions, ...weakQuestions]..shuffle(_rng);
    return combined;
  }

  /// For spaced repetition: insert review questions at intervals
  List<QuestionModel> generateWithSpacedRepetition({
    required MoonDefinition moon,
    required int count,
  }) {
    final base = generateQuestions(moon: moon, count: count);
    final reviewCandidates = _getSpacedRepetitionQuestions(moon);

    if (reviewCandidates.isEmpty) return base;

    // Insert review questions at positions 3, 10
    final result = List<QuestionModel>.from(base);
    if (result.length > 3 && reviewCandidates.isNotEmpty) {
      result.insert(3, reviewCandidates[0]);
    }
    if (result.length > 10 && reviewCandidates.length > 1) {
      result.insert(10, reviewCandidates[1]);
    }
    return result;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  List<QuestionModel> _generateAllForMoon(MoonDefinition moon) {
    return List.generate(10, (i) {
      return QuestionModel(
        operandA: moon.tableNumber,
        operandB: i + 1,
        type: moon.type,
        source: QuestionSource.normal,
      );
    })..shuffle(_rng);
  }

  List<QuestionModel> _getWeakQuestions(MoonDefinition moon) {
    if (state is! AdaptiveReady) return [];
    final perfMap = (state as AdaptiveReady).performanceMap;

    return List.generate(10, (i) {
      return QuestionModel(
        operandA: moon.tableNumber,
        operandB: i + 1,
        type: moon.type,
        source: QuestionSource.weaknessList,
      );
    }).where((q) {
      final perf = perfMap[q.key];
      if (perf == null) return false;
      return perf.weaknessScore > _weaknessThreshold;
    }).toList();
  }

  List<QuestionModel> _getSpacedRepetitionQuestions(MoonDefinition moon) {
    if (state is! AdaptiveReady) return [];
    final perfMap = (state as AdaptiveReady).performanceMap;
    final now = DateTime.now();

    return List.generate(10, (i) {
      return QuestionModel(
        operandA: moon.tableNumber,
        operandB: i + 1,
        type: moon.type,
        source: QuestionSource.spacedRepetition,
      );
    }).where((q) {
      final perf = perfMap[q.key];
      if (perf == null) return false;
      // Due for review if last seen > 1 day and still weak
      final daysSince = now.difference(perf.lastSeen).inDays;
      return daysSince >= 1 && perf.weaknessScore > _masteryThreshold;
    }).toList();
  }

  List<QuestionModel> _pickRandom(List<QuestionModel> list, int count) {
    if (list.isEmpty) return [];
    final shuffled = List<QuestionModel>.from(list)..shuffle(_rng);
    return shuffled.take(count).toList();
  }

  // ── Public query ───────────────────────────────────────────────────────────

  QuestionPerformance? getPerformance(String questionKey) {
    if (state is! AdaptiveReady) return null;
    return (state as AdaptiveReady).performanceMap[questionKey];
  }

  List<String> getWeakQuestionKeys() {
    if (state is! AdaptiveReady) return [];
    return (state as AdaptiveReady)
        .performanceMap
        .entries
        .where((e) => e.value.weaknessScore > _weaknessThreshold)
        .map((e) => e.key)
        .toList();
  }
}
