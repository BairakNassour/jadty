import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:jadty/model/reading_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResultController extends ChangeNotifier {
  final ReadingRequest request;
  final String region;
  final String zodiac;
  final String country;
  final String userName;

  String grandmaResponse = '';
  bool isLoading = true;
  bool hasError = false;
  bool isSpeaking = false;

  final FlutterTts _flutterTts = FlutterTts();

  ResultController({
    required this.request,
    required this.region,
    required this.zodiac,
    required this.country,
    required this.userName,
  }) {
    _initTts();
    analyzeWithGemini();
  }

  String _getCountryLanguageCode(String countryName) {
    debugPrint("ssss");
    debugPrint(countryName);
    debugPrint("ssss");
    if (countryName.contains('مصر')) return 'ar-EG';
    if (countryName.contains('السعودية') ||
        countryName.contains('الإمارات') ||
        countryName.contains('الكويت') ||
        countryName.contains('قطر') ||
        countryName.contains('عمان') ||
        countryName.contains('البحرين'))
      return 'ar-SA';
    if (countryName.contains('سوريا') ||
        countryName.contains('لبنان') ||
        countryName.contains('الأردن') ||
        countryName.contains('فلسطين'))
      return 'ar-JO';
    if (countryName.contains('المغرب')) return 'ar-MA';
    if (countryName.contains('العراق')) return 'ar-IQ';
    return 'ar-SA';
  }

  Future<void> _initTts() async {
    final langCode = _getCountryLanguageCode(country);

    try {
      await _flutterTts.setLanguage(langCode);
    } catch (_) {
      await _flutterTts.setLanguage("ar");
    }

    // 👵 1. خفض طبقة الصوت لتصبح أعمق وأقرب لكبار السن
    await _flutterTts.setPitch(0.70);

    // 👵 2. إبطاء سرعة الكلام لتبدو عفوية وبطيئة
    await _flutterTts.setSpeechRate(0.32);

    // 👵 3. اختيار الصوت العربي المناسب
    try {
      List<dynamic>? voices = await _flutterTts.getVoices;
      if (voices != null) {
        for (var voice in voices) {
          if (voice["locale"].toString().startsWith("ar") &&
              (voice["name"].toString().contains("language") ||
                  voice["name"].toString().contains("network"))) {
            await _flutterTts.setVoice({
              "name": voice["name"],
              "locale": voice["locale"],
            });
            break;
          }
        }
      }
    } catch (e) {
      debugPrint("لم يتم العثور على أصوات إضافية: $e");
    }

    _flutterTts.setStartHandler(() {
      isSpeaking = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      isSpeaking = false;
      notifyListeners();
    });

    _flutterTts.setCancelHandler(() {
      isSpeaking = false;
      notifyListeners();
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    if (isSpeaking) {
      await _flutterTts.stop();
      isSpeaking = false;
      notifyListeners();
    } else {
      await _flutterTts.speak(text);
    }
  }

  void retry() {
    isLoading = true;
    hasError = false;
    grandmaResponse = '';
    notifyListeners();
    analyzeWithGemini();
  }

  Future<void> analyzeWithGemini() async {
    String requestDetails = '';

    switch (request.type) {
      case ReadingType.cup:
        requestDetails = 'قراءة فنجان القهوة بناءً على الصورة المرفقة.';
        break;
      case ReadingType.palm:
        requestDetails =
            'قراءة كف اليد وتفسير خطوط الكف بناءً على الصورة المرفقة.';
        break;
      case ReadingType.askGrandma:
        requestDetails =
            'الإجابة على سؤال حفيدك التالي: "${request.userQuestionOrDream ?? ''}"';
        break;
      case ReadingType.dream:
        requestDetails =
            'تفسير حلم حفيدك التالي: "${request.userQuestionOrDream ?? ''}"';
        break;
    }

    final promptText =
        '''
أنتِ الآن "جدة" طيّبة وعجوز خفيفة الدم من دولة "$country" ومن منطقة "$region".
المستخدم هو حفيدك العزيز وبرجه هو "$zodiac".

⚠️ تعليمات اللهجة والكلام (صارم جداً):
1. اكتبِ النص بالكامل باللهجة العامية المحكية البحتة 100% كما تُنطق في الشارع والبيوت القديمة في منطقة "$region".
2. يُمنع منعاً باتاً استخدام أي كلمة باللغة العربية الفصحى أو الفصحى المعربة (مثل: سوف، كذلك، هذا، هذه، بل، إن، ولكن... إلخ).
3. استخدمِ الكلمات العامية اليومية المكتوبة بطريقة نطقها (مثال الشامية: شو، كرمال، هيك، عم شوف | المصرية: كده، عشان، إيه، ده، دي | وهكذا حسب منطقة $region).
4. استخدمِ لزمات ومصطلحات الجدات الشعبية والتراثية المشهورة في "$region".

المطلوب:
- الخدمة المطلوبة: $requestDetails
- اسم الحفيد: $userName
${(request.type == ReadingType.dream || request.type == ReadingType.askGrandma) ? '-توسعلو بالرد على السؤال او تفسير الحلم برد اهل منطقتو وليس من الضروري الربط بالبرج' : ''}
- ربط الكلام ببرجه "$zodiac" بطريقة طريفة وعفوية ومليئة بنصائح الجدات والبركة.
${(request.type == ReadingType.cup || request.type == ReadingType.palm) ? '- يجب التأكد أولاً إن كانت الصورة المرفقة هي بالفعل صورة (فنجان أو كف) بحسب الخدمة المطلوبة، وإن لم تكن كذلك أخبره بأسلوب طريف أنها ليست الصورة المطلوبة.' : ''}
- اختمي كلامك بنصيحة جدة دافئة ومحبة للحفيد.

⚠️ شروط التنسيق:
- تكون مشكلة بالفتحة والضمة والكسرة بحيث يقرأ التطبيق بسهولة عبر محرك الصوت.
- قسّمي الكلام إلى فقرات قصيرة مريحة للعين.
- لا تستخدمي علامات النجمة (*) أو الأرقام إطلاقاً.
- استخدمي الإيموجي المناسبة في بداية كل فكرة (مثل: ☕، 👁️، 🌿، 💡، ❤️، 🌙).
- اجعلي النص يبدو كحوار شفوي ومباشر بين جدة وحفيدها بدون أي رسميات.
''';

    // 🇸🇾 التحقق مما إذا كانت الدولة هي سوريا (بالعربية أو الإنجليزية)
    final bool isSyria =
        country.contains('سوريا') || country.toLowerCase().contains('syria');

    // 🔄 إذا كانت الدولة سوريا، يتم التوجه مباشرةً إلى البروكسي وتجاوز الاتصال المباشر
    if (isSyria) {
      debugPrint('🇸🇾 البلد سوريا: الاتصال المباشر عبر البروكسي فوراً...');
      await _callHostingerProxy(promptText);
      return;
    }

    // 🌟 1. المحاولة الأولى: الاتصال المباشر (بقية الدول)
    try {
      // جلب المفتاح المخزن من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('GEMINI_API_KEY');
       print(apiKey);
      // التحقق من وجود المفتاح
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('مفتاح Gemini API غير موجود في SharedPreferences!');
      }

      final modelsToTry = ['gemini-3.6-flash', 'gemini-3.5-flash'];
      final prompt = TextPart(promptText);
      List<Part> contentParts = [prompt];
      if (request.imagePath != null && request.imagePath!.isNotEmpty) {
        final imageBytes = await File(request.imagePath!).readAsBytes();
        final imagePart = DataPart('image/jpeg', imageBytes);
        contentParts.add(imagePart);
      }

      GenerateContentResponse? response;
      for (final modelName in modelsToTry) {
        try {
          final model = GenerativeModel(model: modelName, apiKey: apiKey);
          response = await model.generateContent([Content.multi(contentParts)]);

          if (response.text != null && response.text!.isNotEmpty) {
            debugPrint(
              '✅ تم التحليل بنجاح بالاتصال المباشر عبر النموذج: $modelName',
            );
            grandmaResponse = response.text!;
            isLoading = false;
            hasError = false;
            notifyListeners();
            speak(grandmaResponse);
            return;
          }
        } catch (e) {
          debugPrint('خطأ في الاتصال المباشر للنموذج $modelName: $e');
        }
      }

      throw Exception('فشل الاتصال المباشر بكل النماذج');
    } catch (directError) {
      debugPrint(
        '⚠️ فشل الاتصال المباشر، جاري التحويل التلقائي لسيرفر هوتسنغر (Fallback)...',
      );
      await _callHostingerProxy(promptText);
    }
  }

  // 🌐 تابع مساعد للاتصال بسيرفر هوتسنغر (البروكسي)
Future<void> _callHostingerProxy(String promptText) async {
    try {
      const String hostingerApiUrl =
          'https://jadty.inchcode.com/api.php?action=gemini_proxy';

      String? base64Image;
      if (request.imagePath != null && request.imagePath!.isNotEmpty) {
        final imageBytes = await File(request.imagePath!).readAsBytes();
        base64Image = base64Encode(imageBytes);
      }

      final response = await http.post(
        Uri.parse(hostingerApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': promptText,
          if (base64Image != null) 'image': base64Image,
        }),
      );

      // سجلات تقنية للمطور فقط في الـ Console
      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && !data.containsKey('error')) {
          final apiResponseText = data['text'] ?? data['response'];

          if (apiResponseText != null &&
              apiResponseText.toString().trim().isNotEmpty) {
            grandmaResponse = apiResponseText.toString();
            isLoading = false;
            hasError = false;
            notifyListeners();
            speak(grandmaResponse);
            return;
          }
        }
      }

      // إذا لم تنجح الاستجابة ننتقل للـ catch
      throw Exception('Server issue');
    } catch (e) {
      // طباعة تفاصيل الخطأ للبرمجيات فقط بداخل الـ Console
      debugPrint('❌ Internal Error: $e');

      // رد الجدة المحبب والنقي بدون أي تفاصيل تقنية
      grandmaResponse =
          'يا تقبرني يا ستي، شكل الخط عم يقطع والنظارات مشوشة شوية وما قدرت أفهم عليك منيح.. ارجع حاكيني مرة ثانية يا عيوني!';
      isLoading = false;
      hasError = true;
      notifyListeners();
    }
  }
  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
