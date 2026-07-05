import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/api_endpoints.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/products/products_list_screen.dart';
import '../features/account/my_account_screen.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/custom_loader_widget.dart';
import '../../core/services/app_update_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  @override

  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Replicate native DashboardActivity.onCreate behavior
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService().checkForUpdate(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Replicate native DashboardActivity.onResume behavior
      AppUpdateService().checkFlexibleUpdateDownloaded(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        storeController: UpgraderStoreController(
          onAndroid: () => UpgraderAppcastStore(
            appcastURL: ApiEndpoints.appcastUrl,
          ),
          oniOS: () => UpgraderAppcastStore(
            appcastURL: ApiEndpoints.appcastUrl,
          ),
        ),
      ),
      child: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, child) {
          return Stack(
          children: [
            Scaffold(
              body: IndexedStack(
                index: dashboardProvider.currentIndex,
                children: const [
                  DashboardScreen(),
                  ProductsListScreen(isStandalone: false),
                  SizedBox(),
                  MyAccountScreen(),
                ],
              ),
              bottomNavigationBar: const CustomBottomNavBar(),
            ),
            if (dashboardProvider.isLoading)
              Material(
                color: Colors.black54,
                child: Center(
                  child: SizedBox(
                    width: 100.w,
                    height: 100.w,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomLoaderWidget(size: 95.w),
                        Text(
                          "Loading..",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
    );
  }
}
