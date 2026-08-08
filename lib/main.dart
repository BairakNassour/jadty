import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 1. إضافة الاستيراد
import 'package:jadty/auth/splash_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(); // تهيئة الفايربيز
  await MobileAds.instance.initialize(); // 2. إضافة تهيئة إعلانات Google AdMob

  runApp(const GrandmaApp());
}

class GrandmaApp extends StatelessWidget {
  const GrandmaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق جدتي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFFDFBF7),
        // إضافة هذا السطر لتعميم الخط على كامل التطبيق
        fontFamily: 'MyCustomFont', 
      ),
      home: const SplashScreen(),
    );
  }
}