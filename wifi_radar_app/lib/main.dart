import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/wifi_scanner_service.dart';
import 'screens/radar_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
  ));
  runApp(const WiFiRadarApp());
}

class WiFiRadarApp extends StatelessWidget {
  const WiFiRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WiFiScannerService(),
      child: MaterialApp(
        title: 'Wi-Fi Радар',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00FF41),
            surface: Colors.black,
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(
              color: Color(0xFF00FF41),
              fontFamily: 'monospace',
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  int _loadStep = 0;

  final _loadSteps = [
    'Инициализация модулей...',
    'Проверка Wi-Fi интерфейса...',
    'Загрузка алгоритмов обнаружения...',
    'Калибровка чувствительности...',
    'СИСТЕМА ГОТОВА',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _runBootSequence();
  }

  Future<void> _runBootSequence() async {
    for (int i = 0; i < _loadSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _loadStep = i);
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const RadarScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00FF41),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.wifi_tethering,
                  color: Color(0xFF00FF41),
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Wi-Fi РАДАР',
                style: TextStyle(
                  color: Color(0xFF00FF41),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'СИСТЕМА ОБНАРУЖЕНИЯ ДВИЖЕНИЯ',
                style: TextStyle(
                  color: Color(0xFF006600),
                  fontSize: 10,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Boot log
              SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_loadSteps.length, (i) {
                    final visible = i <= _loadStep;
                    final isCurrent = i == _loadStep;
                    return Opacity(
                      opacity: visible ? 1.0 : 0.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              isCurrent ? '> ' : '  ',
                              style: const TextStyle(
                                color: Color(0xFF00FF41),
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              _loadSteps[i],
                              style: TextStyle(
                                color: isCurrent
                                    ? const Color(0xFF00FF41)
                                    : const Color(0xFF006600),
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 32),
              // Progress bar
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: (_loadStep + 1) / _loadSteps.length,
                  backgroundColor: const Color(0xFF003300),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF00FF41)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
