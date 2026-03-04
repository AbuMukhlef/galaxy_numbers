import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

class SyncIdle extends SyncState {}

class SyncInProgress extends SyncState {}

class SyncSuccess extends SyncState {
  final DateTime syncedAt;
  const SyncSuccess(this.syncedAt);
  @override
  List<Object?> get props => [syncedAt];
}

class SyncOffline extends SyncState {}

class SyncError extends SyncState {
  final String message;
  const SyncError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class SyncCubit extends Cubit<SyncState> {
  SyncCubit() : super(SyncIdle());

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> syncAll(String userId) async {
    emit(SyncInProgress());
    try {
      await Future.wait([
        _syncProgress(userId),
        _syncPerformance(userId),
        _syncBadges(userId),
        _syncStreak(userId),
      ]);
      emit(SyncSuccess(DateTime.now()));
    } on PostgrestException catch (e) {
      emit(SyncError(e.message));
    } catch (e) {
      // Likely offline
      emit(SyncOffline());
    }
  }

  // ── Progress ───────────────────────────────────────────────────────────────

  Future<void> _syncProgress(String userId) async {
    final box = await Hive.openBox<MoonProgress>('moon_progress');
    final userProgress = box.values
        .where((p) => p.userId == userId)
        .map((p) => p.toJson())
        .toList();

    if (userProgress.isEmpty) return;

    await _client
        .from('progress')
        .upsert(userProgress, onConflict: 'user_id, moon_key');
  }

  // ── Performance ────────────────────────────────────────────────────────────

  Future<void> _syncPerformance(String userId) async {
    final box = await Hive.openBox<QuestionPerformance>('performance');
    final userPerf = box.values
        .where((p) => p.userId == userId)
        .map((p) => p.toJson())
        .toList();

    if (userPerf.isEmpty) return;

    await _client
        .from('performance')
        .upsert(userPerf, onConflict: 'user_id, question_key');
  }

  // ── Badges ─────────────────────────────────────────────────────────────────

  Future<void> _syncBadges(String userId) async {
    final box = await Hive.openBox<BadgeModel>('badges');
    final userBadges = box.values
        .where((b) => b.userId == userId)
        .map((b) => b.toJson())
        .toList();

    if (userBadges.isEmpty) return;

    await _client
        .from('badges')
        .upsert(userBadges, onConflict: 'user_id, badge_type');
  }

  // ── Streak ─────────────────────────────────────────────────────────────────

  Future<void> _syncStreak(String userId) async {
    final box = await Hive.openBox<StreakModel>('streaks');
    final streak = box.get(userId);
    if (streak == null) return;

    await _client
        .from('streaks')
        .upsert(streak.toJson(), onConflict: 'user_id');
  }

  // ── Pull from Supabase (restore on new device) ─────────────────────────────

  Future<void> pullFromCloud(String userId) async {
    emit(SyncInProgress());
    try {
      final progressData = await _client
          .from('progress')
          .select()
          .eq('user_id', userId);

      final box = await Hive.openBox<MoonProgress>('moon_progress');
      for (final row in progressData as List) {
        final progress = MoonProgress.fromJson(row);
        await box.put('${userId}_${progress.moonKey}', progress);
      }

      emit(SyncSuccess(DateTime.now()));
    } catch (e) {
      emit(SyncOffline());
    }
  }
}
