import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'config/routes/app_router.dart';
import 'core/constants/app_theme.dart';
import 'core/di/service_locator.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/splash_provider.dart';
import 'presentation/providers/companies_provider.dart';
import 'presentation/providers/signup_provider.dart';
import 'presentation/providers/forgot_password_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/product_list_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/providers/checkout_provider.dart';
import 'presentation/providers/orders_provider.dart';
import 'presentation/providers/address_provider.dart';
import 'presentation/providers/scan_provider.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'presentation/widgets/global_session_listener.dart';

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  HttpOverrides.global = MyHttpOverrides(); // Bypass SSL verification

  setupLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;

        return SafeArea(
          child: ScreenUtilInit(
            designSize: isTablet ? const Size(768, 1024) : const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (_, child) {
              return MultiProvider(
                providers: [
                  ChangeNotifierProvider(
                      create: (_) => AuthProvider(getIt<AuthRepository>())),
                  ChangeNotifierProvider(create: (_) => SplashProvider()),
                  ChangeNotifierProvider(create: (_) => CompaniesProvider()),
                  ChangeNotifierProvider(create: (_) => SignUpProvider()),
                  ChangeNotifierProvider(
                      create: (_) => ForgotPasswordProvider()),
                  ChangeNotifierProvider(
                      create: (_) =>
                          DashboardProvider(getIt<AuthRemoteDataSource>())),
                  ChangeNotifierProvider(
                      create: (_) =>
                          ProductListProvider(getIt<AuthRemoteDataSource>())),
                  ChangeNotifierProvider(
                      create: (_) =>
                          CartProvider(getIt<AuthRemoteDataSource>())),
                  ChangeNotifierProvider(
                      create: (_) =>
                          CheckoutProvider(getIt<AuthRemoteDataSource>())),
                  ChangeNotifierProvider(
                      create: (_) =>
                          OrdersProvider(getIt<AuthRemoteDataSource>())),
                  ChangeNotifierProvider(
                      create: (_) =>
                          AddressProvider(getIt<AuthRemoteDataSource>())),
                  ChangeNotifierProvider(
                      create: (_) =>
                          ScanProvider(getIt<AuthRemoteDataSource>())),
                ],
                // ValueListenableBuilder rebuilds MaterialApp whenever
                // AppThemeService notifies through themeNotifier (on company
                // selection or app restart).
                child: ValueListenableBuilder<int>(
                  valueListenable: AppTheme.themeNotifier,
                  builder: (_, __, ___) => GlobalSessionListener(
                    child: MaterialApp.router(
                      title: 'EzyOrders',
                      theme: AppTheme.lightTheme,
                      routerConfig: AppRouter.router,
                      debugShowCheckedModeBanner: false,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

