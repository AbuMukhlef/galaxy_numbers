import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/cubits.dart';

class AppProviders extends StatelessWidget {
  final Widget child;
  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>(create: (_) => AuthCubit()..init()),
      BlocProvider<AdaptiveCubit>(create: (_) => AdaptiveCubit()),
      BlocProvider<GalaxyCubit>(create: (_) => GalaxyCubit()),
      BlocProvider<MoonCubit>(create: (_) => MoonCubit()),
      BlocProvider<ChallengeCubit>(
        create: (ctx) => ChallengeCubit(adaptiveCubit: ctx.read<AdaptiveCubit>())),
      BlocProvider<StreakCubit>(create: (_) => StreakCubit()),
      BlocProvider<SyncCubit>(create: (_) => SyncCubit()),
    ],
    child: child);
}
