import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laundry28/core/theme/app_theme.dart';
import 'package:laundry28/core/constants/app_routes.dart';
import 'package:laundry28/features/admin/cubit/auth_cubit.dart';
import 'package:laundry28/features/admin/cubit/dashboard_cubit.dart';
import 'package:laundry28/features/admin/cubit/new_order_cubit.dart';
import 'package:laundry28/features/tracking/cubit/tracking_cubit.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit()),
          BlocProvider(create: (_) => DashboardCubit()),
          BlocProvider(create: (_) => NewOrderCubit()),
          BlocProvider(create: (_) => TrackingCubit()),
        ],
        child: MaterialApp.router(
          title: 'Laundry28',
          theme: AppTheme.lightTheme,
          routerConfig: AppRoutes.router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}