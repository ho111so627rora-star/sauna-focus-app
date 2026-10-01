import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/session_provider.dart';
import 'providers/audio_settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/sauna_screen.dart';
import 'screens/cold_bath_screen.dart';
import 'screens/air_bath_screen.dart';
import 'screens/completion_screen.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 音声サービスを初期化
  await AudioService().initialize();
  
  runApp(const SaunaFocusApp());
}

class SaunaFocusApp extends StatelessWidget {
  const SaunaFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SessionProvider()),
        ChangeNotifierProvider(create: (context) => AudioSettingsProvider()),
      ],
      child: MaterialApp(
        title: 'サウナフォーカス',
      theme: ThemeData(
          primarySwatch: Colors.orange,
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        home: const AppNavigator(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  @override
  void initState() {
    super.initState();
    // セッション履歴を読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadSessionHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        // 現在のフェーズに基づいて画面を表示
        switch (sessionProvider.currentPhase) {
          case SessionPhase.home:
            return const HomeScreen();
          case SessionPhase.sauna:
            return const SaunaScreen();
          case SessionPhase.lowryu:
            return const SaunaScreen(); // ロウリュはサウナ画面で処理
          case SessionPhase.coldBath:
            return const ColdBathScreen();
          case SessionPhase.airBath:
            return const AirBathScreen();
          case SessionPhase.completed:
            return const CompletionScreen();
        }
      },
    );
  }
}
