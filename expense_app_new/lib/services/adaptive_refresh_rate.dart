import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// Adaptive refresh rate service for different device capabilities
class AdaptiveRefreshRate {
  static const List<int> supportedRefreshRates = [60, 90, 120, 144];

  /// Get optimal animation duration based on device refresh rate
  static Duration getAnimationDuration(int refreshRate, {Duration baseDuration = const Duration(milliseconds: 300)}) {
    // Calculate animation duration based on refresh rate
    // Higher refresh rate = smoother animations at shorter duration
    final durationMs = baseDuration.inMilliseconds;
    
    if (refreshRate >= 144) {
      // 144 Hz: Very smooth, can use shorter durations
      return Duration(milliseconds: (durationMs * 0.8).toInt());
    } else if (refreshRate >= 120) {
      // 120 Hz: Smooth, slightly shorter
      return Duration(milliseconds: (durationMs * 0.9).toInt());
    } else if (refreshRate >= 90) {
      // 90 Hz: Standard smooth
      return Duration(milliseconds: durationMs);
    } else {
      // 60 Hz: Standard, might need slightly longer for smoothness
      return Duration(milliseconds: (durationMs * 1.1).toInt());
    }
  }

  /// Get optimal frame rate for the device
  static int getOptimalRefreshRate() {
    if (Platform.isAndroid) {
      // Android devices typically support 60, 90, 120, or 144 Hz
      // Default to 60 for compatibility
      return 60;
    } else if (Platform.isIOS) {
      // iOS devices typically support 60 or 120 Hz
      return 60;
    }
    return 60;
  }

  /// Enable adaptive refresh rate
  static void enableAdaptiveRefreshRate() {
    // This is handled by Flutter engine automatically
    // Just ensure WidgetsFlutterBinding is initialized
    WidgetsFlutterBinding.ensureInitialized();
  }

  /// Get animation curve optimized for refresh rate
  static Curve getOptimalCurve(int refreshRate) {
    if (refreshRate >= 120) {
      // High refresh rate: can use more complex curves
      return Curves.elasticOut;
    } else if (refreshRate >= 90) {
      // Medium refresh rate: standard curves
      return Curves.easeOutCubic;
    } else {
      // Low refresh rate: simpler curves for smoothness
      return Curves.easeOut;
    }
  }
}

/// Mixin for widgets that need adaptive animations
mixin AdaptiveAnimationMixin {
  Duration getAnimationDuration({Duration baseDuration = const Duration(milliseconds: 300)}) {
    return AdaptiveRefreshRate.getAnimationDuration(
      AdaptiveRefreshRate.getOptimalRefreshRate(),
      baseDuration: baseDuration,
    );
  }

  Curve getAnimationCurve() {
    return AdaptiveRefreshRate.getOptimalCurve(
      AdaptiveRefreshRate.getOptimalRefreshRate(),
    );
  }
}
