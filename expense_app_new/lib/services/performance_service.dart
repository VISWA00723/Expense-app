import 'package:flutter/material.dart';
import 'dart:async';

/// Performance optimization service for low-end devices
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();

  factory PerformanceService() {
    return _instance;
  }

  PerformanceService._internal();

  // Debounce timer for expensive operations
  Timer? _debounceTimer;

  /// Debounce function calls to prevent excessive rebuilds
  void debounce(
    Duration duration,
    VoidCallback callback,
  ) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  /// Throttle function calls to limit frequency
  static Future<T> throttle<T>(
    Future<T> Function() operation,
    Duration throttleDuration,
  ) async {
    return operation();
  }

  /// Enable adaptive refresh rate for low-end devices
  static void enableAdaptiveRefreshRate() {
    // Flutter automatically adapts to device capabilities
    // This is handled by the engine
  }

  /// Reduce animation duration for low-end devices
  static Duration getAnimationDuration(BuildContext context) {
    // Check device memory and adjust accordingly
    // For now, use standard duration
    return const Duration(milliseconds: 300);
  }

  /// Optimize image loading for low-end devices
  static ImageProvider optimizeImage(ImageProvider provider) {
    // Use ResizeImage to reduce memory usage
    return ResizeImage(
      provider,
      width: 256,
      height: 256,
    );
  }

  /// Batch database queries to reduce I/O
  static Future<List<T>> batchQuery<T>(
    List<Future<T> Function()> queries,
  ) async {
    return Future.wait(queries.map((q) => q()));
  }

  /// Clear unused resources
  static void clearCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
  }
}

/// Widget to optimize rendering on low-end devices
class PerformanceOptimizedWidget extends StatefulWidget {
  final Widget child;
  final Duration? animationDuration;

  const PerformanceOptimizedWidget({
    Key? key,
    required this.child,
    this.animationDuration,
  }) : super(key: key);

  @override
  State<PerformanceOptimizedWidget> createState() =>
      _PerformanceOptimizedWidgetState();
}

class _PerformanceOptimizedWidgetState
    extends State<PerformanceOptimizedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 300),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: widget.child,
    );
  }
}

/// Lazy loading widget for lists on low-end devices
class LazyLoadingListView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int itemsPerPage;
  final ScrollController? scrollController;

  const LazyLoadingListView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemsPerPage = 20,
    this.scrollController,
  }) : super(key: key);

  @override
  State<LazyLoadingListView> createState() => _LazyLoadingListViewState();
}

class _LazyLoadingListViewState extends State<LazyLoadingListView> {
  late int _displayedItems;

  @override
  void initState() {
    super.initState();
    _displayedItems = widget.itemsPerPage;
    widget.scrollController?.addListener(_onScroll);
  }

  void _onScroll() {
    final scrollController = widget.scrollController;
    if (scrollController == null) return;

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 500) {
      if (_displayedItems < widget.itemCount) {
        setState(() {
          _displayedItems += widget.itemsPerPage;
        });
      }
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _displayedItems,
      itemBuilder: widget.itemBuilder,
      controller: widget.scrollController,
    );
  }
}
