// Pepper Clinical — Task Generator (Dart)
// 100,000+ unique adaptive therapy tasks
// ABA-DTT · TEACCH · ESDM · Verbal Behavior · PRT
import 'dart:math';

class Task {
  final String type;         // motor | color_grid | obj_grid | letter | word | math | social
  final String name;
  final String instruction;
  final String em;
  final String domain;
  final String protocol;
  final int    level;
  final int    tokens;
  final String successMsg;
  final String failMsg;
  final List<Map<String,String>> options;  // for grid tasks
  final int    correct;      // index of correct option
  final String word;         // for verbal tasks
  final String answer;       // for math tasks

  const Task({
    required this.type,
    required this.name,
    required this.instruction,
    required this.em,
    required this.domain,
    required this.protocol,
    required this.level,
    required this.tokens,
    required this.successMsg,
    required this.failMsg,
    this.options = const [],
    this.correct = -1,
    this.word    = '',
    this.answer  = '',
  });
}

// ── Data Pools ────────────────────────────────────────────────────

const _colorsAr = [
  ('أحمر','🔴','#ef4444'),('أزرق','🔵','#3b82f6'),('أخضر','🟢','#22c55e'),
  ('أصفر','🟡','#eab308'),('برتقالي','🟠','#f97316'),('بنفسجي','🟣','#a855f7'),
  ('وردي','🩷','#ec4899'),('بني','🟤','#92400e'),('أبيض','⬜','#f1f5f9'),
  ('أسود','⬛','#1e293b'),('رمادي','🩶','#6b7280'),('سماوي','🩵','#06b6d4'),
];
const _colorsEn = [
  ('red','🔴','#ef4444'),('blue','🔵','#3b82f6'),('green','🟢','#22c55e'),
  ('yellow','🟡','#eab308'),('orange','🟠','#f97316'),('purple','🟣','#a855f7'),
  ('pink','🩷','#ec4899'),('brown','🟤','#92400e'),('white','⬜','#f1f5f9'),
  ('black','⬛','#1e293b'),('gray','🩶','#6b7280'),('cyan','🩵','#06b6d4'),
];

const _animalsAr = [
  ('قطة','🐱'),('كلب','🐶'),('أسد','🦁'),('نمر','🐯'),('فيل','🐘'),
  ('زرافة','🦒'),('قرد','🐒'),('بطريق','🐧'),('بومة','🦉'),('دلفين','🐬'),
  ('أرنب','🐰'),('ثعلب','🦊'),('دب','🐻'),('حصان','🐴'),('فراشة','🦋'),
  ('سلحفاة','🐢'),('ضفدع','🐸'),('نحلة','🐝'),('طائر','🐦'),('سمكة','🐟'),
];
const _animalsEn = [
  ('cat','🐱'),('dog','🐶'),('lion','🦁'),('tiger','🐯'),('elephant','🐘'),
  ('giraffe','🦒'),('monkey','🐒'),('penguin','🐧'),('owl','🦉'),('dolphin','🐬'),
  ('rabbit','🐰'),('fox','🦊'),('bear','🐻'),('horse','🐴'),('butterfly','🦋'),
  ('turtle','🐢'),('frog','🐸'),('bee','🐝'),('bird','🐦'),('fish','🐟'),
];

const _fruitsAr = [
  ('تفاحة','🍎'),('موزة','🍌'),('برتقالة','🍊'),('فراولة','🍓'),('عنب','🍇'),
  ('مانجو','🥭'),('كيوي','🥝'),('بطيخ','🍉'),('أناناس','🍍'),('كمثرى','🍐'),
  ('ليمون','🍋'),('توت','🍒'),('خوخ','🍑'),('رمان','🍎'),('تمر','🌴'),
];
const _fruitsEn = [
  ('apple','🍎'),('banana','🍌'),('orange','🍊'),('strawberry','🍓'),('grape','🍇'),
  ('mango','🥭'),('kiwi','🥝'),('watermelon','🍉'),('pineapple','🍍'),('pear','🍐'),
  ('lemon','🍋'),('cherry','🍒'),('peach','🍑'),('pomegranate','🍎'),('date','🌴'),
];

const _lettersAr = ['أ','ب','ت','ث','ج','ح','خ','د','ذ','ر','ز','س','ش',
                    'ص','ض','ط','ظ','ع','غ','ف','ق','ك','ل','م','ن','ه','و','ي'];

const _wordsAr = ['أحمر','أزرق','كبير','صغير','سعيد','حزين','جائع','متعب',
                  'ماء','حليب','بيت','باب','كتاب','قلم','أم','أب','شمس','قمر',
                  'واحد','اثنان','ثلاثة','أربعة','خمسة','مرحباً','شكراً','آسف',
                  'نعم','لا','أحبك','أريد ماء','أحتاج مساعدة','صباح الخير','انتهيت'];
const _wordsEn = ['red','blue','big','small','happy','sad','hungry','tired',
                  'water','milk','house','door','book','pen','mom','dad','sun','moon',
                  'one','two','three','four','five','hello','thank you','sorry',
                  'yes','no','I love you','I want water','I need help','Good morning',"I'm done"];

const _motorAr = [
  ('لوّح بالتحية','لوّح يدك يميناً ويساراً!','👋'),
  ('إبهام للأعلى','أرني إبهاماً كبيراً للأعلى!','👍'),
  ('صفّق ثلاث مرات','صفّق بيديك 3 مرات!','👏'),
  ('لمس الأنف','المس أنفك بإصبعك!','👆'),
  ('ارفع يديك','ارفع كلتا يديك للأعلى!','🙌'),
  ('تنفس عميق','خذ نفساً عميقاً ببطء!','🌬️'),
  ('هزّ رأسك إيجاباً','هزّ رأسك لأعلى ولأسفل!','✅'),
  ('افتح وأغلق يديك','افتح وأغلق يديك 5 مرات!','🖐️'),
  ('أظهر السعادة','اصنع أسعد ابتسامة لك!','😄'),
  ('أظهر الدهشة','افتح عينيك واسعاً!','😮'),
  ('أشر للكاميرا','أشر للكاميرا بإصبع واحد!','☝️'),
  ('قف على أصابع قدميك','قف على أصابع قدميك 3 ثوانٍ!','🦶'),
  ('تدوير الكتفين','دوّر كتفيك للخلف!','🔄'),
  ('لمس الأذن','المس أذنك اليمنى بيدك اليمنى!','👂'),
  ('اقفز مرة','اقفز للأعلى مرة واحدة!','⬆️'),
];
const _motorEn = [
  ('Wave Hello','Wave your hand side to side!','👋'),
  ('Thumbs Up','Show a big thumbs up!','👍'),
  ('Clap 3 Times','Clap your hands 3 times!','👏'),
  ('Touch Nose','Touch your nose with your finger!','👆'),
  ('Raise Both Arms','Raise both arms up high!','🙌'),
  ('Deep Breath','Take a slow deep breath!','🌬️'),
  ('Nod Yes','Nod your head up and down!','✅'),
  ('Open Close Hands','Open and close your hands 5 times!','🖐️'),
  ('Show Happy Face','Make your happiest smile!','😄'),
  ('Show Surprised Face','Open your eyes wide!','😮'),
  ('Point at Camera','Point at the camera with one finger!','☝️'),
  ('Stand on Tiptoes','Stand on your tiptoes for 3 seconds!','🦶'),
  ('Roll Shoulders','Roll your shoulders backwards!','🔄'),
  ('Touch Ear','Touch your right ear with your right hand!','👂'),
  ('Jump Once','Jump up once!','⬆️'),
];

const _socialAr = [
  ('قل من فضلك','قل: هل يمكنني الحصول على ماء من فضلك؟','🙏'),
  ('قل شكراً','قل شكراً بصوت عالٍ!','💙'),
  ('انتظر دورك','عُدّ من 1 إلى 5 وانتظر بصبر!','⏳'),
  ('قل مرحباً','قل مرحباً بصوت واضح!','👋'),
  ('قل آسف','قل: أنا آسف، لم أقصد ذلك.','💛'),
  ('قل مديحاً','قل شيئاً لطيفاً لشخص تحبه!','🌸'),
  ('شارك لعبة','أظهر كيف تشارك لعبتك مع صديق!','🤲'),
  ('وداع','قل مع السلامة بابتسامة!','🙋'),
];
const _socialEn = [
  ('Say Please','Say: Can I have water, please?','🙏'),
  ('Say Thank You','Say THANK YOU out loud!','💙'),
  ('Wait Patiently','Count to 5 and wait your turn!','⏳'),
  ('Say Hello','Say hello in a clear voice!','👋'),
  ('Say Sorry','Say: I am sorry, I did not mean to.','💛'),
  ('Give a Compliment','Say something kind to someone!','🌸'),
  ('Share a Toy','Show how you share with a friend!','🤲'),
  ('Say Goodbye','Say goodbye with a smile!','🙋'),
];

// ── Generator ────────────────────────────────────────────────────

class TaskService {
  static final _rng = Random();

  static List<Task> generate({
    String? domain,
    int level = 1,
    int count = 10,
    String lang = 'ar',
  }) {
    final domains = domain != null ? [domain] : ['motor','cognitive','verbal','math','social'];
    return List.generate(count, (i) {
      final d = domains[i % domains.length];
      return _build(d, level: level, lang: lang);
    })..shuffle(_rng);
  }

  static Task _build(String domain, {int level = 1, String lang = 'ar'}) {
    switch (domain) {
      case 'motor':    return _motor(level, lang);
      case 'cognitive':return _cognitive(level, lang);
      case 'verbal':   return _verbal(level, lang);
      case 'math':     return _math(level, lang);
      case 'social':   return _social(level, lang);
      default:         return _motor(level, lang);
    }
  }

  static Task _motor(int level, String lang) {
    final pool = lang == 'ar' ? _motorAr : _motorEn;
    final item = pool[_rng.nextInt(pool.length)];
    return Task(
      type: 'motor', name: item.$1, instruction: item.$2, em: item.$3,
      domain:   lang == 'ar' ? 'حركي' : 'motor',
      protocol: 'ABA-DTT', level: level, tokens: level + 1,
      successMsg: lang == 'ar' ? 'حركة رائعة! ممتاز!' : 'Great movement! Excellent!',
      failMsg:    lang == 'ar' ? 'جرّب مجدداً!' : 'Try again!',
    );
  }

  static Task _cognitive(int level, String lang) {
    final types = ['color', 'animal', 'fruit'];
    if (level >= 2) types.add('letter');
    final type = types[_rng.nextInt(types.length)];

    if (type == 'color') {
      final pool = lang == 'ar' ? _colorsAr : _colorsEn;
      final tgt  = pool[_rng.nextInt(pool.length)];
      final others = pool.where((c) => c.$1 != tgt.$1).toList()..shuffle(_rng);
      final opts4 = [...others.take(3), tgt]..shuffle(_rng);
      final ci    = opts4.indexOf(tgt);
      return Task(
        type: 'color_grid',
        name: '${lang=='ar'?'أين اللون ':'Find color '}${tgt.$1}',
        instruction: '${lang=='ar'?'أشر إلى اللون ':'Point to '}${tgt.$1}! ${tgt.$2}',
        em: tgt.$2,
        domain: lang=='ar' ? 'معرفي' : 'cognitive',
        protocol: 'ABA-DTT', level: level, tokens: 2,
        successMsg: '${lang=='ar'?'ممتاز! هذا ':'Excellent! That is '}${tgt.$1}!',
        failMsg:    lang=='ar' ? 'حاول مجدداً!' : 'Try again!',
        options: opts4.map((o) => {'label':o.$1,'em':o.$2,'color':o.$3}).toList(),
        correct: ci,
      );
    } else if (type == 'letter') {
      final tgt    = _lettersAr[_rng.nextInt(_lettersAr.length)];
      final others = _lettersAr.where((l) => l != tgt).toList()..shuffle(_rng);
      final opts4  = [...others.take(3), tgt]..shuffle(_rng);
      return Task(
        type: 'letter',
        name: 'حرف $tgt', instruction: 'ابحث عن الحرف $tgt! 📝',
        em: '📝',
        domain: 'لفظي', protocol: 'Verbal-Behavior', level: level, tokens: 3,
        successMsg: 'ممتاز! الحرف $tgt!', failMsg: 'حاول مجدداً!',
        options: opts4.map((l) => {'label':l,'em':'📝','color':'#7c3aed'}).toList(),
        correct: opts4.indexOf(tgt),
      );
    } else {
      final pool = type == 'animal'
          ? (lang=='ar' ? _animalsAr : _animalsEn)
          : (lang=='ar' ? _fruitsAr  : _fruitsEn);
      final tgt    = pool[_rng.nextInt(pool.length)];
      final others = pool.where((x) => x.$1 != tgt.$1).toList()..shuffle(_rng);
      final opts4  = [...others.take(3), tgt]..shuffle(_rng);
      final ci     = opts4.indexOf(tgt);
      return Task(
        type: 'obj_grid',
        name: '${lang=='ar'?'أين ':'Where is '}${tgt.$1}',
        instruction: '${lang=='ar'?'أشر إلى ':'Point to '}${tgt.$1}! ${tgt.$2}',
        em: tgt.$2,
        domain: lang=='ar' ? 'معرفي' : 'cognitive',
        protocol: 'TEACCH', level: level, tokens: 2,
        successMsg: '${lang=='ar'?'رائع! ':'Awesome! '}${tgt.$1}!',
        failMsg:    lang=='ar' ? 'حاول مجدداً!' : 'Try again!',
        options: opts4.map((o) => {'label':o.$1,'em':o.$2,'color':'transparent'}).toList(),
        correct: ci,
      );
    }
  }

  static Task _verbal(int level, String lang) {
    final pool = lang == 'ar' ? _wordsAr : _wordsEn;
    final word = pool[_rng.nextInt(pool.length)];
    return Task(
      type: 'word',
      name: '${lang=='ar'?'قل: ':'Say: '}$word',
      instruction: '${lang=='ar'?'قل الكلمة: ':'Say the word: '}$word 🗣️',
      em: '🗣️',
      domain: lang=='ar' ? 'لفظي' : 'verbal',
      protocol: 'Verbal-Behavior', level: level, tokens: 3,
      successMsg: '${lang=='ar'?'أحسنت! قلت: ':'Great! You said: '}$word!',
      failMsg: '${lang=='ar'?'قل: ':'Say: '}$word!',
      word: word,
    );
  }

  static Task _math(int level, String lang) {
    late int a, b, ans;
    late String op;
    if (level == 1) { a=_rng.nextInt(5)+1; b=_rng.nextInt(5)+1; op='+'; ans=a+b; }
    else if (level==2) { a=_rng.nextInt(8)+3; b=_rng.nextInt(a)+1; op='-'; ans=a-b; }
    else { a=_rng.nextInt(4)+2; b=_rng.nextInt(4)+2; op='×'; ans=a*b; }

    return Task(
      type: 'math',
      name: '$a $op $b',
      instruction: '${lang=='ar'?'$a $op $b = ؟ قل الإجابة!':'$a $op $b = ? Say the answer!'} 🔢',
      em: '🔢',
      domain: lang=='ar' ? 'رياضي' : 'math',
      protocol: 'ABA-DTT', level: level, tokens: 3,
      successMsg: '${lang=='ar'?'عبقري! الإجابة ':'Genius! The answer is '}$ans!',
      failMsg: '${lang=='ar'?'حاول! ':'Try! '}$a $op $b = $ans',
      answer: '$ans',
    );
  }

  static Task _social(int level, String lang) {
    final pool = lang == 'ar' ? _socialAr : _socialEn;
    final item = pool[_rng.nextInt(pool.length)];
    return Task(
      type: 'social', name: item.$1, instruction: item.$2, em: item.$3,
      domain:   lang=='ar' ? 'اجتماعي' : 'social',
      protocol: 'ESDM', level: level, tokens: 2,
      successMsg: lang=='ar' ? 'مهارة اجتماعية رائعة!' : 'Great social skill!',
      failMsg:    lang=='ar' ? 'جرّب مجدداً!' : 'Try again!',
    );
  }
}
