import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/models/order_models.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/utils/common_methods.dart';
import 'package:provider/provider.dart';
import '../../../providers/dashboard_provider.dart';

class OrderListItemWidget extends StatelessWidget {
  final OrderHistoryResult order;
  final VoidCallback onViewDetails;
  final VoidCallback onReorder;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  const OrderListItemWidget({
    super.key,
    required this.order,
    required this.onViewDetails,
    required this.onReorder,
    required this.onDuplicate,
    required this.onDelete,
    required this.onDownload,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      // Assuming API format is yyyy-MM-dd HH:mm:ss
      DateTime dateTime = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm a').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = order.orderStatus?.toLowerCase() == "cancelled";
    final dashboardProvider = context.read<DashboardProvider>();
    final allowCancel = dashboardProvider.profileResponse?.results?.firstOrNull?.allowCustomerToCancelOrder == "Yes";
    final allowReplicate = dashboardProvider.profileResponse?.results?.firstOrNull?.allowCustomersToReplicateOrders == "Yes";
    final allowReorder = dashboardProvider.profileResponse?.results?.firstOrNull?.allowCustomerToReorderSameProducts == "Yes";

    final showCancel = allowCancel && 
      (order.orderStatus?.toLowerCase() == "received" || order.orderStatus?.toLowerCase() == "processing");

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(
          horizontal: CommonMethods.safeSize(10.w), 
          vertical: CommonMethods.safeSize(6.h)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CommonMethods.safeSize(4.r, defaultValue: 4)),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(CommonMethods.safeSize(12.w)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID Section
            Row(
              children: [
                Text(
                  "Order ID : ",
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: CommonMethods.safeSize(13.sp, defaultValue: 13),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  order.refNo ?? "",
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: CommonMethods.safeSize(13.sp, defaultValue: 13),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: CommonMethods.safeSize(6.h)),

            // Order Amount Section
            Row(
              children: [
                Text(
                  "Order Amount : ",
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: CommonMethods.safeSize(13.sp, defaultValue: 13),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CommonMethods.setPriceFormatString(order.orderAmount),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: CommonMethods.safeSize(13.sp, defaultValue: 13),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: CommonMethods.safeSize(6.h)),

            // Qty and Status Row
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        "Qty : ",
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: CommonMethods.safeSize(13.sp, defaultValue: 13),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${order.quantity ?? 0}",
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: CommonMethods.safeSize(13.sp, defaultValue: 13),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      order.orderStatus ?? "",
                      style: TextStyle(
                        color: isCancelled
                            ? AppTheme.redColor
                            : Colors.green.shade600,
                        fontSize: CommonMethods.safeSize(12.sp, defaultValue: 12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: CommonMethods.safeSize(4.w)),
                    Icon(
                      isCancelled ? Icons.cancel : Icons.check_circle,
                      color: isCancelled
                          ? AppTheme.redColor
                          : Colors.green.shade600,
                      size: CommonMethods.safeSize(20.sp, defaultValue: 20),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: CommonMethods.safeSize(6.h)),

            // Email Row
            Row(
              children: [
                Icon(Icons.email_outlined,
                    color: AppTheme.primaryColor, 
                    size: CommonMethods.safeSize(16.sp, defaultValue: 16)),
                SizedBox(width: CommonMethods.safeSize(6.w)),
                Expanded(
                  child: Text(
                    order.email ?? "",
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: CommonMethods.safeSize(13.sp, defaultValue: 13),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: CommonMethods.safeSize(6.h)),

            // Date Row
            Row(
              children: [
                Icon(Icons.calendar_month_outlined,
                    color: AppTheme.primaryColor, 
                    size: CommonMethods.safeSize(16.sp, defaultValue: 16)),
                SizedBox(width: CommonMethods.safeSize(6.w)),
                Expanded(
                  child: Text(
                    _formatDate(order.orderDate),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: CommonMethods.safeSize(13.sp, defaultValue: 13),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: CommonMethods.safeSize(12.h)),

            // Actions Row
            Row(
              children: [
                // Action Buttons Group
                _buildActionButton(
                  icon: Icons.shopping_cart_outlined,
                  color: const Color(0xFFFDB833), // Bright Orange/Yellow
                  onTap: onReorder,
                  visible: allowReorder,
                ),
                _buildActionButton(
                  icon: Icons.description_outlined,
                  color: const Color(0xFF283593), // Dark Blue
                  onTap: onDuplicate,
                  visible: allowReplicate,
                ),
                _buildActionButton(
                  icon: Icons.delete_outline,
                  color: const Color(0xFFE91E63), // Pinkish Red
                  onTap: onDelete,
                  visible: showCancel,
                ),
                _buildActionButton(
                  icon: Icons.download_outlined,
                  color: const Color(0xFF00BCD4), // Cyan
                  onTap: onDownload,
                  visible: true,
                ),

                const Spacer(),

                // View Details Button
                ElevatedButton(
                  onPressed: onViewDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppTheme.primaryButtonColor, // Vivid Bright Blue
                    padding:
                        EdgeInsets.symmetric(
                            horizontal: CommonMethods.safeSize(16.w), 
                            vertical: 0),
                    minimumSize: Size(0, CommonMethods.safeSize(36.w, defaultValue: 36)), // Match height of icon buttons
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(CommonMethods.safeSize(4.r, defaultValue: 4))),
                    elevation: 0,
                  ),
                  child: Text(
                    "View Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: CommonMethods.safeSize(12.sp, defaultValue: 12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool visible,
  }) {
    if (!visible) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(right: CommonMethods.safeSize(8.w)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: CommonMethods.safeSize(36.w, defaultValue: 36),
          height: CommonMethods.safeSize(36.w, defaultValue: 36),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(CommonMethods.safeSize(4.r, defaultValue: 4)),
          ),
          child: Icon(icon, color: Colors.white, 
              size: CommonMethods.safeSize(20.sp, defaultValue: 20)),
        ),
      ),
    );
  }
}
