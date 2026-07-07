import 'dart:async';

import 'package:ezy_orders_flutter/presentation/features/dashboard/widgets/section_header_widget.dart';
import 'package:ezy_orders_flutter/presentation/features/dashboard/widgets/supplier_item_widget.dart';
import 'package:ezy_orders_flutter/presentation/providers/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class SuppliersSection extends StatefulWidget {
  const SuppliersSection({super.key});

  @override
  State<SuppliersSection> createState() => _SuppliersSectionState();
}

class _SuppliersSectionState extends State<SuppliersSection> {
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;

  /// Current page index (0-based).
  int _pageIndex = 0;
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  /// Whether the user is actively interacting (touch or hover)
  bool _isInteracting = false;

  double _itemWidth = 0;
  double _gapBetween = 0;

  int get _itemsPerPage {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape ? 3 : 2;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _updateScrollBounds();
      _startAutoScroll();
    });
  }

  void _updateScrollBounds() {
    if (!_scrollController.hasClients) return;
    final px = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;
    setState(() {
      _canScrollLeft = px > 1.0;
      _canScrollRight = px < (maxScroll - 1.0);
    });
  }

  // ── Scroll listener ────────────────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients || _itemWidth == 0) return;

    final itemsPerPage = _itemsPerPage;
    final double pageStep = itemsPerPage * (_itemWidth + _gapBetween);
    final double px = _scrollController.position.pixels;
    final double maxScroll = _scrollController.position.maxScrollExtent;

    // Use a small threshold for boundary detection
    int newPage;
    if (px >= maxScroll - 5.0) {
      // We are at the very end
      final provider = context.read<DashboardProvider>();
      final count = provider.supplierLogosResponse?.results?.length ?? 0;
      newPage = (count / itemsPerPage).ceil() - 1;
    } else {
      newPage = (px / pageStep).round();
    }

    if (px >= maxScroll - 50.0) {
      final provider = context.read<DashboardProvider>();
      if (!provider.isSupplierLogosLoadingMore) {
        provider.loadMoreSupplierLogos();
      }
    }

    if (newPage != _pageIndex ||
        _canScrollLeft != (px > 1.0) ||
        _canScrollRight != (px < maxScroll - 1.0)) {
      if (mounted) {
        setState(() {
          _pageIndex = newPage;
          _canScrollLeft = px > 1.0;
          _canScrollRight = px < (maxScroll - 1.0);
        });
      }
    }
  }

  void _snapIfIdle() {
    if (!_scrollController.hasClients || _itemWidth == 0 || _isInteracting) {
      return;
    }
    _scrollToPage(_pageIndex);
  }

  // ── Auto-scroll ────────────────────────────────────────────────────────────

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted ||
          !_scrollController.hasClients ||
          _itemWidth == 0 ||
          _isInteracting) {
        return;
      }

      final provider = context.read<DashboardProvider>();
      final suppliers = provider.supplierLogosResponse?.results ?? [];
      if (suppliers.isEmpty) return;

      final itemsPerPage = _itemsPerPage;
      final int totalPages = (suppliers.length / itemsPerPage).ceil();

      // If we are at the last page, stay there for one cycle before looping
      if (_pageIndex >= totalPages - 1) {
        _scrollToPage(0);
      } else {
        _scrollToPage(_pageIndex + 1);
      }
    });
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _goToPageNav(bool forward, int totalItems) {
    final itemsPerPage = _itemsPerPage;
    final int totalPages = (totalItems / itemsPerPage).ceil();
    int nextPage = forward ? _pageIndex + 1 : _pageIndex - 1;
    if (nextPage >= totalPages) nextPage = 0;
    if (nextPage < 0) nextPage = totalPages - 1;
    _scrollToPage(nextPage);
  }

  void _scrollToPage(int pageIndex) {
    if (!_scrollController.hasClients || _itemWidth == 0) return;

    final itemsPerPage = _itemsPerPage;
    final double pageStep = itemsPerPage * (_itemWidth + _gapBetween);
    final double targetOffset = (pageIndex * pageStep)
        .clamp(0.0, _scrollController.position.maxScrollExtent);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final response = provider.supplierLogosResponse;

        if (response == null ||
            response.results == null ||
            response.results!.isEmpty) {
          return const SizedBox.shrink();
        }

        final suppliers = response.results!;

        return LayoutBuilder(
          builder: (context, constraints) {
            final double totalWidth = constraints.maxWidth;
            final double leftPad = 8.w;
            final double gapBetween = 6.w;

            final orientation = MediaQuery.of(context).orientation;
            // Display 3 items in landscape, 2 in portrait
            final int itemsPerPage = orientation == Orientation.landscape ? 3 : 2;
            
            final double itemWidth =
                (totalWidth - leftPad - (gapBetween * (itemsPerPage - 1)) - leftPad) / itemsPerPage;

            _itemWidth = itemWidth;
            _gapBetween = gapBetween;

            return Column(
              children: [
                SectionHeaderWidget(
                  title: "Suppliers",
                  onPrevTap: (suppliers.length > itemsPerPage && _canScrollLeft)
                      ? () => _goToPageNav(false, suppliers.length)
                      : null,
                  onNextTap: (suppliers.length > itemsPerPage && _canScrollRight)
                      ? () => _goToPageNav(true, suppliers.length)
                      : null,
                  itemCount: suppliers.length,
                  minItemsForNav: itemsPerPage + 1,
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _isInteracting = true),
                  onExit: (_) => setState(() => _isInteracting = false),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollStartNotification) {
                        _isInteracting = true;
                      } else if (notification is ScrollEndNotification) {
                        _isInteracting = false;
                        WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _snapIfIdle());
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(width: leftPad),
                            ...List.generate(suppliers.length, (index) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SupplierItemWidget(
                                    image: suppliers[index]?.image,
                                    brandName: suppliers[index]?.brandName,
                                    brandId:
                                        suppliers[index]?.brandId?.toString() ??
                                            suppliers[index]
                                                ?.companyId
                                                ?.toString(),
                                    width: itemWidth,
                                  ),
                                  if (index < suppliers.length - 1 || provider.isSupplierLogosLoadingMore)
                                    SizedBox(width: gapBetween),
                                ],
                              );
                            }),
                            if (provider.isSupplierLogosLoadingMore)
                              Container(
                                width: 50.w,
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                                ),
                              ),
                            SizedBox(width: leftPad),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
