import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final ThemeMode mode;
  final String darkStyle; // 'black' or 'purple'

  const ThemeState({this.mode = ThemeMode.system, this.darkStyle = 'black'});

  ThemeState copyWith({ThemeMode? mode, String? darkStyle}) {
    return ThemeState(
      mode: mode ?? this.mode,
      darkStyle: darkStyle ?? this.darkStyle,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('themeMode') ?? 'system';
    final darkStyle = prefs.getString('darkStyle') ?? 'black';
    
    ThemeMode mode;
    switch (modeStr) {
      case 'light': mode = ThemeMode.light; break;
      case 'dark': mode = ThemeMode.dark; break;
      default: mode = ThemeMode.system;
    }
    
    state = ThemeState(mode: mode, darkStyle: darkStyle);
  }

  Future<void> setMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeStr;
    switch (mode) {
      case ThemeMode.light: modeStr = 'light'; break;
      case ThemeMode.dark: modeStr = 'dark'; break;
      default: modeStr = 'system';
    }
    await prefs.setString('themeMode', modeStr);
    state = state.copyWith(mode: mode);
  }

  Future<void> setDarkStyle(String style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('darkStyle', style);
    state = state.copyWith(darkStyle: style);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
