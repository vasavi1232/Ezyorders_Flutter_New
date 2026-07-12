import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/companies_provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/assets.dart';
import '../../../core/constants/url_api_key.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/custom_loader_widget.dart';
import '../../widgets/error_view.dart';

class CompaniesListScreen extends StatefulWidget {
  const CompaniesListScreen({super.key});

  @override
  State<CompaniesListScreen> createState() => _CompaniesListScreenState();
}

class _CompaniesListScreenState extends State<CompaniesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompaniesProvider>().fetchCompanies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor, // @color/blue
      body: SafeArea(
        child: Column(
          children: [
            // Header Section (Logo Card)
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppTheme.primaryColor,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: Colors.white, // Inner LinearLayout background
                        child: Column(
                          children: [
                            // Top Card with Logo
                            Card(
                              margin: EdgeInsets.zero,
                              elevation: 1,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              child: Container(
                                width: double.infinity,
                                height: 50.h, // Increased size
                                padding: EdgeInsets.symmetric(vertical: 0),
                                alignment: Alignment.center,
                                child: Image.asset(
                                  AppAssets.appLogo,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            // GridView
                            Expanded(
                              child: Stack(
                                children: [
                                  Consumer<CompaniesProvider>(
                                    builder: (context, provider, child) {
                                      if (provider.errorMsg != null) {
                                        return ErrorView(
                                          errorMessage: provider.errorMsg,
                                          onRetry: () => provider.fetchCompanies(),
                                        );
                                      }

                                      final mediaQuery = MediaQuery.of(context);
                                      final isLandscape = mediaQuery.orientation == Orientation.landscape;
                                      final isTablet = mediaQuery.size.shortestSide >= 600;
                                      
                                      // Only use landscape-specific layout if the device is a tablet
                                      final bool isLandscapeTablet = isLandscape && isTablet;
                                      
                                      // 3 columns only for tablets in landscape, otherwise 2
                                      int crossAxisCount = isLandscapeTablet ? 3 : 2;
                                      
                                      // Default aspect ratio for phone is 0.58. For tablet 0.85.
                                      double aspectRatio = isTablet ? 0.85 : 0.58;
                                      
                                      if (isLandscapeTablet) {
                                        aspectRatio = 0.9; // Adjusting aspect ratio for landscape tablet
                                      }

                                      // Calculate a global fallback color from any company that has a primaryButtonColor
                                      Color? apiFallbackColor;
                                      for (var c in provider.companies) {
                                        if (c.primaryButtonColor != null && c.primaryButtonColor!.isNotEmpty) {
                                          apiFallbackColor = AppTheme.hexToColor(c.primaryButtonColor);
                                          break;
                                        }
                                      }
                                      final effectiveFallback = apiFallbackColor ?? AppTheme.blackColor;

                                      return GridView.builder(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 15),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          childAspectRatio: aspectRatio,
                                          mainAxisSpacing: 10.h,
                                          crossAxisSpacing: 8.w,
                                        ),
                                        itemCount: provider.companies.length,
                                        itemBuilder: (context, index) {
                                          final company =
                                              provider.companies[index];

                                          String imageUrl = company.image ?? "";
                                          if (imageUrl.isNotEmpty &&
                                              !imageUrl.startsWith('http')) {
                                            imageUrl =
                                                UrlApiKey.companyMainUrl +
                                                    imageUrl;
                                          }

                                          // Individual button color: primary_button_color -> theme_color -> group fallback
                                          final buttonColor = AppTheme.hexToColor(
                                            company.primaryButtonColor,
                                            fallback: AppTheme.hexToColor(
                                              company.themeColor,
                                              fallback: effectiveFallback,
                                            ),
                                          );

                                          return Card(
                                            elevation: 2,
                                            color: Colors.white,
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  // Company Image
                                                  Expanded(
                                                    flex: 3,
                                                    child: CachedNetworkImage(
                                                      imageUrl: imageUrl,
                                                      width: double.infinity,
                                                      fit: BoxFit.contain,
                                                      placeholder:
                                                          (context, url) =>
                                                              const SizedBox(),
                                                      errorWidget: (context, url,
                                                              error) =>
                                                          Icon(Icons.error, size: isTablet ? 40 : 24),
                                                    ),
                                                  ),

                                                  SizedBox(height: isTablet ? 12 : 6),

                                                  // Company Name & Description (Centered)
                                                  Expanded(
                                                    flex: 2,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          company.name ?? "",
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                               TextStyle(
                                                            color: AppTheme
                                                                .lightBlue,
                                                            fontSize: isTablet ? 18.sp : 15.sp,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          company.natureOfBusiness ??
                                                              "",
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                               TextStyle(
                                                            color: Colors.black,
                                                            fontSize: isTablet ? 14.sp : 12.sp,
                                                                  fontWeight:
                                                                  FontWeight.bold
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 8),
                                                    child: SizedBox(
                                                      width: double.infinity,
                                                      height: isLandscapeTablet 
                                                          ? 75.h
                                                          : (isTablet ? 44.h : 35.h),
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          provider
                                                              .selectCompany(
                                                                  context,
                                                                  company);
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor: buttonColor,
                                                          padding:
                                                              EdgeInsets.zero,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        isLandscapeTablet ? 32.r : (isTablet ? 24.r : 20.r)),
                                                          ),
                                                        ),
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text(
                                                            "Select Company",
                                                            maxLines: 1,
                                                            softWrap: false,
                                                            overflow:
                                                                TextOverflow
                                                                    .visible,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: isLandscapeTablet 
                                                                  ? 16.sp
                                                                  : (isTablet ? 16.sp : 14.sp),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  Consumer<CompaniesProvider>(
                                    builder: (context, provider, child) {
                                      if (provider.isLoading) {
                                        return Container(
                                          color: Colors.black54,
                                          child: Center(
                                            child: SizedBox(
                                              width: 100.w,
                                              height: 100.w,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  CustomLoaderWidget(
                                                      size: 100.w),
                                                  Text(
                                                    "Please Wait",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color:
                                                          AppTheme.primaryColor,
                                                      fontSize: 13.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
