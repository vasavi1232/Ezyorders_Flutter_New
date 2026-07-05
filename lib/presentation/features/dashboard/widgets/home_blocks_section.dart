import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../providers/dashboard_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/network/image_cache_manager.dart';

class HomeBlocksSection extends StatelessWidget {
  const HomeBlocksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final response = provider.homeBlocksResponse;
        if (response == null ||
            response.results == null ||
            response.results!.isEmpty) {
          return const SizedBox.shrink();
        }

        final blocks = response.results!;

        // Android uses horizontal layout.
        // It's likely a single row if items fit, or scrollable.
        // Adapter logic shows standard RecyclerView.
        // Given dimens (170dp width for text + 45dp image), items are ~220dp wide.

        return Container(
          height: 70, // Estimate based on content
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            itemCount: blocks.length,
            itemBuilder: (context, index) {
              final item = blocks[index];
              if (item == null) return const SizedBox.shrink();

              final isLast = index == blocks.length - 1;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image
                  SizedBox(
                    width: 45,
                    height: 45,
                    child: _buildImage(item.image),
                  ),
                  const SizedBox(width: 5),

                  // Text Column
                  SizedBox(
                    width: 170, // @dimen/dimen_170
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CommonMethods.decodeHtmlEntities(item.name),
                          style: TextStyle(
                            color: AppTheme.textColor, // @color/blue
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        Text(
                          CommonMethods.decodeHtmlEntities(item.description),
                          style: TextStyle(
                            color: AppTheme.textColor.withValues(alpha: 0.7), // @color/darkgray_color
                            fontSize: 12.sp, // @dimen/top_10 approx 10dp -> 12sp
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  if (!isLast)
                    Container(
                      width: 1,
                      height: 55,
                      color: Colors.grey,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(color: Colors.grey[200]);
    }
    String finalUrl = path;
    if (!path.startsWith("http")) {
      finalUrl = "${UrlApiKey.mainUrl}$path";
    }

    return CachedNetworkImage(
      imageUrl: finalUrl,
      fit: BoxFit.contain,
      cacheManager: ImageCacheManager(),
      placeholder: (context, url) => Container(color: Colors.grey[200]),
      errorWidget: (context, url, error) =>
          const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
