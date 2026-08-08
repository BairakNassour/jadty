import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/app_config_model.dart';

class SplashController {
  static const String configUrl = 'https://jadty.inchcode.com/api.php?action=config';

  final List<String> grandmaPhrases = [
    'عم بصُب القهوة ونستنّاها تبرد...',
    'عم بنظّف النظارة عشان أشوف زين!',
    'يا فتاح يا عليم... ثواني ويجهز الفال',
    'هلا بحفيدي.. نورت دار الجدة!❤️',
  ];

  /// جلب الإعدادات من السيرفر
  Future<AppConfigModel?> fetchAppConfig() async {
    try {
      final response = await http.get(Uri.parse(configUrl)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppConfigModel.fromJson(data);
      }
    } catch (e) {
      // في حال الفشل أو انقطاع الإنترنت يمكن إرجاع null واستكمال الدخول بشكل طبيعي
      print('Config fetch error: $e');
    }
    return null;
  }

  /// التحقق مما إذا كان إصدار التطبيق الحالي مدعوماً
// ضع هنا رقم البناء (Build Number) الحالي لتطبيقك يدوياً
  final int manualBuildNumber = 1; // قم بتغييره يدوياً (مثلاً 2، 3، إلخ) كلما قمت بتحديث التطبيق

  Future<bool> isVersionSupported(AppConfigModel config) async {
    try {
      // استخدام رقم البناء اليدوي مباشرة بدلاً من package_info_plus
      int currentBuildNumber = manualBuildNumber;

      // التأكد من أن رقم البناء الحاضر ضمن مصفوفة الإصدارات المدعومة
      return config.supportedVersions.contains(currentBuildNumber);
    } catch (e) {
      return true; // السماح بالمرور كإجراء احتياطي عند حدوث خطأ
    }
  }
}