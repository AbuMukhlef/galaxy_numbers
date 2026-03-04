import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../models/models.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// STATES
// ═══════════════════════════════════════════════════════════════════════════════

abstract class GalaxyState extends Equatable {
  const GalaxyState();
  @override
  List<Object?> get props => [];
}

class GalaxyInitial extends GalaxyState {}
class GalaxyLoading extends GalaxyState {}

class GalaxyLoaded extends GalaxyState {
  final List<MoonDefinition> moons;
  final Map<String, MoonProgress> progressMap;
  final String userId;
  // ✅ timestamp يضمن أن كل emit مختلف — Equatable لن يمنع التحديث أبداً
  final int _ts;

  GalaxyLoaded({
    required this.moons,
    required this.progressMap,
    required this.userId,
  }) : _ts = DateTime.now().microsecondsSinceEpoch;

  MoonProgress? progressFor(String key) => progressMap[key];
  bool isUnlocked(String key) => progressMap[key]?.isUnlocked ?? false;
  bool isCompleted(String key) => progressMap[key]?.isCompleted ?? false;
  double energyFor(String key) => progressMap[key]?.energy ?? 0.0;

  @override
  List<Object?> get props => [_ts];
}

class GalaxyError extends GalaxyState {
  final String message;
  const GalaxyError(this.message);
  @override
  List<Object?> get props => [message];
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUBIT
// ═══════════════════════════════════════════════════════════════════════════════

class GalaxyCubit extends Cubit<GalaxyState> {
  static const _boxName = 'moon_progress';

  GalaxyCubit() : super(GalaxyInitial());

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> loadGalaxy(String userId, String path) async {
    emit(GalaxyLoading());
    try {
      final map = await _freshProgressMap(userId);
      emit(GalaxyLoaded(moons: multiplicationMoons, progressMap: map, userId: userId));
    } catch (e) {
      emit(GalaxyError(e.toString()));
    }
  }

  // ── Refresh يدوي عبر RefreshIndicator ─────────────────────────────────────

  Future<void> refresh(String userId) async {
    if (state is! GalaxyLoaded) return;
    final map = await _freshProgressMap(userId);
    emit(GalaxyLoaded(
      moons: multiplicationMoons,
      progressMap: map,
      userId: userId,
    ));
  }

  // ── syncFromHive: يقرأ قمراً واحداً من Hive ويُصدر state محدَّث ──────────────
  // يُستدعى من ChallengeScreen بعد completeLayer
  // لا يحسب طاقة بنفسه — فقط يقرأ ما حفظه completeLayer في Hive

  Future<void> syncFromHive({
    required String userId,
    required String moonKey,
  }) async {
    if (state is! GalaxyLoaded) return;
    final current = state as GalaxyLoaded;
    // أعد بناء الـ map كاملاً من Hive — يعكس آخر حالة حفظها completeLayer
    final freshMap = await _freshProgressMap(userId);
    emit(GalaxyLoaded(
      moons:       current.moons,
      progressMap: freshMap,
      userId:      userId,
    ));
  }

  // ── updateMoonEnergy: يُستدعى بعد كل جلسة تحدٍّ ──────────────────────────
  //
  // ✅ الإصلاح الكامل:
  //   1. حدّث طاقة القمر الحالي في Hive
  //   2. إذا اكتمل (100%) → افتح التالي في Hive فوراً
  //   3. أعد بناء progressMap كاملاً من Hive
  //   4. أصدر GalaxyLoaded جديد → الشاشة تتحدث تلقائياً

  Future<void> updateMoonEnergy({
    required String userId,
    required String moonKey,
    required double newEnergy,
  }) async {
    if (state is! GalaxyLoaded) return;
    final current = state as GalaxyLoaded;

    final box      = Hive.box<MoonProgress>(_boxName);
    final progress = box.get('\${userId}_\$moonKey');
    if (progress == null) return;

    // تحديث الطاقة في Hive
    progress.energy = newEnergy.clamp(0.0, 100.0);

    if (progress.energy >= 100.0) {
      // اكتمال → فتح التالي + إعادة بناء كاملة
      if (!progress.isCompleted) progress.isCompleted = true;
      await progress.save();
      await _unlockNext(userId, moonKey, box);

      // إعادة بناء كاملة لأن قمراً جديداً فُتح
      final freshMap = await _freshProgressMap(userId);
      emit(GalaxyLoaded(moons: current.moons, progressMap: freshMap, userId: userId));
    } else {
      // ✅ تحديث سريع: فقط حدّث هذا القمر في الـ map بدون قراءة Hive كاملاً
      // يُستدعى مع كل إجابة صحيحة فيجب أن يكون خفيفاً
      await progress.save();
      final updatedMap = Map<String, MoonProgress>.from(current.progressMap);
      updatedMap[moonKey] = progress;
      emit(GalaxyLoaded(moons: current.moons, progressMap: updatedMap, userId: userId));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// يقرأ progress كل قمر من Hive من جديد — يضمن مزامنة 100%
  Future<Map<String, MoonProgress>> _freshProgressMap(String userId) async {
    final box = Hive.box<MoonProgress>(_boxName);
    final Map<String, MoonProgress> map = {};

    for (int i = 0; i < multiplicationMoons.length; i++) {
      final moon = multiplicationMoons[i];
      final key  = '${userId}_${moon.key}';
      var progress = box.get(key);

      if (progress == null) {
        progress = MoonProgress(
          userId: userId,
          moonKey: moon.key,
          isUnlocked: i == 0, // القمر الأول مفتوح دائماً
        );
        await box.put(key, progress);
      }
      map[moon.key] = progress;
    }
    return map;
  }

  Future<void> _unlockNext(
    String userId,
    String completedKey,
    Box<MoonProgress> box,
  ) async {
    final idx = multiplicationMoons.indexWhere((m) => m.key == completedKey);
    if (idx < 0 || idx + 1 >= multiplicationMoons.length) return;

    final next    = multiplicationMoons[idx + 1];
    final nextKey = '${userId}_${next.key}';
    var nextP = box.get(nextKey);

    if (nextP == null) {
      // إنشاء progress للقمر التالي وفتحه
      nextP = MoonProgress(userId: userId, moonKey: next.key, isUnlocked: true);
      await box.put(nextKey, nextP);
    } else if (!nextP.isUnlocked) {
      nextP.isUnlocked = true;
      await nextP.save();
    }
  }
}
