import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jadty/component/AppColors.dart';

class EscapingGrandma extends StatefulWidget {
  const EscapingGrandma({Key? key}) : super(key: key);

  @override
  State<EscapingGrandma> createState() => _EscapingGrandmaState();
}

class _EscapingGrandmaState extends State<EscapingGrandma> {
  Offset _currentOffset = Offset.zero;
  bool _showMessage = false;
  Timer? _timer;
  final Random _random = Random();
  
  int _currentIndex = 0;

  // 50 جملة كوميدية بدون إيموجيات
  final List<String> _funnyMessages = [
    "ليش عم تضغط عليي؟",
    "يا ابني اتركني بحالي!",
    "شبك لاحقني وين ما رحت؟",
    "خلص!!",
    "تقبرني روح العب بعيد عني",
    "أكلت ولا بعدك عم تنقر بهالموبايل؟",
    "ولك والله ركبي عم يوجعوني!",
    "عم تفعصني فعص، شو شايفني زر؟",
    "ولي على قامتي، شو هالولد اللحوح!",
    "قامت قيامتك، حل عني بقا!",
    "لك روح جيبلي كاسة شاي أزينلك",
    "والله لأقوم اضربك بالشحاطة!",
    "شو هالجيل يلي ما بيهدأ!",
    "لك يرضى عليك بعد إصبعتك عني",
    "يستر على حريماتك تركني نام",
    "تضرب شو انك غليظ!",
    "لك شو شايفني لعبة بين ايديك؟",
    "والله لتكسرلي ضهر هالعكازة عليك",
    "قوم طبخلك طبخة نفاد تعبي كرشك",
    "تضرب أنت وهالشاشة يلي بايدك",
    "ولي على أمتي منك ومن جنانك",
    "لك بكفي نق!",
    "لك شو عم تدور بالخبزات؟",
    "روح شفلك شغل ومغزى بدل هالفقس",
    "يوه! ما أغلظك وما أثقل دمك",
    "العما شو انك لزقة!",
    "لك مو عيب تكبس ع جدتك؟",
    "روح يا ابني الله يهديك ويهدي البال",
    "والله لأحكي لأبوك عليك بس يرجع",
    "شو صار للناس؟ جُنت وركبت الحصص!",
    "لك ارحمني شوي، قلبي الصغير لا يتحمل",
    "تضرب بقعة، شو انك نقاق!",
    "قوم افحص سكرك وشوف ضغطك وتركني",
    "بدي روح اعمل قهوة، حل عني!",
    "ولك يا صحن الملبس أنت، شو بدك مني؟",
    "كبسة ثانية وبدي صرخ ولم عليك الحارة!",
    "العمى شو هالفظاعة!",
    "هي آخرة تعبي عليك",
    "مو فاضيتلك عم ساوي كبة",
    "روح دورلك على عروس بدل هالمسخرة",
    "ولك اترك الشاشة وشوف الشمس شو لونها",
    "راح النهار وأنت عم تفعص بي وجهي",
    "لك يا ربي دخيلك من هالجيل!",
    "إيها... سقا الله أيام زمان لما كان الولد يستحي",
    "رح ناديلك العو ياكلك!",
    "اتركني أقرأ الأذكار ويرضى عليك",
    "والله لو قمتلك ما بتسلم مني",
    "يحرق حريشك شو لزقة!",
    "بقيت تضغط ولا ما بقيت؟",
    "خلصت الجمل وما خلصت غلاظتك!"
  ];

  void _onPointerDown(PointerDownEvent event) {
    _timer?.cancel();
    setState(() {
      _showMessage = false;
      double dx = (_random.nextDouble() * 2.0) - 1.0;
      double dy = (_random.nextDouble() * 2.0) - 1.0;
      _currentOffset = Offset(dx, dy);
    });
  }

  void _onPointerUp(PointerEvent event) {
    setState(() {
      _currentOffset = Offset.zero;
      _showMessage = true;
      _currentIndex = (_currentIndex + 1) % _funnyMessages.length;
    });

    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showMessage = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _showMessage ? 1.0 : 0.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryCoffee.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _funnyMessages[_currentIndex],
              style: const TextStyle(
                color: primaryCoffee,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'MyCustomFont',
              ),
            ),
          ),
        ),
        
        Listener(
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerUp,
          child: AnimatedSlide(
            offset: _currentOffset,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: surfaceWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryCoffee.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: bgColor,
                backgroundImage: AssetImage(
                  'assets/grandma-grandmother.gif',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}