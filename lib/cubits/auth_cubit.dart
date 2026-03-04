import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../models/models.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthNoUsers extends AuthState {}

class AuthUserSelected extends AuthState {
  final UserModel user;
  const AuthUserSelected(this.user);
  @override
  List<Object?> get props => [user.id];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class AuthCubit extends Cubit<AuthState> {
  static const _boxName = 'users';

  AuthCubit() : super(AuthInitial());

  Future<void> init() async {
    emit(AuthLoading());
    try {
      final box = await Hive.openBox<UserModel>(_boxName);
      if (box.isEmpty) {
        emit(AuthNoUsers());
      } else {
        // Auto-select last used user
        final user = box.values.last;
        emit(AuthUserSelected(user));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    final box = await Hive.openBox<UserModel>(_boxName);
    return box.values.toList();
  }

  Future<void> createUser({
    required String name,
    required String selectedPath,
  }) async {
    emit(AuthLoading());
    try {
      final box = await Hive.openBox<UserModel>(_boxName);
      final user = UserModel.create(name: name, selectedPath: selectedPath);
      await box.put(user.id, user);
      emit(AuthUserSelected(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> selectUser(String userId) async {
    emit(AuthLoading());
    try {
      final box = await Hive.openBox<UserModel>(_boxName);
      final user = box.get(userId);
      if (user == null) {
        emit(AuthError('User not found'));
      } else {
        emit(AuthUserSelected(user));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> deleteUser(String userId) async {
    final box = await Hive.openBox<UserModel>(_boxName);
    await box.delete(userId);
    final remaining = box.values.toList();
    if (remaining.isEmpty) {
      emit(AuthNoUsers());
    } else {
      emit(AuthUserSelected(remaining.last));
    }
  }

  void logout() => emit(AuthNoUsers());
}
