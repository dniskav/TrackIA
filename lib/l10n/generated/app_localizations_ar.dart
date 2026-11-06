// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'TrackIA';

  @override
  String get languageSystem => 'لغة الجهاز';

  @override
  String get languageSpanish => 'الإسبانية';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languagePreference => 'اللغة';

  @override
  String get welcomeTitle => 'مرحبًا بك';

  @override
  String get welcomeHelpTitle => 'المساعدة والترحيب';

  @override
  String welcomeStep(Object current, Object total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get welcomeSlide1Title => 'مرحبًا بك';

  @override
  String get welcomeSlide1Body =>
      'تحدّث مع مساعد الذكاء الاصطناعي لإعداد نشاط وطرح الأسئلة ومراجعة تقدمك. أنت من يقرر متى تبدأ.';

  @override
  String get welcomeSlide2Title => 'تحدّث أو اكتب';

  @override
  String get welcomeSlide2Body =>
      'تدعم المحادثة النص والإملاء والمرفقات. لاستخدام الذكاء الاصطناعي، اربط مزودًا من القائمة. تظل سجلاتك المحلية متاحة إذا انقطع الاتصال.';

  @override
  String get welcomeSlide3Title => 'تحكّم في نشاطك';

  @override
  String get welcomeSlide3Body =>
      'اختر نشاطًا أو أنشئه. إعداده لا يبدأ المؤقت: اضغط ابدأ عندما تكون مستعدًا، وإيقاف عند نهاية كل فترة.';

  @override
  String get welcomeSlide4Title => 'احتفظ ببياناتك';

  @override
  String get welcomeSlide4Body =>
      'تُحفظ سجلاتك على هذا الجهاز. يمكنك ربط Google Sheets في أي وقت ومراجعة حالة كل إرسال.';

  @override
  String get welcomeSlide5Title => 'رفاقك';

  @override
  String get welcomeSlide5Body =>
      'اختر GymBro أو التركيز أو الهدوء أو اليوميات. يمكنك تعديل التعليمات وإنشاء رفاق آخرين وربط ورقة أو علامة تبويب Google مختلفة لكل واحد.';

  @override
  String get welcomeSlide6Title => 'الأوضاع والتذكيرات';

  @override
  String get welcomeSlide6Body =>
      'لكل رفيق وضع. افتح قائمته (⋮) واضغط «الأوضاع والتذكيرات»: وضع التذكير ينبهك في الوقت الذي تختاره فقط؛ ويضيف وضع اللعبة أهدافًا وسلاسل إنجازات وجوائز. لتعمل تنبيهات الراحة حتى مع تشغيل عدم الإزعاج، انتقل إلى الإعدادات ← التذكيرات.';

  @override
  String get welcomeSaveErrorTitle => 'تعذر حفظ اختيارك';

  @override
  String get welcomeSaveErrorBody =>
      'يمكنك المحاولة مجددًا أو المتابعة. إذا تابعت، قد يظهر دليل الترحيب عند فتح التطبيق مرة أخرى.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get continueWithoutSaving => 'المتابعة دون حفظ';

  @override
  String get welcomeNeverAgain => 'عدم الإظهار مجددًا';

  @override
  String get welcomeNeverAgainHelp =>
      'إذا لم تحدد هذا الخيار، فسيظهر الدليل عند فتح التطبيق. يمكنك تغييره من المساعدة.';

  @override
  String get skip => 'تخطي';

  @override
  String get previous => 'السابق';

  @override
  String get next => 'التالي';

  @override
  String get start => 'ابدأ';

  @override
  String get welcomeAutoShow => 'إظهار الترحيب عند الفتح';

  @override
  String get devicePreferenceSaved => 'يُحفظ اختيارك على هذا الجهاز.';

  @override
  String get showWelcome => 'عرض دليل الترحيب';

  @override
  String get savePreferenceError => 'تعذر حفظ التفضيل.';

  @override
  String get companionsTitle => 'رفاقك';

  @override
  String get companionsDescription =>
      'اختر من تعمل معه. يحتفظ كل رفيق بمحادثته ويمكنه استخدام ورقة أو علامة تبويب Google مختلفة.';

  @override
  String get companionsEmpty => 'ليس لديك رفاق بعد. أنشئ رفيقًا للبدء.';

  @override
  String get createCompanion => 'إنشاء رفيق';

  @override
  String companionOptions(Object name) {
    return 'خيارات $name';
  }

  @override
  String companionProgress(Object name) {
    return 'تقدم $name';
  }

  @override
  String companionStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'سلسلة الإنجاز: # يوم',
      many: 'سلسلة الإنجاز: # يومًا',
      few: 'سلسلة الإنجاز: # أيام',
      two: 'سلسلة الإنجاز: يومان',
      one: 'سلسلة الإنجاز: يوم واحد',
      zero: 'لا توجد سلسلة إنجاز',
    );
    return '$_temp0';
  }

  @override
  String get remindersPaused => 'التذكيرات متوقفة مؤقتًا';

  @override
  String get resume => 'استئناف';

  @override
  String get edit => 'تعديل';

  @override
  String get modeAndNotices => 'الأوضاع والتذكيرات';

  @override
  String get delete => 'حذف';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String companionDeleteTitle(Object name) {
    return 'حذف $name؟';
  }

  @override
  String get companionDeleteBody =>
      'سيتم حذف محادثته وملفاته واتصاله المحلي بـ Sheets. لن تُحذف ورقة Google أو سجلات النشاط.';

  @override
  String companionDeleteError(Object error) {
    return 'تعذر الحذف: $error';
  }

  @override
  String companionSaveError(Object error) {
    return 'تعذر الحفظ: $error';
  }

  @override
  String get companionLoadError => 'تعذر تحميل الرفاق. اضغط لإعادة المحاولة.';

  @override
  String get createCompanionTitle => 'إنشاء رفيق';

  @override
  String get editCompanionTitle => 'تعديل رفيق';

  @override
  String get companionName => 'الاسم';

  @override
  String get companionPurpose => 'ما الغرض منه؟';

  @override
  String get companionInstructions => 'تعليمات الذكاء الاصطناعي (اختياري)';

  @override
  String get companionInstructionsHelp => 'تُستخدم عند ربط مزود.';

  @override
  String get icon => 'الأيقونة';

  @override
  String get color => 'اللون';

  @override
  String get settings => 'الإعدادات';

  @override
  String get assistant => 'المساعد';

  @override
  String get artificialIntelligence => 'الذكاء الاصطناعي';

  @override
  String get yourData => 'بياناتك';

  @override
  String get accountAndData => 'الحساب والبيانات';

  @override
  String get localProfile => 'الملف المحلي';

  @override
  String get exportImport => 'تصدير واستيراد';

  @override
  String get appSection => 'التطبيق';

  @override
  String get notices => 'التذكيرات';

  @override
  String get enabled => 'مفعّلة';

  @override
  String get disabled => 'متوقفة';

  @override
  String get appearance => 'المظهر';

  @override
  String get helpWelcome => 'المساعدة والترحيب';

  @override
  String get verified => 'تم التحقق';

  @override
  String get notConnected => 'غير متصل';

  @override
  String get notVerified => 'لم يتم التحقق';

  @override
  String get unavailable => 'غير متاح';

  @override
  String get checking => 'جارٍ التحقق…';

  @override
  String get automatic => 'تلقائي';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String companionSettingsTitle(Object name) {
    return 'الأوضاع والتذكيرات · $name';
  }

  @override
  String get mode => 'الوضع';

  @override
  String get reminderMode => 'تذكير';

  @override
  String get reminderModeDetail => 'ينبهك فقط في الوقت الذي تختاره.';

  @override
  String get gameMode => 'لعبة';

  @override
  String get gameModeDetail =>
      'أهداف وسلاسل إنجازات وجوائز، إلى جانب التذكيرات.';

  @override
  String get goals => 'الأهداف';

  @override
  String get streaks => 'سلاسل الإنجاز';

  @override
  String get achievements => 'الجوائز';

  @override
  String get encouragementMessages => 'رسائل التشجيع';

  @override
  String get freeDaysPerWeek => 'أيام راحة في الأسبوع';

  @override
  String get freeDaysHelp => 'لا تقطع سلسلة الإنجاز.';

  @override
  String get dailyNotice => 'تذكير يومي';

  @override
  String get remindersPausedDetail => 'مرّت 7 أيام مجدولة دون تسجيل نشاط.';

  @override
  String get remindAboutActivity => 'ذكّرني بهذا النشاط';

  @override
  String get monday => 'الاثنين';

  @override
  String get tuesday => 'الثلاثاء';

  @override
  String get wednesday => 'الأربعاء';

  @override
  String get thursday => 'الخميس';

  @override
  String get friday => 'الجمعة';

  @override
  String get saturday => 'السبت';

  @override
  String get sunday => 'الأحد';

  @override
  String get from => 'من';

  @override
  String get until => 'إلى';

  @override
  String get lastCall => 'التنبيه الأخير';

  @override
  String get lastCallTime => 'وقت التنبيه الأخير';

  @override
  String get neutral => 'محايد';

  @override
  String get motivating => 'مشجّع';

  @override
  String get minimumForDay => 'الحد الأدنى لليوم';

  @override
  String get quantity => 'الكمية';

  @override
  String get sessions => 'جلسات';

  @override
  String get minutes => 'دقائق';

  @override
  String get preview => 'معاينة';

  @override
  String get putGoal => 'تحديد هدف';

  @override
  String get whatToMeasure => 'ما الذي تريد قياسه؟';

  @override
  String get timeMinutes => 'الوقت (بالدقائق)';

  @override
  String get sessionCount => 'الجلسات';

  @override
  String get perDay => 'في اليوم';

  @override
  String get perWeek => 'في الأسبوع';

  @override
  String get target => 'الهدف';

  @override
  String get minimumStreakOptional =>
      'الحد الأدنى للحفاظ على السلسلة (اختياري)';

  @override
  String get chooseTime => 'اختر الوقت';

  @override
  String get goalMustBePositive => 'يجب أن يكون الهدف رقمًا أكبر من 0.';

  @override
  String get minimumMustBePositive =>
      'يجب أن يكون الحد الأدنى رقمًا أكبر من 0.';

  @override
  String get companionSettingsLoadError => 'تعذر تحميل الإعدادات.';

  @override
  String get companionSettingsSaveError => 'تعذر حفظ الإعدادات.';

  @override
  String get aiNotConnected => 'الذكاء الاصطناعي غير متصل';

  @override
  String get chooseProviderAndModel => 'اختر مزودًا ونموذجًا.';

  @override
  String get connect => 'اتصال';

  @override
  String get aiNotVerified => 'لم يتم التحقق من الذكاء الاصطناعي';

  @override
  String get verifyConnectionAssistant => 'اختبر الاتصال لتفعيل المساعد.';

  @override
  String get verify => 'تحقق';

  @override
  String get aiUnavailable => 'الذكاء الاصطناعي غير متاح';

  @override
  String get reviewProviderRetry => 'راجع المزود وحاول مجددًا.';

  @override
  String get review => 'مراجعة';

  @override
  String get waitingPhraseOne => 'أنا هنا لمساعدتك عندما تكون مستعدًا.';

  @override
  String get waitingPhraseTwo => 'خذ وقتك، يمكننا المتابعة هنا.';

  @override
  String get waitingPhraseThree => 'نتابع متى شئت.';

  @override
  String get waitingPhraseFour => 'يمكنك مواصلة الكتابة عندما يناسبك.';

  @override
  String get logoDescription => 'شعار TrackIA';

  @override
  String get chatArchive => 'أرشفة المحادثة';

  @override
  String get chatArchives => 'المحادثات المؤرشفة';

  @override
  String get chatSendToSheets => 'الإرسال إلى Google Sheets';

  @override
  String get chatAiProvider => 'موفر الذكاء الاصطناعي';

  @override
  String get chatConfigureAi => 'إعداد الذكاء الاصطناعي';

  @override
  String get chatVerifyConnection =>
      'التحقق من الاتصال · يستخدم واجهة API الخاصة بك';

  @override
  String get chatTraining => 'التدريب';

  @override
  String get chatLoadSheets => 'تحميل Google Sheets';

  @override
  String get chatSheetPending => 'تفسير الجدول بالذكاء الاصطناعي';

  @override
  String get chatWelcomePrompt =>
      'ما الذي تود فعله اليوم؟ أخبرني لنخطط له معًا.';

  @override
  String get chatLoadDataPrompt =>
      'حمّل بياناتك باستخدام + متى شئت. يمكن للذكاء الاصطناعي تفسير تنسيقها عند الاتصال.';

  @override
  String get chatPrepareActivity => 'تحضير';

  @override
  String get chatWaitingModel => 'بانتظار النموذج…';

  @override
  String get chatDeferredArchive =>
      'سيؤرشف المساعد هذه المحادثة عند عودتك إلى النهاية.';

  @override
  String get chatGoLatest => 'الانتقال إلى أحدث رسالة';

  @override
  String get chatListening => 'جارٍ الاستماع… راجع النص واضغط إرسال.';

  @override
  String get chatAttach => 'إرفاق';

  @override
  String get chatComposeHint => 'اكتب رسالتك أو أمْلِها…';

  @override
  String get chatConnectAiHint => 'اتصل بالذكاء الاصطناعي للبدء';

  @override
  String get chatStopDictation => 'إيقاف الإملاء';

  @override
  String get chatDictate => 'إملاء رسالة';

  @override
  String get chatSend => 'إرسال';

  @override
  String get chatAssistantImageAlt => 'صورة';

  @override
  String get chatInputDirections => 'اتجاه نص الرسالة';

  @override
  String get activityStart => 'ابدأ';

  @override
  String get activityStop => 'إيقاف';

  @override
  String get activityFinish => 'إنهاء';

  @override
  String get activityFinishDay => 'إنهاء اليوم';

  @override
  String get activityChooseAnother => 'اختيار نشاط آخر';

  @override
  String get activitySubtractCycle => 'إنقاص دورة';

  @override
  String get activityAddCycle => 'إضافة دورة مكتملة';

  @override
  String get activityNoticesOff => 'التنبيهات متوقفة';

  @override
  String get activityEnableNotices => 'تفعيل';

  @override
  String get activityCycles => 'الدورات';

  @override
  String get aiUnavailableFocus =>
      'الذكاء الاصطناعي غير متاح · يمكنك التوقف وحفظ الملاحظات محليًا';

  @override
  String get activityRestInProgress => 'استراحة جارية';

  @override
  String get activityRestChangeNoticePrompt =>
      'هل تريد تغيير التنبيه المجدول بالفعل أيضًا؟';

  @override
  String get activityKeepNotice => 'الاحتفاظ بالتنبيه';

  @override
  String get activityChangeNotice => 'تغيير التنبيه';

  @override
  String get personalityInstructions => 'الشخصية والتعليمات';

  @override
  String get personalityInstructionsHelp =>
      'صف النبرة وكيف تريد من هذا الرفيق دعمك. يؤثر ذلك على ردوده بالذكاء الاصطناعي فقط.';

  @override
  String get personalitySuggestionTone => 'استخدم نبرة ودودة وواضحة.';

  @override
  String get personalitySuggestionAsk =>
      'اطرح أسئلة موجزة عندما تنقص التفاصيل.';

  @override
  String get personalitySuggestionAccuracy =>
      'لا تختلق معلومات أو تقدمًا لم أذكره.';

  @override
  String get personalityTooLong => 'يجب ألا تتجاوز تعليمات الشخصية 4000 حرف.';

  @override
  String get personalityDraftTitle => 'مسودة الشخصية';

  @override
  String get personalityDraftAccept => 'استخدام المسودة';

  @override
  String get personalityDraftButton => 'ساعدني في صياغتها';

  @override
  String get personalityDraftError =>
      'تعذر إنشاء المسودة. تحقق من اتصال الذكاء الاصطناعي وحاول مجددًا.';

  @override
  String get activityTargetTitle => 'العدد المستهدف للمجموعات';

  @override
  String get activityTargetLabel => 'المجموعات (اتركه فارغًا للإزالة)';

  @override
  String get activityTargetInvalid =>
      'أدخل عددًا مستهدفًا بين 1 و100، أو اتركه فارغًا.';

  @override
  String get activityTargetEditTooltip => 'تعديل العدد المستهدف للمجموعات';

  @override
  String activityTargetPreservedProgress(Object target, Object completed) {
    return 'الهدف: $target. سيبقى تقدمك محفوظًا مع $completed مجموعات مكتملة.';
  }

  @override
  String get activityTargetUpdated => 'تم تحديث الهدف.';

  @override
  String get activityNoTarget => 'بلا هدف';

  @override
  String activityTargetChangedEvent(Object target) {
    return 'غيّرت العدد المستهدف للمجموعات إلى $target';
  }

  @override
  String get chatTargetProposalAmbiguous =>
      'لم يتغير الهدف: الاقتراح ملتبس أو لا يخص نشاطًا جاريًا.';

  @override
  String get chatTargetConfirmTitle => 'تغيير العدد المستهدف للمجموعات';

  @override
  String get chatTargetRemovePrompt => 'هل تريد إزالة الهدف؟';

  @override
  String chatTargetSetPrompt(Object target) {
    return 'هل تريد تحديد الهدف بـ $target مجموعات؟';
  }

  @override
  String chatTargetSetPromptWithProgress(Object target, Object completed) {
    return 'هل تريد تحديد الهدف بـ $target مجموعات؟ لقد أكملت $completed؛ وسيبقى التقدم محفوظًا بالكامل.';
  }

  @override
  String get chatTargetConfirmButton => 'تغيير';

  @override
  String get chatTargetSavedNoTarget => 'تم حفظ الهدف: بلا هدف.';

  @override
  String chatTargetSaved(Object target) {
    return 'تم حفظ الهدف: $target مجموعات.';
  }

  @override
  String chatTargetSavedWithProgress(Object target, Object completed) {
    return 'تم حفظ الهدف: $target مجموعات. سيبقى تقدمك محفوظًا مع $completed مجموعات مكتملة.';
  }

  @override
  String get chatTargetStale =>
      'لم يتغير الهدف. ربما تغير النشاط؛ راجعه وحاول مجددًا.';

  @override
  String get sheetsTitle => 'جداول بيانات Google الخاصة بك';

  @override
  String get sheetsChooseTitle => 'اختر جدول بيانات التمرين';

  @override
  String get sheetsSearch => 'البحث بالاسم';

  @override
  String get sheetsSearchTooltip => 'بحث';

  @override
  String get sheetsConnect => 'الاتصال بـ Google';

  @override
  String get sheetsReconnect => 'تغيير الحساب أو إعادة التفويض';

  @override
  String get sheetsNoResults =>
      'لم يتم العثور على جداول. جرّب اسماً آخر أو غيّر الحساب.';

  @override
  String get sheetsLoadMore => 'تحميل مزيد من الجداول';

  @override
  String get dataTitle => 'بياناتك';

  @override
  String get dataCreateBackup => 'إنشاء نسخة احتياطية ومشاركتها';

  @override
  String get dataRestoreBackup => 'استعادة نسخة احتياطية';

  @override
  String get aiProviderTitle => 'موفّر الذكاء الاصطناعي';

  @override
  String get aiConnectTitle => 'اربط مساعدك';

  @override
  String get aiProviderLabel => 'موفّر';

  @override
  String get sheetChooseTab => 'اختر علامة التبويب التي تحتوي على تمارينك';

  @override
  String get sheetReview => 'مراجعة الجدول';

  @override
  String sheetRowsRead(Object count) {
    return 'تمت قراءة $count صفاً. سيتم تحميل علامة التبويب كاملة؛ تظهر هنا أول 12 صفاً.';
  }

  @override
  String sheetRowsReadPreview(Object count) {
    return 'تمت قراءة $count صفاً. معاينة:';
  }

  @override
  String get sheetLoadPending =>
      'سيُحفظ الجدول على هذا الهاتف بانتظار تفسيره. لا تحتاج إلى الذكاء الاصطناعي لتحميله. بعد الاتصال، يمكنك طلب تفسير بنيته. لا يؤدي التحميل إلى إنشاء تمارين أو إرسال الخلايا إلى الموفّر.';

  @override
  String get sheetSendToAi =>
      'عند الضغط على تحميل وتحليل، ستُرسل هذه الخلايا إلى موفّر الذكاء الاصطناعي المُعدّ. تُحفظ الصفوف كما تظهر ولا تتحول إلى تمارين.';

  @override
  String get sheetReadOnlyGoogle =>
      'هذه نسخة للقراءة فقط. لجلب التغييرات اللاحقة، استخدم تحديث الجدول في الدردشة.';

  @override
  String get sheetReadOnlyFile =>
      'هذه نسخة للقراءة فقط من الملف. لجلب التغييرات، أعد تحميله.';

  @override
  String get sheetsConnecting => 'جارٍ الاتصال بـ Google…';

  @override
  String get sheetsAuthorizeProgress => 'اختر حسابك واسمح بالقراءة من Google…';

  @override
  String get sheetsSearchProgress => 'جارٍ البحث عن جداولك…';

  @override
  String sheetsLoadingTabs(Object name) {
    return 'جارٍ تحميل علامات التبويب في $name…';
  }

  @override
  String sheetsReadingTab(Object name) {
    return 'جارٍ قراءة $name…';
  }

  @override
  String get sheetsReadError => 'تعذرت قراءة الجدول. حاول مرة أخرى.';

  @override
  String get sheetsGoogleError => 'تعذر الاتصال بـ Google.';

  @override
  String get sheetsRetry => 'إعادة تحميل الجداول';

  @override
  String get sheetsPartial => 'أعاد Google نتائج بحث جزئية. ابحث باسم الجدول.';

  @override
  String get sheetsAuthIncomplete =>
      'لم يُكمل Google التفويض. اضغط على الاتصال بـ Google للمحاولة مجدداً؛ لم يتم تحميل جداولك بعد.';

  @override
  String get sheetsSearchAccountChanged =>
      'تغير الحساب أثناء البحث. أعد الاتصال للمتابعة.';

  @override
  String get sheetsChooseAccountChanged =>
      'تغير الحساب أثناء الاختيار. أعد الاتصال للمتابعة.';

  @override
  String get sheetsReadAccountChanged =>
      'تغير الحساب أثناء القراءة. لم يتم تحميل البيانات.';

  @override
  String get sheetsNoTabs => 'لا توجد علامات تبويب متاحة في هذا الجدول.';

  @override
  String get sheetsReadRowsIntro =>
      'صفاً تمت قراءتها. سيتم تحميل علامة التبويب كاملة؛ تظهر هنا أول 12 صفاً.';

  @override
  String get syncTitle => 'إرسال إلى جداول بيانات Google';

  @override
  String get syncIntro =>
      'اربط Google واختر جدولك مرة واحدة. يمكن للدردشة الاطلاع على أحدث البيانات وإرسال النتائج؛ ويمكنك هنا أيضاً مراجعة إرسال يدوي.';

  @override
  String get syncNoSessions =>
      'لا توجد جلسات مكتملة لإرسالها. يمكنك اختبار الاتصال دون بدء نشاط.';

  @override
  String get syncWorkout => 'التمرين';

  @override
  String get syncConnectWrite => 'الاتصال بـ Google والسماح بالكتابة';

  @override
  String syncDestinationAccount(Object email) {
    return 'حساب الوجهة: $email';
  }

  @override
  String get syncCheckConnection => 'التحقق من الاتصال';

  @override
  String get syncDisconnect => 'قطع الاتصال بهذا الجدول';

  @override
  String get syncChangeAccount => 'تغيير حساب الوجهة';

  @override
  String get syncCreateNew => 'إنشاء جدول جديد';

  @override
  String get syncNewSheetName => 'اسم الجدول الجديد';

  @override
  String get syncCreateDrive => 'إنشاء جدول في Google Drive';

  @override
  String get syncSheet => 'جدول Google';

  @override
  String get syncTab => 'علامة التبويب';

  @override
  String get syncInstructions => 'تفضيلات الجدول أو ملاحظاته';

  @override
  String get syncInstructionsHint => 'مثال: استخدم قسم أكتوبر، إجمالي الأوزان';

  @override
  String get syncAllowOverwrite =>
      'السماح بتحديث الخلايا التي تحتوي على بيانات';

  @override
  String get syncOverwriteHelp =>
      'ستعرض المراجعة القيمة السابقة والجديدة. تُحفظ الصيغ.';

  @override
  String get syncAutomatic => 'إرسال الجلسات تلقائياً عند الانتهاء';

  @override
  String get syncAutomaticChatHelp =>
      'يظل الإرسال عبر الدردشة متاحاً عند إيقاف الإرسال التلقائي مؤقتاً.';

  @override
  String get syncAutomaticActivityHelp =>
      'لا تحدد سجلات النشاط المرافق بعد؛ يمكنك طلب الإرسال والتعديلات من الدردشة.';

  @override
  String get syncSavePreferences => 'حفظ الاتصال والتفضيلات';

  @override
  String get syncReviewLoadChat => 'مراجعة الجدول وتحميله في الدردشة';

  @override
  String get syncDiagnostics => 'تشخيص الاتصال';

  @override
  String get syncDiagnosticsHelp =>
      'اختبر علامة التبويب المحددة دون بدء نشاط. يستخدم اختبار الكتابة علامة تبويب مؤقتة ولا يغيّر تمارينك.';

  @override
  String get syncTestRead => 'اختبار القراءة بالذكاء الاصطناعي';

  @override
  String get syncTestWrite => 'اختبار الكتابة بالذكاء الاصطناعي';

  @override
  String get syncPrepare => 'إعداد الإرسال ومراجعته';

  @override
  String get syncNoSheet => 'اختر جدولاً وعلامة تبويب.';

  @override
  String get syncNoValidWorkout => 'اختر جدولاً وعلامة تبويب وتمريناً مكتملاً.';

  @override
  String get syncSessionUnavailable => 'لم تعد الجلسة متاحة.';

  @override
  String get syncConnectionError =>
      'تعذر استرداد الجدول المحفوظ. يمكنك اختيار جدول آخر.';

  @override
  String get syncOperationError => 'تعذر إكمال العملية. حاول مرة أخرى.';

  @override
  String get syncGoogleUnconfirmed => 'لم يؤكد Google تنفيذ العملية.';

  @override
  String get syncNameInvalid => 'أدخل اسماً لا يتجاوز 80 حرفاً.';

  @override
  String get syncLoadChatTitle => 'مراجعة الجدول للدردشة';

  @override
  String get syncConfirmLoad => 'تأكيد وتحميل';

  @override
  String syncReadConfirmed(Object count, Object answer) {
    return 'تم تأكيد القراءة: استلام $count صفاً من Google. رد النموذج: $answer';
  }

  @override
  String syncWriteConfirmed(Object marker) {
    return 'تم تأكيد الكتابة: اقترح النموذج «$marker»، وقبل Google الاختبار وحُذفت علامة التبويب المؤقتة. لم تُرسل أي تمارين.';
  }

  @override
  String get syncSentConfirmed =>
      'تم إرسال التمرين إلى جداول بيانات Google. تم التحقق من الإيصال؛ لن يؤدي الإرسال مجدداً إلى تكراره.';

  @override
  String get syncReturnChat => 'العودة إلى الدردشة';

  @override
  String syncDestination(Object name, Object tab) {
    return 'الوجهة: $name / $tab';
  }

  @override
  String get syncReceiptNote =>
      'سيحفظ Google أيضاً إيصال الإرسال لمنع التكرار.';

  @override
  String syncReviewCount(Object count) {
    return '$count خلية. سيتحقق التطبيق من عدم تغييرها منذ هذه المراجعة.';
  }

  @override
  String get syncOriginalData => 'عرض بيانات التمرين الأصلية';

  @override
  String get syncConfirmSend => 'تأكيد الإرسال إلى جداول بيانات Google';

  @override
  String get syncDiscard => 'تجاهل الاقتراح';

  @override
  String get sheetNoTabs => 'لا توجد علامات تبويب متاحة في هذا الجدول.';

  @override
  String get sheetsLoad => 'تحميل الجدول';

  @override
  String get sheetsLoadAnalyze => 'تحميل وتحليل';

  @override
  String get rowLabel => 'صف';

  @override
  String get syncProposedSessionInvalid =>
      'الجلسة المقترحة غير مكتملة أو لا تنتمي إلى هذا الملف الشخصي. اختر جلسة صالحة.';

  @override
  String get syncConnectionSaved =>
      'تم حفظ الاتصال. ستقرأ الدردشة الجدول الحالي ويمكنها إرسال النتائج دون طلب التفويض في كل مرة.';

  @override
  String get syncIdentityUnconfirmed => 'تعذر تأكيد حساب Google المحدد.';

  @override
  String get sheetAllRowsWillLoad => 'سيتم تحميل جميع صفوف علامة التبويب.';

  @override
  String get syncAccountChangedReview =>
      'تغير الحساب أثناء مراجعة علامة التبويب. تم الاحتفاظ بالجدول السابق؛ أعد الاتصال لتحميله.';

  @override
  String syncLoadedIntoChat(Object name, Object tab) {
    return 'تم تحميل الجدول في الدردشة: $name / $tab.';
  }

  @override
  String get syncConfigureAi =>
      'أعد إعداد الذكاء الاصطناعي أولاً لاختبار وصول النموذج.';

  @override
  String get syncModelEmpty => 'لم يُرجع النموذج أي رد.';

  @override
  String get syncInvalidMarker => 'رد النموذج لكنه لم يقدم علامة اختبار صالحة.';

  @override
  String get syncWorkoutChanged =>
      'تغير التمرين. أعد إعداد الإرسال لمراجعة البيانات الحالية.';

  @override
  String get syncRefreshAfterSendFailed =>
      'تم تأكيد الإرسال. تعذر تحديث نسخة الدردشة؛ أعد تحميل الجدول للاطلاع على بياناته الجديدة.';

  @override
  String syncReceiptSent(Object workout, Object id, Object name, Object tab) {
    return 'تم تأكيد جداول بيانات Google: أُرسل التمرين «$workout» ($id) إلى «$name / $tab». يؤكد إيصال Google الإرسال.';
  }

  @override
  String syncReceiptCreated(Object name, Object tab) {
    return 'تم تأكيد جداول بيانات Google: أُنشئ الجدول «$name» وعلامة التبويب «$tab». لم يتم إرسال التقدم بعد.';
  }

  @override
  String get sheetsAssistantIntro =>
      'اربط حسابك واختر الجدول وعلامة التبويب. راجع البيانات قبل مشاركتها مع مساعدك.';

  @override
  String get sheetsImportIntro =>
      'يستخدم TrackIA تفويض Google لقراءة جداولك. تُحفظ البيانات على هذا الهاتف عند تأكيد الاستيراد.';

  @override
  String get sheetsErrorExpired => 'انتهى تفويض Google. أعد الاتصال بحسابك.';

  @override
  String get sheetsErrorPermission =>
      'لا يسمح Google بهذه العملية. تحقق من الوصول وأذونات الجدول.';

  @override
  String get sheetsErrorAccount =>
      'لا تتطابق القراءة مع الحساب المفوض. أعد الاتصال من ملفك الشخصي.';

  @override
  String get sheetsErrorNotFound => 'لم يعد هذا الجدول متاحاً لهذا الحساب.';

  @override
  String get sheetsErrorRateLimit =>
      'تلقى Google طلبات كثيرة. انتظر قليلاً ثم حاول مرة أخرى.';

  @override
  String get sheetsErrorNetwork =>
      'تعذر تأكيد العملية مع Google. تم الاحتفاظ بالتقدم المحلي؛ سيتحقق الإيصال عند إعادة المحاولة.';

  @override
  String get sheetsErrorTooLarge =>
      'يتجاوز حجم علامة التبويب 20 ميغابايت. اختر علامة تبويب أصغر.';

  @override
  String get sheetsErrorGeneric =>
      'تعذر على Google إكمال العملية. حاول مرة أخرى.';

  @override
  String get sheetsErrorBusy =>
      'هناك عملية Google قيد التنفيذ. انتظر حتى تنتهي.';

  @override
  String syncBeforeValue(Object value) {
    return 'السابق: $value';
  }

  @override
  String get syncEmptyCell => '(فارغة)';

  @override
  String get syncDisconnected =>
      'تم قطع الاتصال بالجدول. تم الاحتفاظ بالبيانات المحلية وعمليات الإرسال المعلقة.';

  @override
  String get aiProviderDescription =>
      'اختر موفّراً سحابياً أو شغّل نموذجاً محلياً على هذا الهاتف. يمكن للنماذج المحلية العمل دون اتصال؛ ويعتمد الأداء على الذاكرة والنموذج المختار.';

  @override
  String get aiConfigReadError => 'تعذرت قراءة الإعدادات المحفوظة.';

  @override
  String aiModelImportError(Object error) {
    return 'تعذر استيراد ملف GGUF: $error';
  }

  @override
  String get aiMemoryAvailableNow => 'المتاح الآن';

  @override
  String get aiMemoryAfterModel => 'بعد النموذج وجهاز العرض';

  @override
  String get aiMemoryAfterContext => 'بعد إضافة سياق النموذج المحدد';

  @override
  String aiMemoryContextEstimate(
    Object context,
    Object minimum,
    Object maximum,
  ) {
    return 'سيستهلك سياق $context نحو $minimum–$maximum من ذاكرة RAM.';
  }

  @override
  String aiMemoryShortfall(Object amount) {
    return 'يتجاوز التقدير الذاكرة المتاحة بمقدار $amount.';
  }

  @override
  String get aiMemoryEstimateHelp =>
      'تقدير تقريبي لأوزان النموذج وجهاز العرض؛ يضيف السياق المحدد استهلاكاً للذاكرة وقد يختلف حسب النموذج.';

  @override
  String get aiConnectedChooseModel =>
      'تم ربط الحساب. اختر نموذجاً واختبر الاتصال لاستخدام المساعد.';

  @override
  String get aiIdentityConnected =>
      'تم ربط الهوية. يمكنك تفويض استخدام خطة ChatGPT بشكل منفصل.';

  @override
  String get aiChatGptDisconnected => 'تم قطع اتصال جلسة ChatGPT.';

  @override
  String get aiChatGptRemoteRevocationUnconfirmed =>
      'تم قطع الاتصال على هذا الهاتف. لم يتم تأكيد الإلغاء عن بُعد؛ افصل TrackIA أيضاً من إعدادات ChatGPT.';

  @override
  String aiOperationError(Object details) {
    return 'تعذر إكمال العملية$details';
  }

  @override
  String aiOperationDetails(Object error) {
    return ': $error';
  }

  @override
  String get aiNoModelImported => 'لم يتم استيراد نموذج.';

  @override
  String get aiSelectImportGguf => 'اختيار / استيراد نموذج .gguf';

  @override
  String get aiLocalContextTitle => 'سياق النموذج المحلي';

  @override
  String aiLocalContextHelp(Object context) {
    return 'يوصي TrackIA بسياق $context لتعليماته وسجله وبياناته. تغطي التوصية احتياجات التطبيق، لا الحد الأقصى لهذا النموذج. إذا لم يدعم النموذج الحجم المختار فقد يتعطل؛ ويمكنك تقليله.';
  }

  @override
  String aiContextSelected(Object context) {
    return 'المحدد: $context';
  }

  @override
  String get aiUseRecommendation => 'استخدام القيمة الموصى بها';

  @override
  String get aiVisualProjector => 'جهاز عرض الصور (اختياري)';

  @override
  String get aiProjectorHelp =>
      'أضفه لاستخدام الصور. يحتاج MiniCPM‑V إلى ملف mmproj GGUF المطابق.';

  @override
  String get aiNoProjector => 'لا يوجد جهاز عرض للصور.';

  @override
  String get aiSelectProjector => 'اختيار جهاز عرض mmproj';

  @override
  String get aiMemoryHelp =>
      'تُعرض الذاكرة المتاحة بشكل منفصل. تعكس توصية 8192 رمزاً احتياجات TrackIA؛ وقد لا يدعمها ملف GGUF ويمكنك اختيار حجم آخر.';

  @override
  String get aiRecalculateMemory => 'إعادة حساب الذاكرة المتاحة';

  @override
  String get aiApiBase => 'عنوان URL الأساسي لواجهة API';

  @override
  String get aiHttpsExample => 'HTTPS، مثال: https://your-provider.com/v1';

  @override
  String get aiChatGptPlanHelp =>
      'استخدم خطتك إذا كان حسابك ومساحة العمل مؤهلين. يُحتسب الاستخدام ضمن الحدود المشتركة. لا يمنح ذلك إمكانية الوصول إلى محادثات ChatGPT.';

  @override
  String get aiChatGptAccount => 'حساب ChatGPT';

  @override
  String get aiChatGptConnectedPlan => 'متصل · تم تفويض استخدام الخطة';

  @override
  String get aiChatGptConnectedIdentity => 'متصل · الهوية فقط';

  @override
  String get aiChatGptNotConnected => 'ChatGPT غير متصل';

  @override
  String get aiContinueChatGpt => 'المتابعة باستخدام ChatGPT';

  @override
  String get aiReviewPlanPermission => 'مراجعة إذن استخدام الخطة';

  @override
  String get aiAuthorizePlan => 'تفويض استخدام خطة ChatGPT الخاصة بي';

  @override
  String get aiAddAccount => 'إضافة حساب أو مساحة عمل أخرى';

  @override
  String get aiViewUsagePermissions => 'عرض الاستخدام والأذونات في ChatGPT';

  @override
  String get aiDisconnectChatGpt => 'قطع اتصال ChatGPT';

  @override
  String get aiCancelConnection => 'إلغاء الاتصال';

  @override
  String get aiApiKey => 'مفتاح API';

  @override
  String get aiHideKey => 'إخفاء المفتاح';

  @override
  String get aiShowKey => 'إظهار المفتاح';

  @override
  String get aiFetchModels => 'الحصول على النماذج / تحديثها';

  @override
  String get aiLoadingModels => 'جارٍ تحميل النماذج…';

  @override
  String get aiModelLabel => 'النموذج';

  @override
  String get aiChooseCatalogModel => 'اختر نموذجاً من الفهرس';

  @override
  String aiCurrentModelPreserved(Object model) {
    return 'النموذج الحالي: $model. سيبقى محفوظاً حتى إن لم يظهر في الفهرس.';
  }

  @override
  String get aiHideManualId => 'إخفاء المعرّف اليدوي';

  @override
  String get aiEnterManualModel => 'إدخال النموذج يدوياً';

  @override
  String get aiModelIdentifier => 'معرّف النموذج';

  @override
  String get aiOpenCodeNotice =>
      'Go مخصص لوكلاء البرمجة. تعرّف هذه الوصلة عن نفسها باسم TrackIA؛ تحقق من الموفّر بشأن دعم هذا الاستخدام. لن يتم التبديل تلقائياً إلى Zen أو خدمة أخرى.';

  @override
  String get aiApiSettings => 'إعدادات API';

  @override
  String get aiHttpsBase => 'عنوان URL أساسي لـ HTTPS';

  @override
  String get aiProtocol => 'التنسيق المتوافق مع النموذج';

  @override
  String get aiConfigSaved => 'تم حفظ الإعدادات.';

  @override
  String get aiSaveLocalModel => 'حفظ النموذج المحلي';

  @override
  String get aiSaveProvider => 'حفظ الموفّر';

  @override
  String aiProviderResponded(Object answer) {
    return 'ردّ الموفّر:\n$answer';
  }

  @override
  String get aiTestLocalModel => 'اختبار النموذج على هذا الهاتف';

  @override
  String get aiTestChatGpt => 'اختبار الاتصال · يستخدم خطة ChatGPT الخاصة بي';

  @override
  String get aiTestApi => 'اختبار الاتصال · يستخدم API الخاصة بك';

  @override
  String get aiConfigDeleted => 'تم حذف الإعدادات والمفتاح.';

  @override
  String get aiDeleteConfig => 'حذف الإعدادات والمفتاح';
}
