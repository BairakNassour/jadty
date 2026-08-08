enum ReadingType {
  cup,        // قراءة الفنجان
  palm,       // قراءة الكف
  askGrandma, // سؤال الجدة
  dream       // تفسير الأحلام
}

class ReadingRequest {
  final String? imagePath;             // جعلناها اختيارية لأن السؤال والحلم لا يتطلبان صورة بالضرورة
  final ReadingType type;
  final String? userQuestionOrDream;  // إضافة نص السؤال أو الحلم

  ReadingRequest({
    this.imagePath,
    required this.type,
    this.userQuestionOrDream,
  });
}