import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GrandmaNativeAdWidget extends StatefulWidget {
  const GrandmaNativeAdWidget({super.key});

  @override
  State<GrandmaNativeAdWidget> createState() => _GrandmaNativeAdWidgetState();
}

class _GrandmaNativeAdWidgetState extends State<GrandmaNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  // معرف تجريبي من Google AdMob (استبدله بمعرف إعلانك الحقيقي في Production)
  final String _adUnitId = 'ca-app-pub-3940256099942544/2247696110';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: _adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
      request: const AdRequest(),
      // تخصيص الألوان والخطوط لتطابق كارت الجدة
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small, // Small أو Medium حسب المساحة
        mainBackgroundColor: const Color(0xFF2C241E), // لون خلفية كارت الجدة
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFFD4A373), // لون الزر الرئيسي للتطبيق
          style: NativeTemplateFontStyle.bold,
          size: 13.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          size: 12.0,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // إذا لم يحمل الإعلان بعد، لا يأخذ أي مساحة في الشاشة
    if (!_isLoaded || _nativeAd == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      height: 90, // ارتفاع مناسب لـ TemplateType.small
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4A373).withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}