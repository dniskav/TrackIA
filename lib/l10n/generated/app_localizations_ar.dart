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
    return 'السلسلة (أيام): $days';
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

  @override
  String appVersion(Object version) {
    return 'الإصدار $version';
  }

  @override
  String get activityIdleOtherActive => 'مرافق آخر نشط';

  @override
  String get activityIdleNoActivity => 'لا يوجد نشاط';

  @override
  String get activityIdleEndOther => 'أنهِ النشاط الآخر لتبدأ هنا';

  @override
  String get activityIdleRegisterAnytime => 'سجّل نشاطًا متى شئت';

  @override
  String get activityNewActivity => 'نشاط جديد';

  @override
  String get activityIdleRecord => 'تسجيل';

  @override
  String get activityRestLabel => 'الراحة';

  @override
  String get activityRestDone => 'انتهت الراحة';

  @override
  String get activityRestPaused => 'الراحة متوقفة مؤقتًا';

  @override
  String get activityRestPause => 'إيقاف مؤقت';

  @override
  String get activityRestContinue => 'متابعة';

  @override
  String get activityRestStart => 'ابدأ الراحة';

  @override
  String get activityRestRestart => 'إعادة تشغيل الراحة';

  @override
  String activityRestAdjust(int seconds) {
    return '$seconds ث · تعديل';
  }

  @override
  String get activityRestNotice =>
      'تنبيه مع بقاء هذه الشاشة مفتوحة؛ يستمر الوقت عند الخروج.';

  @override
  String get activityRestDurationTitle => 'مدة الراحة';

  @override
  String get activityRestSecondsLabel => 'ثوانٍ';

  @override
  String get activityRestRangeHint =>
      'بين 5 و1800 ثانية. عند التطبيق يصبح المؤقت جاهزًا للبدء.';

  @override
  String get activityRestApply => 'تطبيق';

  @override
  String get activityDialogNameTitle => 'اسم النشاط';

  @override
  String get activityDialogSaveName => 'حفظ الاسم';

  @override
  String get activityDialogRestRange => 'بين 0 و1800';

  @override
  String get activityDialogWhatToDo => 'ماذا ستفعل؟';

  @override
  String get activityDialogYourActivities => 'أنشطتك';

  @override
  String get activityDialogInstantRecord => 'تسجيل لحظي';

  @override
  String get activityDialogYourActivity => 'نشاطك';

  @override
  String get activityDialogFromCurrentWorkout => 'من التمرين الحالي';

  @override
  String activityDialogSetsProgress(
    Object done,
    Object target,
    Object repsMin,
    Object repsMax,
  ) {
    return '$done/$target مجموعات · $repsMin–$repsMax تكرارات';
  }

  @override
  String get activityDialogRepeat => 'أعد تنفيذه';

  @override
  String activityDialogRoutineSets(Object routine, int sets) {
    return '$routine · $sets مجموعات';
  }

  @override
  String get activityDialogEndTitle => 'إنهاء النشاط';

  @override
  String get activityDialogDate => 'التاريخ';

  @override
  String get activityDialogTime => 'الوقت';

  @override
  String get activityBuilderNameRequired => 'اكتب اسمًا للنشاط.';

  @override
  String get activityBuilderOnlyIntegers => 'اكتب أعدادًا صحيحة فقط.';

  @override
  String activityBuilderRange(Object what, int min, int max) {
    return '$what بين $min و$max.';
  }

  @override
  String get activityBuilderWhatDuration => 'المدة';

  @override
  String get activityBuilderWhatRest => 'الراحة';

  @override
  String get activityBuilderWhatSegments => 'الأجزاء المخططة';

  @override
  String get activityBuilderWhatCycles => 'الدورات المخططة';

  @override
  String get activityBuilderDurationRequired => 'حدد المدة بالدقائق.';

  @override
  String get activityBuilderSegmentNamesPair =>
      'حدد صيغة المفرد والجمع للجزء، أو اترك الحقلين فارغين.';

  @override
  String get activityBuilderFromTemplate => 'ابدأ من قالب';

  @override
  String get activityBuilderHowMeasured => 'كيف يُقاس؟';

  @override
  String get activityBuilderInstantTitle => 'لحظي';

  @override
  String get activityBuilderInstantDetail => 'تسجيل بدون مؤقت';

  @override
  String get activityBuilderFreeTitle => 'مفتوح';

  @override
  String get activityBuilderFreeDetail => 'ساعة إيقاف، بلا عد تنازلي';

  @override
  String get activityBuilderTimedTitle => 'بمدة محددة';

  @override
  String get activityBuilderTimedDetail => 'عد تنازلي لمدة ثابتة';

  @override
  String get activityBuilderSegmentsTitle => 'على أجزاء';

  @override
  String get activityBuilderSegmentsDetail => 'عدة أجزاء مع راحة';

  @override
  String get activityBuilderDuration => 'المدة (بالدقائق)';

  @override
  String get activityBuilderSegmentHelper => 'اختياري: لكل جزء';

  @override
  String get activityBuilderPlannedSegments => 'الأجزاء المخططة (اختياري)';

  @override
  String get activityBuilderRestBetween => 'الراحة بين الأجزاء (ثوانٍ)';

  @override
  String get activityBuilderRestHelper => '90 تعني دقيقة ونصفًا';

  @override
  String get activityBuilderPlannedCycles => 'الدورات المخططة (اختياري)';

  @override
  String get activityBuilderSegmentSingular => 'الجزء الواحد يسمى';

  @override
  String get activityBuilderSegmentPlural => 'الأجزاء المتعددة تسمى';

  @override
  String get activityBuilderWhatToNote => 'ماذا تريد أن تدوّن؟ (اختياري)';

  @override
  String activityBuilderRemoveField(Object label) {
    return 'إزالة $label';
  }

  @override
  String get activityBuilderMaxFields => 'الحد الأقصى 12 حقلًا';

  @override
  String get activityBuilderAddField => 'إضافة حقل';

  @override
  String get activityBuilderSaveInActivities => 'حفظ في أنشطتك';

  @override
  String get activityBuilderSaveInActivitiesHelp =>
      'لتكرارها دون إعادة إنشائها.';

  @override
  String get activityBuilderPrepare => 'تجهيز النشاط';

  @override
  String get activityBuilderNewField => 'حقل جديد';

  @override
  String get activityBuilderFieldNameRequired =>
      'اكتب اسم حقل من 80 حرفًا كحد أقصى.';

  @override
  String get activityBuilderFieldName => 'اسم الحقل';

  @override
  String get activityBuilderFieldType => 'النوع';

  @override
  String get activityBuilderFieldUnit => 'الوحدة (اختياري)';

  @override
  String get activityBuilderOptions => 'الخيارات';

  @override
  String get activityBuilderOptionsHelp => 'مفصولة بفواصل';

  @override
  String get activityBuilderScaleMin => 'الحد الأدنى';

  @override
  String get activityBuilderScaleMax => 'الحد الأقصى';

  @override
  String get activityBuilderScaleRange =>
      'اكتب الحد الأدنى والحد الأقصى للمقياس.';

  @override
  String get activityBuilderAggregate => 'طريقة الحساب';

  @override
  String get activityBuilderCountSingular => 'يُحسب كـ (مفرد)';

  @override
  String get activityBuilderCountSingularHelp => 'اختياري، مثلًا: كتاب';

  @override
  String get activityBuilderCountPlural => 'يُحسب كـ (جمع)';

  @override
  String get activityBuilderCountPluralHelp => 'اختياري، مثلًا: كتب';

  @override
  String get activityBuilderAdd => 'إضافة';

  @override
  String get aiPerReadError => 'تعذّرت قراءة إعدادات IA لكل مرافق.';

  @override
  String get aiPerSaveError => 'تعذّر حفظ التغيير.';

  @override
  String get aiPerTitle => 'لكل مرافق';

  @override
  String get aiPerNoProvider =>
      'اربط مزوّدًا أولًا لتتمكن من اختيار نموذج مختلف لكل مرافق.';

  @override
  String get aiPerHelp =>
      'يستخدم كل مرافق مزوّدك، أو نموذجًا خاصًا به من المزوّد نفسه.';

  @override
  String get aiPerDefault => 'افتراضي';

  @override
  String aiPerDialogTitle(Object name) {
    return 'الذكاء الاصطناعي لـ $name';
  }

  @override
  String aiPerDialogHelp(Object service) {
    return 'يستخدم $service بمفتاح ملفك الشخصي. يغيّر النموذج الخاص بهذا المرافق فقط.';
  }

  @override
  String get aiPerUseDefault => 'استخدام الإعداد الافتراضي';

  @override
  String get aiSetAndroidFileAccess =>
      'لم يتح Android الوصول إلى الملف المحدد.';

  @override
  String get aiSetGgufTitle => 'نموذج GGUF';

  @override
  String aiSetLocalContextHelp(Object context) {
    return 'توصي TrackIA بـ $context لتعليماتها وسجلها وبياناتها. التوصية تلبي احتياجات التطبيق، وليست الحد الأقصى لملف GGUF هذا. إذا لم يدعم النموذج الحجم المختار فقد يفشل؛ القرار لك في خفضه.';
  }

  @override
  String aiSetModelsCountChatGpt(int count) {
    return 'النماذج المتاحة لهذا الحساب: $count. اختبار الاتصال يؤكد الوصول إلى النموذج الذي تختاره.';
  }

  @override
  String aiSetCatalogCountApi(int count) {
    return 'تم جلب $count نموذجًا من المزوّد. يؤكد اختبار الاتصال ما إذا كان مفتاحك يستطيع استخدام النموذج الذي تختاره.';
  }

  @override
  String get aiSetCatalogErrorChatGpt =>
      'تعذّر جلب قائمة النماذج لهذا الحساب. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get aiSetCatalogErrorApi =>
      'تعذّر جلب القائمة. يمكنك المحاولة مرة أخرى أو إدخال النموذج يدويًا.';

  @override
  String get transferSheetReadError => 'تعذّرت قراءة الجدول.';

  @override
  String get transferSheetTooLarge => 'حجم الجدول يتجاوز 20 ميغابايت.';

  @override
  String get transferSheetLoadError => 'تعذّر تحميل الجدول. حاول مرة أخرى.';

  @override
  String get transferSheetLoaded =>
      'تم تحميل الجدول. في انتظار تفسيره بواسطة الذكاء الاصطناعي.';

  @override
  String get transferFileTooLarge => 'حجم الملف يتجاوز 20 ميغابايت.';

  @override
  String get transferSheetSelectedError => 'تعذّرت قراءة الجدول المحدد.';

  @override
  String get transferFileReadError => 'تعذّرت قراءة الملف أو مشاركته.';

  @override
  String get transferDefaultSheetName => 'الجدول المحمّل';

  @override
  String get transferShareSubject => 'نسخة احتياطية من TrackIA';

  @override
  String get transferShareText => 'احفظ هذا الملف في Drive أو في مكان آمن.';

  @override
  String get transferRestoreTitle => 'هل تريد استعادة هذه النسخة؟';

  @override
  String transferRestoreBody(int workouts, int routines, Object active) {
    return 'يحتوي على الجلسات: $workouts · الروتينات: $routines$active. ستستبدل جميع البيانات الموجودة حاليًا على هذا الهاتف. احفظ نسخة حالية أولًا إن أردت الاحتفاظ بها.';
  }

  @override
  String get transferRestoreActive => '، بما في ذلك جلسة قيد التنفيذ';

  @override
  String get transferRestoreAction => 'استعادة';

  @override
  String get transferRestored =>
      'تمت استعادة النسخة. تم تحديث الجلسات والروتينات.';

  @override
  String get transferNoAccessSheet =>
      'تعذّرت قراءة هذا الجدول. في Google Sheets استخدم «إرسال نسخة» بصيغة Excel أو CSV واختر TrackIA.';

  @override
  String get transferHeadline => 'سجلك، تحت سيطرتك';

  @override
  String get transferIntro =>
      'احفظ نسخة خارج هذا الهاتف لاستعادتها أو نقلها إلى هاتف آخر.';

  @override
  String get transferBackupTitle => 'نسخة احتياطية';

  @override
  String get transferBackupHelp => 'تتضمن السجل والروتينات والجلسة الجارية.';

  @override
  String get transferSheetsTitle => 'سجل Google Sheets';

  @override
  String get transferSheetsHelpAndroid =>
      'حمّل جدولك وعلامة التبويب بإذن من Google، أو اختر نسخة Excel أو CSV. تُحفظ الخلايا الأصلية، وسيتمكن الذكاء الاصطناعي من تفسير تنسيقك عند الاتصال.';

  @override
  String get transferSheetsHelpOther =>
      'حمّل نسخة Excel أو CSV. تُحفظ الخلايا الأصلية، في انتظار تفسيرها بواسطة الذكاء الاصطناعي.';

  @override
  String get transferImportSheets => 'استيراد من Google Sheets';

  @override
  String get transferChooseFileAndroid => 'اختر ملفًا من الهاتف أو Drive';

  @override
  String get transferChooseFileOther => 'اختر نسخة XLSX أو CSV';

  @override
  String transferWorkoutSubtitle(Object date, int exercises, int sets) {
    return '$date · $exercises تمارين · $sets مجموعات';
  }

  @override
  String get transferNoColumnWorkout => 'بدون عمود · التدريب';

  @override
  String get transferChooseColumn => 'اختر عمودًا';

  @override
  String get transferCsvReviewError => 'تعذّر فحص ملف CSV.';

  @override
  String get transferImportSessionsTitle => 'هل تريد استيراد هذه الجلسات؟';

  @override
  String transferImportSessionsBody(int count, int sets, int errors) {
    return 'ستتم إضافة الجلسات: $count مع المجموعات: $sets. الصفوف المتخطاة بسبب أخطاء: $errors.';
  }

  @override
  String get transferImportAction => 'استيراد';

  @override
  String get transferImportError => 'تعذّر الاستيراد.';

  @override
  String get transferImportSheetTitle => 'استيراد الجدول';

  @override
  String transferImportedSummary(int added, int duplicates) {
    return 'الجلسات المضافة: $added · المكررات المتخطاة: $duplicates';
  }

  @override
  String transferRowsFound(int count) {
    return 'تم العثور على $count صفًا';
  }

  @override
  String get transferMapHelp => 'طابق أعمدة جدولك. كل صف يمثل مجموعة واحدة.';

  @override
  String get transferDate => 'التاريخ';

  @override
  String get transferSessionOptional => 'الجلسة (اختياري)';

  @override
  String get transferExercise => 'التمرين';

  @override
  String get transferWeightKg => 'الوزن (كجم)';

  @override
  String get transferReps => 'التكرارات';

  @override
  String get transferReviewImport => 'مراجعة الاستيراد';

  @override
  String transferPreviewSummary(
    int newCount,
    int duplicateCount,
    int errorCount,
  ) {
    return 'جلسات جديدة: $newCount · مكررة: $duplicateCount · صفوف بها أخطاء: $errorCount';
  }

  @override
  String transferValidRows(int valid, int total) {
    return '$valid مجموعة صالحة من $total صفًا.';
  }

  @override
  String get transferAllSessions => 'كل الجلسات';

  @override
  String transferSeeSessions(int count) {
    return 'عرض $count جلسة';
  }

  @override
  String get transferErrorRows => 'صفوف بها أخطاء';

  @override
  String transferSeeErrors(int count) {
    return 'عرض $count خطأ';
  }

  @override
  String get transferImportNew => 'استيراد الجلسات الجديدة';

  @override
  String get transferCloseAction => 'إغلاق';

  @override
  String get chatAttachVoiceError =>
      'تعذّر التعرّف على الصوت. تحقّق من إذن الميكروفون أو اكتب رسالتك.';

  @override
  String get chatAttachVoiceUnavailable =>
      'التعرّف على الصوت غير متاح. تحقّق من إذن الميكروفون وخدمة الصوت في الهاتف.';

  @override
  String get chatAttachDictationStart => 'تعذّر بدء الإملاء الصوتي.';

  @override
  String get chatAttachCamera => 'الكاميرا';

  @override
  String get chatAttachPhotos => 'الصور';

  @override
  String get chatAttachPdf => 'مستند PDF';

  @override
  String get chatAttachPdfHint => 'يحتاج نموذجًا يدعم المستندات';

  @override
  String get chatAttachAudio => 'ملف صوتي';

  @override
  String get chatAttachAudioHint => 'يتطلب نموذج Gemini يدعم الصوت';

  @override
  String get chatAttachSpreadsheet => 'جدول Excel أو CSV';

  @override
  String get chatAttachSheet => 'Google Sheets / Drive';

  @override
  String get chatAttachNeedsAi =>
      'صل الذكاء الاصطناعي لإرسال الصور أو المستندات أو الصوت. يمكنك تحميل جدول بدون ذكاء اصطناعي.';

  @override
  String get chatAttachPhotoTooLarge => 'الصورة أكبر من 4 MB.';

  @override
  String get chatAttachPhotoFormat => 'اختر صورة بصيغة JPG أو PNG أو WebP.';

  @override
  String get chatAttachPhotoEmpty =>
      'يجب أن تحتوي الصورة على محتوى ولا تتجاوز 4 MB.';

  @override
  String get chatAttachAudioNeedsGemini =>
      'لإرسال ملف صوتي، اضبط نموذج Gemini يدعم الصوت. يمكنك استخدام ميكروفون الدردشة لإملاء رسالتك.';

  @override
  String get chatAttachTooLarge => 'المرفق أكبر من 4 MB.';

  @override
  String get chatAttachUnreadable => 'تعذّرت قراءة المرفق.';

  @override
  String get chatAttachFormat => 'صيغة المرفق غير مدعومة.';

  @override
  String get chatAttachInvalidPdf => 'الملف لا يحتوي على PDF صالح.';

  @override
  String get chatAttachOpenFailed => 'تعذّر فتح المرفق.';

  @override
  String get chatAttachRecoveredTooLarge =>
      'الصورة المستعادة أكبر من 4 MB. اختر صورة أصغر.';

  @override
  String get chatMenuCompanionsError => 'تعذّر تحميل المرافقين.';

  @override
  String get chatMenuMore => 'خيارات إضافية';

  @override
  String get chatMenuTraining => 'الروتينات والسجل';

  @override
  String get chatMenuProgress => 'التقدم';

  @override
  String get chatMenuSheet => 'الجدول المحمّل';

  @override
  String get chatMenuRecover => 'استعادة التحضير';

  @override
  String get chatSendFocusTooLong => 'السجل يتجاوز 8000 حرف.';

  @override
  String get chatSendSavedNoAi =>
      'تم حفظ السجل على الهاتف. الذكاء الاصطناعي غير متاح لتفسيره.';

  @override
  String get chatSendSavedNoProvider =>
      'تم حفظ السجل على الهاتف. اضبط المزوّد لاستشارة المساعد.';

  @override
  String get chatSendAssistantError =>
      'تعذّر الاتصال بالمساعد. راجع السجل المحلي.';

  @override
  String get chatSendQueueUnavailable =>
      'طابور الإرسال الدائم غير متاح. احتفظ بالنص وأعد فتح الدردشة.';

  @override
  String get chatSendTooLong => 'الرسالة تتجاوز 8000 حرف.';

  @override
  String get chatSendConfigureProvider => 'اضبط المزوّد بزر الإعدادات للبدء.';

  @override
  String get chatSendSaveError =>
      'تعذّر حفظ الرسالة على الهاتف. احتفظ بالنص وحاول مرة أخرى.';

  @override
  String get chatSendProposalIncomplete =>
      'أرسل النموذج اقتراحًا غير مكتمل. اطلب منه إعداد التمرين مرة أخرى ليظهر زر البدء.';

  @override
  String get chatSendAnswerSaveError =>
      'وصل الرد، لكن تعذّر حفظ المحادثة على الهاتف.';

  @override
  String get chatSendFailed => 'تعذّر إكمال المحادثة. يمكنك المحاولة مرة أخرى.';

  @override
  String get chatMsgOnlyLastEditable =>
      'يمكن تعديل آخر رسالة فقط. اكتب التصحيح كرسالة جديدة.';

  @override
  String get chatMsgPending => 'في انتظار الإرسال';

  @override
  String get chatMsgSending => 'جارٍ الإرسال';

  @override
  String get chatMsgAnswered => 'تم الرد';

  @override
  String get chatMsgFailed => 'لم يُقبل؛ يمكنك إعادة الإرسال';

  @override
  String get chatMsgUncertain =>
      'نتيجة غير مؤكدة؛ إعادة الإرسال محظورة حتى المراجعة';

  @override
  String get chatMsgHistory => 'السجل';

  @override
  String get chatMsgResend => 'إعادة الإرسال';

  @override
  String get chatMsgAiNotReady => 'الذكاء الاصطناعي غير جاهز.';

  @override
  String get chatMsgSendInProgress => 'هناك إرسال جارٍ.';

  @override
  String get chatMsgChangedWhileEditing =>
      'تغيّرت الرسالة أثناء التعديل. راجع السجل.';

  @override
  String get chatMsgSaveNotSent =>
      'تم حفظ التعديل، لكن تعذّر إرساله الآن. استخدم إعادة الإرسال عندما تستطيع.';

  @override
  String get chatMsgSavedOnly =>
      'تم حفظ التعديل. استخدم إعادة الإرسال لإرسال هذه النسخة.';

  @override
  String get chatMsgLengthError => 'اكتب رسالة من 1 إلى 8000 حرف.';

  @override
  String get chatMsgEditError => 'تعذّر حفظ التعديل؛ يُحتفظ بالأصل.';

  @override
  String get chatMsgHistoryTitle => 'سجل النسخ';

  @override
  String chatMsgVersion(int n) {
    return 'النسخة $n';
  }

  @override
  String chatMsgVersionCurrent(int n) {
    return 'النسخة $n · الحالية';
  }

  @override
  String get chatMsgClose => 'إغلاق';

  @override
  String get chatMsgHistoryError => 'تعذّر فتح السجل.';

  @override
  String get chatMsgEditTitle => 'تعديل الرسالة';

  @override
  String get chatMsgEditLabel => 'النص المصحح';

  @override
  String get chatMsgEditHelper => 'تُحفظ النسخة الأصلية في السجل.';

  @override
  String chatMsgSendBlocked(Object reason) {
    return 'لا يمكن الإرسال الآن: $reason';
  }

  @override
  String get chatMsgSaveAndSend => 'حفظ وإرسال';

  @override
  String get chatSheetReloadError => 'تعذّر استعادة الجدول المحمّل.';

  @override
  String get chatSheetAndroidOnly => 'الاتصال بجداول Google متاح على Android.';

  @override
  String get chatSheetSaveError =>
      'تعذّر حفظ الجدول على الهاتف. تُحفظ النسخة السابقة.';

  @override
  String get chatSheetInterpretPending =>
      'وصل الرد، لكن الجدول ما زال بانتظار التفسير على الهاتف.';

  @override
  String get chatSheetRefreshError =>
      'تعذّر تحديث الجدول. تُحفظ النسخة السابقة.';

  @override
  String get chatSheetRemoveError => 'تعذّر إزالة نسخة الجدول.';

  @override
  String chatSheetDialogBody(
    Object title,
    int rows,
    Object date,
    Object status,
  ) {
    return '$title · $rows صف\nآخر قراءة: $date.\n\n$status';
  }

  @override
  String get chatSheetStatusPending =>
      'بانتظار تفسير الذكاء الاصطناعي. لم يتم استيراد أي تدريبات.';

  @override
  String get chatSheetStatusAnalyzed =>
      'حلّل المساعد هذه النسخة؛ لم يتم استيراد أي تدريبات.';

  @override
  String get chatSheetRemove => 'إزالة من السياق';

  @override
  String get chatSheetChange => 'تغيير الجدول';

  @override
  String get chatSheetRefresh => 'تحديث الجدول';

  @override
  String chatSheetLabel(Object title) {
    return 'الجدول · $title';
  }

  @override
  String chatProposalRepeated(int seconds) {
    return 'مجموعات / فترات · راحة $seconds ث';
  }

  @override
  String chatProposalContinuous(int seconds) {
    return 'نشاط متواصل · راحة $seconds ث';
  }

  @override
  String chatSheetPendingInfo(Object name) {
    return '«$name» محمّل · بانتظار التفسير. تُحفظ البيانات الأصلية.';
  }

  @override
  String get chatGameFocusOpen =>
      'أنهِ النشاط المفتوح مع المرافق الآخر قبل تحضير هذا.';

  @override
  String get chatGamePrepareError => 'تعذّر تحضير النشاط. حاول مرة أخرى.';

  @override
  String chatGameGoalTitle(Object goal) {
    return 'هدف مقترح: $goal';
  }

  @override
  String chatGameAchievementTitle(Object title) {
    return 'إنجاز مقترح: $title';
  }

  @override
  String get chatGameCopyTitle => 'نصوص تذكير مقترحة';

  @override
  String get chatDeliveryQueueError =>
      'تعذّر فتح طابور الدردشة الدائم. لن تُرسل الرسائل عبر تخزين بديل.';

  @override
  String get chatDeliveryRestoredPending =>
      'حُفظت رسالتك بدون رد. يمكنك إرسالها مرة أخرى.';

  @override
  String get chatDeliveryUncertain =>
      'هناك إرسال بنتيجة غير مؤكدة. لن يُعاد إرساله تلقائيًا؛ راجع السجل قبل القرار.';

  @override
  String get chatDeliveryBacklog =>
      'لديك رسائل محفوظة بلا رد. استخدم إعادة الإرسال عندما تريد؛ لن تُرسل تلقائيًا.';

  @override
  String get chatDeliveryOtherChat =>
      'الرسالة تنتمي إلى دردشة أخرى ولن تُرسل هنا.';

  @override
  String get chatDeliveryNotSafe => 'إعادة إرسال هذه الرسالة غير آمنة.';

  @override
  String get chatDeliveryStateChanged =>
      'تغيّرت حالة الرسالة بالفعل؛ لم يُجرَ إرسال آخر.';

  @override
  String get chatDeliveryUncertainSend =>
      'نتيجة الإرسال غير مؤكدة. لن يُعاد إرساله تلقائيًا؛ تحقّق مما إذا وصل رد.';

  @override
  String get chatDeliveryFailed =>
      'تعذّر إكمال المحادثة. تبقى الرسالة محفوظة ولن يُعاد إرسالها تلقائيًا.';

  @override
  String get chatArchiveIncompleteDirective =>
      'طلب النموذج الأرشفة ببيانات ناقصة. تبقى الدردشة مفتوحة.';

  @override
  String get chatArchiveDoneAuto =>
      'أرشف المساعد الدردشة. يمكنك عرضها في الدردشات المؤرشفة.';

  @override
  String get chatArchiveDone => 'تمت أرشفة الدردشة. تم تحرير السياق النشط.';

  @override
  String get chatArchiveViewAction => 'عرض الأرشيف';

  @override
  String get chatArchiveError => 'تعذّرت الأرشفة. تُحفظ المحادثة والتدريبات.';

  @override
  String get chatArchiveSyncInvalid =>
      'اقتراح الإرسال غير صالح. استخدم خيار «إرسال إلى Google Sheets» في القائمة.';

  @override
  String get chatArchiveRecalled => 'الأرشيف متاح لرسالتك التالية إلى المساعد.';

  @override
  String get chatArchiveReadError => 'تعذّر فتح الأرشيف.';

  @override
  String get chatDraftSaveError =>
      'تعذّر حفظ المسودة. احتفظ بالنص وحاول مرة أخرى.';

  @override
  String get chatLoadError => 'تعذّر استعادة المحادثة السابقة.';

  @override
  String get chatLoadSheetError =>
      'تعذّر استعادة الجدول المحفوظ. أعد تحميله من Google Sheets.';

  @override
  String get chatPersistTooLarge => 'الدردشة تتجاوز 20 MB؛ تعذّر حفظها كاملة.';

  @override
  String get creatorCreate => 'إنشاء';

  @override
  String get creatorCreateFailed => 'تعذّر إنشاء الرفيق. لم يُحفظ أي شيء.';

  @override
  String get creatorAssistedTitle => 'الإنشاء بمساعدة الذكاء الاصطناعي';

  @override
  String get creatorAiTitle => 'بمساعدة الذكاء الاصطناعي';

  @override
  String get creatorAiReadySubtitle =>
      'أخبره بما تريد متابعته وسيقترح عليك رفيقًا.';

  @override
  String get creatorAiNotReadySubtitle =>
      'عليك ربط مزوّد ذكاء اصطناعي والتحقق منه.';

  @override
  String get creatorOpenAiSettings => 'فتح إعدادات الذكاء الاصطناعي';

  @override
  String get creatorManualTitle => 'يدويًا';

  @override
  String get creatorManualSubtitle =>
      'اختر الاسم والأيقونة واللون والوضع والتنبيه بنفسك.';

  @override
  String get creatorNewTitle => 'رفيق جديد';

  @override
  String get creatorEditProposalTitle => 'تعديل الاقتراح';

  @override
  String get creatorNameLength => 'اكتب اسمًا من 1 إلى 40 حرفًا.';

  @override
  String get creatorLevelReminderTitle => 'تذكير فقط';

  @override
  String get creatorLevelReminderDetail => 'يذكّرك فقط.';

  @override
  String get creatorLevelGoalsTitle => 'الأهداف والسلاسل';

  @override
  String get creatorLevelGoalsDetail =>
      'موصى به: الأهداف والسلاسل بلا إنجازات.';

  @override
  String get creatorLevelGameTitle => 'اللعبة الكاملة';

  @override
  String get creatorLevelGameDetail => 'أهداف وسلاسل وإنجازات.';

  @override
  String creatorActivityLabel(Object name) {
    return 'ما تسجّله: $name';
  }

  @override
  String get creatorRemoveActivity => 'إزالة النشاط';

  @override
  String creatorGoalLabel(Object text) {
    return 'الهدف: $text';
  }

  @override
  String get creatorRemoveGoal => 'إزالة الهدف';

  @override
  String get creatorRemind => 'ذكّرني';

  @override
  String get creatorDecideOnStart => 'تحدده عند البدء';

  @override
  String get creatorPunctualSuffix => ' · تسجيل لمرة واحدة';

  @override
  String get creatorNoGoal => 'بلا هدف';

  @override
  String get creatorNoReminder => 'بلا تنبيه';

  @override
  String creatorReminderLabel(Object text) {
    return 'التنبيه: $text';
  }

  @override
  String creatorLevelLabel(Object text) {
    return 'المستوى: $text';
  }

  @override
  String get creatorDiscard => 'تجاهل';

  @override
  String get creatorNoAiConnected => 'لا يوجد ذكاء اصطناعي متصل.';

  @override
  String get creatorConversationFailed =>
      'تعذّر إكمال المحادثة. يمكنك المحاولة مرة أخرى.';

  @override
  String get creatorInputHint => 'اكتب هنا';

  @override
  String get creatorPromptHelper => 'تُستخدم عند ربط مزوّد.';

  @override
  String get creatorLevelSection => 'المستوى';

  @override
  String get proposalIgnore => 'تجاهل';

  @override
  String get proposalAdd => 'إضافة';

  @override
  String get proposalUseTexts => 'استخدام هذه النصوص';

  @override
  String get proposalSuggestLater => 'ليس الآن';

  @override
  String get proposalSuggestNever => 'عدم الاقتراح مرة أخرى';

  @override
  String get proposalLockedTitle =>
      'اقتراح الذكاء الاصطناعي حول بيانات ثبّتها بنفسك';

  @override
  String get proposalApply => 'تطبيق';

  @override
  String proposalChangeLine(
    Object label,
    int current,
    Object unit,
    int proposed,
  ) {
    return '$label: $current $unit → $proposed $unit';
  }

  @override
  String get proposalLockLabel => 'ثبّتّه أنت. المس لإلغاء التثبيت';

  @override
  String get homeNewWorkoutTitle => 'جلسة تدريب جديدة';

  @override
  String get homeSessionNameLabel => 'اسم الجلسة';

  @override
  String get homeWorkout => 'جلسة تدريب';

  @override
  String get homeAddExerciseTitle => 'إضافة تمرين';

  @override
  String get homeExerciseNameLabel => 'اسم التمرين';

  @override
  String get homeAdd => 'إضافة';

  @override
  String get homeBack => 'رجوع';

  @override
  String get homeYourSession => 'جلستك';

  @override
  String get homeAssistantTooltip => 'مساعد TrackIA';

  @override
  String get homeReload => 'إعادة التحميل';

  @override
  String get homeLoadLog => 'تحميل السجل';

  @override
  String get homeHeroTitle => 'جهدك.\nتقدّمك.';

  @override
  String get homeHeroSubtitle => 'مجموعة واحدة في كل مرة. سجّل ما تفعله اليوم.';

  @override
  String get homeNextSession => 'جلستك القادمة';

  @override
  String get homeInProgress => 'الجلسة جارية';

  @override
  String get homeReadyQuestion => 'هل نتدرّب؟';

  @override
  String get homeAddExercisesHint => 'أضف تمارينك وسجّل كل مجموعة.';

  @override
  String homeActivitiesRecords(int activities, int records) {
    return 'الأنشطة: $activities · السجلات: $records';
  }

  @override
  String get homeStartWorkout => 'بدء التدريب';

  @override
  String get homeContinueWorkout => 'متابعة التدريب';

  @override
  String get homeCompletedSessions => 'جلسات مكتملة';

  @override
  String get homeRecords => 'سجلات';

  @override
  String get homeLastActivity => 'آخر نشاط';

  @override
  String get homeEmptyHistoryTitle => 'هنا تبدأ قصتك';

  @override
  String get homeEmptyHistorySubtitle => 'سيظهر تدريبك الأول هنا عندما تنهيه.';

  @override
  String get homeSavedOffline => 'محفوظ على هذا الجهاز · بلا اتصال';

  @override
  String get homeJourneyTitle => 'رحلتك';

  @override
  String get homeEverySessionCounts => 'كل جلسة تُحتسب.';

  @override
  String get homeNoSessionsTitle => 'لا توجد جلسات بعد';

  @override
  String get homeNoSessionsSubtitle =>
      'أنهِ تدريبًا وراجع هنا جميع تمارينه ومجموعاته.';

  @override
  String get homeStatusInProgress => 'جارٍ';

  @override
  String get homeStatusCompleted => 'مكتمل';

  @override
  String homeFinishedAt(Object date) {
    return 'انتهت: $date';
  }

  @override
  String homeFinishRecorded(Object date) {
    return 'تم تسجيل الإنهاء: $date';
  }

  @override
  String homeFinishRecordedByUser(Object date) {
    return 'تم تسجيل الإنهاء: $date · وقت اخترته بنفسك';
  }

  @override
  String get homeTimeKeptWarning =>
      'تم حفظ الوقت مع تنبيه. يمكنك مراجعته لاحقًا.';

  @override
  String get homeTimeKeptWarningShort => 'تم حفظ الوقت مع تنبيه.';

  @override
  String get homeActivities => 'أنشطة';

  @override
  String homeIntervalsRepeated(int count) {
    return 'المجموعات / المقاطع: $count';
  }

  @override
  String homeIntervals(int count) {
    return 'المقاطع: $count';
  }

  @override
  String get homeNotStarted => 'لم تبدأ';

  @override
  String homeEndedAt(Object date) {
    return 'النهاية: $date';
  }

  @override
  String homeDraft(Object draft) {
    return 'مسودة: $draft';
  }

  @override
  String get homeFinishWorkout => 'إنهاء التدريب';

  @override
  String get homeAddSetToFinish =>
      'سجّل مجموعة واحدة على الأقل لإنهاء التدريب.';

  @override
  String get homeEachSetSaved => 'تُحفظ كل مجموعة عند الضغط على حفظ.';

  @override
  String get homeDiscardTitle => 'هل تريد تجاهل الجلسة؟';

  @override
  String get homeDiscardBody =>
      'ستُحذف هذه الجلسة وجميع مجموعاتها. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get homeDiscard => 'تجاهل';

  @override
  String get homeDiscardSession => 'تجاهل الجلسة';

  @override
  String get homeSavedWellDone => 'تم حفظ الجلسة. أحسنت.';

  @override
  String get homeViewHistory => 'عرض السجل';

  @override
  String homeDeleteExerciseTooltip(Object name) {
    return 'حذف التمرين $name';
  }

  @override
  String get homeDeleteExerciseTitle => 'هل تريد حذف التمرين؟';

  @override
  String homeDeleteExerciseBody(Object name, int count) {
    return 'سيُحذف $name وعدد المجموعات: $count.';
  }

  @override
  String get homeDelete => 'حذف';

  @override
  String homeTargetProgress(
    int done,
    int target,
    Object repsMin,
    Object repsMax,
  ) {
    return 'المجموعات المسجّلة: $done من $target · $repsMin–$repsMax تكرار';
  }

  @override
  String get homeNoPreviousSession => 'لا توجد جلسة سابقة مسجّلة';

  @override
  String homeLastTime(Object date) {
    return 'آخر مرة · $date';
  }

  @override
  String get homeNoSetsYet => 'لم تسجّل أي مجموعات بعد.';

  @override
  String get homeSetHeader => 'المجموعة';

  @override
  String get homeKgHeader => 'كغ';

  @override
  String get homeRepsHeader => 'التكرارات';

  @override
  String homeSetOptionsTooltip(int number) {
    return 'خيارات المجموعة $number';
  }

  @override
  String homeSetDeleteBody(Object weight, int reps) {
    return '$weight كغ × التكرارات: $reps.';
  }

  @override
  String homeWeightReps(Object weight, int reps) {
    return '$weight كغ × $reps';
  }

  @override
  String get homeEditSet => 'تعديل المجموعة';

  @override
  String get homeDeleteSet => 'حذف المجموعة';

  @override
  String get homeAddSet => 'إضافة مجموعة';

  @override
  String homeRest(int seconds) {
    return 'راحة $seconds ث';
  }

  @override
  String get homeFirstSetTitle => 'جهّز مجموعتك الأولى';

  @override
  String get homeFirstSetSubtitle =>
      'أضف تمرينًا لتبدأ بتسجيل الوزن والتكرارات.';

  @override
  String get homeFinishSession => 'إنهاء الجلسة';

  @override
  String get homeTabToday => 'اليوم';

  @override
  String get homeTabRoutines => 'الروتينات';

  @override
  String get homeTabHistory => 'السجل';

  @override
  String get homeSessionStarted =>
      'بدأت الجلسة. يمكنك فتح قسم التدريب للتسجيل.';

  @override
  String get homeSessionStartFailed => 'تعذّر بدء التدريب.';

  @override
  String get homeActiveSessionChanged => 'تغيّرت الجلسة النشطة. راجعها.';

  @override
  String get homeSavedSheetPending =>
      'تم حفظ التدريب على الهاتف. إرسال البيانات إلى Google Sheets بانتظار التأكيد.';

  @override
  String get homeSavedSheetNotUpdated =>
      'تم حفظ التدريب على الهاتف. لم يتم تحديث Google Sheets.';

  @override
  String get homeFinishFailed => 'تعذّر إنهاء التدريب.';

  @override
  String get homeReviewFinishTitle => 'مراجعة وقت الانتهاء';

  @override
  String homeFinishIssuesBody(Object issues) {
    return '$issues\n\nهل تريد حفظ الوقت المختار كما هو؟ ستُحفظ السجلات لمراجعتها لاحقًا إن رغبت.';
  }

  @override
  String get homeBackAndFix => 'رجوع وتصحيح';

  @override
  String get homeSaveThatTime => 'حفظ ذلك الوقت';

  @override
  String get homeDate => 'التاريخ';

  @override
  String get homeTime => 'الوقت';

  @override
  String get homeStartSession => 'بدء الجلسة';

  @override
  String get homeOptionYes => 'نعم';

  @override
  String get homeOptionNo => 'لا';

  @override
  String get homeBoolYes => 'نعم';

  @override
  String get homeBoolNo => 'لا';

  @override
  String get homeNoteOptional => 'ملاحظة (اختياري)';

  @override
  String homeNumberInvalid(Object label) {
    return '$label: اكتب رقمًا.';
  }

  @override
  String get homeNoteOrValueRequired => 'أدخل قيمة أو اكتب ملاحظة.';

  @override
  String get homeSessionFinished => 'انتهت الجلسة';

  @override
  String get homeSummaryEmpty => 'لا جديد هذه المرة. نواصل.';

  @override
  String get homeNewAchievement => 'إنجاز جديد';

  @override
  String get homeDone => 'تم';

  @override
  String get homeSuggestionSquat => 'القرفصاء';

  @override
  String get homeSuggestionBench => 'ضغط المقعد';

  @override
  String get homeSuggestionRow => 'تجديف';

  @override
  String get homeNewSet => 'مجموعة جديدة';

  @override
  String get homeWeightLabel => 'الوزن (كغ)';

  @override
  String get homeWeightHint => 'مثال: 20.5';

  @override
  String get homeRepsLabel => 'التكرارات';

  @override
  String get homeRepsHint => 'مثال: 10';

  @override
  String get homeZeroWeightHint => 'استخدم 0 كغ إذا كنت تتدرّب بدون وزن خارجي.';

  @override
  String get homeExercisesLabel => 'التمارين';

  @override
  String get homeDeleteSetTitle => 'هل تريد حذف المجموعة؟';

  @override
  String get accountsConnectError => 'تعذّر الاتصال بجوجل.';

  @override
  String get accountsSwitchError => 'تعذّر تبديل الحساب. بياناتك محفوظة.';

  @override
  String get accountsDescription =>
      'لكل حساب محادثته وإعدادات الذكاء الاصطناعي وجدوله وتدريباته على هذا الهاتف. يبقى السجل السابق في الملف المحلي. الربط لا ينسخ هذه البيانات ولا يرفعها.';

  @override
  String get accountsConnectAnother => 'ربط حساب Google آخر';

  @override
  String get accountsActiveProfile => 'الملف النشط';

  @override
  String get accountsReconnectProfile => 'العودة إلى هذا الملف عبر Google';

  @override
  String get accountsDisconnect => 'قطع الاتصال والعودة إلى الملف المحلي';

  @override
  String get accountsDisconnectNotice =>
      'قطع الاتصال يحتفظ ببيانات كل ملف على هذا الهاتف. لا يحذف ملفات Google ولا يلغي الوصول من حسابك في Google.';

  @override
  String get appearanceSaveError => 'تعذّر حفظ السمة. حاول مرة أخرى.';

  @override
  String get appearanceIntro =>
      'اختر الطريقة التي تفضّل بها رؤية TrackIA. يُحفظ اختيارك على هذا الهاتف.';

  @override
  String get appearanceSystemHint => 'استخدام سمة الجهاز';

  @override
  String get archiveSearchLabel => 'البحث بالعنوان أو الملخص';

  @override
  String get archiveRecoverError => 'تعذّر استرجاع المحادثة. الأرشيف محفوظ.';

  @override
  String get archiveEmpty => 'لا توجد محادثات مؤرشفة بعد.';

  @override
  String archiveChatSubtitle(Object date, Object count) {
    return '$date · عدد الرسائل: $count';
  }

  @override
  String get archiveAutomaticTag => 'أرشفه المساعد';

  @override
  String get archiveContinuityTitle => 'ملخص الاستمرارية';

  @override
  String archiveReasonLine(Object reason) {
    return 'سبب المساعد: $reason';
  }

  @override
  String get archiveConsultFromChat => 'الاستعلام من المحادثة';

  @override
  String get archiveYou => 'أنت';

  @override
  String archiveAttachmentKept(Object name) {
    return 'المرفق المحفوظ: $name';
  }

  @override
  String get notifUnsupported => 'تنبيهات الراحة متاحة على Android فقط.';

  @override
  String get notifDndActive => 'وضع عدم الإزعاج مفعّل';

  @override
  String get notifDndTotalSilence =>
      'أنت في وضع «الصمت التام»: يحظر Android التنبيهات، حتى بوصفها منبهات.';

  @override
  String get notifDndAlarm =>
      'تنبيهات الراحة تُسمع كمنبه. التنبيهات الأخرى لن تُسمع ولن تهتز.';

  @override
  String get notifDndPlain =>
      'في الوقت الحالي لن تُسمع تنبيهات الراحة ولن تهتز.';

  @override
  String get notifEnabledTitle => 'تنبيهات النشاط والراحة';

  @override
  String get notifEnabledSubtitle =>
      'النشاط جاهز، والمقطع جارٍ، ونهاية المقطع، ونهاية الراحة.';

  @override
  String get notifAlarmStyleTitle => 'التعامل معها كمنبه';

  @override
  String get notifAlarmStyleSubtitle =>
      'تُسمع نهايات الراحة والمقاطع وتهتز حتى إن كان وضع عدم الإزعاج على الأولوية.';

  @override
  String get notifChannelBlockedTitle => 'يحظر Android قناة المنبه';

  @override
  String get notifChannelBlockedSubtitle => 'فعّلها من إعدادات القناة.';

  @override
  String get notifExactTitle => 'السماح بالتنبيهات الدقيقة';

  @override
  String get notifExactSubtitle => 'بدون هذا الإذن قد يؤخر Android التنبيه.';

  @override
  String get notifCheck => 'التحقق';

  @override
  String get notifTest => 'اختبار التنبيه';

  @override
  String get notifTestAlarm => 'اختبار مع تفعيل عدم الإزعاج';

  @override
  String get notifOpenDnd => 'فتح إعدادات عدم الإزعاج';

  @override
  String get notifSilenceNote =>
      'في «الصمت التام» يحظر Android كل شيء، بما في ذلك المنبهات. وهناك لا يفيد إلا السماح بها من إعدادات هاتفك.';

  @override
  String get progressLoadError => 'تعذّر حساب التقدم.';

  @override
  String get progressMonth1 => 'يناير';

  @override
  String get progressMonth2 => 'فبراير';

  @override
  String get progressMonth3 => 'مارس';

  @override
  String get progressMonth4 => 'أبريل';

  @override
  String get progressMonth5 => 'مايو';

  @override
  String get progressMonth6 => 'يونيو';

  @override
  String get progressMonth7 => 'يوليو';

  @override
  String get progressMonth8 => 'أغسطس';

  @override
  String get progressMonth9 => 'سبتمبر';

  @override
  String get progressMonth10 => 'أكتوبر';

  @override
  String get progressMonth11 => 'نوفمبر';

  @override
  String get progressMonth12 => 'ديسمبر';

  @override
  String progressDayStatus(int day, Object month, Object status) {
    return '$day $month: $status';
  }

  @override
  String get progressDayDone => 'تم';

  @override
  String get progressDayPending => 'معلّق';

  @override
  String get progressDayMissed => 'لم يتم';

  @override
  String progressTitle(Object name) {
    return 'التقدم · $name';
  }

  @override
  String progressStreakCurrent(int n) {
    return 'السلسلة الحالية (أيام): $n';
  }

  @override
  String progressStreakBest(int best) {
    return 'أفضل سلسلة: $best';
  }

  @override
  String progressFreeDays(int used, int total) {
    return 'أيام الراحة هذا الأسبوع: $used/$total';
  }

  @override
  String get progressGoalToday => 'هدف اليوم';

  @override
  String get progressGoalWeek => 'هدف الأسبوع';

  @override
  String progressGoalValues(Object value, Object target) {
    return '$value من $target';
  }

  @override
  String get progressLastFourWeeks => 'آخر 4 أسابيع';

  @override
  String progressAchievementUnlocked(Object title) {
    return '$title، تم فتحه';
  }

  @override
  String progressAchievementLocked(Object title, int percent) {
    return '$title، مقفل، تقدم $percent%';
  }

  @override
  String progressAchievementsTitle(int unlocked, int total) {
    return 'الإنجازات · $unlocked من $total';
  }

  @override
  String get progressAchievementsEmptyPlay =>
      'ستظهر إنجازاتك عند إنهاء نشاطك الأول.';

  @override
  String progressAchievementsEmptyEnable(Object place) {
    return 'فعّل وضع اللعب والإنجازات من «$place».';
  }

  @override
  String get routinesTitle => 'روتيناتك';

  @override
  String get routinesSubtitle => 'جهّز مرة واحدة. تدرّب بإيقاعك.';

  @override
  String get routinesCreate => 'إنشاء روتين';

  @override
  String get routinesEmptyTitle => 'جلستك القادمة، جاهزة';

  @override
  String get routinesEmptyBody =>
      'أنشئ مثلاً «الساق A» مع تمارينك ومجموعاتك ونطاق تكراراتك.';

  @override
  String routinesOptionsTooltip(Object name) {
    return 'خيارات $name';
  }

  @override
  String get routinesDeleteTitle => 'حذف الروتين؟';

  @override
  String routinesDeleteBody(Object name) {
    return 'سيُحذف «$name». ستبقى تدريباتك المحفوظة والجلسة الجارية.';
  }

  @override
  String get routinesEditMenu => 'تعديل الروتين';

  @override
  String get routinesDeleteMenu => 'حذف الروتين';

  @override
  String get routinesDelete => 'حذف';

  @override
  String get routinesTrain => 'تدرّب';

  @override
  String get routinesContinueSession => 'متابعة الجلسة النشطة';

  @override
  String get routinesNeedExercise => 'أضف تمريناً واحداً على الأقل.';

  @override
  String get routinesNameLabel => 'اسم الروتين';

  @override
  String get routinesNameHint => 'مثال: الساق A';

  @override
  String get routinesEditorHelp =>
      'حدّد أهدافك. ستُسجَّل المجموعات عند التدريب.';

  @override
  String routinesMoveUp(int n) {
    return 'نقل التمرين $n للأعلى';
  }

  @override
  String routinesMoveDown(int n) {
    return 'نقل التمرين $n للأسفل';
  }

  @override
  String routinesEditExercise(int n) {
    return 'تعديل التمرين $n';
  }

  @override
  String routinesRemoveExercise(int n) {
    return 'إزالة التمرين $n';
  }

  @override
  String get routinesAddExercise => 'إضافة تمرين إلى الروتين';

  @override
  String get routinesSaving => 'جارٍ الحفظ…';

  @override
  String get routinesSave => 'حفظ الروتين';

  @override
  String get routinesLeaveTitle => 'الخروج دون حفظ؟';

  @override
  String get routinesLeaveBody => 'ستُفقد التغييرات على هذا الروتين.';

  @override
  String get routinesKeepEditing => 'متابعة التعديل';

  @override
  String get routinesDiscard => 'تجاهل التغييرات';

  @override
  String get routinesBack => 'رجوع';

  @override
  String get routinesExerciseDialogTitle => 'تمرين الروتين';

  @override
  String get routinesEditTargetTitle => 'تعديل الهدف';

  @override
  String get routinesExerciseLabel => 'التمرين';

  @override
  String get routinesExerciseHint => 'مثال: القرفصاء';

  @override
  String get routinesTargetSets => 'المجموعات المخططة';

  @override
  String get routinesRepsMin => 'أدنى تكرارات';

  @override
  String get routinesRepsMax => 'أقصى تكرارات';

  @override
  String get routinesRestSeconds => 'الراحة (ثوانٍ)';

  @override
  String get routinesSaveExercise => 'حفظ التمرين';

  @override
  String get focusCounterSaveError => 'تعذّر حفظ العداد. حاول مرة أخرى.';

  @override
  String get focusResultSaveError =>
      'تعذّر حفظ النتيجة. احتفظ بالنص وحاول مرة أخرى.';

  @override
  String get focusSaveActivityError => 'تعذّر الحفظ في أنشطتك.';

  @override
  String get focusRecordSaveError => 'تعذّر حفظ السجل. حاول مرة أخرى.';

  @override
  String get focusReviewTimeTitle => 'مراجعة الوقت';

  @override
  String get focusReviewTimeBody =>
      'الوقت المختار لا يطابق السجلات. هل تريد حفظ هذا الوقت والإبقاء عليها؟';

  @override
  String get focusBack => 'رجوع';

  @override
  String get focusSaveThatTime => 'حفظ هذا الوقت';

  @override
  String get focusRunning => 'جارٍ';

  @override
  String get focusReady => 'جاهز';

  @override
  String get focusRest => 'راحة';

  @override
  String focusRepeatedRest(Object progress, Object segments) {
    return '$progress $segments · راحة';
  }

  @override
  String focusSegmentCount(Object segment, int count) {
    return '$segment $count';
  }

  @override
  String focusSegmentCountOfTarget(Object segment, int count, int target) {
    return '$segment $count من $target';
  }

  @override
  String get focusSegmentSerie => 'مجموعة';

  @override
  String get focusSegmentTramo => 'مقطع';

  @override
  String get focusSegmentSeries => 'مجموعات';

  @override
  String get focusSegmentTramos => 'مقاطع';

  @override
  String focusRemoveField(Object label) {
    return 'إزالة $label';
  }

  @override
  String focusAddField(Object label) {
    return 'إضافة $label';
  }

  @override
  String get datePatternLongWeekday => 'EEEE، d MMMM';

  @override
  String get datePatternLongDateTime => 'd MMMM · HH:mm';

  @override
  String get datePatternShortDateTime => 'd MMM yyyy · HH:mm';

  @override
  String get datePatternShortDate => 'd MMM';

  @override
  String get datePatternNumericDate => 'd/M/yyyy';

  @override
  String get datePatternNumericDateTime => 'd/M/yyyy HH:mm';

  @override
  String get datePatternNumericDateTimeSeconds => 'd/M/yyyy HH:mm:ss';

  @override
  String get datePatternPaddedDateTime => 'dd/MM/yyyy HH:mm';

  @override
  String get builderTypeNumber => 'رقم';

  @override
  String get builderTypeScale => 'مقياس';

  @override
  String get builderTypeText => 'نص';

  @override
  String get builderTypeChoice => 'خيار';

  @override
  String get builderTypeBoolean => 'نعم أو لا';

  @override
  String get builderAggSum => 'جمع';

  @override
  String get builderAggMax => 'أفضل نتيجة';

  @override
  String get builderAggAvg => 'المتوسط';

  @override
  String get builderAggDistinct => 'عدّ المختلفة';

  @override
  String get builderAggCountTrue => 'عدّ نعم';

  @override
  String get builderAggNone => 'ملاحظات فقط';

  @override
  String get proposalLabelActivitySeconds => 'مدة المقطع';

  @override
  String get proposalLabelTargetCycles => 'الدورات المتوقعة';

  @override
  String get proposalLabelUnitCycles => 'دورات';

  @override
  String get proposalLabelUnitSeconds => 'ث';

  @override
  String get creatorStaticGreeting =>
      'أخبرني بما تريد أن تواظب عليه وسأساعدك في إنشاء مرافقك.';

  @override
  String get creatorStaticDayLetters => 'ن,ث,ر,خ,ج,س,ح';

  @override
  String get proposalGameSuggestion =>
      'لقد واظبت عدة أيام متتالية. هل تريد تفعيل وضع اللعب لرؤية الأهداف والسلاسل والإنجازات؟';

  @override
  String reminderPhraseWindowStartCheer1(Object nombre, Object meta) {
    return '$nombre ينتظرك: هدف اليوم $meta.';
  }

  @override
  String reminderPhraseWindowStartCheer2(Object nombre) {
    return '$nombre ينتظرك اليوم.';
  }

  @override
  String reminderPhraseWindowStartNeutral1(Object meta) {
    return 'هذا وقت مناسب لنشاطك. هدف اليوم: $meta.';
  }

  @override
  String get reminderPhraseWindowStartNeutral2 => 'هذا وقت مناسب لنشاطك.';

  @override
  String reminderPhraseLastCallCheer1(Object minimo, Object racha) {
    return 'آخر فرصة: بـ$minimo تحافظ على سلسلة $racha يومًا.';
  }

  @override
  String reminderPhraseLastCallCheer2(Object faltan) {
    return 'لا تفقد سلسلتك: يتبقى $faltan هذا الأسبوع.';
  }

  @override
  String get reminderPhraseLastCallCheer3 => 'آخر فرصة لليوم.';

  @override
  String reminderPhraseLastCallNeutral1(Object minimo) {
    return 'ما زال أمامك وقت اليوم. يكفي $minimo.';
  }

  @override
  String reminderPhraseLastCallNeutral2(Object faltan) {
    return 'يتبقى $faltan هذا الأسبوع.';
  }

  @override
  String get reminderPhraseLastCallNeutral3 => 'ما زال أمامك وقت اليوم.';

  @override
  String reminderPhraseInactiveGymbroCheer(Object dias) {
    return 'يا صديقي، مرّت $dias أيام دون تدريب. هيا نتحرك قليلًا.';
  }

  @override
  String reminderPhraseInactiveCheer1(Object dias) {
    return 'لم نلتقِ منذ $dias أيام. شيء قصير اليوم؟';
  }

  @override
  String get reminderPhraseInactiveCheer2 => 'شيء قصير اليوم؟';

  @override
  String reminderPhraseInactiveNeutral1(Object dias) {
    return 'لم تسجّل شيئًا منذ $dias أيام.';
  }

  @override
  String get reminderPhraseInactiveNeutral2 => 'لم تسجّل منذ بضعة أيام.';

  @override
  String get reminderPhraseMinimumSessionOne => 'جلسة واحدة';

  @override
  String reminderPhraseMinimumSessions(Object n) {
    return '$n جلسات';
  }

  @override
  String reminderPhraseMinimumMinutes(Object n) {
    return '$n دقيقة';
  }

  @override
  String reminderPhraseMinimumField(Object n, Object campo) {
    return '$n $campo';
  }

  @override
  String memoryTitle(Object name) {
    return 'ذاكرة $name';
  }

  @override
  String get memoryIntro =>
      'ما يتذكره هذا المرافق عنك. يمكنك مراجعته أو تعديله أو حذفه في أي وقت. يُعامَل كمعلومات عنك وليس كتعليمات.';

  @override
  String get memoryOpen => 'ذاكرة المرافق';

  @override
  String get memoryOpenHelp => 'عرض ما يتذكره وتعديله وحذفه، والنسخة السحابية.';

  @override
  String get memoryEmpty => 'لا توجد ذكريات محفوظة بعد.';

  @override
  String get memoryLoadError => 'تعذّر تحميل الذكريات.';

  @override
  String get memoryActionError => 'تعذّر إكمال الإجراء. لم تتغير ذكرياتك.';

  @override
  String get memoryStatusActive => 'نشط';

  @override
  String get memoryStatusPending => 'بانتظار التأكيد';

  @override
  String get memorySourceExplicit => 'طلبتَه أنت';

  @override
  String get memorySourceInferred => 'اقتراح من الذكاء الاصطناعي';

  @override
  String get memorySourceEdited => 'عدّلتَه أنت';

  @override
  String get memoryConfirm => 'تأكيد';

  @override
  String get memoryConfirmed => 'تم تأكيد الذكرى.';

  @override
  String get memoryEdit => 'تعديل';

  @override
  String get memoryEditTitle => 'تعديل الذكرى';

  @override
  String get memoryEditLabel => 'الذكرى';

  @override
  String get memoryEditEmpty => 'لا يمكن أن تكون الذكرى فارغة.';

  @override
  String get memoryEditTooLong => 'لا يمكن أن تتجاوز الذكرى 2000 حرف.';

  @override
  String get memoryEdited => 'تم حفظ الذكرى.';

  @override
  String get memoryDeleteLocalAction => 'حذف من هذا الهاتف';

  @override
  String get memoryDeleteLocalTitle => 'هل تريد حذف هذه الذكرى من هذا الهاتف؟';

  @override
  String get memoryDeleteLocalBody =>
      'سيُحذف من هذا الهاتف فقط وسيتوقف المرافق عن استخدامه. لا يحذف النسخة الموجودة في السحابة؛ استخدم «حذف من السحابة» لذلك.';

  @override
  String get memoryDeletedLocal =>
      'تم حذف الذكرى من هذا الهاتف. لم تُمَسّ النسخة السحابية.';

  @override
  String get memoryCloudTitle => 'النسخة السحابية';

  @override
  String get memoryCloudHelp =>
      'اختيارية وبطلب منك فقط. تُحفظ الذكريات النشطة لهذا المرافق دون محادثات أو مفاتيح. وهي غير مشفّرة من طرف إلى طرف.';

  @override
  String get memoryCloudUnavailable =>
      'لم يتم ربط Google Drive بعد في هذا الإصدار';

  @override
  String get memoryCloudNoAccount =>
      'اربط حساب Google لاستخدام النسخة السحابية.';

  @override
  String memoryCloudAccount(Object account) {
    return 'الحساب: $account';
  }

  @override
  String memoryCloudLastCopy(Object date, int revision) {
    return 'آخر نسخة شوهدت: $date (المراجعة $revision)';
  }

  @override
  String get memoryCloudSave => 'حفظ في السحابة';

  @override
  String get memoryCloudLoad => 'تحميل من السحابة';

  @override
  String get memoryCloudDelete => 'حذف من السحابة';

  @override
  String get memoryCloudSaveTitle => 'هل تريد الحفظ في السحابة؟';

  @override
  String memoryCloudSaveBody(Object account, int count) {
    return 'ستُرفع الذكريات النشطة لهذا المرافق إلى الحساب $account. الذكريات المراد رفعها: $count. لا تُرفع الذكريات بانتظار التأكيد. إذا تغيّرت النسخة السحابية فلن تُستبدل.';
  }

  @override
  String memoryCloudSaved(Object account) {
    return 'تم حفظ النسخة في الحساب $account.';
  }

  @override
  String memoryCloudLoaded(int count) {
    return 'تم تحميل النسخة. الذكريات المضافة: $count.';
  }

  @override
  String get memoryCloudLoadCancelled => 'أُلغي التحميل. لم يتغير شيء.';

  @override
  String get memoryCloudDeleteTitle => 'هل تريد حذف النسخة السحابية؟';

  @override
  String memoryCloudDeleteBody(Object account, Object date) {
    return 'ستُحذف نسخة هذا المرافق من الحساب $account (المحفوظة في $date). لا يحذف الذكريات الموجودة على هذا الهاتف. لا يمكن التراجع عن ذلك.';
  }

  @override
  String memoryCloudDeleted(Object account) {
    return 'تم حذف النسخة من الحساب $account. لم تُمَسّ الذكريات على هذا الهاتف.';
  }

  @override
  String get memoryCloudDeleteCancelled => 'أُلغي الحذف. لم يتغير شيء.';

  @override
  String get memoryCloudNotFound => 'لا توجد نسخة سحابية لهذا المرافق.';

  @override
  String get memoryCloudConflict =>
      'النسخة السحابية تختلف عن آخر نسخة رأيتها. لم يتغير شيء؛ استخدم «تحميل من السحابة» لمراجعتها.';

  @override
  String get memoryCloudUncertain =>
      'تعذّر تأكيد النتيجة؛ ربما نُفّذت العملية. حمّل من جديد للتحقق قبل التكرار.';

  @override
  String get memoryCloudCancelled => 'أُلغيت العملية. لم يتغير شيء.';

  @override
  String get memoryCloudDenied => 'لم تمنح Google الإذن. لم يتغير شيء.';

  @override
  String get memoryCloudFailed =>
      'تعذّر إكمال العملية السحابية. لم تتغير ذكرياتك المحلية.';

  @override
  String get memoryPreviewTitle => 'معاينة النسخة';

  @override
  String memoryPreviewFrom(Object account, Object date) {
    return 'الحساب $account، نسخة بتاريخ $date';
  }

  @override
  String memoryPreviewAdd(int count) {
    return 'ستُضاف: $count';
  }

  @override
  String memoryPreviewSkip(int count) {
    return 'تُتجاهل (موجودة مسبقًا): $count';
  }

  @override
  String memoryPreviewConflict(int count) {
    return 'متعارضة (لا تُطبّق): $count';
  }

  @override
  String get memoryPreviewConflictHelp =>
      'لا تُحلّ التعارضات تلقائيًا: تبقى ذكرياتك المحلية كما هي.';

  @override
  String get memoryPreviewNothing => 'لا يوجد ما يُضاف.';

  @override
  String get memoryPreviewApply => 'إضافة الذكريات';

  @override
  String get agreementTitle => 'اتفاقيات الدعم';

  @override
  String get agreementNew => 'اتفاقية جديدة';

  @override
  String get agreementEmpty =>
      'ليس لديك اتفاقيات بعد. أنشئ واحدة بزر اتفاقية جديدة؛ لا يُسجَّل إلا ما تدوّنه أنت.';

  @override
  String get agreementLoadError => 'تعذّر تحميل الاتفاقيات.';

  @override
  String get agreementSaveError => 'تعذّر حفظ التغيير. الاتفاقية كما كانت.';

  @override
  String get agreementStatusActive => 'نشطة';

  @override
  String get agreementStatusPaused => 'متوقفة مؤقتًا';

  @override
  String get agreementStatusCompleted => 'منتهية';

  @override
  String get agreementObjectiveLabel => 'الهدف';

  @override
  String get agreementUnitLabel => 'الوحدة (اختياري)';

  @override
  String get agreementMeasureLabel => 'القياس';

  @override
  String get agreementMeasureOptionalLabel => 'القياس (اختياري)';

  @override
  String get agreementConsent =>
      'أوافق على إنشاء هذه الاتفاقية. لن يُسجَّل إلا ما أدوّنه.';

  @override
  String get agreementErrorObjective => 'اكتب هدفًا (حتى 2000 حرف).';

  @override
  String get agreementErrorMeasure =>
      'يجب أن يكون القياس رقمًا محدودًا يساوي 0 أو أكبر.';

  @override
  String get agreementErrorConsent => 'ضع علامة في المربع لإنشاء الاتفاقية.';

  @override
  String get agreementCancel => 'إلغاء';

  @override
  String get agreementCreate => 'إنشاء';

  @override
  String get agreementSave => 'حفظ';

  @override
  String get agreementModify => 'تعديل';

  @override
  String get agreementPause => 'إيقاف مؤقت';

  @override
  String get agreementResume => 'استئناف';

  @override
  String get agreementComplete => 'إنهاء';

  @override
  String get agreementCompleteTitle => 'إنهاء الاتفاقية؟';

  @override
  String get agreementCompleteBody =>
      'لا يمكن تعديل الاتفاقية المنتهية ولا إضافة تقدم إليها. يبقى السجل محفوظًا.';

  @override
  String get agreementRecordProgress => 'تسجيل تقدم';

  @override
  String get agreementRecord => 'تسجيل';

  @override
  String get agreementAmountLabel => 'الكمية (اختياري)';

  @override
  String get agreementNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get agreementReminderLabel => 'تنبيه';

  @override
  String get agreementEventsTitle => 'التقدم المسجّل';

  @override
  String get agreementNoEvents => 'لا يوجد تقدم مسجّل بعد.';

  @override
  String get agreementChangesTitle => 'سجل التغييرات';

  @override
  String get agreementNoChanges => 'لا تغييرات منذ الإنشاء.';

  @override
  String agreementRevisionLabel(int n) {
    return 'المراجعة $n';
  }

  @override
  String get packageShareRow => 'مشاركة المرافق';

  @override
  String get packageShareRowHelp =>
      'ينشئ ملف .trackia بإعدادات هذا المرافق، دون بياناتك.';

  @override
  String get packageShareTitle => 'مشاركة هذا المرافق؟';

  @override
  String get packageShareIncludes =>
      'تتم مشاركة: الاسم والأيقونة واللون والوصف وتعليمات الأسلوب والوضع وقوالب النشاط ونصوص التذكيرات.';

  @override
  String get packageShareExcludes =>
      'لا تتم مشاركة: مفاتيح الذكاء الاصطناعي والمحادثات والذاكرة وورقة Google والحسابات وبياناتك.';

  @override
  String get packageShareReceiverNote =>
      'يمكن لمن يستلمه استيراده ومراجعته قبل استخدامه.';

  @override
  String get packageShareTemplatesLimited => 'تُضمَّن أول 5 قوالب نشاط فقط.';

  @override
  String get packageShareConfirm => 'مشاركة';

  @override
  String get packageShareInstructionsTooLong =>
      'تتجاوز التعليمات الحد المسموح به للمشاركة وهو 4000 حرف. اختصرها وحاول مرة أخرى. لم تتم مشاركة أي شيء.';

  @override
  String get packageShareInvalid =>
      'يحتوي هذا المرافق على بيانات لا يمكن مشاركتها. لم تتم مشاركة أي شيء.';

  @override
  String get packageShareWriteError =>
      'تعذّر تجهيز الملف للمشاركة. لم تتم مشاركة أي شيء.';

  @override
  String get packageImportTitle => 'استيراد مرافق';

  @override
  String get packageImportIntro =>
      'اختر ملف .trackia أو الصق النص الذي شُورك معك. ستظهر معاينة قبل حفظ أي شيء.';

  @override
  String get packageImportPickFile => 'اختيار ملف';

  @override
  String get packageImportPasteLabel => 'نص المرافق';

  @override
  String get packageImportPreviewButton => 'عرض المعاينة';

  @override
  String get packageImportFileError => 'تعذّرت قراءة الملف.';

  @override
  String get packageImportExternalNotice =>
      'هذا المحتوى قادم من الخارج: راجعه قبل حفظه.';

  @override
  String get packageImportModeNote =>
      'سيُحفظ بوضع «تذكير» دون أذونات أو اتصالات. يمكنك تغيير ذلك لاحقًا.';

  @override
  String get packageImportActivityTitle => 'النشاط الذي سيأتي معه';

  @override
  String packageImportActivityFields(Object fields) {
    return 'الحقول: $fields';
  }

  @override
  String get packageImportRemindersTitle => 'نصوص التنبيهات';

  @override
  String get packageImportReminderWindowStart => 'عند بدء الفترة';

  @override
  String get packageImportReminderLastCall => 'التذكير الأخير';

  @override
  String get packageImportReminderInactive => 'بلا نشاط';

  @override
  String get packageImportWarningsTitle => 'تحذيرات';

  @override
  String packageImportWarningAppBlocksRemoved(int count) {
    return 'أُزيلت كتل داخلية للتطبيق من المحتوى. العدد: $count';
  }

  @override
  String packageImportWarningModeReset(Object mode) {
    return 'طلبت الحزمة وضع «$mode»؛ سيبدأ بوضع «تذكير» ويمكنك تغييره لاحقًا.';
  }

  @override
  String packageImportWarningExtraTemplates(int count) {
    return 'لا تُطبَّق أنشطة أخرى في الحزمة. العدد: $count';
  }

  @override
  String get packageImportWarningSuspicious =>
      'يبدو أن التعليمات تحاول تغيير قواعد المساعد. اقرأها بعناية أو احذفها.';

  @override
  String get packageImportWarningInstructionsEmpty =>
      'لم يتبقَّ نص في التعليمات بعد إزالة الكتل الداخلية.';

  @override
  String get packageImportSave => 'حفظ المرافق';

  @override
  String get packageImportSaveFailed => 'تعذّر حفظ المرافق.';

  @override
  String packageImportProblemField(Object field) {
    return 'الحقل: $field';
  }

  @override
  String get packageImportProblemEmpty =>
      'لا شيء للاستيراد: النص أو الملف فارغ.';

  @override
  String get packageImportProblemTooLarge => 'المحتوى كبير جدًا ليكون مرافقًا.';

  @override
  String get packageImportProblemBadEncoding =>
      'النص تالف أو ناقص: ليس بتنسيق صالح.';

  @override
  String get packageImportProblemBadCompression =>
      'المحتوى تالف وتعذّر فك ضغطه.';

  @override
  String get packageImportProblemTooLargeExpanded =>
      'المحتوى كبير جدًا بعد فتحه وتم رفضه للأمان.';

  @override
  String get packageImportProblemMalformed =>
      'تعذّرت قراءة المحتوى: ليس مرافقًا صالحًا.';

  @override
  String get packageImportProblemNotAPackage => 'هذا ليس مرافقًا من TrackIA.';

  @override
  String get packageImportProblemUnsupportedVersion =>
      'هذا المرافق من إصدار أحدث. حدّث TrackIA لاستيراده.';

  @override
  String get packageImportProblemChecksumMismatch =>
      'تغيّر المحتوى أو تلف: فشل فحص السلامة.';

  @override
  String get packageImportProblemForbiddenField =>
      'يتضمن المحتوى بيانات يجب ألا تُنقل أبدًا (مفاتيح، محادثات، ذاكرة…). لم يُستورد.';

  @override
  String get packageImportProblemUnknownField =>
      'يتضمن المحتوى حقلًا لا يقبله هذا الإصدار. لم يُستورد.';

  @override
  String get packageImportProblemMissingField => 'ينقص المحتوى حقل مطلوب.';

  @override
  String get packageImportProblemInvalidField =>
      'حقل في المحتوى غير صالح أو يتجاوز حدّه.';

  @override
  String get importedTrustWarning => 'هذا المرافق مستورد: أكّد قبل أن يتصرف.';

  @override
  String get importedTrustConfirm => 'تأكيد';

  @override
  String get importedTrustSheetTitle => 'تعديل جدول Google Sheets الخاص بك؟';

  @override
  String importedTrustSheetTarget(String sheet, String tab) {
    return 'الجدول: $sheet · علامة التبويب: $tab';
  }

  @override
  String importedTrustCellLine(String cell, String before, String after) {
    return '$cell: «$before» ← «$after»';
  }

  @override
  String get importedTrustEmptyValue => '(فارغة)';

  @override
  String get importedTrustCancelledSheet =>
      'تم إلغاء الإجراء: لم يتم تعديل جدول Google Sheets.';

  @override
  String get importedTrustActivityTitle => 'تجهيز هذا النشاط؟';

  @override
  String importedTrustActivityRest(int seconds) {
    return 'الراحة: $seconds ث';
  }

  @override
  String importedTrustActivityDuration(int seconds) {
    return 'مدة النشاط: $seconds ث';
  }

  @override
  String importedTrustActivityTargetSets(int count) {
    return 'المجموعات المستهدفة: $count';
  }

  @override
  String importedTrustActivityFields(String fields) {
    return 'الحقول: $fields';
  }

  @override
  String importedTrustCancelledActivity(String name) {
    return 'تم إلغاء الإجراء: لم يتم تجهيز النشاط «$name».';
  }

  @override
  String get importedTrustLabel => 'مستورد';

  @override
  String get importedTrustSwitch => 'الوثوق بهذا المرافق';

  @override
  String get importedTrustSwitchHelp =>
      'حتى تثق به، سيطلب التأكيد قبل تعديل جدولك أو تجهيز الأنشطة.';

  @override
  String get importedTrustDialogTitle => 'الوثوق بهذا المرافق؟';

  @override
  String get importedTrustDialogBody =>
      'سيتوقف عن طلب التأكيد قبل تعديل جدولك أو تجهيز الأنشطة. افعل ذلك فقط إذا كنت تثق بمن شاركه معك.';

  @override
  String get importedTrustDialogConfirm => 'وثوق';

  @override
  String get importedTrustSaveError => 'تعذر حفظ التغيير. حاول مرة أخرى.';

  @override
  String get packageQrTitle => 'رمز QR للرفيق';

  @override
  String get packageQrNote => 'سيرى من يمسحه معاينة قبل حفظ أي شيء.';

  @override
  String get packageQrShareFile => 'مشاركة الملف';

  @override
  String get packageQrClose => 'إغلاق';

  @override
  String get packageQrTooLarge => 'حجمه كبير جدًا لرمز QR: تتم مشاركته كملف.';

  @override
  String get packageScanTitle => 'مسح مرافق';

  @override
  String get packageScanHint => 'وجّه الكاميرا نحو رمز QR الخاص بالمرافق.';

  @override
  String get packageScanTorch => 'المصباح';

  @override
  String get packageScanPermissionDenied =>
      'لم يتم منح إذن الكاميرا. يمكنك استيراد المرافق من ملف أو بلصق النص.';

  @override
  String get packageScanCameraError =>
      'تعذّر استخدام الكاميرا. يمكنك استيراد المرافق من ملف أو بلصق النص.';

  @override
  String get packageScanUseFile => 'الاستيراد من ملف أو نص';

  @override
  String get restScreenSharedCopyUnreadable => 'تعذّرت قراءة النسخة المشتركة.';

  @override
  String get restScreenSharedCopyOpenError => 'تعذّر فتح النسخة المشتركة.';

  @override
  String restScreenCompanionsLoadDetail(Object error) {
    return 'تعذّر تحميل المرافقين: $error';
  }

  @override
  String restScreenTimerLabel(Object label) {
    return 'الوقت: $label';
  }
}
