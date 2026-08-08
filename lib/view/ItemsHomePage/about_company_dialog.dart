import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jadty/component/AppColors.dart';

class AboutCompanyDialog extends StatelessWidget {
  final Function(String) showSnackBar;

  const AboutCompanyDialog({Key? key, required this.showSnackBar}) : super(key: key);

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showSnackBar("لا يمكن فتح الرابط حالياً");
    }
  }

  Widget _buildContactItem(IconData icon, String title, String url) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: accentOrange, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: primaryCoffee,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => _launchURL(url),
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: accentOrange.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryCoffee.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentOrange.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                  'assets/companylogo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "InchCode",
              style: TextStyle(
                color: primaryCoffee,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Software Solutions & Development",
              style: TextStyle(
                color: primaryCoffee.withOpacity(0.5),
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 15),
            const Divider(color: bgColor, thickness: 2),
            const SizedBox(height: 15),
            Text(
              "نحن فخورون بتطوير هذا التطبيق.\nإذا كنت ترغب في بناء مشروعك الخاص، يسعدنا أن نكون شريكك التقني.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryCoffee.withOpacity(0.8),
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            _buildContactItem(
              Icons.language,
              "الموقع الإلكتروني",
              "https://companyshow.inchcode.com/",
            ),
            _buildContactItem(
              Icons.chat_bubble_outline,
              "فرع دبي (واتساب)",
              "https://wa.me/971565991072",
            ),
            _buildContactItem(
              Icons.chat_bubble_outline,
              "فرع السعودية (واتساب)",
              "https://wa.me/966571871733",
            ),
            _buildContactItem(
              Icons.chat_bubble_outline,
              "فرع سوريا (واتساب)",
              "https://wa.me/963936979261",
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  "إغلاق",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}