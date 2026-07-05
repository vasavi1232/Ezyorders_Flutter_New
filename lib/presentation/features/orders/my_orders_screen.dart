import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes/app_routes.dart';
import '../../providers/orders_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../../config/theme/app_theme.dart';
import 'widgets/order_list_item_widget.dart';
import 'widgets/custom_confirm_dialog.dart';
import 'widgets/custom_success_dialog.dart';
import 'widgets/custom_pdf_dialog.dart';
import 'widgets/add_to_cart_success_dialog.dart';
import 'widgets/custom_error_dialog.dart';
import 'order_details_screen.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/custom_loader_widget.dart';
import 'package:intl/intl.dart';
import '../../../data/models/order_models.dart';
import '../../../core/utils/common_methods.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchInitialOrders());
  }

  void _fetchInitialOrders() {
    context.read<OrdersProvider>().fetchOrders(
          isRefresh: true,
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final ordersProvider = context.read<OrdersProvider>();
      if (ordersProvider.hasMore && !ordersProvider.isMoreLoading) {
        ordersProvider.fetchOrders();
      }
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller,
      {DateTime? firstDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _submitFilters() {
    final ordersProvider = context.read<OrdersProvider>();
    ordersProvider.updateFilters(
      _searchController.text,
      _fromDateController.text,
      _toDateController.text,
    );
    _fetchInitialOrders();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _fromDateController.clear();
      _toDateController.clear();
    });
    final ordersProvider = context.read<OrdersProvider>();
    ordersProvider.clearFilters();
    _fetchInitialOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CustomBottomNavBar(),
      appBar: AppBar(
        title: Text(
          "My Orders",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: AppTheme.backIconSize(context)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildFilterSection(),
              Expanded(child: _buildOrdersList()),
            ],
          ),
          Consumer<OrdersProvider>(
            builder: (context, provider, child) {
              // Show overlay if loading (Initial fetch or Actions)
              // But not for pagination (handled by list footer)
              // We need to distinguish pagination loading. OrdersProvider usually has isMoreLoading.
              // If isLoading is true, it's a blocking load (or initial).
              if (provider.isLoading) {
                return Container(
                  color: AppTheme.lightGrayBg.withValues(
                      alpha: 0.7), // Adjusted to be a valid color for Container
                  margin: EdgeInsets.only(
                      bottom: CommonMethods.safeSize(10.h)), // Valid property for Container
                  child: Center(
                    child: SizedBox(
                      width: CommonMethods.safeSize(100.w, defaultValue: 100),
                      height: CommonMethods.safeSize(100.w, defaultValue: 100),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomLoaderWidget(size: CommonMethods.safeSize(100.w, defaultValue: 100)),
                          Text(
                            "Please Wait",
                            textAlign: TextAlign.center,
                             style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: CommonMethods.safeSize(13.sp, defaultValue: 13),
                                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(CommonMethods.safeSize(12.w)),
      color: Colors.white,
      child: Column(
        children: [
          // Search Box
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search here",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(vertical: CommonMethods.safeSize(10.h)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(CommonMethods.safeSize(4.r, defaultValue: 4))),
            ),
          ),
          SizedBox(height: CommonMethods.safeSize(10.h)),
          // Date Pickers Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromDateController,
                  readOnly: true,
                  onTap: () => _selectDate(context, _fromDateController),
                  decoration: InputDecoration(
                    hintText: "From Date",
                    suffixIcon: const Icon(Icons.calendar_today,
                        color: AppTheme.primaryColor),
                    contentPadding:
                        EdgeInsets.symmetric(
                            horizontal: CommonMethods.safeSize(10.w), 
                            vertical: CommonMethods.safeSize(10.h)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CommonMethods.safeSize(4.r, defaultValue: 4))),
                  ),
                ),
              ),
              SizedBox(width: CommonMethods.safeSize(10.w)),
              Expanded(
                child: TextField(
                  controller: _toDateController,
                  readOnly: true,
                  onTap: () {
                    DateTime? startDate;
                    if (_fromDateController.text.isNotEmpty) {
                      startDate = DateFormat('dd/MM/yyyy')
                          .parse(_fromDateController.text);
                    }
                    _selectDate(context, _toDateController,
                        firstDate: startDate);
                  },
                  decoration: InputDecoration(
                    hintText: "To Date",
                    suffixIcon: const Icon(Icons.calendar_today,
                        color: AppTheme.primaryColor),
                    contentPadding:
                        EdgeInsets.symmetric(
                            horizontal: CommonMethods.safeSize(10.w), 
                            vertical: CommonMethods.safeSize(10.h)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CommonMethods.safeSize(4.r, defaultValue: 4))),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: CommonMethods.safeSize(10.h)),
          // Buttons Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryButtonColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(CommonMethods.safeSize(4.r, defaultValue: 4))),
                  ),
                  child: const Text("Submit",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _clearFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.redColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(CommonMethods.safeSize(4.r, defaultValue: 4))),
                  ),
                  child: const Text("Clear",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return Consumer<OrdersProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.orders.isEmpty) {
          return const SizedBox.shrink(); // Overlay handles it
        }

        if (provider.orders.isEmpty) {
          return Center(
              child: Text(
            "No orders data found",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ));
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: provider.orders.length + (provider.isMoreLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.orders.length) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomLoaderWidget(size: CommonMethods.safeSize(30.w, defaultValue: 30)),
              );
            }

            final order = provider.orders[index];
            return OrderListItemWidget(
              order: order,
              onViewDetails: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => OrderDetailsScreen(order: order)),
                );
              },
              onReorder: () => _handleReorder(order),
              onDuplicate: () => _handleDuplicate(order),
              onDelete: () => _handleCancel(order),
              onDownload: () => _handleDownload(order),
            );
          },
        );
      },
    );
  }

  void _handleReorder(OrderHistoryResult order) async {
    final dashboardProvider = context.read<DashboardProvider>();
    final contentText = dashboardProvider.profileResponse?.results?.firstOrNull?.reorderConfirmationText ??
        "You are Re-Ordering the same products.\nProducts price will update with the current price.";

    // Show confirmation dialog (Android parity)
    final bool? confirm = await _showConfirmDialog(
      title: "Re-Order Confirmation",
      orderId: order.refNo ?? "",
      content: contentText,
      confirmText: "Re-Order",
      confirmColor: AppTheme.tealColor,
      confirmButtonColor: AppTheme.primaryButtonColor,
    );

    if (confirm == true && mounted) {
      final ordersProvider = context.read<OrdersProvider>();
      final success = await ordersProvider.reorderOrder(
        oldOrderId: order.orderId.toString(),
      );
      if (success && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AddToCartSuccessDialog(
            onClosed: () async {
              if (mounted) {
                // Initialize checkout state BEFORE navigating to ensure totals are fresh
                final authProvider = context.read<AuthProvider>();
                final checkoutProvider = context.read<CheckoutProvider>();
                final dashboardProvider = context.read<DashboardProvider>();

                await checkoutProvider.initCheckout(
                    authProvider.user?.accessToken ?? "",
                    authProvider.user?.customerId ?? "",
                    stabilize: true);
                
                // Update global cart count
                dashboardProvider.setCartCount(CommonMethods.cartCount);

                if (mounted) {
                  // Direct navigation to Step 1 (Cart) via checkout route
                  while (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  context.push(AppRoutes.checkout, extra: {'initialStep': 0});
                }
              }
            },
          ),
        );
      } else if (mounted) {
        _showErrorDialog("Re-Order Failed", ordersProvider.actionError ?? "Unknown error occurred");
      }
    }
  }

  void _handleDuplicate(OrderHistoryResult order) async {
    final dashboardProvider = context.read<DashboardProvider>();
    final contentText = dashboardProvider.profileResponse?.results?.firstOrNull?.replicateOrderConfirmationText ??
        "Do you want to duplicate this order?";

    final bool? confirm = await _showConfirmDialog(
      title: "Duplicate Order Confirmation",
      orderId: order.refNo ?? "",
      content: contentText,
      confirmText: "Duplicate",
      confirmColor: AppTheme.primaryColor,
    );

    if (confirm == true && mounted) {
      final ordersProvider = context.read<OrdersProvider>();
      final newOrderId = await ordersProvider.duplicateOrder(
        oldOrderId: order.orderId.toString(),
      );
      if (newOrderId != null && mounted) {
        _showSuccessDialog("Order Duplicated Successfully", "#$newOrderId");
        _fetchInitialOrders();
      } else if (mounted) {
        _showErrorDialog("Duplicate Order Failed", ordersProvider.actionError ?? "Unknown error occurred");
      }
    }
  }

  void _handleCancel(OrderHistoryResult order) async {
    final bool? confirm = await _showConfirmDialog(
      title: "Cancel Order Confirmation",
      orderId: order.refNo ?? "",
      content: "Do you want to cancel this order?",
      confirmText: "Cancel Order",
      confirmColor: AppTheme.redColor,
    );

    if (confirm == true && mounted) {
      final ordersProvider = context.read<OrdersProvider>();
      final success = await ordersProvider.cancelOrder(
        orderId: order.orderId.toString(),
      );
      if (success && mounted) {
        _fetchInitialOrders();
      }
    }
  }

  void _handleDownload(OrderHistoryResult order) {
    if (order.pdfFile != null && order.pdfFile!.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => CustomPdfDialog(
          pdfUrl: order.pdfFile!,
          orderId: order.refNo ?? "Unknown",
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invoice not available yet.")));
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String orderId,
    required String content,
    required String confirmText,
    required Color confirmColor,
    Color? confirmButtonColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => CustomConfirmDialog(
        title: title,
        orderId: orderId,
        content: content,
        confirmText: confirmText,
        confirmColor: confirmColor,
        confirmButtonColor: confirmButtonColor,
      ),
    );
  }

  void _showSuccessDialog(String title, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => CustomSuccessDialog(
        title: title,
        orderId: orderId,
        content: "", // Currently unused based on design, can leave empty
      ),
    );
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => CustomErrorDialog(
        title: title,
        content: content,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }
}
