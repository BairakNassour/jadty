import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jadty/model/reading_request.dart';
import 'package:jadty/model/user_model.dart';

class AuthAndScanController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final ImagePicker _picker = ImagePicker();

  // نستخدم Completer لربط الـ Listener مع دالة تسجيل الدخول
  Completer<UserModel?>? _loginCompleter;

  // متغير لتخزين بيانات المستخدم الضيف محلياً
  UserModel? _guestUser;

  // المُنشئ (Constructor): يعمل تلقائياً عند استدعاء الكنترولر لتهيئة جوجل
  AuthAndScanController() {
    _initSocialListeners();
  }

  // الحصول على المستخدم الحالي (يتفقد الضيف أولاً ثم Firebase)
  UserModel? get currentUser {
    if (_guestUser != null) {
      return _guestUser;
    }

    final user = _auth.currentUser;
    if (user == null) return null;

    return UserModel(
      uid: user.uid,
      displayName: user.displayName ?? 'مستخدم',
      email: user.email ?? '',
      photoUrl: user.photoURL ?? '',
    );
  }

  // تسجيل الدخول كضيف مع تعبئة كامل الحقول بقيم افتراضية لتجنب الـ null
  Future<UserModel> signInAsGuest(String guestName) async {
    final cleanName = guestName.trim().isEmpty ? 'ضيف' : guestName.trim();
    final timeStamp = DateTime.now().millisecondsSinceEpoch;

    // إنشاء كائن المستخدم الضيف بكافة حقوله
    _guestUser = UserModel(
      uid: 'guest_$timeStamp',
      displayName: cleanName,
      email: '$cleanName@email.com',
      photoUrl: '', // قيمة افتراضية غير فارغة للصورة
    );

    return _guestUser!;
  }

  // التقاط صورة مباشرة عبر الكاميرا
  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      return pickedFile?.path;
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }

  // التقاط صورة عبر الاستديو
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      return pickedFile?.path;
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }

  // التقاط صورة للكف أو الفنجان وتغليفها في ReadingRequest
  Future<ReadingRequest?> pickImage(ReadingType type, ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      return ReadingRequest(imagePath: pickedFile.path, type: type);
    }
    return null;
  }

  // التهيئة والاستماع لأحداث جوجل مع إضافة الـ serverClientId
  void _initSocialListeners() {
    _googleSignIn.initialize(
      serverClientId: '894366798660-q8ev4e785d5dqngsfh4iuphlerrd2lsv.apps.googleusercontent.com',
    ).then((_) {
      _googleSignIn.authenticationEvents.listen((event) async {
        GoogleSignInAccount? googleUser;

        if (event is GoogleSignInAuthenticationEventSignIn) {
          googleUser = event.user;
        } else {
          googleUser = null;
        }

        if (googleUser != null) {
          final googleAuth = await googleUser.authentication;

          final credential = GoogleAuthProvider.credential(
            idToken: googleAuth.idToken,
          );

          final userCredential = await _auth.signInWithCredential(credential);
          final user = userCredential.user;

          if (user != null) {
            _guestUser = null; // إعادة تعيين حساب الضيف إذا سجل بجوجل

            final userModel = UserModel(
              uid: user.uid,
              displayName: user.displayName ?? 'مستخدم',
              email: user.email ?? '',
              photoUrl: user.photoURL ?? '',
            );

            // إرسال النتيجة الناجحة
            if (_loginCompleter != null && !_loginCompleter!.isCompleted) {
              _loginCompleter!.complete(userModel);
            }
          }
        } else {
          // إرسال نتيجة فارغة في حال الإلغاء
          if (_loginCompleter != null && !_loginCompleter!.isCompleted) {
            _loginCompleter!.complete(null);
          }
        }
      });
    });
  }

  // تشغيل عملية تسجيل الدخول لجوجل
  Future<UserModel?> signInWithGoogle() async {
    _loginCompleter = Completer<UserModel?>();

    try {
      await _googleSignIn.authenticate();
    } catch (e) {
      print("Google Auth Error: $e");
      if (!_loginCompleter!.isCompleted) {
        _loginCompleter!.complete(null);
      }
    }

    return _loginCompleter!.future;
  }

  // تسجيل الخروج وتصفير البيانات
  Future<void> signOut() async {
    try {
      _guestUser = null; // مسح بيانات الضيف عند الخروج
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print("SignOut Error: $e");
    }
  }
}