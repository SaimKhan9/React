import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/editor_provider.dart';
import 'providers/room_provider.dart';
import 'providers/webrtc_provider.dart';
import 'ui/lobby/lobby_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive dark status & navigation bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.darkBg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final isDarkStored = prefs.getString(kStorageThemeKey);
  final initialDark = isDarkStored == null || isDarkStored == 'dark';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => WebRTCProvider()),
        ChangeNotifierProvider(create: (_) => EditorProvider()),
      ],
      child: DevArenaApp(initialDark: initialDark),
    ),
  );
}

class DevArenaApp extends StatefulWidget {
  final bool initialDark;

  const DevArenaApp({super.key, required this.initialDark});

  @override
  State<DevArenaApp> createState() => _DevArenaAppState();
}

class _DevArenaAppState extends State<DevArenaApp> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.initialDark;
  }

  void _toggleTheme() async {
    setState(() => _isDark = !_isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kStorageThemeKey, _isDark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevArena Live',
      debugShowCheckedModeBanner: false,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: LobbyScreen(
        onToggleTheme: _toggleTheme,
        isDark: _isDark,
      ),
    );
  }
}
