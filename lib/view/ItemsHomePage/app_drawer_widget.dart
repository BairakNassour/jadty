import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jadty/component/AppColors.dart';
import 'package:jadty/controller/auth_and_scan_controller.dart';
import 'package:url_launcher/url_launcher.dart'; // لفتح روابط المتاجر
import 'package:share_plus/share_plus.dart'; // لمشاركة التطبيق

class AppDrawerWidget extends StatelessWidget {
  final AuthAndScanController controller;
  final VoidCallback onRefillTap;
  final VoidCallback onAboutTap;
  final VoidCallback onLogoutSuccess;
  final Function(String) showSnackBar;

  const AppDrawerWidget({
    Key? key,
    required this.controller,
    required this.onRefillTap,
    required this.onAboutTap,
    required this.onLogoutSuccess,
    required this.showSnackBar,
  }) : super(key: key);

  // دالة مساعدة لفتح الروابط (للمتاجر وسياسة الخصوصية)
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showSnackBar('عذراً، لا يمكن فتح الرابط حالياً');
    }
  }

  // دالة تقييم التطبيق
  Future<void> _rateApp() async {
    // ضع هنا معرف تطبيقك على الأندرويد (Package Name)
    const String androidPackageName = 'com.jadty.app'; 
    // ضع هنا معرف تطبيقك على أبل (App ID)
    const String iosAppId = '1234567890'; 

    final String url = Platform.isAndroid
        ? 'https://play.google.com/store/apps/details?id=$androidPackageName'
        : 'https://apps.apple.com/app/id$iosAppId';
    
    await _launchURL(url);
  }

  // دالة مشاركة التطبيق
  void _shareApp() {
    // ضع رابط التحميل أو موقع التطبيق هنا
    const String appLink = 'https://play.google.com/store/apps/details?id=com.jadty.app';
    Share.share('حمل تطبيق جدتي لقراءة الفنجان والكف بروح التراث! ☕✨\n$appLink');
  }

  // دالة التواصل عبر الإيميل
  Future<void> _contactUs() async {
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: 'bairak23455@gmail.com', // 💡 انتبه: هل الإيميل bairak أم baitak كما في سياسة الخصوصية؟
    queryParameters: {
      'subject': 'تواصل من داخل تطبيق جدتي',
    },
  );

  try {
    // نتحقق أولاً، وإن تعذرcanLaunchUrl على المحاكي، نحاول التشغيل مباشرة مع try-catch
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
    } else {
      // محاولة احتياطية مباشرة (تفيد في بعض الأجهزة)
      bool launched = await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        showSnackBar('عذراً، لا يوجد تطبيق بريد إلكتروني مثبت على الجهاز');
      }
    }
  } catch (e) {
    showSnackBar('تعذر فتح تطبيق البريد الإلكتروني');
  }
}

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? primaryCoffee),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color ?? primaryCoffee,
        ),
      ),
      trailing: Icon(
        Icons.chevron_left,
        size: 18,
        color: (color ?? primaryCoffee).withOpacity(0.3),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;

    return Drawer(
      backgroundColor: bgColor,
      child: Column(
        children: [
          // رأس القائمة (Header)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 20,
              right: 20,
              left: 20,
            ),
            decoration: const BoxDecoration(
              color: primaryCoffee,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: accentOrange, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: bgColor,
                    backgroundImage: (user != null &&
                            user.photoUrl != null &&
                            user.photoUrl!.isNotEmpty)
                        ? NetworkImage(user.photoUrl!) as ImageProvider
                        : const AssetImage('assets/grandma-grandmother.gif'),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  user != null
                      ? (user.displayName != null && user.displayName!.isNotEmpty
                          ? user.displayName!
                          : "أهلاً بك يا حفيد الجدة")
                      : "تطبيق جدتي",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user != null
                      ? (user.email ?? "حساب مسجّل")
                      : "قراءة الفنجان والكف بروح التراث",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          // عناصر القائمة (Body)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildDrawerItem(
                  icon: Icons.local_cafe_rounded,
                  title: 'تجديد فنجان القهوة',
                  onTap: () {
                    Navigator.pop(context);
                    onRefillTap();
                  },
                ),
                
                const Divider(indent: 20, endIndent: 20, thickness: 0.5),

                // الأقسام الجديدة التي تجعل التطبيق كاملاً
                _buildDrawerItem(
                  icon: Icons.star_rate_rounded,
                  title: 'قيّم التطبيق',
                  color: Colors.amber[700], // لون مميز للتقييم
                  onTap: () {
                    Navigator.pop(context);
                    _rateApp();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.share_rounded,
                  title: 'شارك التطبيق',
                  onTap: () {
                    Navigator.pop(context);
                    _shareApp();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.email_rounded,
                  title: 'تواصل معنا',
                  onTap: () {
                    Navigator.pop(context);
                    _contactUs();
                  },
                ),
                
                const Divider(indent: 20, endIndent: 20, thickness: 0.5),

                _buildDrawerItem(
                  icon: Icons.privacy_tip_rounded,
                  title: 'سياسة الخصوصية',
                  onTap: () {
                    Navigator.pop(context);
                    // ضع رابط سياسة الخصوصية الخاص بك هنا
                    _launchURL('https://jadty.inchcode.com/privcay.php');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline_rounded,
                  title: 'حول التطبيق والمطور',
                  onTap: () {
                    Navigator.pop(context);
                    onAboutTap();
                  },
                ),
                
                if (user != null) ...[
                  const SizedBox(height: 20),
                  _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'تسجيل الخروج',
                    color: Colors.redAccent,
                    onTap: () async {
                      await controller.signOut();
                      Navigator.pop(context);
                      onLogoutSuccess();
                      showSnackBar('تم تسجيل الخروج بنجاح');
                    },
                  ),
                ],
                const SizedBox(height: 20), // مسافة في أسفل القائمة
              ],
            ),
          ),
        ],
      ),
    );
  }
}