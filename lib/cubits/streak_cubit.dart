import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../models/models.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class StreakState extends Equatable {
  const StreakState();
  @override
  List<Object?> get props => [];
}

class StreakInitial extends StreakState {}

class StreakLoaded extends StreakState {
  final StreakModel streak;
  const StreakLoaded(this.streak);
  @override
  List<Object?> get props => [streak.currentStreak, streak.lastPlayDate];
}

/// Fired when streak hits a milestone (every 3 days)
class StreakMilestone extends StreakState {
  final StreakModel streak;
  final String celebrationMessageAr;
  const StreakMilestone(this.streak, this.celebrationMessageAr);
  @override
  List<Object?> get props => [streak.currentStreak];
}

class StreakBroken extends StreakState {
  final StreakModel streak;
  const StreakBroken(this.streak);
  @override
  List<Object?> get props => [streak.currentStreak];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class StreakCubit extends Cubit<StreakState> {
  static const _boxName = 'streaks';

  StreakCubit() : super(StreakInitial());

  Future<void> loadStreak(String userId) async {
    final box = await Hive.openBox<StreakModel>(_boxName);
    var streak = box.get(userId);

    if (streak == null) {
      streak = StreakModel(userId: userId);
      await box.put(userId, streak);
    }

    if (streak.isStreakBroken) {
      emit(StreakBroken(streak));
    } else {
      emit(StreakLoaded(streak));
    }
  }

  Future<void> recordPlay(String userId) async {
    final box = await Hive.openBox<StreakModel>(_boxName);
    var streak = box.get(userId);

    streak ??= StreakModel(userId: userId);

    final isMilestone = streak.recordPlay();
    await box.put(userId, streak);

    if (isMilestone) {
      final message = _getMilestoneMessage(streak.currentStreak);
      emit(StreakMilestone(streak, message));
    } else {
      emit(StreakLoaded(streak));
    }
  }

  String _getMilestoneMessage(int days) {
    // Uses stored user name from state context — generic fallback here
    return '⚡ $days أيام قوة متتالية! أنتِ أسطورة 🔥';
  }

  int get currentStreak {
    if (state is StreakLoaded) return (state as StreakLoaded).streak.currentStreak;
    if (state is StreakMilestone) return (state as StreakMilestone).streak.currentStreak;
    return 0;
  }
}
