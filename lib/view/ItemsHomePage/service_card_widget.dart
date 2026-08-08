import 'package:flutter/material.dart';
import 'package:jadty/component/AppColors.dart';

class ServiceCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final Image icon;
  final VoidCallback onTap;

  const ServiceCardWidget({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryCoffee.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        leading: Container(
          width: 60, // تثبيت العرض
          height: 60, // تثبيت الارتفاع لضمان دائرة منتظمة
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: accentOrange.withOpacity(0.3)),
          ),
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain, // لضمان ظهور الصورة بالكامل بوضوح
              child: icon,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: primaryCoffee,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 15, color: primaryCoffee.withOpacity(0.6)),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
          color: accentOrange,
        ),
        onTap: onTap,
      ),
    );
  }
}