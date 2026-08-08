import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jadty/component/AppColors.dart';
import 'package:jadty/model/reading_request.dart';
import 'package:jadty/controller/auth_and_scan_controller.dart';
import 'package:jadty/view/ItemsHomePage/AnimatedGrandmaAvatar.dart';
import 'package:jadty/view/ItemsHomePage/ItemLst.dart';
import 'package:jadty/view/ItemsHomePage/about_company_dialog.dart';
import 'package:jadty/view/ItemsHomePage/app_drawer_widget.dart';
import 'package:jadty/view/ItemsHomePage/service_card_widget.dart';
import 'package:jadty/view/result_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthAndScanController _controller = AuthAndScanController();

  String? selectedCountry;
  String? selectedRegion;
  String? selectedZodiac;

  int coffeeCups = 4;
  static const int maxCoffeeCups = 4;

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  // معرفات الإعلانات التجريبية الرسمية للإعلان البيني (Interstitial)
  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test Ad Unit Android
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test Ad Unit iOS
    }
    return 'ca-app-pub-3940256099942544/1033173712';
  }

  @override
  void initState() {
    super.initState();
    _loadAndCheckCoffeeCups();
    _loadInterstitialAd(); // تحميل الإعلان مسبقاً فور فتح الشاشة
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  // تحميل الإعلان في الخلفية
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('=== AdMob: تم تحميل الإعلان بنجاح ومستعد للعرض ===');
          setState(() {
            _interstitialAd = ad;
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (error) {
          debugPrint('=== AdMob: فشل تحميل الإعلان: $error ===');
          setState(() {
            _isAdLoaded = false;
            _interstitialAd = null;
          });
        },
      ),
    );
  }

  // دالة عرض الإعلان المشتركة: لا تنفذ الـ Action إلا بعد إغلاق الإعلان تماماً
  void _showAdAndPerformAction(
    VoidCallback onAdClosedAction, {
    bool requireAdToComplete = false, // خيار لتحديد هل الإعلان إجباري أم لا
  }) {
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('=== AdMob: تم إغلاق الإعلان من قبل المستخدم ===');
          ad.dispose();
          _isAdLoaded = false;
          _loadInterstitialAd(); // تحضير إعلان جديد للمرة القادمة
          onAdClosedAction(); // شاهد الإعلان وأغلقه بنجاح -> تنفيذ العملية
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('=== AdMob: فشل عرض الإعلان: $error ===');
          ad.dispose();
          _isAdLoaded = false;
          _loadInterstitialAd();

          if (!requireAdToComplete) {
            onAdClosedAction(); // استمرار عادي للنتيجة
          } else {
            _showCustomSnackBar(
              'تعذر عرض الإعلان، يرجى المحاولة لاحقاً لتجديد القهوة.',
            );
          }
        },
      );

      _interstitialAd!.show();
    } else {
      debugPrint('=== AdMob: الإعلان غير جاهز بعد ===');
      _loadInterstitialAd(); // بدء التحميل للمرة القادمة

      if (!requireAdToComplete) {
        onAdClosedAction(); // في الخدمات العادية: استمرار مباشر للنتيجة
      } else {
        // في حالة تجديد القهوة: نطلب منه الانتظار ثوانٍ لحين تجهيز الإعلان
        _showCustomSnackBar(
          'جاري تحضير الإعلان، يرجى المحاولة بعد ثوانٍ لتجديد القهوة...',
        );
      }
    }
  }

  Future<void> _loadAndCheckCoffeeCups() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetDateStr = prefs.getString('last_coffee_reset');
    final now = DateTime.now();

    if (lastResetDateStr != null) {
      final lastResetDate = DateTime.parse(lastResetDateStr);
      if (now.day != lastResetDate.day ||
          now.month != lastResetDate.month ||
          now.year != lastResetDate.year) {
        await prefs.setInt('coffee_cups', maxCoffeeCups);
        await prefs.setString('last_coffee_reset', now.toIso8601String());
        setState(() => coffeeCups = maxCoffeeCups);
      } else {
        setState(
          () => coffeeCups = prefs.getInt('coffee_cups') ?? maxCoffeeCups,
        );
      }
    } else {
      await prefs.setInt('coffee_cups', maxCoffeeCups);
      await prefs.setString('last_coffee_reset', now.toIso8601String());
      setState(() => coffeeCups = maxCoffeeCups);
    }
  }

  Future<void> _decrementCoffee() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (coffeeCups > 0) coffeeCups--;
    });
    await prefs.setInt('coffee_cups', coffeeCups);
  }

  // تجديد القهوة: لا يجدد الحبات إلا بعد مشاهدة الإعلان وإغلاقه
  void _refillCoffeeWithAd() {
    _showAdAndPerformAction(() async {
      final prefs = await SharedPreferences.getInstance();
      setState(() => coffeeCups = maxCoffeeCups);
      await prefs.setInt('coffee_cups', coffeeCups);
      _showCustomSnackBar('تمت إعادة تعبئة 4 حبات قهوة بنجاح!');
    }, requireAdToComplete: true);
  }

  void _handleServiceSelection(ReadingType type) {
    if (selectedCountry == null ||
        selectedRegion == null ||
        selectedZodiac == null) {
      _showCustomSnackBar('يا ابني كمل بياناتك لتعرف الجدة تحاكيك!');
      return;
    }

    if (coffeeCups <= 0) {
      _showOutOfCoffeeDialog();
      return;
    }

    if (type == ReadingType.cup || type == ReadingType.palm) {
      _handleImagePick(type);
    } else if (type == ReadingType.askGrandma || type == ReadingType.dream) {
      _showTextInputDialog(type);
    }
  }

  void _handleImagePick(ReadingType type) async {
    final ReadingRequest? request = await _controller.pickImage(
      type,
      ImageSource.camera,
    );
    if (request == null) return;

    _showAdAndPerformAction(() async {
      await _decrementCoffee();
      if (_controller.currentUser == null) {
        _showLoginDialog(request);
      } else {
        _navigateToResult(request);
      }
    });
  }

  void _showTextInputDialog(ReadingType type) {
    final TextEditingController textController = TextEditingController();
    final String title = type == ReadingType.askGrandma
        ? 'اسأل الجدة '
        : 'تفسير حلم ';
    final String hint = type == ReadingType.askGrandma
        ? 'اكتب سؤالك للجدة هنا...'
        : 'احكِ للجدة حلمك بالتفصيل...';

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: primaryCoffee,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 17),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: primaryCoffee.withOpacity(0.5),
                      fontSize: 16,
                    ),
                    fillColor: bgColor,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: accentOrange.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: accentOrange, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          if (textController.text.trim().isEmpty) {
                            _showCustomSnackBar('يرجى كتابة النص أولاً!');
                            return;
                          }
                          Navigator.pop(context);
        
                          // إظهار الإعلان، والانتقال فقط بعد إغلاقه
                          _showAdAndPerformAction(() async {
                            await _decrementCoffee();
                            ReadingRequest request = ReadingRequest(
                              type: type,
                              userQuestionOrDream: textController.text.trim(),
                            );
        
                            if (_controller.currentUser == null) {
                              _showLoginDialog(request);
                            } else {
                              _navigateToResult(request);
                            }
                          });
                        },
                        child: const Text(
                          'إرسال للجدة',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(color: primaryCoffee.withOpacity(0.6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOutOfCoffeeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.free_breakfast_outlined,
                size: 50,
                color: accentOrange,
              ),
              const SizedBox(height: 16),
              const Text(
                'خلصوا حبات القهوة اليوم!',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: primaryCoffee,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'شربت 4 فناجين اليوم يا ابني. بتحب تحضر إعلان لتجدد 4 حبات قهوة فوراً؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: primaryCoffee.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentOrange,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _refillCoffeeWithAd();
                },
                icon: const Icon(
                  Icons.ondemand_video_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  'مشاهدة إعلان لتجديد القهوة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'انتظار للغد',
                  style: TextStyle(color: primaryCoffee.withOpacity(0.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: accentOrange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: primaryCoffee,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

void _showLoginDialog(ReadingRequest request) {
  final nameController = TextEditingController();

  showDialog(
    context: context,
    barrierColor: primaryCoffee.withOpacity(0.6),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceWhite,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: primaryCoffee.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // أيقونة الفنجان العلوية
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentOrange.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Image.asset('assets/coffe.png', height: 28, width: 24),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'مرحباً بك!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryCoffee,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'لتتمكن الجدة من قراءة طالعك وحفظ نتائجك، اختر طريقة الدخول:',
                  style: TextStyle(
                    fontSize: 15,
                    color: primaryCoffee.withOpacity(0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
        
                // حقل إدخال الاسم للضيف (موحد الاستايل)
                TextField(
                  controller: nameController,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: primaryCoffee),
                  decoration: InputDecoration(
                    hintText: 'أدخل اسمك للدخول كضيف...',
                    hintStyle: TextStyle(color: primaryCoffee.withOpacity(0.4)),
                    filled: true,
                    fillColor: bgColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accentOrange, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
        
                // زر الدخول كضيف (متاح لكل المنصات بنفس الستايل الأساسي)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final enteredName = nameController.text.trim();
                    if (enteredName.isEmpty) {
                      _showCustomSnackBar('يرجى كتابة اسمك للمتابعة كضيف');
                      return;
                    }
        
                    Navigator.pop(context); // إغلاق الدايلوغ
                    
                    // حفظ بيانات الضيف ببريد إلكتروني تلقائي name@email.com
                    final guestUser = await _controller.signInAsGuest(enteredName);
                    _navigateToResult(request);
                  },
                  child: const Text(
                    'المتابعة كضيف',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        
                // زر تسجيل الدخول من خلال جوجل (يظهر فقط في Android)
                if (Platform.isAndroid) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryCoffee,
                      minimumSize: const Size(double.infinity, 50),
                      side: BorderSide(
                        color: primaryCoffee.withOpacity(0.2),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context); // إغلاق الدايلوغ
                      final user = await _controller.signInWithGoogle();
                      if (user != null) {
                        _navigateToResult(request);
                      } else {
                        _showCustomSnackBar('فشل تسجيل الدخول، حاول مرة أخرى.');
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.g_mobiledata_rounded, size: 28),
                        SizedBox(width: 6),
                        Text(
                          'ادخل بحساب غوغل لاعرف\n جاوبك اكتر يا عيني',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
        
                const SizedBox(height: 8),
        
                // زر الإلغاء
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryCoffee.withOpacity(0.5),
                  ),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  void _navigateToResult(ReadingRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          request: request,
          controller: _controller,
          country: selectedCountry!,
          region: selectedRegion!,
          zodiac: selectedZodiac!,
          UserName: _controller.currentUser!.displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: bgColor,
          drawer: AppDrawerWidget(
            controller: _controller,
            onRefillTap: _refillCoffeeWithAd,
            onAboutTap: () {
              showDialog(
                context: context,
                builder: (context) =>
                    AboutCompanyDialog(showSnackBar: _showCustomSnackBar),
              );
            },
            onLogoutSuccess: () {
              setState(() {}); // تحديث الواجهة بعد تسجيل الخروج
            },
            showSnackBar: _showCustomSnackBar,
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,

            iconTheme: const IconThemeData(color: primaryCoffee),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: surfaceWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentOrange.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryCoffee.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      '$coffeeCups/$maxCoffeeCups',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryCoffee,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Image.asset('assets/coffe.png', height: 25, width: 20),
                  ],
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      EscapingGrandma(),
                      const SizedBox(height: 12),
                      const Text(
                        'أهلاً بك عند الجدة',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: primaryCoffee,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // قائمة الاختيارات
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryCoffee.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ================= الدروي داون الأول (البلد) =================
                      DropdownButtonFormField<String>(
                        value: selectedCountry,
                        isExpanded:
                            true, // لمنع خطأ تجاوز النص إذا كان الاسم طويلاً
                        decoration: InputDecoration(
                          labelText: 'اختر البلد',
                          labelStyle: const TextStyle(
                            color: primaryCoffee,
                            fontSize: 17,
                          ),
                          prefixIcon: Padding(
                            // استخدام Directional ليتناسب مع اللغة العربية RTL
                            padding: const EdgeInsetsDirectional.only(
                              start: 14.0,
                              end: 12.0,
                            ),
                            child: ClipOval(
                              child: SizedBox(
                                width: 32, // تم تصغير الحجم ليتناسق مع النص
                                height: 32,
                                child: Image.asset(
                                  'assets/global.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 50, // لضبط المساحة الكلية للأيقونة
                            minHeight: 32,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14, // زيادة طفيفة ليتوسط النص مع الصورة
                          ),
                        ),
                        items: arabCountriesAndRegions.keys.map((country) {
                          return DropdownMenuItem(
                            value: country,
                            child: Text(
                              country,
                              style: const TextStyle(fontSize: 18),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedCountry = val;
                            selectedRegion = null;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // ================= الدروي داون الثاني (المنطقة) =================
                      DropdownButtonFormField<String>(
                        value: selectedRegion,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'اختر المنطقة',
                          labelStyle: const TextStyle(
                            color: primaryCoffee,
                            fontSize: 17,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 14.0,
                              end: 12.0,
                            ),
                            child: ClipOval(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: Image.asset(
                                  'assets/place.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 50,
                            minHeight: 32,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        items: selectedCountry == null
                            ? []
                            : arabCountriesAndRegions[selectedCountry]!.map((
                                region,
                              ) {
                                return DropdownMenuItem(
                                  value: region,
                                  child: Text(
                                    region,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                );
                              }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedRegion = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // ================= الدروي داون الثالث (البرج) =================
                      DropdownButtonFormField<String>(
                        value: selectedZodiac,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'اختر برجك',
                          labelStyle: const TextStyle(
                            color: primaryCoffee,
                            fontSize: 17,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 14.0,
                              end: 12.0,
                            ),
                            child: ClipOval(
                              child: Container(
                                width: 32,
                                height: 32,
                                // إذا كانت أيقونة البرج شفافة وتحتاج خلفية، يمكنك إضافة لون هنا:
                                // color: primaryCoffee.withOpacity(0.05),
                                child: Image.asset(
                                  'assets/zodiac.png',
                                  fit: BoxFit
                                      .cover, // أو BoxFit.contain إذا كانت الأيقونة تنقص من الحواف
                                ),
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 50,
                            minHeight: 32,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        items: zodiacs.map((zodiac) {
                          return DropdownMenuItem(
                            value: zodiac,
                            child: Text(
                              zodiac,
                              style: const TextStyle(fontSize: 18),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedZodiac = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),

                ServiceCardWidget(
                  title: 'قراءة الفنجان',
                  subtitle: 'التقط صورة لفنجانك واعرف طالعك',
                  icon: Image.asset('assets/cofeecup.png'),
                  onTap: () => _handleServiceSelection(ReadingType.cup),
                ),
                ServiceCardWidget(
                  title: 'قراءة الكف',
                  subtitle: 'صوّر كف يدك للجدة',
                  icon: Image.asset('assets/palmreading.png'),
                  onTap: () => _handleServiceSelection(ReadingType.palm),
                ),
                ServiceCardWidget(
                  title: 'اسأل الجدة',
                  subtitle: 'استشر الجدة في أي موضوع',
                  icon: Image.asset('assets/question.png'),
                  onTap: () => _handleServiceSelection(ReadingType.askGrandma),
                ),
                ServiceCardWidget(
                  title: 'تفسير حلم',
                  subtitle: 'احكِ حلمك للجدة لتفسره لك',
                  icon: Image.asset('assets/dreams.png'),
                  onTap: () => _handleServiceSelection(ReadingType.dream),
                ),
                SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
