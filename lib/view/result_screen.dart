import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jadty/component/AppColors.dart';
import 'package:jadty/controller/result_controller.dart';
import 'package:jadty/model/reading_request.dart';
import 'package:jadty/controller/auth_and_scan_controller.dart';
import 'package:jadty/view/ItemsHomePage/native_ad_widget.dart';

class ResultScreen extends StatefulWidget {
  final ReadingRequest request;
  final AuthAndScanController controller;
  final String region;
  final String zodiac;
  final String country;
  final String UserName;

  const ResultScreen({
    Key? key,
    required this.request,
    required this.controller,
    required this.region,
    required this.zodiac,
    required this.country,
    required this.UserName,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late ResultController _resultController;

  // المتغيرات الخاصة بالإعلان البيني (AdMob Interstitial)
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  // معرفات إعلانات الاختبار الرسمية من AdMob
  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Android Test Ad Unit
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // iOS Test Ad Unit
    }
    return 'ca-app-pub-3940256099942544/1033173712';
  }

  @override
  void initState() {
    super.initState();
    _resultController = ResultController(
      request: widget.request,
      region: widget.region,
      zodiac: widget.zodiac,
      country: widget.country,
      userName: widget.UserName,
    );

    // تحميل وعرض الإعلان أثناء فترة انتظار التحليل
    _loadAndShowInterstitialAd();
  }

  /// تحميل الإعلان البيني وعرضه فور تجهيزه أثناء انتظار التحليل
  void _loadAndShowInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('=== ResultScreen: تم تحميل الإعلان البيني بنجاح ===');
          if (!mounted) return;
          setState(() {
            _interstitialAd = ad;
            _isAdLoaded = true;
          });

          // عرض الإعلان البيني مباشرة أثناء وقت الانتظار
          _showInterstitialAd();
        },
        onAdFailedToLoad: (error) {
          debugPrint('=== ResultScreen: فشل تحميل الإعلان البيني: $error ===');
          if (!mounted) return;
          setState(() {
            _isAdLoaded = false;
            _interstitialAd = null;
          });
        },
      ),
    );
  }

  /// عرض الإعلان البيني في حال تم تحميله
  void _showInterstitialAd() {
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isAdLoaded = false;
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _isAdLoaded = false;
        },
      );

      _interstitialAd!.show();
    }
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _resultController.dispose();
    super.dispose();
  }

  String _getScreenTitle() {
    switch (widget.request.type) {
      case ReadingType.cup:
        return 'قراءة الفنجان';
      case ReadingType.palm:
        return 'قراءة الكف';
      case ReadingType.askGrandma:
        return 'سؤال الجدة';
      case ReadingType.dream:
        return 'تفسير الحلم';
      case ReadingType.talk:
        return 'خبر الجدة عن مشكلتك';
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasImage = widget.request.imagePath != null &&
        widget.request.imagePath!.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            _getScreenTitle(),
            style: const TextStyle(
              color: primaryCoffee,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: primaryCoffee, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        body: AnimatedBuilder(
          animation: _resultController,
          builder: (context, child) {
            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1️⃣ عرض الصورة أو نص السؤال/الحلم
                    if (hasImage)
                      _buildImageCard()
                    else
                      _buildTextQuestionCard(),

                    const SizedBox(height: 40),

                    // 2️⃣ + 3️⃣ بطاقة كلام الجدة مدمجة مع صورتها بتصميم عصري
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        // البطاقة البيضاء للنتيجة
                        Container(
                          margin: const EdgeInsets.only(top: 55),
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 70, 24, 28),
                          decoration: BoxDecoration(
                            color: surfaceWhite,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: primaryCoffee.withOpacity(0.06),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _buildResponseContent(context),
                        ),

                        // صورة الجدة العائمة (Floating Avatar)
                        Positioned(
                          top: 0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCirc,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: surfaceWhite,
                              boxShadow: _resultController.isSpeaking
                                  ? [
                                      BoxShadow(
                                        color: accentOrange.withOpacity(0.5),
                                        blurRadius: 25,
                                        spreadRadius: 8,
                                      ),
                                      BoxShadow(
                                        color: accentOrange.withOpacity(0.2),
                                        blurRadius: 50,
                                        spreadRadius: 15,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: primaryCoffee.withOpacity(0.1),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      )
                                    ],
                            ),
                            child: const CircleAvatar(
                              radius: 50,
                              backgroundColor: bgColor,
                              backgroundImage:
                                  AssetImage('assets/grandma-grandmother.gif'),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 4️⃣ الإعلان المدمج (Native Ad)
                    const GrandmaNativeAdWidget(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ====================== دوال بناء أجزاء الواجهة (Widgets) ====================== //

  Widget _buildImageCard() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primaryCoffee.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          alignment: Alignment.bottomRight,
          fit: StackFit.expand,
          children: [
            Image.file(
              File(widget.request.imagePath!),
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBadge(Icons.location_on_rounded, widget.region),
                  _buildBadge(Icons.auto_awesome_rounded, widget.zodiac),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border(
          right: BorderSide(color: accentOrange.withOpacity(0.7), width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryCoffee.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.format_quote_rounded,
                      color: accentOrange.withOpacity(0.8), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    widget.request.type == ReadingType.askGrandma
                        ? 'سؤالك للجدة'
                        : 'حلمك الذي رويته',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryCoffee.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              _buildBadge(Icons.auto_awesome_rounded, widget.zodiac,
                  darkTheme: true),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.request.userQuestionOrDream ?? '',
            style: const TextStyle(
              fontSize: 17,
              height: 1.6,
              color: primaryCoffee,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseContent(BuildContext context) {
    if (_resultController.isLoading) {
      return Column(
        children: [
          const CircularProgressIndicator(
            color: accentOrange,
            strokeWidth: 3.5,
            strokeCap: StrokeCap.round,
          ),
          const SizedBox(height: 24),
          Text(
            'الجدة عم تتسمعلك وتفكر بكلامها الحنون...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryCoffee.withOpacity(0.8),
            ),
          ),
        ],
      );
    }

    if (_resultController.hasError) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Colors.redAccent,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _resultController.grandmaResponse,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: primaryCoffee,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resultController.retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryCoffee,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 22),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _resultController.speak(_resultController.grandmaResponse),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _resultController.isSpeaking
                        ? accentOrange
                        : primaryCoffee.withOpacity(0.08),
                    foregroundColor: _resultController.isSpeaking
                        ? Colors.white
                        : primaryCoffee,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(
                    _resultController.isSpeaking
                        ? Icons.pause_rounded
                        : Icons.volume_up_rounded,
                    size: 24,
                  ),
                  label: Text(
                    _resultController.isSpeaking ? 'إيقاف الصوت' : 'احكي يا جدة',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: primaryCoffee.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                padding: const EdgeInsets.all(14),
                icon: Icon(
                  Icons.copy_rounded,
                  color: primaryCoffee.withOpacity(0.8),
                  size: 22,
                ),
                tooltip: 'نسخ الكلام',
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _resultController.grandmaResponse),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'تم نسخ كلام الجدة بنجاح!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: accentOrange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.all(20),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1.5, color: bgColor),
        const SizedBox(height: 24),
        Text(
          _resultController.grandmaResponse,
          style: const TextStyle(
            fontSize: 20,
            height: 1.9,
            color: primaryCoffee,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String text, {bool darkTheme = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: darkTheme
                ? accentOrange.withOpacity(0.15)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: darkTheme
                  ? accentOrange.withOpacity(0.3)
                  : Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: darkTheme ? accentOrange : Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: darkTheme ? accentOrange : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}