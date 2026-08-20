import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/app_config_model.dart';

class SplashController {
  // قائمة وروابط الـ Config حسب الأولوية (الجديد ثم القديم)
  final List<String> configUrls = [
    'http://eliteapplication.tech:8000/api?action=config', // الرابط الجديد (Laravel)
    'https://jadty.inchcode.com/api.php?action=config',    // الرابط القديم (Hostinger)
  ];

  final List<String> grandmaPhrases = [
    'عم بصُب القهوة ونستنّاها تبرد...',
    'عم بنظّف النظارة عشان أشوف زين!',
    'يا فتاح يا عليم... ثواني ويجهز الفال',
    'هلا بحفيدي.. نورت دار الجدة!❤️',
  ];

  /// جلب الإعدادات من السيرفر مع إمكانية التحويل التلقائي عند الفشل (Fallback)
  Future<AppConfigModel?> fetchAppConfig() async {
    for (final url in configUrls) {
      debugPrint('🚀 Trying Config URL: $url');

      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        debugPrint('📥 Status Code ($url): ${response.statusCode}');

        if (response.statusCode == 200) {
          final decodedData = jsonDecode(response.body);

          if (decodedData is Map) {
            // 🎯 تحويل الخريطة إلى النوع الصحيح المعتمد لتفادي مشكلة الـ Type Assignment Error
            final Map<String, dynamic> data =
                Map<String, dynamic>.from(decodedData);

            // حفظ مفتاح GEMINI_API_KEY إذا كان موجوداً بالرد
            if (data.containsKey('GEMINI_API_KEY') && data['GEMINI_API_KEY'] != null) {
              final String apiKey = data['GEMINI_API_KEY'].toString();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('GEMINI_API_KEY', apiKey);
            }

            // 🎯 طباعة السيرفر الناجح في الـ Console
            debugPrint('✅ Successfully fetched config using URL: $url');

            return AppConfigModel.fromJson(data);
          }
        }

        debugPrint('⚠️ Config request failed on $url. Trying fallback...');
      } catch (e) {
        debugPrint('❌ Error fetching config from $url: $e');
      }
    }

    // في حال فشل كل السيرفرات
    debugPrint('❌ All Config endpoints failed.');
    return null;
  }

  /// التحقق مما إذا كان إصدار التطبيق الحالي مدعوماً
  final int manualBuildNumber = 3; // رقم البناء الحالي لتطبيقك

  Future<bool> isVersionSupported(AppConfigModel config) async {
    try {
      int currentBuildNumber = manualBuildNumber;
      debugPrint('Current build: $currentBuildNumber');
      debugPrint('Supported versions: ${config.supportedVersions}');

      return config.supportedVersions.contains(currentBuildNumber);
    } catch (e) {
      return true; // السماح بالمرور كإجراء احتياطي عند حدوث خطأ
    }
  }
}