import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jadty/view/home_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../component/AppColors.dart';
import '../controller/splash_controller.dart';
import '../model/app_config_model.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final SplashController _controller = SplashController();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  int _currentPhraseIndex = 0;
  Timer? _phraseTimer;

  @override
  void initState() {
    super.initState();

    // 1. إعداد أنيميشن حركة اللوغو
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // 2. مؤقت عبارات الجدة
    _phraseTimer = Timer.periodic(const Duration(milliseconds: 1600), (timer) {
      if (mounted) {
        setState(() {
          _currentPhraseIndex =
              (_currentPhraseIndex + 1) % _controller.grandmaPhrases.length;
        });
      }
    });

    // 3. بدء عملية الفحص والانتقال
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    // جلب التكوين من السيرفر
    AppConfigModel? config = await _controller.fetchAppConfig();

    // حساب الوقت المنقضي لضمان عرض السباش لمدة 3 ثوانٍ على الأقل
    final elapsedTime = DateTime.now().difference(startTime);
    final minDisplayDuration = const Duration(milliseconds: 6800);
    if (elapsedTime < minDisplayDuration) {
      await Future.delayed(minDisplayDuration - elapsedTime);
    }

    if (!mounted) return;

    // التحقق من صحة الإصدار بحال توفر الإعدادات
    if (config != null) {
      bool isSupported = await _controller.isVersionSupported(config);

      if (!isSupported || config.forceUpdate) {
        _showUpdateDialog(config);
        return;
      }
    }

    // الانتقال للشاشة الرئيسية
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showUpdateDialog(AppConfigModel config) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'تحديث جديد متوفر',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryCoffee,
              ),
            ),
            content: const Text(
              'يا حبيبي الجدة حدّثت الدار! لا بد من تحديث التطبيق للاستمرار في الاستخدام.',
              style: TextStyle( color: primaryCoffee),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final url = Platform.isIOS
                      ? config.appStoreUrl
                      : config.playStoreUrl;
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text(
                  'تحديث الآن',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accentOrange,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phraseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: double.infinity,
          color: bgColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // الشعار والأنيميشن
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        child: Image.asset(
                          'assets/logo.png',
                          width: 200,
                          height: 200,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.coffee,
                              size: 100,
                              color: primaryCoffee,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // العبارات المتغيرة
              SizedBox(
                height: 50,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _controller.grandmaPhrases[_currentPhraseIndex],
                    key: ValueKey<int>(_currentPhraseIndex),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: primaryCoffee,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // مؤشر التحميل
              const Padding(
                padding: EdgeInsets.only(bottom: 50.0),
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    color: accentOrange,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}