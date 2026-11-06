import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'TrackIA'**
  String get appTitle;

  /// No description provided for @languageSystem.
  ///
  /// In es, this message translates to:
  /// **'Idioma del dispositivo'**
  String get languageSystem;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In es, this message translates to:
  /// **'Árabe'**
  String get languageArabic;

  /// No description provided for @languagePreference.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languagePreference;

  /// No description provided for @welcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenida'**
  String get welcomeTitle;

  /// No description provided for @welcomeHelpTitle.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y bienvenida'**
  String get welcomeHelpTitle;

  /// No description provided for @welcomeStep.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String welcomeStep(Object current, Object total);

  /// No description provided for @welcomeSlide1Title.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get welcomeSlide1Title;

  /// No description provided for @welcomeSlide1Body.
  ///
  /// In es, this message translates to:
  /// **'Conversa con tu asistente de IA para preparar una actividad, resolver dudas y revisar tu progreso. Tú decides cuándo empezar.'**
  String get welcomeSlide1Body;

  /// No description provided for @welcomeSlide2Title.
  ///
  /// In es, this message translates to:
  /// **'Habla o escribe'**
  String get welcomeSlide2Title;

  /// No description provided for @welcomeSlide2Body.
  ///
  /// In es, this message translates to:
  /// **'El chat admite texto, dictado y adjuntos. Para usar la IA, conecta un proveedor desde el menú. Si se corta la conexión, tus registros locales siguen disponibles.'**
  String get welcomeSlide2Body;

  /// No description provided for @welcomeSlide3Title.
  ///
  /// In es, this message translates to:
  /// **'Controla tu actividad'**
  String get welcomeSlide3Title;

  /// No description provided for @welcomeSlide3Body.
  ///
  /// In es, this message translates to:
  /// **'Elige o crea una actividad. Prepararla no inicia el reloj: pulsa Iniciar cuando estés listo y Parar al terminar cada tramo.'**
  String get welcomeSlide3Body;

  /// No description provided for @welcomeSlide4Title.
  ///
  /// In es, this message translates to:
  /// **'Conserva tus datos'**
  String get welcomeSlide4Title;

  /// No description provided for @welcomeSlide4Body.
  ///
  /// In es, this message translates to:
  /// **'Tus registros se guardan en el móvil. Puedes conectar Google Sheets cuando quieras y revisar el estado de cada envío.'**
  String get welcomeSlide4Body;

  /// No description provided for @welcomeSlide5Title.
  ///
  /// In es, this message translates to:
  /// **'Tus acompañantes'**
  String get welcomeSlide5Title;

  /// No description provided for @welcomeSlide5Body.
  ///
  /// In es, this message translates to:
  /// **'Elige GymBro, Enfoque, Calma o Diario. Puedes editar sus instrucciones, crear otros y conectar una hoja o pestaña de Google distinta para cada uno.'**
  String get welcomeSlide5Body;

  /// No description provided for @welcomeSlide6Title.
  ///
  /// In es, this message translates to:
  /// **'Modo y avisos'**
  String get welcomeSlide6Title;

  /// No description provided for @welcomeSlide6Body.
  ///
  /// In es, this message translates to:
  /// **'Cada acompañante tiene su modo. Abre su menú (⋮) y pulsa «Modo y avisos»: con Recordatorio solo te avisa a la hora que elijas; con Juego añade metas, rachas y logros. Para que los avisos de descanso suenen aunque tengas No molestar, ve a Ajustes → Avisos.'**
  String get welcomeSlide6Body;

  /// No description provided for @welcomeSaveErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la elección'**
  String get welcomeSaveErrorTitle;

  /// No description provided for @welcomeSaveErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes volver a intentarlo o continuar. Si continúas, la bienvenida podría aparecer al abrir la app de nuevo.'**
  String get welcomeSaveErrorBody;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @continueWithoutSaving.
  ///
  /// In es, this message translates to:
  /// **'Continuar sin guardar'**
  String get continueWithoutSaving;

  /// No description provided for @welcomeNeverAgain.
  ///
  /// In es, this message translates to:
  /// **'No volver a mostrar'**
  String get welcomeNeverAgain;

  /// No description provided for @welcomeNeverAgainHelp.
  ///
  /// In es, this message translates to:
  /// **'Si la dejas sin marcar, verás esta guía al abrir la app. Puedes cambiarlo en Ayuda.'**
  String get welcomeNeverAgainHelp;

  /// No description provided for @skip.
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get skip;

  /// No description provided for @previous.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @start.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get start;

  /// No description provided for @welcomeAutoShow.
  ///
  /// In es, this message translates to:
  /// **'Mostrar bienvenida al abrir'**
  String get welcomeAutoShow;

  /// No description provided for @devicePreferenceSaved.
  ///
  /// In es, this message translates to:
  /// **'Tu elección se guarda en este dispositivo.'**
  String get devicePreferenceSaved;

  /// No description provided for @showWelcome.
  ///
  /// In es, this message translates to:
  /// **'Ver bienvenida'**
  String get showWelcome;

  /// No description provided for @savePreferenceError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la preferencia.'**
  String get savePreferenceError;

  /// No description provided for @companionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus acompañantes'**
  String get companionsTitle;

  /// No description provided for @companionsDescription.
  ///
  /// In es, this message translates to:
  /// **'Elige con quién trabajar. Cada uno conserva su conversación y puede usar una hoja o pestaña de Google distinta.'**
  String get companionsDescription;

  /// No description provided for @companionsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes acompañantes. Crea uno para empezar.'**
  String get companionsEmpty;

  /// No description provided for @createCompanion.
  ///
  /// In es, this message translates to:
  /// **'Crear acompañante'**
  String get createCompanion;

  /// No description provided for @companionOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones de {name}'**
  String companionOptions(Object name);

  /// No description provided for @companionProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso de {name}'**
  String companionProgress(Object name);

  /// No description provided for @companionStreak.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, one{Racha: 1 día} other{Racha: # días}}'**
  String companionStreak(int days);

  /// No description provided for @remindersPaused.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios en pausa'**
  String get remindersPaused;

  /// No description provided for @resume.
  ///
  /// In es, this message translates to:
  /// **'Reanudar'**
  String get resume;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @modeAndNotices.
  ///
  /// In es, this message translates to:
  /// **'Modo y avisos'**
  String get modeAndNotices;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @companionDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar {name}?'**
  String companionDeleteTitle(Object name);

  /// No description provided for @companionDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán su chat, archivos y conexión local de Sheets. La hoja de Google y los registros de actividad no se borrarán.'**
  String get companionDeleteBody;

  /// No description provided for @companionDeleteError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo borrar: {error}'**
  String companionDeleteError(Object error);

  /// No description provided for @companionSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar: {error}'**
  String companionSaveError(Object error);

  /// No description provided for @companionLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los acompañantes. Pulsa para reintentar.'**
  String get companionLoadError;

  /// No description provided for @createCompanionTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear acompañante'**
  String get createCompanionTitle;

  /// No description provided for @editCompanionTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar acompañante'**
  String get editCompanionTitle;

  /// No description provided for @companionName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get companionName;

  /// No description provided for @companionPurpose.
  ///
  /// In es, this message translates to:
  /// **'¿Para qué sirve?'**
  String get companionPurpose;

  /// No description provided for @companionInstructions.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones para la IA (opcional)'**
  String get companionInstructions;

  /// No description provided for @companionInstructionsHelp.
  ///
  /// In es, this message translates to:
  /// **'Se usan cuando conectes un proveedor.'**
  String get companionInstructionsHelp;

  /// No description provided for @icon.
  ///
  /// In es, this message translates to:
  /// **'Icono'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settings;

  /// No description provided for @assistant.
  ///
  /// In es, this message translates to:
  /// **'Asistente'**
  String get assistant;

  /// No description provided for @artificialIntelligence.
  ///
  /// In es, this message translates to:
  /// **'Inteligencia artificial'**
  String get artificialIntelligence;

  /// No description provided for @yourData.
  ///
  /// In es, this message translates to:
  /// **'Tus datos'**
  String get yourData;

  /// No description provided for @accountAndData.
  ///
  /// In es, this message translates to:
  /// **'Cuenta y datos'**
  String get accountAndData;

  /// No description provided for @localProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil local'**
  String get localProfile;

  /// No description provided for @exportImport.
  ///
  /// In es, this message translates to:
  /// **'Exportar e importar'**
  String get exportImport;

  /// No description provided for @appSection.
  ///
  /// In es, this message translates to:
  /// **'App'**
  String get appSection;

  /// No description provided for @notices.
  ///
  /// In es, this message translates to:
  /// **'Avisos'**
  String get notices;

  /// No description provided for @enabled.
  ///
  /// In es, this message translates to:
  /// **'Activados'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In es, this message translates to:
  /// **'Desactivados'**
  String get disabled;

  /// No description provided for @appearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get appearance;

  /// No description provided for @helpWelcome.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y bienvenida'**
  String get helpWelcome;

  /// No description provided for @verified.
  ///
  /// In es, this message translates to:
  /// **'Verificada'**
  String get verified;

  /// No description provided for @notConnected.
  ///
  /// In es, this message translates to:
  /// **'Sin conectar'**
  String get notConnected;

  /// No description provided for @notVerified.
  ///
  /// In es, this message translates to:
  /// **'Sin verificar'**
  String get notVerified;

  /// No description provided for @unavailable.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get unavailable;

  /// No description provided for @checking.
  ///
  /// In es, this message translates to:
  /// **'Comprobando…'**
  String get checking;

  /// No description provided for @automatic.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get automatic;

  /// No description provided for @light.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get dark;

  /// No description provided for @companionSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Modo y avisos · {name}'**
  String companionSettingsTitle(Object name);

  /// No description provided for @mode.
  ///
  /// In es, this message translates to:
  /// **'Modo'**
  String get mode;

  /// No description provided for @reminderMode.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio'**
  String get reminderMode;

  /// No description provided for @reminderModeDetail.
  ///
  /// In es, this message translates to:
  /// **'Solo te avisa a la hora que elijas.'**
  String get reminderModeDetail;

  /// No description provided for @gameMode.
  ///
  /// In es, this message translates to:
  /// **'Juego'**
  String get gameMode;

  /// No description provided for @gameModeDetail.
  ///
  /// In es, this message translates to:
  /// **'Metas, rachas y logros, además de los avisos.'**
  String get gameModeDetail;

  /// No description provided for @goals.
  ///
  /// In es, this message translates to:
  /// **'Metas'**
  String get goals;

  /// No description provided for @streaks.
  ///
  /// In es, this message translates to:
  /// **'Rachas'**
  String get streaks;

  /// No description provided for @achievements.
  ///
  /// In es, this message translates to:
  /// **'Logros'**
  String get achievements;

  /// No description provided for @encouragementMessages.
  ///
  /// In es, this message translates to:
  /// **'Mensajes de ánimo'**
  String get encouragementMessages;

  /// No description provided for @freeDaysPerWeek.
  ///
  /// In es, this message translates to:
  /// **'Días libres por semana'**
  String get freeDaysPerWeek;

  /// No description provided for @freeDaysHelp.
  ///
  /// In es, this message translates to:
  /// **'No rompen la racha.'**
  String get freeDaysHelp;

  /// No description provided for @dailyNotice.
  ///
  /// In es, this message translates to:
  /// **'Aviso diario'**
  String get dailyNotice;

  /// No description provided for @remindersPausedDetail.
  ///
  /// In es, this message translates to:
  /// **'Pasaron 7 días programados sin registrar nada.'**
  String get remindersPausedDetail;

  /// No description provided for @remindAboutActivity.
  ///
  /// In es, this message translates to:
  /// **'Recordarme esta actividad'**
  String get remindAboutActivity;

  /// No description provided for @monday.
  ///
  /// In es, this message translates to:
  /// **'lunes'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In es, this message translates to:
  /// **'martes'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In es, this message translates to:
  /// **'miércoles'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In es, this message translates to:
  /// **'jueves'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In es, this message translates to:
  /// **'viernes'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In es, this message translates to:
  /// **'sábado'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In es, this message translates to:
  /// **'domingo'**
  String get sunday;

  /// No description provided for @from.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get from;

  /// No description provided for @until.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get until;

  /// No description provided for @lastCall.
  ///
  /// In es, this message translates to:
  /// **'Última llamada'**
  String get lastCall;

  /// No description provided for @lastCallTime.
  ///
  /// In es, this message translates to:
  /// **'Hora de la última llamada'**
  String get lastCallTime;

  /// No description provided for @neutral.
  ///
  /// In es, this message translates to:
  /// **'Neutro'**
  String get neutral;

  /// No description provided for @motivating.
  ///
  /// In es, this message translates to:
  /// **'Motivador'**
  String get motivating;

  /// No description provided for @minimumForDay.
  ///
  /// In es, this message translates to:
  /// **'Mínimo para ese día'**
  String get minimumForDay;

  /// No description provided for @quantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get quantity;

  /// No description provided for @sessions.
  ///
  /// In es, this message translates to:
  /// **'sesiones'**
  String get sessions;

  /// No description provided for @minutes.
  ///
  /// In es, this message translates to:
  /// **'minutos'**
  String get minutes;

  /// No description provided for @preview.
  ///
  /// In es, this message translates to:
  /// **'Así se verá'**
  String get preview;

  /// No description provided for @putGoal.
  ///
  /// In es, this message translates to:
  /// **'Poner una meta'**
  String get putGoal;

  /// No description provided for @whatToMeasure.
  ///
  /// In es, this message translates to:
  /// **'Qué medir'**
  String get whatToMeasure;

  /// No description provided for @timeMinutes.
  ///
  /// In es, this message translates to:
  /// **'Tiempo (minutos)'**
  String get timeMinutes;

  /// No description provided for @sessionCount.
  ///
  /// In es, this message translates to:
  /// **'Sesiones'**
  String get sessionCount;

  /// No description provided for @perDay.
  ///
  /// In es, this message translates to:
  /// **'al día'**
  String get perDay;

  /// No description provided for @perWeek.
  ///
  /// In es, this message translates to:
  /// **'a la semana'**
  String get perWeek;

  /// No description provided for @target.
  ///
  /// In es, this message translates to:
  /// **'Objetivo'**
  String get target;

  /// No description provided for @minimumStreakOptional.
  ///
  /// In es, this message translates to:
  /// **'Mínimo para mantener la racha (opcional)'**
  String get minimumStreakOptional;

  /// No description provided for @chooseTime.
  ///
  /// In es, this message translates to:
  /// **'Elige la hora'**
  String get chooseTime;

  /// No description provided for @goalMustBePositive.
  ///
  /// In es, this message translates to:
  /// **'El objetivo debe ser un número mayor que 0.'**
  String get goalMustBePositive;

  /// No description provided for @minimumMustBePositive.
  ///
  /// In es, this message translates to:
  /// **'El mínimo debe ser un número mayor que 0.'**
  String get minimumMustBePositive;

  /// No description provided for @companionSettingsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los ajustes.'**
  String get companionSettingsLoadError;

  /// No description provided for @companionSettingsSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron guardar los ajustes.'**
  String get companionSettingsSaveError;

  /// No description provided for @aiNotConnected.
  ///
  /// In es, this message translates to:
  /// **'IA sin conectar'**
  String get aiNotConnected;

  /// No description provided for @chooseProviderAndModel.
  ///
  /// In es, this message translates to:
  /// **'Elige un proveedor y un modelo.'**
  String get chooseProviderAndModel;

  /// No description provided for @connect.
  ///
  /// In es, this message translates to:
  /// **'Conectar'**
  String get connect;

  /// No description provided for @aiNotVerified.
  ///
  /// In es, this message translates to:
  /// **'IA sin verificar'**
  String get aiNotVerified;

  /// No description provided for @verifyConnectionAssistant.
  ///
  /// In es, this message translates to:
  /// **'Prueba la conexión para activar el asistente.'**
  String get verifyConnectionAssistant;

  /// No description provided for @verify.
  ///
  /// In es, this message translates to:
  /// **'Verificar'**
  String get verify;

  /// No description provided for @aiUnavailable.
  ///
  /// In es, this message translates to:
  /// **'IA no disponible'**
  String get aiUnavailable;

  /// No description provided for @reviewProviderRetry.
  ///
  /// In es, this message translates to:
  /// **'Revisa el proveedor y vuelve a probar.'**
  String get reviewProviderRetry;

  /// No description provided for @review.
  ///
  /// In es, this message translates to:
  /// **'Revisar'**
  String get review;

  /// No description provided for @waitingPhraseOne.
  ///
  /// In es, this message translates to:
  /// **'Estoy aquí para ayudarte.'**
  String get waitingPhraseOne;

  /// No description provided for @waitingPhraseTwo.
  ///
  /// In es, this message translates to:
  /// **'Tómate un momento; aquí seguimos.'**
  String get waitingPhraseTwo;

  /// No description provided for @waitingPhraseThree.
  ///
  /// In es, this message translates to:
  /// **'Cuando quieras, continuamos.'**
  String get waitingPhraseThree;

  /// No description provided for @waitingPhraseFour.
  ///
  /// In es, this message translates to:
  /// **'Puedes seguir escribiendo cuando te venga bien.'**
  String get waitingPhraseFour;

  /// No description provided for @logoDescription.
  ///
  /// In es, this message translates to:
  /// **'Logotipo de TrackIA'**
  String get logoDescription;

  /// No description provided for @chatArchive.
  ///
  /// In es, this message translates to:
  /// **'Archivar chat'**
  String get chatArchive;

  /// No description provided for @chatArchives.
  ///
  /// In es, this message translates to:
  /// **'Chats archivados'**
  String get chatArchives;

  /// No description provided for @chatSendToSheets.
  ///
  /// In es, this message translates to:
  /// **'Enviar a Google Sheets'**
  String get chatSendToSheets;

  /// No description provided for @chatAiProvider.
  ///
  /// In es, this message translates to:
  /// **'Proveedor de IA'**
  String get chatAiProvider;

  /// No description provided for @chatConfigureAi.
  ///
  /// In es, this message translates to:
  /// **'Configurar IA'**
  String get chatConfigureAi;

  /// No description provided for @chatVerifyConnection.
  ///
  /// In es, this message translates to:
  /// **'Verificar conexión · usa tu API'**
  String get chatVerifyConnection;

  /// No description provided for @chatTraining.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento'**
  String get chatTraining;

  /// No description provided for @chatLoadSheets.
  ///
  /// In es, this message translates to:
  /// **'Cargar Google Sheets'**
  String get chatLoadSheets;

  /// No description provided for @chatSheetPending.
  ///
  /// In es, this message translates to:
  /// **'Interpretar hoja con IA'**
  String get chatSheetPending;

  /// No description provided for @chatWelcomePrompt.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te gustaría hacer hoy? Cuéntame y lo organizamos juntos.'**
  String get chatWelcomePrompt;

  /// No description provided for @chatLoadDataPrompt.
  ///
  /// In es, this message translates to:
  /// **'Carga tus datos con + cuando quieras. La IA podrá interpretar su formato cuando esté conectada.'**
  String get chatLoadDataPrompt;

  /// No description provided for @chatPrepareActivity.
  ///
  /// In es, this message translates to:
  /// **'Preparar'**
  String get chatPrepareActivity;

  /// No description provided for @chatWaitingModel.
  ///
  /// In es, this message translates to:
  /// **'Esperando al modelo…'**
  String get chatWaitingModel;

  /// No description provided for @chatDeferredArchive.
  ///
  /// In es, this message translates to:
  /// **'El asistente archivará este chat cuando vuelvas al final.'**
  String get chatDeferredArchive;

  /// No description provided for @chatGoLatest.
  ///
  /// In es, this message translates to:
  /// **'Ir al último mensaje'**
  String get chatGoLatest;

  /// No description provided for @chatListening.
  ///
  /// In es, this message translates to:
  /// **'Escuchando… Revisa el texto y pulsa Enviar.'**
  String get chatListening;

  /// No description provided for @chatAttach.
  ///
  /// In es, this message translates to:
  /// **'Adjuntar'**
  String get chatAttach;

  /// No description provided for @chatComposeHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe o dicta tu mensaje…'**
  String get chatComposeHint;

  /// No description provided for @chatConnectAiHint.
  ///
  /// In es, this message translates to:
  /// **'Conecta tu IA para empezar'**
  String get chatConnectAiHint;

  /// No description provided for @chatStopDictation.
  ///
  /// In es, this message translates to:
  /// **'Terminar dictado'**
  String get chatStopDictation;

  /// No description provided for @chatDictate.
  ///
  /// In es, this message translates to:
  /// **'Dictar mensaje'**
  String get chatDictate;

  /// No description provided for @chatSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get chatSend;

  /// No description provided for @chatAssistantImageAlt.
  ///
  /// In es, this message translates to:
  /// **'Imagen'**
  String get chatAssistantImageAlt;

  /// No description provided for @chatInputDirections.
  ///
  /// In es, this message translates to:
  /// **'Dirección del texto del mensaje'**
  String get chatInputDirections;

  /// No description provided for @activityStart.
  ///
  /// In es, this message translates to:
  /// **'Iniciar'**
  String get activityStart;

  /// No description provided for @activityStop.
  ///
  /// In es, this message translates to:
  /// **'Parar'**
  String get activityStop;

  /// No description provided for @activityFinish.
  ///
  /// In es, this message translates to:
  /// **'Terminar'**
  String get activityFinish;

  /// No description provided for @activityFinishDay.
  ///
  /// In es, this message translates to:
  /// **'Finalizar día'**
  String get activityFinishDay;

  /// No description provided for @activityChooseAnother.
  ///
  /// In es, this message translates to:
  /// **'Elegir otra actividad'**
  String get activityChooseAnother;

  /// No description provided for @activitySubtractCycle.
  ///
  /// In es, this message translates to:
  /// **'Restar ciclo'**
  String get activitySubtractCycle;

  /// No description provided for @activityAddCycle.
  ///
  /// In es, this message translates to:
  /// **'Añadir ciclo completado'**
  String get activityAddCycle;

  /// No description provided for @activityNoticesOff.
  ///
  /// In es, this message translates to:
  /// **'Avisos desactivados'**
  String get activityNoticesOff;

  /// No description provided for @activityEnableNotices.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get activityEnableNotices;

  /// No description provided for @activityCycles.
  ///
  /// In es, this message translates to:
  /// **'Ciclos'**
  String get activityCycles;

  /// No description provided for @aiUnavailableFocus.
  ///
  /// In es, this message translates to:
  /// **'IA no disponible · puedes parar y guardar notas localmente'**
  String get aiUnavailableFocus;

  /// No description provided for @activityRestInProgress.
  ///
  /// In es, this message translates to:
  /// **'Descanso en curso'**
  String get activityRestInProgress;

  /// No description provided for @activityRestChangeNoticePrompt.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres cambiar también el aviso que ya está programado?'**
  String get activityRestChangeNoticePrompt;

  /// No description provided for @activityKeepNotice.
  ///
  /// In es, this message translates to:
  /// **'Conservar aviso'**
  String get activityKeepNotice;

  /// No description provided for @activityChangeNotice.
  ///
  /// In es, this message translates to:
  /// **'Cambiar aviso'**
  String get activityChangeNotice;

  /// No description provided for @personalityInstructions.
  ///
  /// In es, this message translates to:
  /// **'Personalidad e instrucciones'**
  String get personalityInstructions;

  /// No description provided for @personalityInstructionsHelp.
  ///
  /// In es, this message translates to:
  /// **'Describe el tono y cómo quieres que te acompañe. Solo afecta a sus respuestas de IA.'**
  String get personalityInstructionsHelp;

  /// No description provided for @personalitySuggestionTone.
  ///
  /// In es, this message translates to:
  /// **'Usa un tono cercano y claro.'**
  String get personalitySuggestionTone;

  /// No description provided for @personalitySuggestionAsk.
  ///
  /// In es, this message translates to:
  /// **'Haz preguntas breves cuando falten datos.'**
  String get personalitySuggestionAsk;

  /// No description provided for @personalitySuggestionAccuracy.
  ///
  /// In es, this message translates to:
  /// **'No inventes información ni avances que no haya contado.'**
  String get personalitySuggestionAccuracy;

  /// No description provided for @personalityTooLong.
  ///
  /// In es, this message translates to:
  /// **'La personalidad no puede superar los 4000 caracteres.'**
  String get personalityTooLong;

  /// No description provided for @personalityDraftTitle.
  ///
  /// In es, this message translates to:
  /// **'Propuesta de personalidad'**
  String get personalityDraftTitle;

  /// No description provided for @personalityDraftAccept.
  ///
  /// In es, this message translates to:
  /// **'Usar propuesta'**
  String get personalityDraftAccept;

  /// No description provided for @personalityDraftButton.
  ///
  /// In es, this message translates to:
  /// **'Ayúdame a redactarla'**
  String get personalityDraftButton;

  /// No description provided for @personalityDraftError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo generar la propuesta. Revisa la conexión de IA e inténtalo de nuevo.'**
  String get personalityDraftError;

  /// No description provided for @activityTargetTitle.
  ///
  /// In es, this message translates to:
  /// **'Objetivo de series'**
  String get activityTargetTitle;

  /// No description provided for @activityTargetLabel.
  ///
  /// In es, this message translates to:
  /// **'Series (vacío para quitar)'**
  String get activityTargetLabel;

  /// No description provided for @activityTargetInvalid.
  ///
  /// In es, this message translates to:
  /// **'Indica un objetivo entre 1 y 100, o déjalo vacío.'**
  String get activityTargetInvalid;

  /// No description provided for @activityTargetEditTooltip.
  ///
  /// In es, this message translates to:
  /// **'Editar objetivo de series'**
  String get activityTargetEditTooltip;

  /// No description provided for @activityTargetPreservedProgress.
  ///
  /// In es, this message translates to:
  /// **'Objetivo: {target}. Conservas {completed} series completadas.'**
  String activityTargetPreservedProgress(Object target, Object completed);

  /// No description provided for @activityTargetUpdated.
  ///
  /// In es, this message translates to:
  /// **'Objetivo actualizado.'**
  String get activityTargetUpdated;

  /// No description provided for @activityNoTarget.
  ///
  /// In es, this message translates to:
  /// **'sin objetivo'**
  String get activityNoTarget;

  /// No description provided for @activityTargetChangedEvent.
  ///
  /// In es, this message translates to:
  /// **'Cambiaste el objetivo de series a {target}'**
  String activityTargetChangedEvent(Object target);

  /// No description provided for @chatTargetProposalAmbiguous.
  ///
  /// In es, this message translates to:
  /// **'No se cambió el objetivo: la propuesta es ambigua o no corresponde a una actividad activa.'**
  String get chatTargetProposalAmbiguous;

  /// No description provided for @chatTargetConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar objetivo de series'**
  String get chatTargetConfirmTitle;

  /// No description provided for @chatTargetRemovePrompt.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres quitar el objetivo?'**
  String get chatTargetRemovePrompt;

  /// No description provided for @chatTargetSetPrompt.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres fijar el objetivo en {target} series?'**
  String chatTargetSetPrompt(Object target);

  /// No description provided for @chatTargetSetPromptWithProgress.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres fijar el objetivo en {target} series? Ya has completado {completed}; se conserva todo el progreso.'**
  String chatTargetSetPromptWithProgress(Object target, Object completed);

  /// No description provided for @chatTargetConfirmButton.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get chatTargetConfirmButton;

  /// No description provided for @chatTargetSavedNoTarget.
  ///
  /// In es, this message translates to:
  /// **'Objetivo guardado: sin objetivo.'**
  String get chatTargetSavedNoTarget;

  /// No description provided for @chatTargetSaved.
  ///
  /// In es, this message translates to:
  /// **'Objetivo guardado: {target} series.'**
  String chatTargetSaved(Object target);

  /// No description provided for @chatTargetSavedWithProgress.
  ///
  /// In es, this message translates to:
  /// **'Objetivo guardado: {target} series. Conservas {completed} series completadas.'**
  String chatTargetSavedWithProgress(Object target, Object completed);

  /// No description provided for @chatTargetStale.
  ///
  /// In es, this message translates to:
  /// **'No se cambió el objetivo. La actividad puede haber cambiado; revísala y vuelve a intentarlo.'**
  String get chatTargetStale;

  /// No description provided for @sheetsTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus hojas de Google Sheets'**
  String get sheetsTitle;

  /// No description provided for @sheetsChooseTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige tu hoja de entrenamiento'**
  String get sheetsChooseTitle;

  /// No description provided for @sheetsSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre'**
  String get sheetsSearch;

  /// No description provided for @sheetsSearchTooltip.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get sheetsSearchTooltip;

  /// No description provided for @sheetsConnect.
  ///
  /// In es, this message translates to:
  /// **'Conectar con Google'**
  String get sheetsConnect;

  /// No description provided for @sheetsReconnect.
  ///
  /// In es, this message translates to:
  /// **'Cambiar cuenta o autorizar de nuevo'**
  String get sheetsReconnect;

  /// No description provided for @sheetsNoResults.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron hojas. Prueba otro nombre o cambia de cuenta.'**
  String get sheetsNoResults;

  /// No description provided for @sheetsLoadMore.
  ///
  /// In es, this message translates to:
  /// **'Cargar más hojas'**
  String get sheetsLoadMore;

  /// No description provided for @dataTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus datos'**
  String get dataTitle;

  /// No description provided for @dataCreateBackup.
  ///
  /// In es, this message translates to:
  /// **'Crear y compartir copia'**
  String get dataCreateBackup;

  /// No description provided for @dataRestoreBackup.
  ///
  /// In es, this message translates to:
  /// **'Restaurar copia'**
  String get dataRestoreBackup;

  /// No description provided for @aiProviderTitle.
  ///
  /// In es, this message translates to:
  /// **'Proveedor de IA'**
  String get aiProviderTitle;

  /// No description provided for @aiConnectTitle.
  ///
  /// In es, this message translates to:
  /// **'Conecta tu asistente'**
  String get aiConnectTitle;

  /// No description provided for @aiProviderLabel.
  ///
  /// In es, this message translates to:
  /// **'Proveedor'**
  String get aiProviderLabel;

  /// No description provided for @sheetChooseTab.
  ///
  /// In es, this message translates to:
  /// **'Elige la pestaña con tus entrenamientos'**
  String get sheetChooseTab;

  /// No description provided for @sheetReview.
  ///
  /// In es, this message translates to:
  /// **'Revisar hoja'**
  String get sheetReview;

  /// No description provided for @sheetRowsRead.
  ///
  /// In es, this message translates to:
  /// **'{count} filas leídas. Se cargará la pestaña completa; aquí se muestran las primeras 12 filas.'**
  String sheetRowsRead(Object count);

  /// No description provided for @sheetRowsReadPreview.
  ///
  /// In es, this message translates to:
  /// **'{count} filas leídas. Vista previa:'**
  String sheetRowsReadPreview(Object count);

  /// No description provided for @sheetLoadPending.
  ///
  /// In es, this message translates to:
  /// **'La hoja se guardará en este móvil, pendiente de interpretación. No necesitas IA para cargarla. Cuando esté conectada, podrás pedirle que interprete su estructura. No se crean entrenamientos ni se envían celdas al proveedor al cargar.'**
  String get sheetLoadPending;

  /// No description provided for @sheetSendToAi.
  ///
  /// In es, this message translates to:
  /// **'Al pulsar Cargar y analizar, estas celdas se enviarán al proveedor de IA configurado. Las filas se conservan tal como aparecen, sin convertirlas en entrenamientos.'**
  String get sheetSendToAi;

  /// No description provided for @sheetReadOnlyGoogle.
  ///
  /// In es, this message translates to:
  /// **'Es una copia de lectura: para traer cambios posteriores usa Actualizar hoja en el chat.'**
  String get sheetReadOnlyGoogle;

  /// No description provided for @sheetReadOnlyFile.
  ///
  /// In es, this message translates to:
  /// **'Es una copia de lectura del archivo. Para traer cambios, vuelve a cargarlo.'**
  String get sheetReadOnlyFile;

  /// No description provided for @sheetsConnecting.
  ///
  /// In es, this message translates to:
  /// **'Conectando con Google…'**
  String get sheetsConnecting;

  /// No description provided for @sheetsAuthorizeProgress.
  ///
  /// In es, this message translates to:
  /// **'Elige tu cuenta y autoriza la lectura en Google…'**
  String get sheetsAuthorizeProgress;

  /// No description provided for @sheetsSearchProgress.
  ///
  /// In es, this message translates to:
  /// **'Buscando tus hojas…'**
  String get sheetsSearchProgress;

  /// No description provided for @sheetsLoadingTabs.
  ///
  /// In es, this message translates to:
  /// **'Cargando las pestañas de {name}…'**
  String sheetsLoadingTabs(Object name);

  /// No description provided for @sheetsReadingTab.
  ///
  /// In es, this message translates to:
  /// **'Leyendo {name}…'**
  String sheetsReadingTab(Object name);

  /// No description provided for @sheetsReadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer la hoja. Vuelve a intentarlo.'**
  String get sheetsReadError;

  /// No description provided for @sheetsGoogleError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo conectar con Google.'**
  String get sheetsGoogleError;

  /// No description provided for @sheetsRetry.
  ///
  /// In es, this message translates to:
  /// **'Volver a cargar las hojas'**
  String get sheetsRetry;

  /// No description provided for @sheetsPartial.
  ///
  /// In es, this message translates to:
  /// **'Google devolvió una búsqueda parcial. Busca la hoja por su nombre.'**
  String get sheetsPartial;

  /// No description provided for @sheetsAuthIncomplete.
  ///
  /// In es, this message translates to:
  /// **'Google no completó la autorización. Pulsa Conectar con Google para volver a intentarlo; aún no se han cargado tus hojas.'**
  String get sheetsAuthIncomplete;

  /// No description provided for @sheetsSearchAccountChanged.
  ///
  /// In es, this message translates to:
  /// **'La cuenta cambió durante la búsqueda. Vuelve a conectar para continuar.'**
  String get sheetsSearchAccountChanged;

  /// No description provided for @sheetsChooseAccountChanged.
  ///
  /// In es, this message translates to:
  /// **'La cuenta cambió durante la selección. Vuelve a conectar para continuar.'**
  String get sheetsChooseAccountChanged;

  /// No description provided for @sheetsReadAccountChanged.
  ///
  /// In es, this message translates to:
  /// **'La cuenta cambió durante la lectura. No se cargaron los datos.'**
  String get sheetsReadAccountChanged;

  /// No description provided for @sheetsNoTabs.
  ///
  /// In es, this message translates to:
  /// **'Esta hoja no tiene pestañas disponibles.'**
  String get sheetsNoTabs;

  /// No description provided for @sheetsReadRowsIntro.
  ///
  /// In es, this message translates to:
  /// **'filas leídas. Se cargará la pestaña completa; aquí se muestran las primeras 12 filas.'**
  String get sheetsReadRowsIntro;

  /// No description provided for @syncTitle.
  ///
  /// In es, this message translates to:
  /// **'Enviar a Google Sheets'**
  String get syncTitle;

  /// No description provided for @syncIntro.
  ///
  /// In es, this message translates to:
  /// **'Conecta Google y elige tu hoja una vez. El chat podrá consultarla actualizada y enviar resultados; aquí también puedes revisar un envío manual.'**
  String get syncIntro;

  /// No description provided for @syncNoSessions.
  ///
  /// In es, this message translates to:
  /// **'No hay sesiones finalizadas para enviar. Puedes probar la conexión sin iniciar una actividad.'**
  String get syncNoSessions;

  /// No description provided for @syncWorkout.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento'**
  String get syncWorkout;

  /// No description provided for @syncConnectWrite.
  ///
  /// In es, this message translates to:
  /// **'Conectar Google y permitir escritura'**
  String get syncConnectWrite;

  /// No description provided for @syncDestinationAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta de destino: {email}'**
  String syncDestinationAccount(Object email);

  /// No description provided for @syncCheckConnection.
  ///
  /// In es, this message translates to:
  /// **'Comprobar conexión'**
  String get syncCheckConnection;

  /// No description provided for @syncDisconnect.
  ///
  /// In es, this message translates to:
  /// **'Desconectar esta hoja'**
  String get syncDisconnect;

  /// No description provided for @syncChangeAccount.
  ///
  /// In es, this message translates to:
  /// **'Cambiar cuenta de destino'**
  String get syncChangeAccount;

  /// No description provided for @syncCreateNew.
  ///
  /// In es, this message translates to:
  /// **'Crear hoja nueva'**
  String get syncCreateNew;

  /// No description provided for @syncNewSheetName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la nueva hoja'**
  String get syncNewSheetName;

  /// No description provided for @syncCreateDrive.
  ///
  /// In es, this message translates to:
  /// **'Crear hoja en mi Google Drive'**
  String get syncCreateDrive;

  /// No description provided for @syncSheet.
  ///
  /// In es, this message translates to:
  /// **'Hoja de Google'**
  String get syncSheet;

  /// No description provided for @syncTab.
  ///
  /// In es, this message translates to:
  /// **'Pestaña'**
  String get syncTab;

  /// No description provided for @syncInstructions.
  ///
  /// In es, this message translates to:
  /// **'Preferencias o aclaraciones sobre la hoja'**
  String get syncInstructions;

  /// No description provided for @syncInstructionsHint.
  ///
  /// In es, this message translates to:
  /// **'Ej.: usa el bloque de octubre, cargas totales'**
  String get syncInstructionsHint;

  /// No description provided for @syncAllowOverwrite.
  ///
  /// In es, this message translates to:
  /// **'Permitir actualizar celdas con datos'**
  String get syncAllowOverwrite;

  /// No description provided for @syncOverwriteHelp.
  ///
  /// In es, this message translates to:
  /// **'La revisión mostrará el valor anterior y el nuevo. Las fórmulas se conservan.'**
  String get syncOverwriteHelp;

  /// No description provided for @syncAutomatic.
  ///
  /// In es, this message translates to:
  /// **'Enviar sesiones automáticamente al finalizar'**
  String get syncAutomatic;

  /// No description provided for @syncAutomaticChatHelp.
  ///
  /// In es, this message translates to:
  /// **'Los envíos del chat siguen disponibles aunque pauses los automáticos.'**
  String get syncAutomaticChatHelp;

  /// No description provided for @syncAutomaticActivityHelp.
  ///
  /// In es, this message translates to:
  /// **'Por ahora los registros de actividad no identifican su acompañante; puedes pedir envíos y ediciones desde el chat.'**
  String get syncAutomaticActivityHelp;

  /// No description provided for @syncSavePreferences.
  ///
  /// In es, this message translates to:
  /// **'Guardar conexión y preferencias'**
  String get syncSavePreferences;

  /// No description provided for @syncReviewLoadChat.
  ///
  /// In es, this message translates to:
  /// **'Revisar y cargar hoja en el chat'**
  String get syncReviewLoadChat;

  /// No description provided for @syncDiagnostics.
  ///
  /// In es, this message translates to:
  /// **'Diagnóstico de la conexión'**
  String get syncDiagnostics;

  /// No description provided for @syncDiagnosticsHelp.
  ///
  /// In es, this message translates to:
  /// **'Prueba la pestaña elegida sin iniciar una actividad. La escritura usa una pestaña temporal y no modifica tus entrenamientos.'**
  String get syncDiagnosticsHelp;

  /// No description provided for @syncTestRead.
  ///
  /// In es, this message translates to:
  /// **'Probar lectura con IA'**
  String get syncTestRead;

  /// No description provided for @syncTestWrite.
  ///
  /// In es, this message translates to:
  /// **'Probar escritura con IA'**
  String get syncTestWrite;

  /// No description provided for @syncPrepare.
  ///
  /// In es, this message translates to:
  /// **'Preparar y revisar envío'**
  String get syncPrepare;

  /// No description provided for @syncNoSheet.
  ///
  /// In es, this message translates to:
  /// **'Elige una hoja y una pestaña.'**
  String get syncNoSheet;

  /// No description provided for @syncNoValidWorkout.
  ///
  /// In es, this message translates to:
  /// **'Elige una hoja, una pestaña y un entrenamiento finalizado.'**
  String get syncNoValidWorkout;

  /// No description provided for @syncSessionUnavailable.
  ///
  /// In es, this message translates to:
  /// **'La sesión ya no está disponible.'**
  String get syncSessionUnavailable;

  /// No description provided for @syncConnectionError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo recuperar la hoja guardada. Puedes elegir otra.'**
  String get syncConnectionError;

  /// No description provided for @syncOperationError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la operación. Inténtalo de nuevo.'**
  String get syncOperationError;

  /// No description provided for @syncGoogleUnconfirmed.
  ///
  /// In es, this message translates to:
  /// **'Google no confirmó la operación.'**
  String get syncGoogleUnconfirmed;

  /// No description provided for @syncNameInvalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre de hasta 80 caracteres.'**
  String get syncNameInvalid;

  /// No description provided for @syncLoadChatTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisar hoja para el chat'**
  String get syncLoadChatTitle;

  /// No description provided for @syncConfirmLoad.
  ///
  /// In es, this message translates to:
  /// **'Confirmar y cargar'**
  String get syncConfirmLoad;

  /// No description provided for @syncReadConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Lectura confirmada: {count} filas recibidas de Google. Respuesta del modelo: {answer}'**
  String syncReadConfirmed(Object count, Object answer);

  /// No description provided for @syncWriteConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Escritura confirmada: el modelo propuso «{marker}», Google aceptó la prueba y la pestaña temporal se eliminó. No se enviaron entrenamientos.'**
  String syncWriteConfirmed(Object marker);

  /// No description provided for @syncSentConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento enviado a Google Sheets. Recibo comprobado; volver a enviarlo no lo duplica.'**
  String get syncSentConfirmed;

  /// No description provided for @syncReturnChat.
  ///
  /// In es, this message translates to:
  /// **'Volver al chat'**
  String get syncReturnChat;

  /// No description provided for @syncDestination.
  ///
  /// In es, this message translates to:
  /// **'Destino: {name} / {tab}'**
  String syncDestination(Object name, Object tab);

  /// No description provided for @syncReceiptNote.
  ///
  /// In es, this message translates to:
  /// **'Google guardará también un recibo del envío para evitar duplicados.'**
  String get syncReceiptNote;

  /// No description provided for @syncReviewCount.
  ///
  /// In es, this message translates to:
  /// **'{count} celdas. Se comprobará que no hayan cambiado desde esta revisión.'**
  String syncReviewCount(Object count);

  /// No description provided for @syncOriginalData.
  ///
  /// In es, this message translates to:
  /// **'Ver datos originales del entrenamiento'**
  String get syncOriginalData;

  /// No description provided for @syncConfirmSend.
  ///
  /// In es, this message translates to:
  /// **'Confirmar y enviar a Google Sheets'**
  String get syncConfirmSend;

  /// No description provided for @syncDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar propuesta'**
  String get syncDiscard;

  /// No description provided for @sheetNoTabs.
  ///
  /// In es, this message translates to:
  /// **'Esta hoja no tiene pestañas disponibles.'**
  String get sheetNoTabs;

  /// No description provided for @sheetsLoad.
  ///
  /// In es, this message translates to:
  /// **'Cargar hoja'**
  String get sheetsLoad;

  /// No description provided for @sheetsLoadAnalyze.
  ///
  /// In es, this message translates to:
  /// **'Cargar y analizar'**
  String get sheetsLoadAnalyze;

  /// No description provided for @rowLabel.
  ///
  /// In es, this message translates to:
  /// **'Fila'**
  String get rowLabel;

  /// No description provided for @syncProposedSessionInvalid.
  ///
  /// In es, this message translates to:
  /// **'La sesión propuesta no está finalizada o no pertenece a este perfil. Elige una sesión válida.'**
  String get syncProposedSessionInvalid;

  /// No description provided for @syncConnectionSaved.
  ///
  /// In es, this message translates to:
  /// **'Conexión guardada. El chat leerá la hoja actual y podrá enviar los resultados sin pedir autorización en cada uso.'**
  String get syncConnectionSaved;

  /// No description provided for @syncIdentityUnconfirmed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo confirmar la cuenta de Google seleccionada.'**
  String get syncIdentityUnconfirmed;

  /// No description provided for @sheetAllRowsWillLoad.
  ///
  /// In es, this message translates to:
  /// **'Se cargarán todas las filas de la pestaña.'**
  String get sheetAllRowsWillLoad;

  /// No description provided for @syncAccountChangedReview.
  ///
  /// In es, this message translates to:
  /// **'La cuenta cambió mientras revisabas la pestaña. La hoja anterior se conserva; vuelve a conectar para cargarla.'**
  String get syncAccountChangedReview;

  /// No description provided for @syncLoadedIntoChat.
  ///
  /// In es, this message translates to:
  /// **'Hoja cargada en el chat: {name} / {tab}.'**
  String syncLoadedIntoChat(Object name, Object tab);

  /// No description provided for @syncConfigureAi.
  ///
  /// In es, this message translates to:
  /// **'Configura primero la IA para probar el acceso desde el modelo.'**
  String get syncConfigureAi;

  /// No description provided for @syncModelEmpty.
  ///
  /// In es, this message translates to:
  /// **'El modelo no devolvió una respuesta.'**
  String get syncModelEmpty;

  /// No description provided for @syncInvalidMarker.
  ///
  /// In es, this message translates to:
  /// **'El modelo respondió, pero no dio un marcador válido para la prueba.'**
  String get syncInvalidMarker;

  /// No description provided for @syncWorkoutChanged.
  ///
  /// In es, this message translates to:
  /// **'El entrenamiento cambió. Prepara de nuevo el envío para revisar los datos actuales.'**
  String get syncWorkoutChanged;

  /// No description provided for @syncRefreshAfterSendFailed.
  ///
  /// In es, this message translates to:
  /// **'Envío confirmado. No se pudo refrescar la copia del chat; vuelve a cargar la hoja para consultar sus nuevos datos.'**
  String get syncRefreshAfterSendFailed;

  /// No description provided for @syncReceiptSent.
  ///
  /// In es, this message translates to:
  /// **'Google Sheets confirmado: entrenamiento «{workout}» ({id}) enviado a «{name} / {tab}». El recibo de Google confirma el envío.'**
  String syncReceiptSent(Object workout, Object id, Object name, Object tab);

  /// No description provided for @syncReceiptCreated.
  ///
  /// In es, this message translates to:
  /// **'Google Sheets confirmado: hoja «{name}» creada, pestaña «{tab}». El progreso aún no se ha enviado.'**
  String syncReceiptCreated(Object name, Object tab);

  /// No description provided for @sheetsAssistantIntro.
  ///
  /// In es, this message translates to:
  /// **'Conecta tu cuenta, elige la hoja y su pestaña. Revisa los datos antes de compartirlos con tu asistente.'**
  String get sheetsAssistantIntro;

  /// No description provided for @sheetsImportIntro.
  ///
  /// In es, this message translates to:
  /// **'TrackIA usa la autorización de Google para leer tus hojas. Los datos se guardan en este móvil cuando confirmas la importación.'**
  String get sheetsImportIntro;

  /// No description provided for @sheetsErrorExpired.
  ///
  /// In es, this message translates to:
  /// **'La autorización de Google ha caducado. Vuelve a conectar tu cuenta.'**
  String get sheetsErrorExpired;

  /// No description provided for @sheetsErrorPermission.
  ///
  /// In es, this message translates to:
  /// **'Google no permite esta operación. Comprueba el acceso y los permisos de la hoja.'**
  String get sheetsErrorPermission;

  /// No description provided for @sheetsErrorAccount.
  ///
  /// In es, this message translates to:
  /// **'La lectura no corresponde a la cuenta autorizada. Vuelve a conectar desde tu perfil.'**
  String get sheetsErrorAccount;

  /// No description provided for @sheetsErrorNotFound.
  ///
  /// In es, this message translates to:
  /// **'La hoja ya no está disponible para esta cuenta.'**
  String get sheetsErrorNotFound;

  /// No description provided for @sheetsErrorRateLimit.
  ///
  /// In es, this message translates to:
  /// **'Google ha recibido demasiadas solicitudes. Espera un momento y vuelve a intentarlo.'**
  String get sheetsErrorRateLimit;

  /// No description provided for @sheetsErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'No se pudo confirmar la operación con Google. El progreso local se conserva; al reintentar se comprobará el recibo.'**
  String get sheetsErrorNetwork;

  /// No description provided for @sheetsErrorTooLarge.
  ///
  /// In es, this message translates to:
  /// **'La pestaña supera 20 MB. Elige una pestaña más pequeña.'**
  String get sheetsErrorTooLarge;

  /// No description provided for @sheetsErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Google no pudo completar la operación. Vuelve a intentarlo.'**
  String get sheetsErrorGeneric;

  /// No description provided for @sheetsErrorBusy.
  ///
  /// In es, this message translates to:
  /// **'Ya hay una operación con Google en curso. Espera a que termine.'**
  String get sheetsErrorBusy;

  /// No description provided for @syncBeforeValue.
  ///
  /// In es, this message translates to:
  /// **'Antes: {value}'**
  String syncBeforeValue(Object value);

  /// No description provided for @syncEmptyCell.
  ///
  /// In es, this message translates to:
  /// **'(vacía)'**
  String get syncEmptyCell;

  /// No description provided for @syncDisconnected.
  ///
  /// In es, this message translates to:
  /// **'Hoja desconectada. Los datos locales y los envíos pendientes se conservan.'**
  String get syncDisconnected;

  /// No description provided for @aiProviderDescription.
  ///
  /// In es, this message translates to:
  /// **'Elige un proveedor en la nube o ejecuta un modelo local en este móvil. Los modelos locales pueden funcionar sin conexión; el rendimiento depende de la memoria y del modelo elegido.'**
  String get aiProviderDescription;

  /// No description provided for @aiConfigReadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer la configuración guardada.'**
  String get aiConfigReadError;

  /// No description provided for @aiModelImportError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo importar el archivo GGUF: {error}'**
  String aiModelImportError(Object error);

  /// No description provided for @aiMemoryAvailableNow.
  ///
  /// In es, this message translates to:
  /// **'Disponible ahora'**
  String get aiMemoryAvailableNow;

  /// No description provided for @aiMemoryAfterModel.
  ///
  /// In es, this message translates to:
  /// **'Después de modelo y proyector'**
  String get aiMemoryAfterModel;

  /// No description provided for @aiMemoryAfterContext.
  ///
  /// In es, this message translates to:
  /// **'Después + contexto seleccionado'**
  String get aiMemoryAfterContext;

  /// No description provided for @aiMemoryContextEstimate.
  ///
  /// In es, this message translates to:
  /// **'El contexto de {context} añadiría aproximadamente {minimum}–{maximum} de RAM.'**
  String aiMemoryContextEstimate(
    Object context,
    Object minimum,
    Object maximum,
  );

  /// No description provided for @aiMemoryShortfall.
  ///
  /// In es, this message translates to:
  /// **'La estimación supera lo disponible por {amount}.'**
  String aiMemoryShortfall(Object amount);

  /// No description provided for @aiMemoryEstimateHelp.
  ///
  /// In es, this message translates to:
  /// **'Estimación orientativa de pesos y proyector; el contexto elegido añade consumo y puede variar según el modelo.'**
  String get aiMemoryEstimateHelp;

  /// No description provided for @aiConnectedChooseModel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta conectada. Elige un modelo y prueba la conexión para usar el asistente.'**
  String get aiConnectedChooseModel;

  /// No description provided for @aiIdentityConnected.
  ///
  /// In es, this message translates to:
  /// **'Identidad conectada. Puedes autorizar por separado el uso de tu plan ChatGPT.'**
  String get aiIdentityConnected;

  /// No description provided for @aiChatGptDisconnected.
  ///
  /// In es, this message translates to:
  /// **'Sesión ChatGPT desconectada.'**
  String get aiChatGptDisconnected;

  /// No description provided for @aiChatGptRemoteRevocationUnconfirmed.
  ///
  /// In es, this message translates to:
  /// **'Sesión desconectada en este móvil. No se confirmó la revocación remota; desconecta TrackIA también en los ajustes de ChatGPT.'**
  String get aiChatGptRemoteRevocationUnconfirmed;

  /// No description provided for @aiOperationError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la operación{details}'**
  String aiOperationError(Object details);

  /// No description provided for @aiOperationDetails.
  ///
  /// In es, this message translates to:
  /// **': {error}'**
  String aiOperationDetails(Object error);

  /// No description provided for @aiNoModelImported.
  ///
  /// In es, this message translates to:
  /// **'No hay modelo importado.'**
  String get aiNoModelImported;

  /// No description provided for @aiSelectImportGguf.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar / importar modelo .gguf'**
  String get aiSelectImportGguf;

  /// No description provided for @aiLocalContextTitle.
  ///
  /// In es, this message translates to:
  /// **'Contexto del modelo local'**
  String get aiLocalContextTitle;

  /// No description provided for @aiLocalContextHelp.
  ///
  /// In es, this message translates to:
  /// **'TrackIA recomienda {context} para sus instrucciones, historial y datos. La recomendación cubre las necesidades de la app, no el límite de este GGUF. Si el modelo no soporta el tamaño elegido, puede fallar; tú decides si bajarlo.'**
  String aiLocalContextHelp(Object context);

  /// No description provided for @aiContextSelected.
  ///
  /// In es, this message translates to:
  /// **'Seleccionado: {context}'**
  String aiContextSelected(Object context);

  /// No description provided for @aiUseRecommendation.
  ///
  /// In es, this message translates to:
  /// **'Usar recomendación'**
  String get aiUseRecommendation;

  /// No description provided for @aiVisualProjector.
  ///
  /// In es, this message translates to:
  /// **'Proyector visual (opcional)'**
  String get aiVisualProjector;

  /// No description provided for @aiProjectorHelp.
  ///
  /// In es, this message translates to:
  /// **'Añádelo para usar imágenes. MiniCPM‑V necesita el archivo mmproj GGUF correspondiente.'**
  String get aiProjectorHelp;

  /// No description provided for @aiNoProjector.
  ///
  /// In es, this message translates to:
  /// **'Sin proyector visual.'**
  String get aiNoProjector;

  /// No description provided for @aiSelectProjector.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar proyector mmproj'**
  String get aiSelectProjector;

  /// No description provided for @aiMemoryHelp.
  ///
  /// In es, this message translates to:
  /// **'La memoria disponible se informa aparte. La recomendación de 8192 tokens responde a lo que TrackIA necesita; el GGUF puede no soportarlo y tú puedes elegir otro tamaño.'**
  String get aiMemoryHelp;

  /// No description provided for @aiRecalculateMemory.
  ///
  /// In es, this message translates to:
  /// **'Volver a calcular memoria disponible'**
  String get aiRecalculateMemory;

  /// No description provided for @aiApiBase.
  ///
  /// In es, this message translates to:
  /// **'URL base de la API'**
  String get aiApiBase;

  /// No description provided for @aiHttpsExample.
  ///
  /// In es, this message translates to:
  /// **'HTTPS, por ejemplo https://tu-proveedor.com/v1'**
  String get aiHttpsExample;

  /// No description provided for @aiChatGptPlanHelp.
  ///
  /// In es, this message translates to:
  /// **'Usa tu plan si tu cuenta y espacio son elegibles. El uso consume sus límites compartidos. No da acceso a tus conversaciones de ChatGPT.'**
  String get aiChatGptPlanHelp;

  /// No description provided for @aiChatGptAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta ChatGPT'**
  String get aiChatGptAccount;

  /// No description provided for @aiChatGptConnectedPlan.
  ///
  /// In es, this message translates to:
  /// **'Conectada · permiso de uso del plan concedido'**
  String get aiChatGptConnectedPlan;

  /// No description provided for @aiChatGptConnectedIdentity.
  ///
  /// In es, this message translates to:
  /// **'Conectada · solo identidad'**
  String get aiChatGptConnectedIdentity;

  /// No description provided for @aiChatGptNotConnected.
  ///
  /// In es, this message translates to:
  /// **'ChatGPT sin conectar'**
  String get aiChatGptNotConnected;

  /// No description provided for @aiContinueChatGpt.
  ///
  /// In es, this message translates to:
  /// **'Continuar con ChatGPT'**
  String get aiContinueChatGpt;

  /// No description provided for @aiReviewPlanPermission.
  ///
  /// In es, this message translates to:
  /// **'Revisar permiso de uso del plan'**
  String get aiReviewPlanPermission;

  /// No description provided for @aiAuthorizePlan.
  ///
  /// In es, this message translates to:
  /// **'Autorizar uso de mi plan ChatGPT'**
  String get aiAuthorizePlan;

  /// No description provided for @aiAddAccount.
  ///
  /// In es, this message translates to:
  /// **'Añadir otra cuenta o espacio'**
  String get aiAddAccount;

  /// No description provided for @aiViewUsagePermissions.
  ///
  /// In es, this message translates to:
  /// **'Ver uso y permisos en ChatGPT'**
  String get aiViewUsagePermissions;

  /// No description provided for @aiDisconnectChatGpt.
  ///
  /// In es, this message translates to:
  /// **'Desconectar ChatGPT'**
  String get aiDisconnectChatGpt;

  /// No description provided for @aiCancelConnection.
  ///
  /// In es, this message translates to:
  /// **'Cancelar conexión'**
  String get aiCancelConnection;

  /// No description provided for @aiApiKey.
  ///
  /// In es, this message translates to:
  /// **'Clave API'**
  String get aiApiKey;

  /// No description provided for @aiHideKey.
  ///
  /// In es, this message translates to:
  /// **'Ocultar clave'**
  String get aiHideKey;

  /// No description provided for @aiShowKey.
  ///
  /// In es, this message translates to:
  /// **'Mostrar clave'**
  String get aiShowKey;

  /// No description provided for @aiFetchModels.
  ///
  /// In es, this message translates to:
  /// **'Obtener / actualizar modelos'**
  String get aiFetchModels;

  /// No description provided for @aiLoadingModels.
  ///
  /// In es, this message translates to:
  /// **'Consultando modelos…'**
  String get aiLoadingModels;

  /// No description provided for @aiModelLabel.
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get aiModelLabel;

  /// No description provided for @aiChooseCatalogModel.
  ///
  /// In es, this message translates to:
  /// **'Elige un modelo del catálogo'**
  String get aiChooseCatalogModel;

  /// No description provided for @aiCurrentModelPreserved.
  ///
  /// In es, this message translates to:
  /// **'Modelo actual: {model}. Se conserva aunque no aparezca en el catálogo.'**
  String aiCurrentModelPreserved(Object model);

  /// No description provided for @aiHideManualId.
  ///
  /// In es, this message translates to:
  /// **'Ocultar identificador manual'**
  String get aiHideManualId;

  /// No description provided for @aiEnterManualModel.
  ///
  /// In es, this message translates to:
  /// **'Introducir modelo manualmente'**
  String get aiEnterManualModel;

  /// No description provided for @aiModelIdentifier.
  ///
  /// In es, this message translates to:
  /// **'Identificador del modelo'**
  String get aiModelIdentifier;

  /// No description provided for @aiOpenCodeNotice.
  ///
  /// In es, this message translates to:
  /// **'Go está orientado a agentes de programación. Esta conexión se identifica como TrackIA; comprueba con tu proveedor si admite este uso. No se cambia automáticamente a Zen ni a otro servicio.'**
  String get aiOpenCodeNotice;

  /// No description provided for @aiApiSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración de la API'**
  String get aiApiSettings;

  /// No description provided for @aiHttpsBase.
  ///
  /// In es, this message translates to:
  /// **'URL base HTTPS'**
  String get aiHttpsBase;

  /// No description provided for @aiProtocol.
  ///
  /// In es, this message translates to:
  /// **'Formato compatible con el modelo'**
  String get aiProtocol;

  /// No description provided for @aiConfigSaved.
  ///
  /// In es, this message translates to:
  /// **'Configuración guardada.'**
  String get aiConfigSaved;

  /// No description provided for @aiSaveLocalModel.
  ///
  /// In es, this message translates to:
  /// **'Guardar modelo local'**
  String get aiSaveLocalModel;

  /// No description provided for @aiSaveProvider.
  ///
  /// In es, this message translates to:
  /// **'Guardar proveedor'**
  String get aiSaveProvider;

  /// No description provided for @aiProviderResponded.
  ///
  /// In es, this message translates to:
  /// **'El proveedor respondió:\n{answer}'**
  String aiProviderResponded(Object answer);

  /// No description provided for @aiTestLocalModel.
  ///
  /// In es, this message translates to:
  /// **'Probar modelo en este móvil'**
  String get aiTestLocalModel;

  /// No description provided for @aiTestChatGpt.
  ///
  /// In es, this message translates to:
  /// **'Probar conexión · usa mi plan ChatGPT'**
  String get aiTestChatGpt;

  /// No description provided for @aiTestApi.
  ///
  /// In es, this message translates to:
  /// **'Probar conexión · usa tu API'**
  String get aiTestApi;

  /// No description provided for @aiConfigDeleted.
  ///
  /// In es, this message translates to:
  /// **'Configuración y clave eliminadas.'**
  String get aiConfigDeleted;

  /// No description provided for @aiDeleteConfig.
  ///
  /// In es, this message translates to:
  /// **'Eliminar configuración y clave'**
  String get aiDeleteConfig;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
