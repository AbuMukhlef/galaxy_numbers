import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/cubits.dart';
import '../models/models.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/galaxy/galaxy_screen.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: switch (state) {
            AuthLoading()      => const _SplashScreen(),
            AuthNoUsers()      => const OnboardingScreen(),
            AuthUserSelected() => _GalaxyRoot(user: (state as AuthUserSelected).user),
            AuthError()        => const OnboardingScreen(),
            _                  => const _SplashScreen(),
          },
        );
      },
    );
  }
}

class _GalaxyRoot extends StatefulWidget {
  final UserModel user;
  const _GalaxyRoot({required this.user});
  @override
  State<_GalaxyRoot> createState() => _GalaxyRootState();
}

class _GalaxyRootState extends State<_GalaxyRoot> {
  @override
  void initState() {
    super.initState();
    context.read<AdaptiveCubit>().loadPerformance(widget.user.id);
    context.read<StreakCubit>().recordPlay(widget.user.id);
    context.read<SyncCubit>().syncAll(widget.user.id);
  }

  @override
  Widget build(BuildContext context) => GalaxyScreen(
    userId: widget.user.id,
    userName: widget.user.name,
    userPath: widget.user.selectedPath);
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF020818),
    body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF), strokeWidth: 2)));
}
