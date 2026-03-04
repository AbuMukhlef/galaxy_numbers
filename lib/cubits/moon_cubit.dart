import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../models/models.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// STATES
// ═══════════════════════════════════════════════════════════════════════════════

abstract class MoonState extends Equatable {
  const MoonState();
  @override
  List<Object?> get props => [];
}

class MoonInitial  extends MoonState {}
class MoonLoading  extends MoonState {}

class MoonLayerActive extends MoonState {
  final MoonDefinition definition;
  final MoonProgress   progress;
  final int            activeLayer;
  final bool           challengeModeUnlocked;
  final int            _ts;

  MoonLayerActive({
    required this.definition,
    required this.progress,
    required this.activeLayer,
    required this.challengeModeUnlocked,
  }) : _ts = DateTime.now().microsecondsSinceEpoch;

  @override
  List<Object?> get props => [_ts];
}

class MoonFullyComplete extends MoonState {
  final MoonDefinition definition;
  final String         userName;
  final String         userId;
  const MoonFullyComplete(this.definition, this.userName, this.userId);
  @override
  List<Object?> get props => [definition.key];
}

class MoonError extends MoonState {
  final String message;
  const MoonError(this.message);
  @override
  List<Object?> get props => [message];
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUBIT
// ═══════════════════════════════════════════════════════════════════════════════

class MoonCubit extends Cubit<MoonState> {
  static const _boxName  = 'moon_progress';
  static const _usersBox = 'users';

  MoonCubit() : super(MoonInitial());

  // ── enterMoon ──────────────────────────────────────────────────────────────

  Future<void> enterMoon({
    required String userId,
    required MoonDefinition definition,
  }) async {
    emit(MoonLoading());
    try {
      final box      = Hive.box<MoonProgress>(_boxName);
      final progress = box.get('${userId}_${definition.key}');
      if (progress == null || !progress.isUnlocked) {
        emit(MoonError('Moon is locked'));
        return;
      }
      _emitActive(definition, progress);
    } catch (e) {
      emit(MoonError(e.toString()));
    }
  }

  // ── completeLayer ──────────────────────────────────────────────────────────
  //
  // ✅ المسؤول الوحيد عن:
  //   1. تحديث layerXDone في Hive
  //   2. إضافة الطاقة
  //   3. إذا اكتملت الثلاث طبقات → energy=100% + isCompleted + فتح التالي
  //   4. إصدار الـ state المناسب
  //
  // ✅ يُصدر energyAfterComplete ليُستخدم في GalaxyCubit بدلاً من حسابه مرتين

  Future<void> completeLayer({
    required String userId,
    required String moonKey,
    required int    layer,
    required double energyGained,
  }) async {
    final box      = Hive.box<MoonProgress>(_boxName);
    final hiveKey  = '${userId}_$moonKey';
    final progress = box.get(hiveKey);
    if (progress == null) return;

    switch (layer) {
      case 1:
        progress.layer1Done   = true;
        progress.currentLayer = 2;
      case 2:
        progress.layer2Done   = true;
        progress.currentLayer = 3;
      case 3:
        progress.layer3Done   = true;
    }

    // ✅ أضف الطاقة هنا — المصدر الوحيد للكتابة في Hive
    progress.addEnergy(energyGained);

    final definition = getMoonDefinition(moonKey);
    if (definition == null) { await progress.save(); return; }

    if (progress.layer1Done && progress.layer2Done && progress.layer3Done) {
      progress.energy      = 100.0;
      progress.isCompleted = true;
      await progress.save();
      await _unlockNext(userId, moonKey, box);
      final userBox = Hive.box<UserModel>(_usersBox);
      final user    = userBox.get(userId);
      emit(MoonFullyComplete(definition, user?.name ?? '', userId));
    } else {
      await progress.save();
      _emitActive(definition, progress);
    }
  }

  // ── addEnergy: يُحدّث UI فقط أثناء الجلسة (بدون كتابة Hive)
  // الكتابة الفعلية تحدث في completeLayer عند نهاية الجلسة

  void addEnergyUI({
    required String userId,
    required String moonKey,
    required double currentEnergy,
  }) {
    if (state is! MoonLayerActive) return;
    final s = state as MoonLayerActive;
    if (s.definition.key != moonKey) return;
    // حدّث الطاقة في الكائن مؤقتاً للـ UI
    s.progress.energy = currentEnergy.clamp(0.0, 100.0);
    _emitActive(s.definition, s.progress);
  }

  // ── reload ─────────────────────────────────────────────────────────────────

  Future<void> reload({
    required String userId,
    required MoonDefinition definition,
  }) => enterMoon(userId: userId, definition: definition);

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _emitActive(MoonDefinition definition, MoonProgress progress) {
    emit(MoonLayerActive(
      definition:             definition,
      progress:               progress,
      activeLayer:            progress.currentLayer,
      challengeModeUnlocked:  progress.energy >= 40.0,
    ));
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
    var   nextP   = box.get(nextKey);

    if (nextP == null) {
      nextP = MoonProgress(userId: userId, moonKey: next.key, isUnlocked: true);
      await box.put(nextKey, nextP);
    } else if (!nextP.isUnlocked) {
      nextP.isUnlocked = true;
      await nextP.save();
    }
  }
}
