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
  /// **'Racha (días): {days}'**
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

  /// No description provided for @appVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String appVersion(Object version);

  /// No description provided for @activityIdleOtherActive.
  ///
  /// In es, this message translates to:
  /// **'Otro acompañante activo'**
  String get activityIdleOtherActive;

  /// No description provided for @activityIdleNoActivity.
  ///
  /// In es, this message translates to:
  /// **'Sin actividad'**
  String get activityIdleNoActivity;

  /// No description provided for @activityIdleEndOther.
  ///
  /// In es, this message translates to:
  /// **'Termina la otra actividad para iniciar aquí'**
  String get activityIdleEndOther;

  /// No description provided for @activityIdleRegisterAnytime.
  ///
  /// In es, this message translates to:
  /// **'Registra una cuando quieras'**
  String get activityIdleRegisterAnytime;

  /// No description provided for @activityNewActivity.
  ///
  /// In es, this message translates to:
  /// **'Nueva actividad'**
  String get activityNewActivity;

  /// No description provided for @activityIdleRecord.
  ///
  /// In es, this message translates to:
  /// **'Registrar'**
  String get activityIdleRecord;

  /// No description provided for @activityRestLabel.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get activityRestLabel;

  /// No description provided for @activityRestDone.
  ///
  /// In es, this message translates to:
  /// **'Descanso terminado'**
  String get activityRestDone;

  /// No description provided for @activityRestPaused.
  ///
  /// In es, this message translates to:
  /// **'Descanso pausado'**
  String get activityRestPaused;

  /// No description provided for @activityRestPause.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get activityRestPause;

  /// No description provided for @activityRestContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get activityRestContinue;

  /// No description provided for @activityRestStart.
  ///
  /// In es, this message translates to:
  /// **'Iniciar descanso'**
  String get activityRestStart;

  /// No description provided for @activityRestRestart.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar descanso'**
  String get activityRestRestart;

  /// No description provided for @activityRestAdjust.
  ///
  /// In es, this message translates to:
  /// **'{seconds}s · Ajustar'**
  String activityRestAdjust(int seconds);

  /// No description provided for @activityRestNotice.
  ///
  /// In es, this message translates to:
  /// **'Aviso con esta pantalla abierta; el tiempo sigue al salir.'**
  String get activityRestNotice;

  /// No description provided for @activityRestDurationTitle.
  ///
  /// In es, this message translates to:
  /// **'Tiempo de descanso'**
  String get activityRestDurationTitle;

  /// No description provided for @activityRestSecondsLabel.
  ///
  /// In es, this message translates to:
  /// **'Segundos'**
  String get activityRestSecondsLabel;

  /// No description provided for @activityRestRangeHint.
  ///
  /// In es, this message translates to:
  /// **'Entre 5 y 1800 segundos. Al aplicar, el contador queda listo para empezar.'**
  String get activityRestRangeHint;

  /// No description provided for @activityRestApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get activityRestApply;

  /// No description provided for @activityDialogNameTitle.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la actividad'**
  String get activityDialogNameTitle;

  /// No description provided for @activityDialogSaveName.
  ///
  /// In es, this message translates to:
  /// **'Guardar nombre'**
  String get activityDialogSaveName;

  /// No description provided for @activityDialogRestRange.
  ///
  /// In es, this message translates to:
  /// **'Entre 0 y 1800'**
  String get activityDialogRestRange;

  /// No description provided for @activityDialogWhatToDo.
  ///
  /// In es, this message translates to:
  /// **'¿Qué vas a hacer?'**
  String get activityDialogWhatToDo;

  /// No description provided for @activityDialogYourActivities.
  ///
  /// In es, this message translates to:
  /// **'Tus actividades'**
  String get activityDialogYourActivities;

  /// No description provided for @activityDialogInstantRecord.
  ///
  /// In es, this message translates to:
  /// **'Registro puntual'**
  String get activityDialogInstantRecord;

  /// No description provided for @activityDialogYourActivity.
  ///
  /// In es, this message translates to:
  /// **'Tu actividad'**
  String get activityDialogYourActivity;

  /// No description provided for @activityDialogFromCurrentWorkout.
  ///
  /// In es, this message translates to:
  /// **'Del entrenamiento actual'**
  String get activityDialogFromCurrentWorkout;

  /// No description provided for @activityDialogSetsProgress.
  ///
  /// In es, this message translates to:
  /// **'{done}/{target} series · {repsMin}–{repsMax} reps'**
  String activityDialogSetsProgress(
    Object done,
    Object target,
    Object repsMin,
    Object repsMax,
  );

  /// No description provided for @activityDialogRepeat.
  ///
  /// In es, this message translates to:
  /// **'Volver a hacer'**
  String get activityDialogRepeat;

  /// No description provided for @activityDialogRoutineSets.
  ///
  /// In es, this message translates to:
  /// **'{routine} · {sets} series'**
  String activityDialogRoutineSets(Object routine, int sets);

  /// No description provided for @activityDialogEndTitle.
  ///
  /// In es, this message translates to:
  /// **'Terminar actividad'**
  String get activityDialogEndTitle;

  /// No description provided for @activityDialogDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get activityDialogDate;

  /// No description provided for @activityDialogTime.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get activityDialogTime;

  /// No description provided for @activityBuilderNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre para la actividad.'**
  String get activityBuilderNameRequired;

  /// No description provided for @activityBuilderOnlyIntegers.
  ///
  /// In es, this message translates to:
  /// **'Escribe solo números enteros.'**
  String get activityBuilderOnlyIntegers;

  /// No description provided for @activityBuilderRange.
  ///
  /// In es, this message translates to:
  /// **'{what} va de {min} a {max}.'**
  String activityBuilderRange(Object what, int min, int max);

  /// No description provided for @activityBuilderWhatDuration.
  ///
  /// In es, this message translates to:
  /// **'La duración'**
  String get activityBuilderWhatDuration;

  /// No description provided for @activityBuilderWhatRest.
  ///
  /// In es, this message translates to:
  /// **'El descanso'**
  String get activityBuilderWhatRest;

  /// No description provided for @activityBuilderWhatSegments.
  ///
  /// In es, this message translates to:
  /// **'Los tramos previstos'**
  String get activityBuilderWhatSegments;

  /// No description provided for @activityBuilderWhatCycles.
  ///
  /// In es, this message translates to:
  /// **'Los ciclos previstos'**
  String get activityBuilderWhatCycles;

  /// No description provided for @activityBuilderDurationRequired.
  ///
  /// In es, this message translates to:
  /// **'Indica la duración en minutos.'**
  String get activityBuilderDurationRequired;

  /// No description provided for @activityBuilderSegmentNamesPair.
  ///
  /// In es, this message translates to:
  /// **'Indica singular y plural del tramo, o deja los dos vacíos.'**
  String get activityBuilderSegmentNamesPair;

  /// No description provided for @activityBuilderFromTemplate.
  ///
  /// In es, this message translates to:
  /// **'Empezar desde una plantilla'**
  String get activityBuilderFromTemplate;

  /// No description provided for @activityBuilderHowMeasured.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo se mide?'**
  String get activityBuilderHowMeasured;

  /// No description provided for @activityBuilderInstantTitle.
  ///
  /// In es, this message translates to:
  /// **'Puntual'**
  String get activityBuilderInstantTitle;

  /// No description provided for @activityBuilderInstantDetail.
  ///
  /// In es, this message translates to:
  /// **'Un registro sin cronómetro'**
  String get activityBuilderInstantDetail;

  /// No description provided for @activityBuilderFreeTitle.
  ///
  /// In es, this message translates to:
  /// **'Libre'**
  String get activityBuilderFreeTitle;

  /// No description provided for @activityBuilderFreeDetail.
  ///
  /// In es, this message translates to:
  /// **'Cronómetro, sin cuenta atrás'**
  String get activityBuilderFreeDetail;

  /// No description provided for @activityBuilderTimedTitle.
  ///
  /// In es, this message translates to:
  /// **'Con duración'**
  String get activityBuilderTimedTitle;

  /// No description provided for @activityBuilderTimedDetail.
  ///
  /// In es, this message translates to:
  /// **'Cuenta atrás de un tiempo fijo'**
  String get activityBuilderTimedDetail;

  /// No description provided for @activityBuilderSegmentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Por tramos'**
  String get activityBuilderSegmentsTitle;

  /// No description provided for @activityBuilderSegmentsDetail.
  ///
  /// In es, this message translates to:
  /// **'Varios tramos con descanso'**
  String get activityBuilderSegmentsDetail;

  /// No description provided for @activityBuilderDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración (minutos)'**
  String get activityBuilderDuration;

  /// No description provided for @activityBuilderSegmentHelper.
  ///
  /// In es, this message translates to:
  /// **'Opcional: de cada tramo'**
  String get activityBuilderSegmentHelper;

  /// No description provided for @activityBuilderPlannedSegments.
  ///
  /// In es, this message translates to:
  /// **'Tramos previstos (opcional)'**
  String get activityBuilderPlannedSegments;

  /// No description provided for @activityBuilderRestBetween.
  ///
  /// In es, this message translates to:
  /// **'Descanso entre tramos (segundos)'**
  String get activityBuilderRestBetween;

  /// No description provided for @activityBuilderRestHelper.
  ///
  /// In es, this message translates to:
  /// **'90 es un minuto y medio'**
  String get activityBuilderRestHelper;

  /// No description provided for @activityBuilderPlannedCycles.
  ///
  /// In es, this message translates to:
  /// **'Ciclos previstos (opcional)'**
  String get activityBuilderPlannedCycles;

  /// No description provided for @activityBuilderSegmentSingular.
  ///
  /// In es, this message translates to:
  /// **'Un tramo se llama'**
  String get activityBuilderSegmentSingular;

  /// No description provided for @activityBuilderSegmentPlural.
  ///
  /// In es, this message translates to:
  /// **'Varios se llaman'**
  String get activityBuilderSegmentPlural;

  /// No description provided for @activityBuilderWhatToNote.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres anotar? (opcional)'**
  String get activityBuilderWhatToNote;

  /// No description provided for @activityBuilderRemoveField.
  ///
  /// In es, this message translates to:
  /// **'Quitar {label}'**
  String activityBuilderRemoveField(Object label);

  /// No description provided for @activityBuilderMaxFields.
  ///
  /// In es, this message translates to:
  /// **'Máximo 12 campos'**
  String get activityBuilderMaxFields;

  /// No description provided for @activityBuilderAddField.
  ///
  /// In es, this message translates to:
  /// **'Añadir campo'**
  String get activityBuilderAddField;

  /// No description provided for @activityBuilderSaveInActivities.
  ///
  /// In es, this message translates to:
  /// **'Guardar en tus actividades'**
  String get activityBuilderSaveInActivities;

  /// No description provided for @activityBuilderSaveInActivitiesHelp.
  ///
  /// In es, this message translates to:
  /// **'Para repetirla sin volver a crearla.'**
  String get activityBuilderSaveInActivitiesHelp;

  /// No description provided for @activityBuilderPrepare.
  ///
  /// In es, this message translates to:
  /// **'Preparar actividad'**
  String get activityBuilderPrepare;

  /// No description provided for @activityBuilderNewField.
  ///
  /// In es, this message translates to:
  /// **'Nuevo campo'**
  String get activityBuilderNewField;

  /// No description provided for @activityBuilderFieldNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre de campo de hasta 80 caracteres.'**
  String get activityBuilderFieldNameRequired;

  /// No description provided for @activityBuilderFieldName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del campo'**
  String get activityBuilderFieldName;

  /// No description provided for @activityBuilderFieldType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get activityBuilderFieldType;

  /// No description provided for @activityBuilderFieldUnit.
  ///
  /// In es, this message translates to:
  /// **'Unidad (opcional)'**
  String get activityBuilderFieldUnit;

  /// No description provided for @activityBuilderOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones'**
  String get activityBuilderOptions;

  /// No description provided for @activityBuilderOptionsHelp.
  ///
  /// In es, this message translates to:
  /// **'Separadas por comas'**
  String get activityBuilderOptionsHelp;

  /// No description provided for @activityBuilderScaleMin.
  ///
  /// In es, this message translates to:
  /// **'Mínimo'**
  String get activityBuilderScaleMin;

  /// No description provided for @activityBuilderScaleMax.
  ///
  /// In es, this message translates to:
  /// **'Máximo'**
  String get activityBuilderScaleMax;

  /// No description provided for @activityBuilderScaleRange.
  ///
  /// In es, this message translates to:
  /// **'Escribe el mínimo y el máximo de la escala.'**
  String get activityBuilderScaleRange;

  /// No description provided for @activityBuilderAggregate.
  ///
  /// In es, this message translates to:
  /// **'Cómo cuenta'**
  String get activityBuilderAggregate;

  /// No description provided for @activityBuilderCountSingular.
  ///
  /// In es, this message translates to:
  /// **'Se cuenta como (uno)'**
  String get activityBuilderCountSingular;

  /// No description provided for @activityBuilderCountSingularHelp.
  ///
  /// In es, this message translates to:
  /// **'Opcional, p. ej. libro'**
  String get activityBuilderCountSingularHelp;

  /// No description provided for @activityBuilderCountPlural.
  ///
  /// In es, this message translates to:
  /// **'Se cuenta como (varios)'**
  String get activityBuilderCountPlural;

  /// No description provided for @activityBuilderCountPluralHelp.
  ///
  /// In es, this message translates to:
  /// **'Opcional, p. ej. libros'**
  String get activityBuilderCountPluralHelp;

  /// No description provided for @activityBuilderAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get activityBuilderAdd;

  /// No description provided for @aiPerReadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer la configuración por acompañante.'**
  String get aiPerReadError;

  /// No description provided for @aiPerSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el cambio.'**
  String get aiPerSaveError;

  /// No description provided for @aiPerTitle.
  ///
  /// In es, this message translates to:
  /// **'Por acompañante'**
  String get aiPerTitle;

  /// No description provided for @aiPerNoProvider.
  ///
  /// In es, this message translates to:
  /// **'Conecta primero un proveedor para poder elegir un modelo distinto en cada acompañante.'**
  String get aiPerNoProvider;

  /// No description provided for @aiPerHelp.
  ///
  /// In es, this message translates to:
  /// **'Cada acompañante usa tu proveedor, o un modelo propio de ese mismo proveedor.'**
  String get aiPerHelp;

  /// No description provided for @aiPerDefault.
  ///
  /// In es, this message translates to:
  /// **'Por defecto'**
  String get aiPerDefault;

  /// No description provided for @aiPerDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'IA de {name}'**
  String aiPerDialogTitle(Object name);

  /// No description provided for @aiPerDialogHelp.
  ///
  /// In es, this message translates to:
  /// **'Usa {service} con la clave de tu perfil. Solo cambia el modelo de este acompañante.'**
  String aiPerDialogHelp(Object service);

  /// No description provided for @aiPerUseDefault.
  ///
  /// In es, this message translates to:
  /// **'Usar el predeterminado'**
  String get aiPerUseDefault;

  /// No description provided for @aiSetAndroidFileAccess.
  ///
  /// In es, this message translates to:
  /// **'Android no entregó acceso al archivo seleccionado.'**
  String get aiSetAndroidFileAccess;

  /// No description provided for @aiSetGgufTitle.
  ///
  /// In es, this message translates to:
  /// **'Modelo GGUF'**
  String get aiSetGgufTitle;

  /// No description provided for @aiSetLocalContextHelp.
  ///
  /// In es, this message translates to:
  /// **'TrackIA recomienda {context} para sus instrucciones, historial y datos. La recomendación es para las necesidades de la app, no para el límite de este GGUF. Si el modelo no soporta el tamaño elegido, puede fallar; tú decides si bajarlo.'**
  String aiSetLocalContextHelp(Object context);

  /// No description provided for @aiSetModelsCountChatGpt.
  ///
  /// In es, this message translates to:
  /// **'Modelos disponibles para esta cuenta: {count}. La prueba de conexión confirma el acceso al elegido.'**
  String aiSetModelsCountChatGpt(int count);

  /// No description provided for @aiSetCatalogCountApi.
  ///
  /// In es, this message translates to:
  /// **'{count} modelos obtenidos del proveedor. La prueba de conexión confirma si tu clave puede usar el elegido.'**
  String aiSetCatalogCountApi(int count);

  /// No description provided for @aiSetCatalogErrorChatGpt.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener el catálogo de esta cuenta. Comprueba la conexión e inténtalo de nuevo.'**
  String get aiSetCatalogErrorChatGpt;

  /// No description provided for @aiSetCatalogErrorApi.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener el catálogo. Puedes volver a intentarlo o indicar el modelo manualmente.'**
  String get aiSetCatalogErrorApi;

  /// No description provided for @transferSheetReadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer la hoja.'**
  String get transferSheetReadError;

  /// No description provided for @transferSheetTooLarge.
  ///
  /// In es, this message translates to:
  /// **'La hoja supera 20 MB.'**
  String get transferSheetTooLarge;

  /// No description provided for @transferSheetLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la hoja. Vuelve a intentarlo.'**
  String get transferSheetLoadError;

  /// No description provided for @transferSheetLoaded.
  ///
  /// In es, this message translates to:
  /// **'Hoja cargada. Pendiente de interpretación por la IA.'**
  String get transferSheetLoaded;

  /// No description provided for @transferFileTooLarge.
  ///
  /// In es, this message translates to:
  /// **'El archivo supera 20 MB.'**
  String get transferFileTooLarge;

  /// No description provided for @transferSheetSelectedError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer la hoja seleccionada.'**
  String get transferSheetSelectedError;

  /// No description provided for @transferFileReadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer o compartir el archivo.'**
  String get transferFileReadError;

  /// No description provided for @transferDefaultSheetName.
  ///
  /// In es, this message translates to:
  /// **'Hoja cargada'**
  String get transferDefaultSheetName;

  /// No description provided for @transferShareSubject.
  ///
  /// In es, this message translates to:
  /// **'Copia de seguridad TrackIA'**
  String get transferShareSubject;

  /// No description provided for @transferShareText.
  ///
  /// In es, this message translates to:
  /// **'Guarda este archivo en Drive o en un lugar seguro.'**
  String get transferShareText;

  /// No description provided for @transferRestoreTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Restaurar esta copia?'**
  String get transferRestoreTitle;

  /// No description provided for @transferRestoreBody.
  ///
  /// In es, this message translates to:
  /// **'Contiene {workouts, plural, one{1 sesión} other{{workouts} sesiones}} y {routines, plural, one{1 rutina} other{{routines} rutinas}}{active}. Sustituirá todos los datos que hay ahora en este teléfono. Guarda antes una copia actual si quieres conservarlos.'**
  String transferRestoreBody(int workouts, int routines, Object active);

  /// No description provided for @transferRestoreActive.
  ///
  /// In es, this message translates to:
  /// **', incluida una sesión en curso'**
  String get transferRestoreActive;

  /// No description provided for @transferRestoreAction.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get transferRestoreAction;

  /// No description provided for @transferRestored.
  ///
  /// In es, this message translates to:
  /// **'Copia restaurada. Sesiones y rutinas actualizadas.'**
  String get transferRestored;

  /// No description provided for @transferNoAccessSheet.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer esa hoja. En Google Sheets usa «Enviar una copia» como Excel o CSV y elige TrackIA.'**
  String get transferNoAccessSheet;

  /// No description provided for @transferHeadline.
  ///
  /// In es, this message translates to:
  /// **'Tu historial, bajo tu control'**
  String get transferHeadline;

  /// No description provided for @transferIntro.
  ///
  /// In es, this message translates to:
  /// **'Guarda una copia fuera de este móvil para recuperarla o pasarla a otro teléfono.'**
  String get transferIntro;

  /// No description provided for @transferBackupTitle.
  ///
  /// In es, this message translates to:
  /// **'Copia de seguridad'**
  String get transferBackupTitle;

  /// No description provided for @transferBackupHelp.
  ///
  /// In es, this message translates to:
  /// **'Incluye historial, rutinas y sesión en curso.'**
  String get transferBackupHelp;

  /// No description provided for @transferSheetsTitle.
  ///
  /// In es, this message translates to:
  /// **'Histórico de Google Sheets'**
  String get transferSheetsTitle;

  /// No description provided for @transferSheetsHelpAndroid.
  ///
  /// In es, this message translates to:
  /// **'Carga tu hoja y pestaña con autorización de Google, o elige una copia Excel o CSV. Se conservan las celdas originales; la IA podrá interpretar tu formato cuando esté conectada.'**
  String get transferSheetsHelpAndroid;

  /// No description provided for @transferSheetsHelpOther.
  ///
  /// In es, this message translates to:
  /// **'Carga una copia Excel o CSV. Se conservan las celdas originales, pendientes de interpretación por la IA.'**
  String get transferSheetsHelpOther;

  /// No description provided for @transferImportSheets.
  ///
  /// In es, this message translates to:
  /// **'Importar desde Google Sheets'**
  String get transferImportSheets;

  /// No description provided for @transferChooseFileAndroid.
  ///
  /// In es, this message translates to:
  /// **'Elegir archivo del móvil o Drive'**
  String get transferChooseFileAndroid;

  /// No description provided for @transferChooseFileOther.
  ///
  /// In es, this message translates to:
  /// **'Elegir copia XLSX o CSV'**
  String get transferChooseFileOther;

  /// No description provided for @transferWorkoutSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{date} · {exercises} ejercicios · {sets} series'**
  String transferWorkoutSubtitle(Object date, int exercises, int sets);

  /// No description provided for @transferNoColumnWorkout.
  ///
  /// In es, this message translates to:
  /// **'Sin columna · Entrenamiento'**
  String get transferNoColumnWorkout;

  /// No description provided for @transferChooseColumn.
  ///
  /// In es, this message translates to:
  /// **'Elegir columna'**
  String get transferChooseColumn;

  /// No description provided for @transferCsvReviewError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo revisar el CSV.'**
  String get transferCsvReviewError;

  /// No description provided for @transferImportSessionsTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Importar estas sesiones?'**
  String get transferImportSessionsTitle;

  /// No description provided for @transferImportSessionsBody.
  ///
  /// In es, this message translates to:
  /// **'Se añadirán {count, plural, one{1 sesión} other{{count} sesiones}} con {sets} series. Filas omitidas por error: {errors}.'**
  String transferImportSessionsBody(int count, int sets, int errors);

  /// No description provided for @transferImportAction.
  ///
  /// In es, this message translates to:
  /// **'Importar'**
  String get transferImportAction;

  /// No description provided for @transferImportError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo importar.'**
  String get transferImportError;

  /// No description provided for @transferImportSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar hoja'**
  String get transferImportSheetTitle;

  /// No description provided for @transferImportedSummary.
  ///
  /// In es, this message translates to:
  /// **'Sesiones importadas: {added} · Duplicadas omitidas: {duplicates}'**
  String transferImportedSummary(int added, int duplicates);

  /// No description provided for @transferRowsFound.
  ///
  /// In es, this message translates to:
  /// **'{count} filas encontradas'**
  String transferRowsFound(int count);

  /// No description provided for @transferMapHelp.
  ///
  /// In es, this message translates to:
  /// **'Asocia las columnas de tu hoja. Una fila representa una serie.'**
  String get transferMapHelp;

  /// No description provided for @transferDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get transferDate;

  /// No description provided for @transferSessionOptional.
  ///
  /// In es, this message translates to:
  /// **'Sesión (opcional)'**
  String get transferSessionOptional;

  /// No description provided for @transferExercise.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio'**
  String get transferExercise;

  /// No description provided for @transferWeightKg.
  ///
  /// In es, this message translates to:
  /// **'Peso (kg)'**
  String get transferWeightKg;

  /// No description provided for @transferReps.
  ///
  /// In es, this message translates to:
  /// **'Repeticiones'**
  String get transferReps;

  /// No description provided for @transferReviewImport.
  ///
  /// In es, this message translates to:
  /// **'Revisar importación'**
  String get transferReviewImport;

  /// No description provided for @transferPreviewSummary.
  ///
  /// In es, this message translates to:
  /// **'Sesiones nuevas: {newCount} · Duplicadas: {duplicateCount} · Filas con error: {errorCount}'**
  String transferPreviewSummary(
    int newCount,
    int duplicateCount,
    int errorCount,
  );

  /// No description provided for @transferValidRows.
  ///
  /// In es, this message translates to:
  /// **'{valid} series válidas de {total} filas.'**
  String transferValidRows(int valid, int total);

  /// No description provided for @transferAllSessions.
  ///
  /// In es, this message translates to:
  /// **'Todas las sesiones'**
  String get transferAllSessions;

  /// No description provided for @transferSeeSessions.
  ///
  /// In es, this message translates to:
  /// **'Ver las {count} sesiones'**
  String transferSeeSessions(int count);

  /// No description provided for @transferErrorRows.
  ///
  /// In es, this message translates to:
  /// **'Filas con errores'**
  String get transferErrorRows;

  /// No description provided for @transferSeeErrors.
  ///
  /// In es, this message translates to:
  /// **'Ver los {count} errores'**
  String transferSeeErrors(int count);

  /// No description provided for @transferImportNew.
  ///
  /// In es, this message translates to:
  /// **'Importar sesiones nuevas'**
  String get transferImportNew;

  /// No description provided for @transferCloseAction.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get transferCloseAction;

  /// No description provided for @chatAttachVoiceError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo reconocer la voz. Comprueba el permiso de micrófono o escribe tu mensaje.'**
  String get chatAttachVoiceError;

  /// No description provided for @chatAttachVoiceUnavailable.
  ///
  /// In es, this message translates to:
  /// **'El reconocimiento de voz no está disponible. Revisa el permiso de micrófono y el servicio de voz del teléfono.'**
  String get chatAttachVoiceUnavailable;

  /// No description provided for @chatAttachDictationStart.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar el dictado.'**
  String get chatAttachDictationStart;

  /// No description provided for @chatAttachCamera.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get chatAttachCamera;

  /// No description provided for @chatAttachPhotos.
  ///
  /// In es, this message translates to:
  /// **'Fotos'**
  String get chatAttachPhotos;

  /// No description provided for @chatAttachPdf.
  ///
  /// In es, this message translates to:
  /// **'Documento PDF'**
  String get chatAttachPdf;

  /// No description provided for @chatAttachPdfHint.
  ///
  /// In es, this message translates to:
  /// **'Necesita un modelo que admita documentos'**
  String get chatAttachPdfHint;

  /// No description provided for @chatAttachAudio.
  ///
  /// In es, this message translates to:
  /// **'Archivo de audio'**
  String get chatAttachAudio;

  /// No description provided for @chatAttachAudioHint.
  ///
  /// In es, this message translates to:
  /// **'Requiere un modelo de Gemini que admita audio'**
  String get chatAttachAudioHint;

  /// No description provided for @chatAttachSpreadsheet.
  ///
  /// In es, this message translates to:
  /// **'Hoja Excel o CSV'**
  String get chatAttachSpreadsheet;

  /// No description provided for @chatAttachSheet.
  ///
  /// In es, this message translates to:
  /// **'Google Sheets / Drive'**
  String get chatAttachSheet;

  /// No description provided for @chatAttachNeedsAi.
  ///
  /// In es, this message translates to:
  /// **'Conecta la IA para enviar imágenes, documentos o audio. Puedes cargar una hoja sin IA.'**
  String get chatAttachNeedsAi;

  /// No description provided for @chatAttachPhotoTooLarge.
  ///
  /// In es, this message translates to:
  /// **'La foto supera 4 MB.'**
  String get chatAttachPhotoTooLarge;

  /// No description provided for @chatAttachPhotoFormat.
  ///
  /// In es, this message translates to:
  /// **'Elige una foto JPG, PNG o WebP.'**
  String get chatAttachPhotoFormat;

  /// No description provided for @chatAttachPhotoEmpty.
  ///
  /// In es, this message translates to:
  /// **'La foto debe tener contenido y no superar 4 MB.'**
  String get chatAttachPhotoEmpty;

  /// No description provided for @chatAttachAudioNeedsGemini.
  ///
  /// In es, this message translates to:
  /// **'Para enviar un archivo de audio configura un modelo de Gemini con audio. Puedes usar el micrófono del chat para dictar el mensaje.'**
  String get chatAttachAudioNeedsGemini;

  /// No description provided for @chatAttachTooLarge.
  ///
  /// In es, this message translates to:
  /// **'El adjunto supera 4 MB.'**
  String get chatAttachTooLarge;

  /// No description provided for @chatAttachUnreadable.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer el adjunto.'**
  String get chatAttachUnreadable;

  /// No description provided for @chatAttachFormat.
  ///
  /// In es, this message translates to:
  /// **'Formato de adjunto no compatible.'**
  String get chatAttachFormat;

  /// No description provided for @chatAttachInvalidPdf.
  ///
  /// In es, this message translates to:
  /// **'El archivo no contiene un PDF válido.'**
  String get chatAttachInvalidPdf;

  /// No description provided for @chatAttachOpenFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el adjunto.'**
  String get chatAttachOpenFailed;

  /// No description provided for @chatAttachRecoveredTooLarge.
  ///
  /// In es, this message translates to:
  /// **'La foto recuperada supera 4 MB. Elige una más pequeña.'**
  String get chatAttachRecoveredTooLarge;

  /// No description provided for @chatMenuCompanionsError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los acompañantes.'**
  String get chatMenuCompanionsError;

  /// No description provided for @chatMenuMore.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get chatMenuMore;

  /// No description provided for @chatMenuTraining.
  ///
  /// In es, this message translates to:
  /// **'Rutinas e historial'**
  String get chatMenuTraining;

  /// No description provided for @chatMenuProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get chatMenuProgress;

  /// No description provided for @chatMenuSheet.
  ///
  /// In es, this message translates to:
  /// **'Hoja cargada'**
  String get chatMenuSheet;

  /// No description provided for @chatMenuRecover.
  ///
  /// In es, this message translates to:
  /// **'Recuperar preparación'**
  String get chatMenuRecover;

  /// No description provided for @chatSendFocusTooLong.
  ///
  /// In es, this message translates to:
  /// **'El registro supera 8000 caracteres.'**
  String get chatSendFocusTooLong;

  /// No description provided for @chatSendSavedNoAi.
  ///
  /// In es, this message translates to:
  /// **'Registro guardado en el móvil. La IA no está disponible para interpretarlo.'**
  String get chatSendSavedNoAi;

  /// No description provided for @chatSendSavedNoProvider.
  ///
  /// In es, this message translates to:
  /// **'Registro guardado en el móvil. Configura el proveedor para consultar al asistente.'**
  String get chatSendSavedNoProvider;

  /// No description provided for @chatSendAssistantError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo consultar al asistente. Revisa el registro local.'**
  String get chatSendAssistantError;

  /// No description provided for @chatSendQueueUnavailable.
  ///
  /// In es, this message translates to:
  /// **'La cola durable no está disponible. Conserva el texto y vuelve a abrir el chat.'**
  String get chatSendQueueUnavailable;

  /// No description provided for @chatSendTooLong.
  ///
  /// In es, this message translates to:
  /// **'El mensaje supera 8000 caracteres.'**
  String get chatSendTooLong;

  /// No description provided for @chatSendConfigureProvider.
  ///
  /// In es, this message translates to:
  /// **'Configura el proveedor con el botón de ajustes para empezar.'**
  String get chatSendConfigureProvider;

  /// No description provided for @chatSendSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el mensaje en el móvil. Conserva el texto y vuelve a intentarlo.'**
  String get chatSendSaveError;

  /// No description provided for @chatSendProposalIncomplete.
  ///
  /// In es, this message translates to:
  /// **'El modelo envió una propuesta incompleta. Pídele que prepare de nuevo el ejercicio para mostrar Iniciar.'**
  String get chatSendProposalIncomplete;

  /// No description provided for @chatSendAnswerSaveError.
  ///
  /// In es, this message translates to:
  /// **'La respuesta llegó, pero no se pudo guardar la conversación en el móvil.'**
  String get chatSendAnswerSaveError;

  /// No description provided for @chatSendFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la conversación. Puedes volver a intentarlo.'**
  String get chatSendFailed;

  /// No description provided for @chatMsgOnlyLastEditable.
  ///
  /// In es, this message translates to:
  /// **'Solo se puede editar el último mensaje. Escribe una corrección como mensaje nuevo.'**
  String get chatMsgOnlyLastEditable;

  /// No description provided for @chatMsgPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de envío'**
  String get chatMsgPending;

  /// No description provided for @chatMsgSending.
  ///
  /// In es, this message translates to:
  /// **'Enviando'**
  String get chatMsgSending;

  /// No description provided for @chatMsgAnswered.
  ///
  /// In es, this message translates to:
  /// **'Respondido'**
  String get chatMsgAnswered;

  /// No description provided for @chatMsgFailed.
  ///
  /// In es, this message translates to:
  /// **'No aceptado; puedes reenviar'**
  String get chatMsgFailed;

  /// No description provided for @chatMsgUncertain.
  ///
  /// In es, this message translates to:
  /// **'Resultado incierto; reenvío bloqueado hasta revisar'**
  String get chatMsgUncertain;

  /// No description provided for @chatMsgHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get chatMsgHistory;

  /// No description provided for @chatMsgResend.
  ///
  /// In es, this message translates to:
  /// **'Reenviar'**
  String get chatMsgResend;

  /// No description provided for @chatMsgAiNotReady.
  ///
  /// In es, this message translates to:
  /// **'La IA no está lista.'**
  String get chatMsgAiNotReady;

  /// No description provided for @chatMsgSendInProgress.
  ///
  /// In es, this message translates to:
  /// **'Hay un envío en curso.'**
  String get chatMsgSendInProgress;

  /// No description provided for @chatMsgChangedWhileEditing.
  ///
  /// In es, this message translates to:
  /// **'El mensaje cambió mientras lo editabas. Revisa el historial.'**
  String get chatMsgChangedWhileEditing;

  /// No description provided for @chatMsgSaveNotSent.
  ///
  /// In es, this message translates to:
  /// **'Edición guardada, pero no se pudo enviar ahora. Usa Reenviar cuando puedas.'**
  String get chatMsgSaveNotSent;

  /// No description provided for @chatMsgSavedOnly.
  ///
  /// In es, this message translates to:
  /// **'Edición guardada. Usa Reenviar para enviar esta versión.'**
  String get chatMsgSavedOnly;

  /// No description provided for @chatMsgLengthError.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje de 1 a 8000 caracteres.'**
  String get chatMsgLengthError;

  /// No description provided for @chatMsgEditError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la edición; el original se conserva.'**
  String get chatMsgEditError;

  /// No description provided for @chatMsgHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial de versiones'**
  String get chatMsgHistoryTitle;

  /// No description provided for @chatMsgVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión {n}'**
  String chatMsgVersion(int n);

  /// No description provided for @chatMsgVersionCurrent.
  ///
  /// In es, this message translates to:
  /// **'Versión {n} · actual'**
  String chatMsgVersionCurrent(int n);

  /// No description provided for @chatMsgClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get chatMsgClose;

  /// No description provided for @chatMsgHistoryError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el historial.'**
  String get chatMsgHistoryError;

  /// No description provided for @chatMsgEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar mensaje'**
  String get chatMsgEditTitle;

  /// No description provided for @chatMsgEditLabel.
  ///
  /// In es, this message translates to:
  /// **'Texto corregido'**
  String get chatMsgEditLabel;

  /// No description provided for @chatMsgEditHelper.
  ///
  /// In es, this message translates to:
  /// **'La versión original se conserva en el historial.'**
  String get chatMsgEditHelper;

  /// No description provided for @chatMsgSendBlocked.
  ///
  /// In es, this message translates to:
  /// **'No se puede enviar ahora: {reason}'**
  String chatMsgSendBlocked(Object reason);

  /// No description provided for @chatMsgSaveAndSend.
  ///
  /// In es, this message translates to:
  /// **'Guardar y enviar'**
  String get chatMsgSaveAndSend;

  /// No description provided for @chatSheetReloadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo recuperar la hoja cargada.'**
  String get chatSheetReloadError;

  /// No description provided for @chatSheetAndroidOnly.
  ///
  /// In es, this message translates to:
  /// **'La conexión con Google Sheets está disponible en Android.'**
  String get chatSheetAndroidOnly;

  /// No description provided for @chatSheetSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la hoja en el móvil. La copia anterior se conserva.'**
  String get chatSheetSaveError;

  /// No description provided for @chatSheetInterpretPending.
  ///
  /// In es, this message translates to:
  /// **'La respuesta llegó, pero la hoja sigue pendiente de interpretación en el móvil.'**
  String get chatSheetInterpretPending;

  /// No description provided for @chatSheetRefreshError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar la hoja. La copia anterior se conserva.'**
  String get chatSheetRefreshError;

  /// No description provided for @chatSheetRemoveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo quitar la copia de la hoja.'**
  String get chatSheetRemoveError;

  /// No description provided for @chatSheetDialogBody.
  ///
  /// In es, this message translates to:
  /// **'{title} · {rows} filas\nÚltima lectura: {date}.\n\n{status}'**
  String chatSheetDialogBody(
    Object title,
    int rows,
    Object date,
    Object status,
  );

  /// No description provided for @chatSheetStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de interpretación por la IA. No se han importado entrenamientos.'**
  String get chatSheetStatusPending;

  /// No description provided for @chatSheetStatusAnalyzed.
  ///
  /// In es, this message translates to:
  /// **'El asistente ha analizado esta copia; no se han importado entrenamientos.'**
  String get chatSheetStatusAnalyzed;

  /// No description provided for @chatSheetRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar del contexto'**
  String get chatSheetRemove;

  /// No description provided for @chatSheetChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar hoja'**
  String get chatSheetChange;

  /// No description provided for @chatSheetRefresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar hoja'**
  String get chatSheetRefresh;

  /// No description provided for @chatSheetLabel.
  ///
  /// In es, this message translates to:
  /// **'Hoja · {title}'**
  String chatSheetLabel(Object title);

  /// No description provided for @chatProposalRepeated.
  ///
  /// In es, this message translates to:
  /// **'Series / tramos · {seconds}s de descanso'**
  String chatProposalRepeated(int seconds);

  /// No description provided for @chatProposalContinuous.
  ///
  /// In es, this message translates to:
  /// **'Actividad continua · {seconds}s de descanso'**
  String chatProposalContinuous(int seconds);

  /// No description provided for @chatSheetPendingInfo.
  ///
  /// In es, this message translates to:
  /// **'«{name}» cargada · pendiente de interpretación. Los datos originales se conservan.'**
  String chatSheetPendingInfo(Object name);

  /// No description provided for @chatGameFocusOpen.
  ///
  /// In es, this message translates to:
  /// **'Termina la actividad abierta en el otro acompañante antes de preparar esta.'**
  String get chatGameFocusOpen;

  /// No description provided for @chatGamePrepareError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo preparar la actividad. Vuelve a intentarlo.'**
  String get chatGamePrepareError;

  /// No description provided for @chatGameGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'Meta propuesta: {goal}'**
  String chatGameGoalTitle(Object goal);

  /// No description provided for @chatGameAchievementTitle.
  ///
  /// In es, this message translates to:
  /// **'Logro propuesto: {title}'**
  String chatGameAchievementTitle(Object title);

  /// No description provided for @chatGameCopyTitle.
  ///
  /// In es, this message translates to:
  /// **'Textos de recordatorio propuestos'**
  String get chatGameCopyTitle;

  /// No description provided for @chatDeliveryQueueError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la cola durable del chat. No se enviarán mensajes por un almacenamiento alternativo.'**
  String get chatDeliveryQueueError;

  /// No description provided for @chatDeliveryRestoredPending.
  ///
  /// In es, this message translates to:
  /// **'Tu mensaje quedó guardado sin respuesta. Puedes volver a enviarlo.'**
  String get chatDeliveryRestoredPending;

  /// No description provided for @chatDeliveryUncertain.
  ///
  /// In es, this message translates to:
  /// **'Hay un envío con resultado incierto. No se reenviará automáticamente; revisa el historial antes de decidir.'**
  String get chatDeliveryUncertain;

  /// No description provided for @chatDeliveryBacklog.
  ///
  /// In es, this message translates to:
  /// **'Tienes mensajes guardados sin respuesta. Usa Reenviar cuando quieras; no se enviarán automáticamente.'**
  String get chatDeliveryBacklog;

  /// No description provided for @chatDeliveryOtherChat.
  ///
  /// In es, this message translates to:
  /// **'El mensaje pertenece a otro chat y no se enviará aquí.'**
  String get chatDeliveryOtherChat;

  /// No description provided for @chatDeliveryNotSafe.
  ///
  /// In es, this message translates to:
  /// **'Este mensaje no es seguro de reenviar.'**
  String get chatDeliveryNotSafe;

  /// No description provided for @chatDeliveryStateChanged.
  ///
  /// In es, this message translates to:
  /// **'El mensaje ya cambió de estado; no se hizo otro envío.'**
  String get chatDeliveryStateChanged;

  /// No description provided for @chatDeliveryUncertainSend.
  ///
  /// In es, this message translates to:
  /// **'El resultado del envío es incierto. No se reenviará automáticamente; comprueba si llegó una respuesta.'**
  String get chatDeliveryUncertainSend;

  /// No description provided for @chatDeliveryFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la conversación. El mensaje permanece guardado; no se hará un reenvío automático.'**
  String get chatDeliveryFailed;

  /// No description provided for @chatArchiveIncompleteDirective.
  ///
  /// In es, this message translates to:
  /// **'El modelo pidió archivar con datos incompletos. El chat sigue abierto.'**
  String get chatArchiveIncompleteDirective;

  /// No description provided for @chatArchiveDoneAuto.
  ///
  /// In es, this message translates to:
  /// **'El asistente archivó el chat. Puedes consultarlo en Chats archivados.'**
  String get chatArchiveDoneAuto;

  /// No description provided for @chatArchiveDone.
  ///
  /// In es, this message translates to:
  /// **'Chat archivado. El contexto activo se ha liberado.'**
  String get chatArchiveDone;

  /// No description provided for @chatArchiveViewAction.
  ///
  /// In es, this message translates to:
  /// **'Ver archivos'**
  String get chatArchiveViewAction;

  /// No description provided for @chatArchiveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo archivar. La conversación y los entrenamientos se conservan.'**
  String get chatArchiveError;

  /// No description provided for @chatArchiveSyncInvalid.
  ///
  /// In es, this message translates to:
  /// **'La propuesta de envío no es válida. Usa Enviar a Google Sheets en el menú.'**
  String get chatArchiveSyncInvalid;

  /// No description provided for @chatArchiveRecalled.
  ///
  /// In es, this message translates to:
  /// **'Archivo disponible para tu próximo mensaje al asistente.'**
  String get chatArchiveRecalled;

  /// No description provided for @chatArchiveReadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo consultar el archivo.'**
  String get chatArchiveReadError;

  /// No description provided for @chatDraftSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el borrador. Conserva el texto y vuelve a intentarlo.'**
  String get chatDraftSaveError;

  /// No description provided for @chatLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo recuperar la conversación anterior.'**
  String get chatLoadError;

  /// No description provided for @chatLoadSheetError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo recuperar la hoja guardada. Vuelve a cargarla desde Google Sheets.'**
  String get chatLoadSheetError;

  /// No description provided for @chatPersistTooLarge.
  ///
  /// In es, this message translates to:
  /// **'El chat supera 20 MB; no se pudo guardar completo.'**
  String get chatPersistTooLarge;

  /// No description provided for @creatorCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get creatorCreate;

  /// No description provided for @creatorCreateFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear el acompañante. No se guardó nada.'**
  String get creatorCreateFailed;

  /// No description provided for @creatorAssistedTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear con ayuda de la IA'**
  String get creatorAssistedTitle;

  /// No description provided for @creatorAiTitle.
  ///
  /// In es, this message translates to:
  /// **'Con ayuda de la IA'**
  String get creatorAiTitle;

  /// No description provided for @creatorAiReadySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuéntale qué quieres seguir y te propone un acompañante.'**
  String get creatorAiReadySubtitle;

  /// No description provided for @creatorAiNotReadySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Necesitas conectar y verificar un proveedor de IA.'**
  String get creatorAiNotReadySubtitle;

  /// No description provided for @creatorOpenAiSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir Ajustes de IA'**
  String get creatorOpenAiSettings;

  /// No description provided for @creatorManualTitle.
  ///
  /// In es, this message translates to:
  /// **'A mano'**
  String get creatorManualTitle;

  /// No description provided for @creatorManualSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige nombre, icono, color, modo y aviso tú mismo.'**
  String get creatorManualSubtitle;

  /// No description provided for @creatorNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo acompañante'**
  String get creatorNewTitle;

  /// No description provided for @creatorEditProposalTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar propuesta'**
  String get creatorEditProposalTitle;

  /// No description provided for @creatorNameLength.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre de entre 1 y 40 caracteres.'**
  String get creatorNameLength;

  /// No description provided for @creatorLevelReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'Solo recordatorio'**
  String get creatorLevelReminderTitle;

  /// No description provided for @creatorLevelReminderDetail.
  ///
  /// In es, this message translates to:
  /// **'Te avisa y ya.'**
  String get creatorLevelReminderDetail;

  /// No description provided for @creatorLevelGoalsTitle.
  ///
  /// In es, this message translates to:
  /// **'Metas y rachas'**
  String get creatorLevelGoalsTitle;

  /// No description provided for @creatorLevelGoalsDetail.
  ///
  /// In es, this message translates to:
  /// **'Recomendado: metas y rachas, sin logros.'**
  String get creatorLevelGoalsDetail;

  /// No description provided for @creatorLevelGameTitle.
  ///
  /// In es, this message translates to:
  /// **'Juego completo'**
  String get creatorLevelGameTitle;

  /// No description provided for @creatorLevelGameDetail.
  ///
  /// In es, this message translates to:
  /// **'Metas, rachas y logros.'**
  String get creatorLevelGameDetail;

  /// No description provided for @creatorActivityLabel.
  ///
  /// In es, this message translates to:
  /// **'Qué anotas: {name}'**
  String creatorActivityLabel(Object name);

  /// No description provided for @creatorRemoveActivity.
  ///
  /// In es, this message translates to:
  /// **'Quitar actividad'**
  String get creatorRemoveActivity;

  /// No description provided for @creatorGoalLabel.
  ///
  /// In es, this message translates to:
  /// **'Meta: {text}'**
  String creatorGoalLabel(Object text);

  /// No description provided for @creatorRemoveGoal.
  ///
  /// In es, this message translates to:
  /// **'Quitar meta'**
  String get creatorRemoveGoal;

  /// No description provided for @creatorRemind.
  ///
  /// In es, this message translates to:
  /// **'Recordarme'**
  String get creatorRemind;

  /// No description provided for @creatorDecideOnStart.
  ///
  /// In es, this message translates to:
  /// **'lo decides al empezar'**
  String get creatorDecideOnStart;

  /// No description provided for @creatorPunctualSuffix.
  ///
  /// In es, this message translates to:
  /// **' · registro puntual'**
  String get creatorPunctualSuffix;

  /// No description provided for @creatorNoGoal.
  ///
  /// In es, this message translates to:
  /// **'sin meta'**
  String get creatorNoGoal;

  /// No description provided for @creatorNoReminder.
  ///
  /// In es, this message translates to:
  /// **'sin aviso'**
  String get creatorNoReminder;

  /// No description provided for @creatorReminderLabel.
  ///
  /// In es, this message translates to:
  /// **'Aviso: {text}'**
  String creatorReminderLabel(Object text);

  /// No description provided for @creatorLevelLabel.
  ///
  /// In es, this message translates to:
  /// **'Nivel: {text}'**
  String creatorLevelLabel(Object text);

  /// No description provided for @creatorDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get creatorDiscard;

  /// No description provided for @creatorNoAiConnected.
  ///
  /// In es, this message translates to:
  /// **'No hay una IA conectada.'**
  String get creatorNoAiConnected;

  /// No description provided for @creatorConversationFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la conversación. Puedes volver a intentarlo.'**
  String get creatorConversationFailed;

  /// No description provided for @creatorInputHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe aquí'**
  String get creatorInputHint;

  /// No description provided for @creatorPromptHelper.
  ///
  /// In es, this message translates to:
  /// **'Se usan cuando conectes un proveedor.'**
  String get creatorPromptHelper;

  /// No description provided for @creatorLevelSection.
  ///
  /// In es, this message translates to:
  /// **'Nivel'**
  String get creatorLevelSection;

  /// No description provided for @proposalIgnore.
  ///
  /// In es, this message translates to:
  /// **'Ignorar'**
  String get proposalIgnore;

  /// No description provided for @proposalAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get proposalAdd;

  /// No description provided for @proposalUseTexts.
  ///
  /// In es, this message translates to:
  /// **'Usar estos textos'**
  String get proposalUseTexts;

  /// No description provided for @proposalSuggestLater.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get proposalSuggestLater;

  /// No description provided for @proposalSuggestNever.
  ///
  /// In es, this message translates to:
  /// **'No volver a sugerir'**
  String get proposalSuggestNever;

  /// No description provided for @proposalLockedTitle.
  ///
  /// In es, this message translates to:
  /// **'Propuesta de la IA sobre datos fijados por ti'**
  String get proposalLockedTitle;

  /// No description provided for @proposalApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get proposalApply;

  /// No description provided for @proposalChangeLine.
  ///
  /// In es, this message translates to:
  /// **'{label}: {current} {unit} → {proposed} {unit}'**
  String proposalChangeLine(
    Object label,
    int current,
    Object unit,
    int proposed,
  );

  /// No description provided for @proposalLockLabel.
  ///
  /// In es, this message translates to:
  /// **'Fijado por ti. Toca para liberar'**
  String get proposalLockLabel;

  /// No description provided for @homeNewWorkoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo entrenamiento'**
  String get homeNewWorkoutTitle;

  /// No description provided for @homeSessionNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la sesión'**
  String get homeSessionNameLabel;

  /// No description provided for @homeWorkout.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento'**
  String get homeWorkout;

  /// No description provided for @homeAddExerciseTitle.
  ///
  /// In es, this message translates to:
  /// **'Añadir ejercicio'**
  String get homeAddExerciseTitle;

  /// No description provided for @homeExerciseNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del ejercicio'**
  String get homeExerciseNameLabel;

  /// No description provided for @homeAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get homeAdd;

  /// No description provided for @homeBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get homeBack;

  /// No description provided for @homeYourSession.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión'**
  String get homeYourSession;

  /// No description provided for @homeAssistantTooltip.
  ///
  /// In es, this message translates to:
  /// **'Asistente TrackIA'**
  String get homeAssistantTooltip;

  /// No description provided for @homeReload.
  ///
  /// In es, this message translates to:
  /// **'Recargar'**
  String get homeReload;

  /// No description provided for @homeLoadLog.
  ///
  /// In es, this message translates to:
  /// **'Cargar bitácora'**
  String get homeLoadLog;

  /// No description provided for @homeHeroTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu esfuerzo.\nTu progreso.'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Una serie a la vez. Lleva el registro de lo que haces hoy.'**
  String get homeHeroSubtitle;

  /// No description provided for @homeNextSession.
  ///
  /// In es, this message translates to:
  /// **'TU PRÓXIMA SESIÓN'**
  String get homeNextSession;

  /// No description provided for @homeInProgress.
  ///
  /// In es, this message translates to:
  /// **'SESIÓN EN CURSO'**
  String get homeInProgress;

  /// No description provided for @homeReadyQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Vamos a entrenar?'**
  String get homeReadyQuestion;

  /// No description provided for @homeAddExercisesHint.
  ///
  /// In es, this message translates to:
  /// **'Añade tus ejercicios y registra cada serie.'**
  String get homeAddExercisesHint;

  /// No description provided for @homeActivitiesRecords.
  ///
  /// In es, this message translates to:
  /// **'Actividades: {activities} · Registros: {records}'**
  String homeActivitiesRecords(int activities, int records);

  /// No description provided for @homeStartWorkout.
  ///
  /// In es, this message translates to:
  /// **'Empezar entrenamiento'**
  String get homeStartWorkout;

  /// No description provided for @homeContinueWorkout.
  ///
  /// In es, this message translates to:
  /// **'Continuar entrenamiento'**
  String get homeContinueWorkout;

  /// No description provided for @homeCompletedSessions.
  ///
  /// In es, this message translates to:
  /// **'sesiones completas'**
  String get homeCompletedSessions;

  /// No description provided for @homeRecords.
  ///
  /// In es, this message translates to:
  /// **'registros'**
  String get homeRecords;

  /// No description provided for @homeLastActivity.
  ///
  /// In es, this message translates to:
  /// **'ÚLTIMA ACTIVIDAD'**
  String get homeLastActivity;

  /// No description provided for @homeEmptyHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Aquí empieza tu historia'**
  String get homeEmptyHistoryTitle;

  /// No description provided for @homeEmptyHistorySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu primer entrenamiento aparecerá aquí cuando lo finalices.'**
  String get homeEmptyHistorySubtitle;

  /// No description provided for @homeSavedOffline.
  ///
  /// In es, this message translates to:
  /// **'Guardado en este dispositivo · Sin conexión'**
  String get homeSavedOffline;

  /// No description provided for @homeJourneyTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu recorrido'**
  String get homeJourneyTitle;

  /// No description provided for @homeEverySessionCounts.
  ///
  /// In es, this message translates to:
  /// **'Cada sesión cuenta.'**
  String get homeEverySessionCounts;

  /// No description provided for @homeNoSessionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay sesiones'**
  String get homeNoSessionsTitle;

  /// No description provided for @homeNoSessionsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Finaliza un entrenamiento y consulta aquí todos sus ejercicios y series.'**
  String get homeNoSessionsSubtitle;

  /// No description provided for @homeStatusInProgress.
  ///
  /// In es, this message translates to:
  /// **'EN CURSO'**
  String get homeStatusInProgress;

  /// No description provided for @homeStatusCompleted.
  ///
  /// In es, this message translates to:
  /// **'COMPLETADO'**
  String get homeStatusCompleted;

  /// No description provided for @homeFinishedAt.
  ///
  /// In es, this message translates to:
  /// **'Finalizó: {date}'**
  String homeFinishedAt(Object date);

  /// No description provided for @homeFinishRecorded.
  ///
  /// In es, this message translates to:
  /// **'Cierre registrado: {date}'**
  String homeFinishRecorded(Object date);

  /// No description provided for @homeFinishRecordedByUser.
  ///
  /// In es, this message translates to:
  /// **'Cierre registrado: {date} · hora elegida por ti'**
  String homeFinishRecordedByUser(Object date);

  /// No description provided for @homeTimeKeptWarning.
  ///
  /// In es, this message translates to:
  /// **'Horario conservado con aviso. Puedes revisarlo más adelante.'**
  String get homeTimeKeptWarning;

  /// No description provided for @homeTimeKeptWarningShort.
  ///
  /// In es, this message translates to:
  /// **'Horario conservado con aviso.'**
  String get homeTimeKeptWarningShort;

  /// No description provided for @homeActivities.
  ///
  /// In es, this message translates to:
  /// **'actividades'**
  String get homeActivities;

  /// No description provided for @homeIntervalsRepeated.
  ///
  /// In es, this message translates to:
  /// **'Series / tramos: {count}'**
  String homeIntervalsRepeated(int count);

  /// No description provided for @homeIntervals.
  ///
  /// In es, this message translates to:
  /// **'Tramos: {count}'**
  String homeIntervals(int count);

  /// No description provided for @homeNotStarted.
  ///
  /// In es, this message translates to:
  /// **'Sin iniciar'**
  String get homeNotStarted;

  /// No description provided for @homeEndedAt.
  ///
  /// In es, this message translates to:
  /// **'Fin: {date}'**
  String homeEndedAt(Object date);

  /// No description provided for @homeDraft.
  ///
  /// In es, this message translates to:
  /// **'Borrador: {draft}'**
  String homeDraft(Object draft);

  /// No description provided for @homeFinishWorkout.
  ///
  /// In es, this message translates to:
  /// **'Finalizar entrenamiento'**
  String get homeFinishWorkout;

  /// No description provided for @homeAddSetToFinish.
  ///
  /// In es, this message translates to:
  /// **'Registra al menos una serie para finalizar.'**
  String get homeAddSetToFinish;

  /// No description provided for @homeEachSetSaved.
  ///
  /// In es, this message translates to:
  /// **'Cada serie se guarda al pulsar Guardar.'**
  String get homeEachSetSaved;

  /// No description provided for @homeDiscardTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar sesión?'**
  String get homeDiscardTitle;

  /// No description provided for @homeDiscardBody.
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán esta sesión y todas sus series. Esta acción no se puede deshacer.'**
  String get homeDiscardBody;

  /// No description provided for @homeDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get homeDiscard;

  /// No description provided for @homeDiscardSession.
  ///
  /// In es, this message translates to:
  /// **'Descartar sesión'**
  String get homeDiscardSession;

  /// No description provided for @homeSavedWellDone.
  ///
  /// In es, this message translates to:
  /// **'Sesión guardada. Buen trabajo.'**
  String get homeSavedWellDone;

  /// No description provided for @homeViewHistory.
  ///
  /// In es, this message translates to:
  /// **'Ver historial'**
  String get homeViewHistory;

  /// No description provided for @homeDeleteExerciseTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar ejercicio {name}'**
  String homeDeleteExerciseTooltip(Object name);

  /// No description provided for @homeDeleteExerciseTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar ejercicio?'**
  String get homeDeleteExerciseTitle;

  /// No description provided for @homeDeleteExerciseBody.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará {name} y sus {count, plural, one{1 serie} other{{count} series}}.'**
  String homeDeleteExerciseBody(Object name, int count);

  /// No description provided for @homeDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get homeDelete;

  /// No description provided for @homeTargetProgress.
  ///
  /// In es, this message translates to:
  /// **'Series registradas: {done} de {target} · {repsMin}–{repsMax} reps'**
  String homeTargetProgress(
    int done,
    int target,
    Object repsMin,
    Object repsMax,
  );

  /// No description provided for @homeNoPreviousSession.
  ///
  /// In es, this message translates to:
  /// **'Sin sesión anterior registrada'**
  String get homeNoPreviousSession;

  /// No description provided for @homeLastTime.
  ///
  /// In es, this message translates to:
  /// **'Última vez · {date}'**
  String homeLastTime(Object date);

  /// No description provided for @homeNoSetsYet.
  ///
  /// In es, this message translates to:
  /// **'Todavía no has registrado series.'**
  String get homeNoSetsYet;

  /// No description provided for @homeSetHeader.
  ///
  /// In es, this message translates to:
  /// **'SERIE'**
  String get homeSetHeader;

  /// No description provided for @homeKgHeader.
  ///
  /// In es, this message translates to:
  /// **'KG'**
  String get homeKgHeader;

  /// No description provided for @homeRepsHeader.
  ///
  /// In es, this message translates to:
  /// **'REPS'**
  String get homeRepsHeader;

  /// No description provided for @homeSetOptionsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Opciones de la serie {number}'**
  String homeSetOptionsTooltip(int number);

  /// No description provided for @homeSetDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'{weight} kg × {reps, plural, one{1 repetición} other{{reps} repeticiones}}.'**
  String homeSetDeleteBody(Object weight, int reps);

  /// No description provided for @homeWeightReps.
  ///
  /// In es, this message translates to:
  /// **'{weight} kg × {reps}'**
  String homeWeightReps(Object weight, int reps);

  /// No description provided for @homeEditSet.
  ///
  /// In es, this message translates to:
  /// **'Editar serie'**
  String get homeEditSet;

  /// No description provided for @homeDeleteSet.
  ///
  /// In es, this message translates to:
  /// **'Eliminar serie'**
  String get homeDeleteSet;

  /// No description provided for @homeAddSet.
  ///
  /// In es, this message translates to:
  /// **'Añadir serie'**
  String get homeAddSet;

  /// No description provided for @homeRest.
  ///
  /// In es, this message translates to:
  /// **'Descansar {seconds}s'**
  String homeRest(int seconds);

  /// No description provided for @homeFirstSetTitle.
  ///
  /// In es, this message translates to:
  /// **'Prepara tu primera serie'**
  String get homeFirstSetTitle;

  /// No description provided for @homeFirstSetSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Añade un ejercicio para empezar a registrar peso y repeticiones.'**
  String get homeFirstSetSubtitle;

  /// No description provided for @homeFinishSession.
  ///
  /// In es, this message translates to:
  /// **'Finalizar entreno'**
  String get homeFinishSession;

  /// No description provided for @homeTabToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get homeTabToday;

  /// No description provided for @homeTabRoutines.
  ///
  /// In es, this message translates to:
  /// **'Rutinas'**
  String get homeTabRoutines;

  /// No description provided for @homeTabHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get homeTabHistory;

  /// No description provided for @homeSessionStarted.
  ///
  /// In es, this message translates to:
  /// **'Entreno iniciado. Puedes abrir Entrenamiento para registrar.'**
  String get homeSessionStarted;

  /// No description provided for @homeSessionStartFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar el entreno.'**
  String get homeSessionStartFailed;

  /// No description provided for @homeActiveSessionChanged.
  ///
  /// In es, this message translates to:
  /// **'La sesión activa ha cambiado. Revísala.'**
  String get homeActiveSessionChanged;

  /// No description provided for @homeSavedSheetPending.
  ///
  /// In es, this message translates to:
  /// **'Entreno guardado en el móvil. El envío a Google Sheets queda pendiente de confirmación.'**
  String get homeSavedSheetPending;

  /// No description provided for @homeSavedSheetNotUpdated.
  ///
  /// In es, this message translates to:
  /// **'Entreno guardado en el móvil. Google Sheets no se ha actualizado.'**
  String get homeSavedSheetNotUpdated;

  /// No description provided for @homeFinishFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo finalizar el entreno.'**
  String get homeFinishFailed;

  /// No description provided for @homeReviewFinishTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisar hora de finalización'**
  String get homeReviewFinishTitle;

  /// No description provided for @homeFinishIssuesBody.
  ///
  /// In es, this message translates to:
  /// **'{issues}\n\n¿Quieres guardar la hora elegida tal cual? Los registros se conservarán para revisarlos después si lo deseas.'**
  String homeFinishIssuesBody(Object issues);

  /// No description provided for @homeBackAndFix.
  ///
  /// In es, this message translates to:
  /// **'Volver y corregir'**
  String get homeBackAndFix;

  /// No description provided for @homeSaveThatTime.
  ///
  /// In es, this message translates to:
  /// **'Guardar esa hora'**
  String get homeSaveThatTime;

  /// No description provided for @homeDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get homeDate;

  /// No description provided for @homeTime.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get homeTime;

  /// No description provided for @homeStartSession.
  ///
  /// In es, this message translates to:
  /// **'Iniciar entreno'**
  String get homeStartSession;

  /// No description provided for @homeOptionYes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get homeOptionYes;

  /// No description provided for @homeOptionNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get homeOptionNo;

  /// No description provided for @homeBoolYes.
  ///
  /// In es, this message translates to:
  /// **'sí'**
  String get homeBoolYes;

  /// No description provided for @homeBoolNo.
  ///
  /// In es, this message translates to:
  /// **'no'**
  String get homeBoolNo;

  /// No description provided for @homeNoteOptional.
  ///
  /// In es, this message translates to:
  /// **'Nota (opcional)'**
  String get homeNoteOptional;

  /// No description provided for @homeNumberInvalid.
  ///
  /// In es, this message translates to:
  /// **'{label}: escribe un número.'**
  String homeNumberInvalid(Object label);

  /// No description provided for @homeNoteOrValueRequired.
  ///
  /// In es, this message translates to:
  /// **'Anota algún valor o escribe una nota.'**
  String get homeNoteOrValueRequired;

  /// No description provided for @homeSessionFinished.
  ///
  /// In es, this message translates to:
  /// **'Sesión terminada'**
  String get homeSessionFinished;

  /// No description provided for @homeSummaryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin novedades esta vez. Seguimos.'**
  String get homeSummaryEmpty;

  /// No description provided for @homeNewAchievement.
  ///
  /// In es, this message translates to:
  /// **'Logro nuevo'**
  String get homeNewAchievement;

  /// No description provided for @homeDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get homeDone;

  /// No description provided for @homeSuggestionSquat.
  ///
  /// In es, this message translates to:
  /// **'Sentadilla'**
  String get homeSuggestionSquat;

  /// No description provided for @homeSuggestionBench.
  ///
  /// In es, this message translates to:
  /// **'Press banca'**
  String get homeSuggestionBench;

  /// No description provided for @homeSuggestionRow.
  ///
  /// In es, this message translates to:
  /// **'Remo'**
  String get homeSuggestionRow;

  /// No description provided for @homeNewSet.
  ///
  /// In es, this message translates to:
  /// **'Nueva serie'**
  String get homeNewSet;

  /// No description provided for @homeWeightLabel.
  ///
  /// In es, this message translates to:
  /// **'Peso (kg)'**
  String get homeWeightLabel;

  /// No description provided for @homeWeightHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 20,5'**
  String get homeWeightHint;

  /// No description provided for @homeRepsLabel.
  ///
  /// In es, this message translates to:
  /// **'Repeticiones'**
  String get homeRepsLabel;

  /// No description provided for @homeRepsHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 10'**
  String get homeRepsHint;

  /// No description provided for @homeZeroWeightHint.
  ///
  /// In es, this message translates to:
  /// **'Usa 0 kg si entrenas sin carga externa.'**
  String get homeZeroWeightHint;

  /// No description provided for @homeExercisesLabel.
  ///
  /// In es, this message translates to:
  /// **'EJERCICIOS'**
  String get homeExercisesLabel;

  /// No description provided for @homeDeleteSetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar serie?'**
  String get homeDeleteSetTitle;

  /// No description provided for @accountsConnectError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo conectar con Google.'**
  String get accountsConnectError;

  /// No description provided for @accountsSwitchError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cambiar de cuenta. Tus datos se conservan.'**
  String get accountsSwitchError;

  /// No description provided for @accountsDescription.
  ///
  /// In es, this message translates to:
  /// **'Cada cuenta tiene su conversación, configuración de IA, hoja y entrenamientos en este móvil. El histórico anterior permanece en el perfil local. Conectar no copia ni sube esos datos.'**
  String get accountsDescription;

  /// No description provided for @accountsConnectAnother.
  ///
  /// In es, this message translates to:
  /// **'Conectar otra cuenta de Google'**
  String get accountsConnectAnother;

  /// No description provided for @accountsActiveProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil activo'**
  String get accountsActiveProfile;

  /// No description provided for @accountsReconnectProfile.
  ///
  /// In es, this message translates to:
  /// **'Volver a este perfil con Google'**
  String get accountsReconnectProfile;

  /// No description provided for @accountsDisconnect.
  ///
  /// In es, this message translates to:
  /// **'Desconectar y volver al perfil local'**
  String get accountsDisconnect;

  /// No description provided for @accountsDisconnectNotice.
  ///
  /// In es, this message translates to:
  /// **'Desconectar conserva los datos de cada perfil en este móvil. No borra archivos de Google ni revoca el acceso desde tu cuenta de Google.'**
  String get accountsDisconnectNotice;

  /// No description provided for @appearanceSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el tema. Vuelve a intentarlo.'**
  String get appearanceSaveError;

  /// No description provided for @appearanceIntro.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo quieres ver TrackIA. La elección se guarda en este móvil.'**
  String get appearanceIntro;

  /// No description provided for @appearanceSystemHint.
  ///
  /// In es, this message translates to:
  /// **'Usar el tema del dispositivo'**
  String get appearanceSystemHint;

  /// No description provided for @archiveSearchLabel.
  ///
  /// In es, this message translates to:
  /// **'Buscar por título o resumen'**
  String get archiveSearchLabel;

  /// No description provided for @archiveRecoverError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo recuperar el chat. El archivo se conserva.'**
  String get archiveRecoverError;

  /// No description provided for @archiveEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay chats archivados.'**
  String get archiveEmpty;

  /// No description provided for @archiveChatSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{date} · {count} mensajes'**
  String archiveChatSubtitle(Object date, Object count);

  /// No description provided for @archiveAutomaticTag.
  ///
  /// In es, this message translates to:
  /// **'archivado por el asistente'**
  String get archiveAutomaticTag;

  /// No description provided for @archiveContinuityTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen de continuidad'**
  String get archiveContinuityTitle;

  /// No description provided for @archiveReasonLine.
  ///
  /// In es, this message translates to:
  /// **'Motivo del asistente: {reason}'**
  String archiveReasonLine(Object reason);

  /// No description provided for @archiveConsultFromChat.
  ///
  /// In es, this message translates to:
  /// **'Consultar desde el chat'**
  String get archiveConsultFromChat;

  /// No description provided for @archiveYou.
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get archiveYou;

  /// No description provided for @archiveAttachmentKept.
  ///
  /// In es, this message translates to:
  /// **'Adjunto conservado: {name}'**
  String archiveAttachmentKept(Object name);

  /// No description provided for @notifUnsupported.
  ///
  /// In es, this message translates to:
  /// **'Los avisos de descanso solo están disponibles en Android.'**
  String get notifUnsupported;

  /// No description provided for @notifDndActive.
  ///
  /// In es, this message translates to:
  /// **'No molestar está activo'**
  String get notifDndActive;

  /// No description provided for @notifDndTotalSilence.
  ///
  /// In es, this message translates to:
  /// **'Estás en «Silencio total»: Android bloquea los avisos, incluso como alarma.'**
  String get notifDndTotalSilence;

  /// No description provided for @notifDndAlarm.
  ///
  /// In es, this message translates to:
  /// **'Los avisos de descanso suenan como alarma. Los demás avisos no sonarían ni vibrarían.'**
  String get notifDndAlarm;

  /// No description provided for @notifDndPlain.
  ///
  /// In es, this message translates to:
  /// **'Ahora mismo los avisos de descanso no sonarían ni vibrarían.'**
  String get notifDndPlain;

  /// No description provided for @notifEnabledTitle.
  ///
  /// In es, this message translates to:
  /// **'Avisos de actividad y descanso'**
  String get notifEnabledTitle;

  /// No description provided for @notifEnabledSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Actividad lista, tramo en marcha, fin de tramo y fin de descanso.'**
  String get notifEnabledSubtitle;

  /// No description provided for @notifAlarmStyleTitle.
  ///
  /// In es, this message translates to:
  /// **'Tratar como alarma'**
  String get notifAlarmStyleTitle;

  /// No description provided for @notifAlarmStyleSubtitle.
  ///
  /// In es, this message translates to:
  /// **'El fin de descanso y de tramo suenan y vibran aunque No molestar esté en modo Prioridad.'**
  String get notifAlarmStyleSubtitle;

  /// No description provided for @notifChannelBlockedTitle.
  ///
  /// In es, this message translates to:
  /// **'Android bloquea el canal de alarma'**
  String get notifChannelBlockedTitle;

  /// No description provided for @notifChannelBlockedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Actívalo en los ajustes del canal.'**
  String get notifChannelBlockedSubtitle;

  /// No description provided for @notifExactTitle.
  ///
  /// In es, this message translates to:
  /// **'Permitir avisos puntuales'**
  String get notifExactTitle;

  /// No description provided for @notifExactSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sin este permiso Android puede retrasar el aviso.'**
  String get notifExactSubtitle;

  /// No description provided for @notifCheck.
  ///
  /// In es, this message translates to:
  /// **'Comprobar'**
  String get notifCheck;

  /// No description provided for @notifTest.
  ///
  /// In es, this message translates to:
  /// **'Probar aviso'**
  String get notifTest;

  /// No description provided for @notifTestAlarm.
  ///
  /// In es, this message translates to:
  /// **'Probar con No molestar activo'**
  String get notifTestAlarm;

  /// No description provided for @notifOpenDnd.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes de No molestar'**
  String get notifOpenDnd;

  /// No description provided for @notifSilenceNote.
  ///
  /// In es, this message translates to:
  /// **'En «Silencio total» Android bloquea todo, incluidas las alarmas. Ahí solo ayuda permitirlas en los ajustes de tu móvil.'**
  String get notifSilenceNote;

  /// No description provided for @progressLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo calcular el progreso.'**
  String get progressLoadError;

  /// No description provided for @progressMonth1.
  ///
  /// In es, this message translates to:
  /// **'enero'**
  String get progressMonth1;

  /// No description provided for @progressMonth2.
  ///
  /// In es, this message translates to:
  /// **'febrero'**
  String get progressMonth2;

  /// No description provided for @progressMonth3.
  ///
  /// In es, this message translates to:
  /// **'marzo'**
  String get progressMonth3;

  /// No description provided for @progressMonth4.
  ///
  /// In es, this message translates to:
  /// **'abril'**
  String get progressMonth4;

  /// No description provided for @progressMonth5.
  ///
  /// In es, this message translates to:
  /// **'mayo'**
  String get progressMonth5;

  /// No description provided for @progressMonth6.
  ///
  /// In es, this message translates to:
  /// **'junio'**
  String get progressMonth6;

  /// No description provided for @progressMonth7.
  ///
  /// In es, this message translates to:
  /// **'julio'**
  String get progressMonth7;

  /// No description provided for @progressMonth8.
  ///
  /// In es, this message translates to:
  /// **'agosto'**
  String get progressMonth8;

  /// No description provided for @progressMonth9.
  ///
  /// In es, this message translates to:
  /// **'septiembre'**
  String get progressMonth9;

  /// No description provided for @progressMonth10.
  ///
  /// In es, this message translates to:
  /// **'octubre'**
  String get progressMonth10;

  /// No description provided for @progressMonth11.
  ///
  /// In es, this message translates to:
  /// **'noviembre'**
  String get progressMonth11;

  /// No description provided for @progressMonth12.
  ///
  /// In es, this message translates to:
  /// **'diciembre'**
  String get progressMonth12;

  /// No description provided for @progressDayStatus.
  ///
  /// In es, this message translates to:
  /// **'{day} de {month}: {status}'**
  String progressDayStatus(int day, Object month, Object status);

  /// No description provided for @progressDayDone.
  ///
  /// In es, this message translates to:
  /// **'cumplido'**
  String get progressDayDone;

  /// No description provided for @progressDayPending.
  ///
  /// In es, this message translates to:
  /// **'pendiente'**
  String get progressDayPending;

  /// No description provided for @progressDayMissed.
  ///
  /// In es, this message translates to:
  /// **'sin cumplir'**
  String get progressDayMissed;

  /// No description provided for @progressTitle.
  ///
  /// In es, this message translates to:
  /// **'Progreso · {name}'**
  String progressTitle(Object name);

  /// No description provided for @progressStreakCurrent.
  ///
  /// In es, this message translates to:
  /// **'Racha actual (días): {n}'**
  String progressStreakCurrent(int n);

  /// No description provided for @progressStreakBest.
  ///
  /// In es, this message translates to:
  /// **'Mejor racha: {best}'**
  String progressStreakBest(int best);

  /// No description provided for @progressFreeDays.
  ///
  /// In es, this message translates to:
  /// **'Días libres esta semana: {used}/{total}'**
  String progressFreeDays(int used, int total);

  /// No description provided for @progressGoalToday.
  ///
  /// In es, this message translates to:
  /// **'Meta de hoy'**
  String get progressGoalToday;

  /// No description provided for @progressGoalWeek.
  ///
  /// In es, this message translates to:
  /// **'Meta de la semana'**
  String get progressGoalWeek;

  /// No description provided for @progressGoalValues.
  ///
  /// In es, this message translates to:
  /// **'{value} de {target}'**
  String progressGoalValues(Object value, Object target);

  /// No description provided for @progressLastFourWeeks.
  ///
  /// In es, this message translates to:
  /// **'Últimas 4 semanas'**
  String get progressLastFourWeeks;

  /// No description provided for @progressAchievementUnlocked.
  ///
  /// In es, this message translates to:
  /// **'{title}, desbloqueado'**
  String progressAchievementUnlocked(Object title);

  /// No description provided for @progressAchievementLocked.
  ///
  /// In es, this message translates to:
  /// **'{title}, bloqueado, {percent} % de progreso'**
  String progressAchievementLocked(Object title, int percent);

  /// No description provided for @progressAchievementsTitle.
  ///
  /// In es, this message translates to:
  /// **'Logros · {unlocked} de {total}'**
  String progressAchievementsTitle(int unlocked, int total);

  /// No description provided for @progressAchievementsEmptyPlay.
  ///
  /// In es, this message translates to:
  /// **'Tus logros aparecerán al terminar tu primera actividad.'**
  String get progressAchievementsEmptyPlay;

  /// No description provided for @progressAchievementsEmptyEnable.
  ///
  /// In es, this message translates to:
  /// **'Activa el modo Juego y los logros en «{place}».'**
  String progressAchievementsEmptyEnable(Object place);

  /// No description provided for @routinesTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus rutinas'**
  String get routinesTitle;

  /// No description provided for @routinesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Prepara una vez. Entrena a tu ritmo.'**
  String get routinesSubtitle;

  /// No description provided for @routinesCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear rutina'**
  String get routinesCreate;

  /// No description provided for @routinesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu próxima sesión, preparada'**
  String get routinesEmptyTitle;

  /// No description provided for @routinesEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Crea, por ejemplo, «Pierna A» con tus ejercicios, series y rango de repeticiones.'**
  String get routinesEmptyBody;

  /// No description provided for @routinesOptionsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Opciones de {name}'**
  String routinesOptionsTooltip(Object name);

  /// No description provided for @routinesDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar rutina?'**
  String get routinesDeleteTitle;

  /// No description provided for @routinesDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará «{name}». Tus entrenamientos guardados y la sesión en curso se conservarán.'**
  String routinesDeleteBody(Object name);

  /// No description provided for @routinesEditMenu.
  ///
  /// In es, this message translates to:
  /// **'Editar rutina'**
  String get routinesEditMenu;

  /// No description provided for @routinesDeleteMenu.
  ///
  /// In es, this message translates to:
  /// **'Eliminar rutina'**
  String get routinesDeleteMenu;

  /// No description provided for @routinesDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get routinesDelete;

  /// No description provided for @routinesTrain.
  ///
  /// In es, this message translates to:
  /// **'Entrenar'**
  String get routinesTrain;

  /// No description provided for @routinesContinueSession.
  ///
  /// In es, this message translates to:
  /// **'Continuar sesión activa'**
  String get routinesContinueSession;

  /// No description provided for @routinesNeedExercise.
  ///
  /// In es, this message translates to:
  /// **'Añade al menos un ejercicio.'**
  String get routinesNeedExercise;

  /// No description provided for @routinesNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la rutina'**
  String get routinesNameLabel;

  /// No description provided for @routinesNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Pierna A'**
  String get routinesNameHint;

  /// No description provided for @routinesEditorHelp.
  ///
  /// In es, this message translates to:
  /// **'Define tus objetivos. Las series se registrarán cuando entrenes.'**
  String get routinesEditorHelp;

  /// No description provided for @routinesMoveUp.
  ///
  /// In es, this message translates to:
  /// **'Subir ejercicio {n}'**
  String routinesMoveUp(int n);

  /// No description provided for @routinesMoveDown.
  ///
  /// In es, this message translates to:
  /// **'Bajar ejercicio {n}'**
  String routinesMoveDown(int n);

  /// No description provided for @routinesEditExercise.
  ///
  /// In es, this message translates to:
  /// **'Editar ejercicio {n}'**
  String routinesEditExercise(int n);

  /// No description provided for @routinesRemoveExercise.
  ///
  /// In es, this message translates to:
  /// **'Quitar ejercicio {n}'**
  String routinesRemoveExercise(int n);

  /// No description provided for @routinesAddExercise.
  ///
  /// In es, this message translates to:
  /// **'Añadir ejercicio a rutina'**
  String get routinesAddExercise;

  /// No description provided for @routinesSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando…'**
  String get routinesSaving;

  /// No description provided for @routinesSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar rutina'**
  String get routinesSave;

  /// No description provided for @routinesLeaveTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Salir sin guardar?'**
  String get routinesLeaveTitle;

  /// No description provided for @routinesLeaveBody.
  ///
  /// In es, this message translates to:
  /// **'Los cambios en esta rutina se perderán.'**
  String get routinesLeaveBody;

  /// No description provided for @routinesKeepEditing.
  ///
  /// In es, this message translates to:
  /// **'Seguir editando'**
  String get routinesKeepEditing;

  /// No description provided for @routinesDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar cambios'**
  String get routinesDiscard;

  /// No description provided for @routinesBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get routinesBack;

  /// No description provided for @routinesExerciseDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio de rutina'**
  String get routinesExerciseDialogTitle;

  /// No description provided for @routinesEditTargetTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar objetivo'**
  String get routinesEditTargetTitle;

  /// No description provided for @routinesExerciseLabel.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio'**
  String get routinesExerciseLabel;

  /// No description provided for @routinesExerciseHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Sentadilla'**
  String get routinesExerciseHint;

  /// No description provided for @routinesTargetSets.
  ///
  /// In es, this message translates to:
  /// **'Series previstas'**
  String get routinesTargetSets;

  /// No description provided for @routinesRepsMin.
  ///
  /// In es, this message translates to:
  /// **'Reps mín.'**
  String get routinesRepsMin;

  /// No description provided for @routinesRepsMax.
  ///
  /// In es, this message translates to:
  /// **'Reps máx.'**
  String get routinesRepsMax;

  /// No description provided for @routinesRestSeconds.
  ///
  /// In es, this message translates to:
  /// **'Descanso (segundos)'**
  String get routinesRestSeconds;

  /// No description provided for @routinesSaveExercise.
  ///
  /// In es, this message translates to:
  /// **'Guardar ejercicio'**
  String get routinesSaveExercise;

  /// No description provided for @focusCounterSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el contador. Vuelve a intentarlo.'**
  String get focusCounterSaveError;

  /// No description provided for @focusResultSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el resultado. Conserva el texto y vuelve a intentarlo.'**
  String get focusResultSaveError;

  /// No description provided for @focusSaveActivityError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar en tus actividades.'**
  String get focusSaveActivityError;

  /// No description provided for @focusRecordSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el registro. Vuelve a intentarlo.'**
  String get focusRecordSaveError;

  /// No description provided for @focusReviewTimeTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisar hora'**
  String get focusReviewTimeTitle;

  /// No description provided for @focusReviewTimeBody.
  ///
  /// In es, this message translates to:
  /// **'La hora elegida no coincide con los registros. ¿Guardar esa hora y conservarlos?'**
  String get focusReviewTimeBody;

  /// No description provided for @focusBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get focusBack;

  /// No description provided for @focusSaveThatTime.
  ///
  /// In es, this message translates to:
  /// **'Guardar esa hora'**
  String get focusSaveThatTime;

  /// No description provided for @focusRunning.
  ///
  /// In es, this message translates to:
  /// **'En marcha'**
  String get focusRunning;

  /// No description provided for @focusReady.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get focusReady;

  /// No description provided for @focusRest.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get focusRest;

  /// No description provided for @focusRepeatedRest.
  ///
  /// In es, this message translates to:
  /// **'{progress} {segments} · Descanso'**
  String focusRepeatedRest(Object progress, Object segments);

  /// No description provided for @focusSegmentCount.
  ///
  /// In es, this message translates to:
  /// **'{segment} {count}'**
  String focusSegmentCount(Object segment, int count);

  /// No description provided for @focusSegmentCountOfTarget.
  ///
  /// In es, this message translates to:
  /// **'{segment} {count} de {target}'**
  String focusSegmentCountOfTarget(Object segment, int count, int target);

  /// No description provided for @focusSegmentSerie.
  ///
  /// In es, this message translates to:
  /// **'serie'**
  String get focusSegmentSerie;

  /// No description provided for @focusSegmentTramo.
  ///
  /// In es, this message translates to:
  /// **'tramo'**
  String get focusSegmentTramo;

  /// No description provided for @focusSegmentSeries.
  ///
  /// In es, this message translates to:
  /// **'series'**
  String get focusSegmentSeries;

  /// No description provided for @focusSegmentTramos.
  ///
  /// In es, this message translates to:
  /// **'tramos'**
  String get focusSegmentTramos;

  /// No description provided for @focusRemoveField.
  ///
  /// In es, this message translates to:
  /// **'Quitar {label}'**
  String focusRemoveField(Object label);

  /// No description provided for @focusAddField.
  ///
  /// In es, this message translates to:
  /// **'Añadir {label}'**
  String focusAddField(Object label);

  /// No description provided for @datePatternLongWeekday.
  ///
  /// In es, this message translates to:
  /// **'EEEE, d \'de\' MMMM'**
  String get datePatternLongWeekday;

  /// No description provided for @datePatternLongDateTime.
  ///
  /// In es, this message translates to:
  /// **'d \'de\' MMMM · HH:mm'**
  String get datePatternLongDateTime;

  /// No description provided for @datePatternShortDateTime.
  ///
  /// In es, this message translates to:
  /// **'d MMM yyyy · HH:mm'**
  String get datePatternShortDateTime;

  /// No description provided for @datePatternShortDate.
  ///
  /// In es, this message translates to:
  /// **'d MMM'**
  String get datePatternShortDate;

  /// No description provided for @datePatternNumericDate.
  ///
  /// In es, this message translates to:
  /// **'d/M/yyyy'**
  String get datePatternNumericDate;

  /// No description provided for @datePatternNumericDateTime.
  ///
  /// In es, this message translates to:
  /// **'d/M/yyyy HH:mm'**
  String get datePatternNumericDateTime;

  /// No description provided for @datePatternNumericDateTimeSeconds.
  ///
  /// In es, this message translates to:
  /// **'d/M/yyyy HH:mm:ss'**
  String get datePatternNumericDateTimeSeconds;

  /// No description provided for @datePatternPaddedDateTime.
  ///
  /// In es, this message translates to:
  /// **'dd/MM/yyyy HH:mm'**
  String get datePatternPaddedDateTime;

  /// No description provided for @builderTypeNumber.
  ///
  /// In es, this message translates to:
  /// **'Número'**
  String get builderTypeNumber;

  /// No description provided for @builderTypeScale.
  ///
  /// In es, this message translates to:
  /// **'Escala'**
  String get builderTypeScale;

  /// No description provided for @builderTypeText.
  ///
  /// In es, this message translates to:
  /// **'Texto'**
  String get builderTypeText;

  /// No description provided for @builderTypeChoice.
  ///
  /// In es, this message translates to:
  /// **'Opción'**
  String get builderTypeChoice;

  /// No description provided for @builderTypeBoolean.
  ///
  /// In es, this message translates to:
  /// **'Sí o no'**
  String get builderTypeBoolean;

  /// No description provided for @builderAggSum.
  ///
  /// In es, this message translates to:
  /// **'Sumar'**
  String get builderAggSum;

  /// No description provided for @builderAggMax.
  ///
  /// In es, this message translates to:
  /// **'Mejor marca'**
  String get builderAggMax;

  /// No description provided for @builderAggAvg.
  ///
  /// In es, this message translates to:
  /// **'Promedio'**
  String get builderAggAvg;

  /// No description provided for @builderAggDistinct.
  ///
  /// In es, this message translates to:
  /// **'Contar distintos'**
  String get builderAggDistinct;

  /// No description provided for @builderAggCountTrue.
  ///
  /// In es, this message translates to:
  /// **'Contar síes'**
  String get builderAggCountTrue;

  /// No description provided for @builderAggNone.
  ///
  /// In es, this message translates to:
  /// **'Solo notas'**
  String get builderAggNone;

  /// No description provided for @proposalLabelActivitySeconds.
  ///
  /// In es, this message translates to:
  /// **'Duración por tramo'**
  String get proposalLabelActivitySeconds;

  /// No description provided for @proposalLabelTargetCycles.
  ///
  /// In es, this message translates to:
  /// **'Ciclos previstos'**
  String get proposalLabelTargetCycles;

  /// No description provided for @proposalLabelUnitCycles.
  ///
  /// In es, this message translates to:
  /// **'ciclos'**
  String get proposalLabelUnitCycles;

  /// No description provided for @proposalLabelUnitSeconds.
  ///
  /// In es, this message translates to:
  /// **'s'**
  String get proposalLabelUnitSeconds;

  /// No description provided for @creatorStaticGreeting.
  ///
  /// In es, this message translates to:
  /// **'Cuéntame qué quieres seguir y te ayudo a crear tu acompañante.'**
  String get creatorStaticGreeting;

  /// No description provided for @creatorStaticDayLetters.
  ///
  /// In es, this message translates to:
  /// **'L,M,X,J,V,S,D'**
  String get creatorStaticDayLetters;

  /// No description provided for @proposalGameSuggestion.
  ///
  /// In es, this message translates to:
  /// **'Llevas varios días seguidos cumpliendo. ¿Quieres activar el modo Juego para ver metas, rachas y logros?'**
  String get proposalGameSuggestion;

  /// No description provided for @reminderPhraseWindowStartCheer1.
  ///
  /// In es, this message translates to:
  /// **'{nombre} te espera: hoy toca {meta}.'**
  String reminderPhraseWindowStartCheer1(Object nombre, Object meta);

  /// No description provided for @reminderPhraseWindowStartCheer2.
  ///
  /// In es, this message translates to:
  /// **'{nombre} te espera hoy.'**
  String reminderPhraseWindowStartCheer2(Object nombre);

  /// No description provided for @reminderPhraseWindowStartNeutral1.
  ///
  /// In es, this message translates to:
  /// **'Es buen momento para tu actividad. Meta de hoy: {meta}.'**
  String reminderPhraseWindowStartNeutral1(Object meta);

  /// No description provided for @reminderPhraseWindowStartNeutral2.
  ///
  /// In es, this message translates to:
  /// **'Es buen momento para tu actividad.'**
  String get reminderPhraseWindowStartNeutral2;

  /// No description provided for @reminderPhraseLastCallCheer1.
  ///
  /// In es, this message translates to:
  /// **'Última llamada: con {minimo} mantienes tu racha de {racha} días.'**
  String reminderPhraseLastCallCheer1(Object minimo, Object racha);

  /// No description provided for @reminderPhraseLastCallCheer2.
  ///
  /// In es, this message translates to:
  /// **'No pierdas la racha: te faltan {faltan} esta semana.'**
  String reminderPhraseLastCallCheer2(Object faltan);

  /// No description provided for @reminderPhraseLastCallCheer3.
  ///
  /// In es, this message translates to:
  /// **'Última llamada para hoy.'**
  String get reminderPhraseLastCallCheer3;

  /// No description provided for @reminderPhraseLastCallNeutral1.
  ///
  /// In es, this message translates to:
  /// **'Aún estás a tiempo hoy. Con {minimo} basta.'**
  String reminderPhraseLastCallNeutral1(Object minimo);

  /// No description provided for @reminderPhraseLastCallNeutral2.
  ///
  /// In es, this message translates to:
  /// **'Te faltan {faltan} esta semana.'**
  String reminderPhraseLastCallNeutral2(Object faltan);

  /// No description provided for @reminderPhraseLastCallNeutral3.
  ///
  /// In es, this message translates to:
  /// **'Aún estás a tiempo hoy.'**
  String get reminderPhraseLastCallNeutral3;

  /// No description provided for @reminderPhraseInactiveGymbroCheer.
  ///
  /// In es, this message translates to:
  /// **'Amigo, llevamos {dias} días sin entrenar. Vamos a movernos un poco.'**
  String reminderPhraseInactiveGymbroCheer(Object dias);

  /// No description provided for @reminderPhraseInactiveCheer1.
  ///
  /// In es, this message translates to:
  /// **'Llevamos {dias} días sin vernos. ¿Algo corto hoy?'**
  String reminderPhraseInactiveCheer1(Object dias);

  /// No description provided for @reminderPhraseInactiveCheer2.
  ///
  /// In es, this message translates to:
  /// **'¿Algo corto hoy?'**
  String get reminderPhraseInactiveCheer2;

  /// No description provided for @reminderPhraseInactiveNeutral1.
  ///
  /// In es, this message translates to:
  /// **'Llevas {dias} días sin registrar.'**
  String reminderPhraseInactiveNeutral1(Object dias);

  /// No description provided for @reminderPhraseInactiveNeutral2.
  ///
  /// In es, this message translates to:
  /// **'Hace unos días que no registras.'**
  String get reminderPhraseInactiveNeutral2;

  /// No description provided for @reminderPhraseMinimumSessionOne.
  ///
  /// In es, this message translates to:
  /// **'1 sesión'**
  String get reminderPhraseMinimumSessionOne;

  /// No description provided for @reminderPhraseMinimumSessions.
  ///
  /// In es, this message translates to:
  /// **'{n} sesiones'**
  String reminderPhraseMinimumSessions(Object n);

  /// No description provided for @reminderPhraseMinimumMinutes.
  ///
  /// In es, this message translates to:
  /// **'{n} min'**
  String reminderPhraseMinimumMinutes(Object n);

  /// No description provided for @reminderPhraseMinimumField.
  ///
  /// In es, this message translates to:
  /// **'{n} {campo}'**
  String reminderPhraseMinimumField(Object n, Object campo);

  /// No description provided for @memoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Memoria de {name}'**
  String memoryTitle(Object name);

  /// No description provided for @memoryIntro.
  ///
  /// In es, this message translates to:
  /// **'Lo que este acompañante recuerda de ti. Puedes revisarlo, editarlo o borrarlo cuando quieras. Se trata como información tuya, nunca como instrucciones.'**
  String get memoryIntro;

  /// No description provided for @memoryOpen.
  ///
  /// In es, this message translates to:
  /// **'Memoria del acompañante'**
  String get memoryOpen;

  /// No description provided for @memoryOpenHelp.
  ///
  /// In es, this message translates to:
  /// **'Ver, editar y borrar lo que recuerda, y la copia en la nube.'**
  String get memoryOpenHelp;

  /// No description provided for @memoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay recuerdos guardados.'**
  String get memoryEmpty;

  /// No description provided for @memoryLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los recuerdos.'**
  String get memoryLoadError;

  /// No description provided for @memoryActionError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la acción. Tus recuerdos no han cambiado.'**
  String get memoryActionError;

  /// No description provided for @memoryStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get memoryStatusActive;

  /// No description provided for @memoryStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de confirmar'**
  String get memoryStatusPending;

  /// No description provided for @memorySourceExplicit.
  ///
  /// In es, this message translates to:
  /// **'Lo pediste tú'**
  String get memorySourceExplicit;

  /// No description provided for @memorySourceInferred.
  ///
  /// In es, this message translates to:
  /// **'Sugerido por la IA'**
  String get memorySourceInferred;

  /// No description provided for @memorySourceEdited.
  ///
  /// In es, this message translates to:
  /// **'Editado por ti'**
  String get memorySourceEdited;

  /// No description provided for @memoryConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get memoryConfirm;

  /// No description provided for @memoryConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Recuerdo confirmado.'**
  String get memoryConfirmed;

  /// No description provided for @memoryEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get memoryEdit;

  /// No description provided for @memoryEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar recuerdo'**
  String get memoryEditTitle;

  /// No description provided for @memoryEditLabel.
  ///
  /// In es, this message translates to:
  /// **'Recuerdo'**
  String get memoryEditLabel;

  /// No description provided for @memoryEditEmpty.
  ///
  /// In es, this message translates to:
  /// **'El recuerdo no puede estar vacío.'**
  String get memoryEditEmpty;

  /// No description provided for @memoryEditTooLong.
  ///
  /// In es, this message translates to:
  /// **'El recuerdo no puede superar 2000 caracteres.'**
  String get memoryEditTooLong;

  /// No description provided for @memoryEdited.
  ///
  /// In es, this message translates to:
  /// **'Recuerdo guardado.'**
  String get memoryEdited;

  /// No description provided for @memoryDeleteLocalAction.
  ///
  /// In es, this message translates to:
  /// **'Borrar del móvil'**
  String get memoryDeleteLocalAction;

  /// No description provided for @memoryDeleteLocalTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar este recuerdo del móvil?'**
  String get memoryDeleteLocalTitle;

  /// No description provided for @memoryDeleteLocalBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrará solo de este móvil y el acompañante dejará de usarlo. No borra la copia que tengas en la nube; para eso usa «Borrar en la nube».'**
  String get memoryDeleteLocalBody;

  /// No description provided for @memoryDeletedLocal.
  ///
  /// In es, this message translates to:
  /// **'Recuerdo borrado de este móvil. La copia en la nube no se ha tocado.'**
  String get memoryDeletedLocal;

  /// No description provided for @memoryCloudTitle.
  ///
  /// In es, this message translates to:
  /// **'Copia en la nube'**
  String get memoryCloudTitle;

  /// No description provided for @memoryCloudHelp.
  ///
  /// In es, this message translates to:
  /// **'Opcional y solo cuando tú lo pidas. Se guardan los recuerdos activos de este acompañante, sin chats ni claves. No está cifrada de extremo a extremo.'**
  String get memoryCloudHelp;

  /// No description provided for @memoryCloudUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Google Drive aún no está conectado en esta versión'**
  String get memoryCloudUnavailable;

  /// No description provided for @memoryCloudNoAccount.
  ///
  /// In es, this message translates to:
  /// **'Conecta una cuenta de Google para usar la copia en la nube.'**
  String get memoryCloudNoAccount;

  /// No description provided for @memoryCloudAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta: {account}'**
  String memoryCloudAccount(Object account);

  /// No description provided for @memoryCloudLastCopy.
  ///
  /// In es, this message translates to:
  /// **'Última copia vista: {date} (revisión {revision})'**
  String memoryCloudLastCopy(Object date, int revision);

  /// No description provided for @memoryCloudSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar en la nube'**
  String get memoryCloudSave;

  /// No description provided for @memoryCloudLoad.
  ///
  /// In es, this message translates to:
  /// **'Cargar de la nube'**
  String get memoryCloudLoad;

  /// No description provided for @memoryCloudDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar en la nube'**
  String get memoryCloudDelete;

  /// No description provided for @memoryCloudSaveTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Guardar en la nube?'**
  String get memoryCloudSaveTitle;

  /// No description provided for @memoryCloudSaveBody.
  ///
  /// In es, this message translates to:
  /// **'Se subirán a la cuenta {account} los recuerdos activos de este acompañante. Recuerdos a subir: {count}. Los pendientes de confirmar no se suben. Si la copia de la nube cambió, no se sobrescribe.'**
  String memoryCloudSaveBody(Object account, int count);

  /// No description provided for @memoryCloudSaved.
  ///
  /// In es, this message translates to:
  /// **'Copia guardada en la cuenta {account}.'**
  String memoryCloudSaved(Object account);

  /// No description provided for @memoryCloudLoaded.
  ///
  /// In es, this message translates to:
  /// **'Copia cargada. Recuerdos añadidos: {count}.'**
  String memoryCloudLoaded(int count);

  /// No description provided for @memoryCloudLoadCancelled.
  ///
  /// In es, this message translates to:
  /// **'Carga cancelada. No se ha cambiado nada.'**
  String get memoryCloudLoadCancelled;

  /// No description provided for @memoryCloudDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar la copia en la nube?'**
  String get memoryCloudDeleteTitle;

  /// No description provided for @memoryCloudDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrará de la cuenta {account} la copia de este acompañante (guardada el {date}). No borra los recuerdos de este móvil. No se puede deshacer.'**
  String memoryCloudDeleteBody(Object account, Object date);

  /// No description provided for @memoryCloudDeleted.
  ///
  /// In es, this message translates to:
  /// **'Copia borrada de la cuenta {account}. Los recuerdos de este móvil no se han tocado.'**
  String memoryCloudDeleted(Object account);

  /// No description provided for @memoryCloudDeleteCancelled.
  ///
  /// In es, this message translates to:
  /// **'Borrado cancelado. No se ha cambiado nada.'**
  String get memoryCloudDeleteCancelled;

  /// No description provided for @memoryCloudNotFound.
  ///
  /// In es, this message translates to:
  /// **'No hay copia en la nube para este acompañante.'**
  String get memoryCloudNotFound;

  /// No description provided for @memoryCloudConflict.
  ///
  /// In es, this message translates to:
  /// **'La copia de la nube es distinta de la última que viste. No se ha modificado nada; usa «Cargar de la nube» para revisarla.'**
  String get memoryCloudConflict;

  /// No description provided for @memoryCloudUncertain.
  ///
  /// In es, this message translates to:
  /// **'No se pudo confirmar el resultado; puede que la operación sí se haya aplicado. Cárgala de nuevo para comprobarlo antes de repetir.'**
  String get memoryCloudUncertain;

  /// No description provided for @memoryCloudCancelled.
  ///
  /// In es, this message translates to:
  /// **'Operación cancelada. No se ha cambiado nada.'**
  String get memoryCloudCancelled;

  /// No description provided for @memoryCloudDenied.
  ///
  /// In es, this message translates to:
  /// **'Google no concedió el permiso. No se ha cambiado nada.'**
  String get memoryCloudDenied;

  /// No description provided for @memoryCloudFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la operación con la nube. No se ha cambiado nada en tus recuerdos locales.'**
  String get memoryCloudFailed;

  /// No description provided for @memoryPreviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Vista previa de la copia'**
  String get memoryPreviewTitle;

  /// No description provided for @memoryPreviewFrom.
  ///
  /// In es, this message translates to:
  /// **'Cuenta {account}, copia del {date}'**
  String memoryPreviewFrom(Object account, Object date);

  /// No description provided for @memoryPreviewAdd.
  ///
  /// In es, this message translates to:
  /// **'Se añadirían: {count}'**
  String memoryPreviewAdd(int count);

  /// No description provided for @memoryPreviewSkip.
  ///
  /// In es, this message translates to:
  /// **'Se omiten (ya existen): {count}'**
  String memoryPreviewSkip(int count);

  /// No description provided for @memoryPreviewConflict.
  ///
  /// In es, this message translates to:
  /// **'En conflicto (no se aplican): {count}'**
  String memoryPreviewConflict(int count);

  /// No description provided for @memoryPreviewConflictHelp.
  ///
  /// In es, this message translates to:
  /// **'Los conflictos no se resuelven solos: tus recuerdos locales se conservan tal cual.'**
  String get memoryPreviewConflictHelp;

  /// No description provided for @memoryPreviewNothing.
  ///
  /// In es, this message translates to:
  /// **'No hay nada que añadir.'**
  String get memoryPreviewNothing;

  /// No description provided for @memoryPreviewApply.
  ///
  /// In es, this message translates to:
  /// **'Añadir recuerdos'**
  String get memoryPreviewApply;

  /// No description provided for @agreementTitle.
  ///
  /// In es, this message translates to:
  /// **'Acuerdos de apoyo'**
  String get agreementTitle;

  /// No description provided for @agreementNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo acuerdo'**
  String get agreementNew;

  /// No description provided for @agreementEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes acuerdos. Crea uno con el botón Nuevo acuerdo; solo se anota lo que tú registres.'**
  String get agreementEmpty;

  /// No description provided for @agreementLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los acuerdos.'**
  String get agreementLoadError;

  /// No description provided for @agreementSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el cambio. El acuerdo sigue como estaba.'**
  String get agreementSaveError;

  /// No description provided for @agreementStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get agreementStatusActive;

  /// No description provided for @agreementStatusPaused.
  ///
  /// In es, this message translates to:
  /// **'En pausa'**
  String get agreementStatusPaused;

  /// No description provided for @agreementStatusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Finalizados'**
  String get agreementStatusCompleted;

  /// No description provided for @agreementObjectiveLabel.
  ///
  /// In es, this message translates to:
  /// **'Objetivo'**
  String get agreementObjectiveLabel;

  /// No description provided for @agreementUnitLabel.
  ///
  /// In es, this message translates to:
  /// **'Unidad (opcional)'**
  String get agreementUnitLabel;

  /// No description provided for @agreementMeasureLabel.
  ///
  /// In es, this message translates to:
  /// **'Medida'**
  String get agreementMeasureLabel;

  /// No description provided for @agreementMeasureOptionalLabel.
  ///
  /// In es, this message translates to:
  /// **'Medida (opcional)'**
  String get agreementMeasureOptionalLabel;

  /// No description provided for @agreementConsent.
  ///
  /// In es, this message translates to:
  /// **'Acepto crear este acuerdo. Solo se anotará lo que yo registre.'**
  String get agreementConsent;

  /// No description provided for @agreementErrorObjective.
  ///
  /// In es, this message translates to:
  /// **'Escribe un objetivo (hasta 2000 caracteres).'**
  String get agreementErrorObjective;

  /// No description provided for @agreementErrorMeasure.
  ///
  /// In es, this message translates to:
  /// **'La medida debe ser un número finito igual o mayor que 0.'**
  String get agreementErrorMeasure;

  /// No description provided for @agreementErrorConsent.
  ///
  /// In es, this message translates to:
  /// **'Marca la casilla para crear el acuerdo.'**
  String get agreementErrorConsent;

  /// No description provided for @agreementCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get agreementCancel;

  /// No description provided for @agreementCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get agreementCreate;

  /// No description provided for @agreementSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get agreementSave;

  /// No description provided for @agreementModify.
  ///
  /// In es, this message translates to:
  /// **'Modificar'**
  String get agreementModify;

  /// No description provided for @agreementPause.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get agreementPause;

  /// No description provided for @agreementResume.
  ///
  /// In es, this message translates to:
  /// **'Reanudar'**
  String get agreementResume;

  /// No description provided for @agreementComplete.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get agreementComplete;

  /// No description provided for @agreementCompleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Finalizar el acuerdo?'**
  String get agreementCompleteTitle;

  /// No description provided for @agreementCompleteBody.
  ///
  /// In es, this message translates to:
  /// **'Un acuerdo finalizado ya no se puede modificar ni admite más avances. El historial se conserva.'**
  String get agreementCompleteBody;

  /// No description provided for @agreementRecordProgress.
  ///
  /// In es, this message translates to:
  /// **'Registrar avance'**
  String get agreementRecordProgress;

  /// No description provided for @agreementRecord.
  ///
  /// In es, this message translates to:
  /// **'Registrar'**
  String get agreementRecord;

  /// No description provided for @agreementAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cantidad (opcional)'**
  String get agreementAmountLabel;

  /// No description provided for @agreementNoteLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota (opcional)'**
  String get agreementNoteLabel;

  /// No description provided for @agreementReminderLabel.
  ///
  /// In es, this message translates to:
  /// **'Aviso'**
  String get agreementReminderLabel;

  /// No description provided for @agreementEventsTitle.
  ///
  /// In es, this message translates to:
  /// **'Avances anotados'**
  String get agreementEventsTitle;

  /// No description provided for @agreementNoEvents.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay avances anotados.'**
  String get agreementNoEvents;

  /// No description provided for @agreementChangesTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial de cambios'**
  String get agreementChangesTitle;

  /// No description provided for @agreementNoChanges.
  ///
  /// In es, this message translates to:
  /// **'Sin cambios desde la creación.'**
  String get agreementNoChanges;

  /// No description provided for @agreementRevisionLabel.
  ///
  /// In es, this message translates to:
  /// **'Revisión {n}'**
  String agreementRevisionLabel(int n);

  /// No description provided for @packageShareRow.
  ///
  /// In es, this message translates to:
  /// **'Compartir acompañante'**
  String get packageShareRow;

  /// No description provided for @packageShareRowHelp.
  ///
  /// In es, this message translates to:
  /// **'Crea un archivo .trackia con la configuración de este acompañante, sin tus datos.'**
  String get packageShareRowHelp;

  /// No description provided for @packageShareTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Compartir este acompañante?'**
  String get packageShareTitle;

  /// No description provided for @packageShareIncludes.
  ///
  /// In es, this message translates to:
  /// **'Se comparte: nombre, icono, color, descripción, instrucciones de estilo, modo, plantillas de actividad y textos de avisos.'**
  String get packageShareIncludes;

  /// No description provided for @packageShareExcludes.
  ///
  /// In es, this message translates to:
  /// **'No se comparte: claves de IA, chats, memoria, hoja de Google, cuentas ni tus datos.'**
  String get packageShareExcludes;

  /// No description provided for @packageShareReceiverNote.
  ///
  /// In es, this message translates to:
  /// **'Quien lo reciba podrá importarlo y revisarlo antes de usarlo.'**
  String get packageShareReceiverNote;

  /// No description provided for @packageShareTemplatesLimited.
  ///
  /// In es, this message translates to:
  /// **'Solo se incluyen las 5 primeras plantillas de actividad.'**
  String get packageShareTemplatesLimited;

  /// No description provided for @packageShareConfirm.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get packageShareConfirm;

  /// No description provided for @packageShareInstructionsTooLong.
  ///
  /// In es, this message translates to:
  /// **'Las instrucciones superan los 4000 caracteres que admite compartir. Acórtalas e inténtalo de nuevo. No se ha compartido nada.'**
  String get packageShareInstructionsTooLong;

  /// No description provided for @packageShareInvalid.
  ///
  /// In es, this message translates to:
  /// **'Este acompañante tiene datos que no se pueden compartir. No se ha compartido nada.'**
  String get packageShareInvalid;

  /// No description provided for @packageShareWriteError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo preparar el archivo para compartir. No se ha compartido nada.'**
  String get packageShareWriteError;

  /// No description provided for @packageImportTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar acompañante'**
  String get packageImportTitle;

  /// No description provided for @packageImportIntro.
  ///
  /// In es, this message translates to:
  /// **'Elige un archivo .trackia o pega el texto que te compartieron. Se mostrará una vista previa antes de guardar nada.'**
  String get packageImportIntro;

  /// No description provided for @packageImportPickFile.
  ///
  /// In es, this message translates to:
  /// **'Elegir archivo'**
  String get packageImportPickFile;

  /// No description provided for @packageImportPasteLabel.
  ///
  /// In es, this message translates to:
  /// **'Texto del acompañante'**
  String get packageImportPasteLabel;

  /// No description provided for @packageImportPreviewButton.
  ///
  /// In es, this message translates to:
  /// **'Ver vista previa'**
  String get packageImportPreviewButton;

  /// No description provided for @packageImportFileError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer el archivo.'**
  String get packageImportFileError;

  /// No description provided for @packageImportExternalNotice.
  ///
  /// In es, this message translates to:
  /// **'Este contenido viene de fuera: revísalo antes de guardarlo.'**
  String get packageImportExternalNotice;

  /// No description provided for @packageImportModeNote.
  ///
  /// In es, this message translates to:
  /// **'Se guardará en modo «recordatorio», sin permisos ni conexiones. Podrás cambiarlo después.'**
  String get packageImportModeNote;

  /// No description provided for @packageImportActivityTitle.
  ///
  /// In es, this message translates to:
  /// **'Actividad que traería'**
  String get packageImportActivityTitle;

  /// No description provided for @packageImportActivityFields.
  ///
  /// In es, this message translates to:
  /// **'Campos: {fields}'**
  String packageImportActivityFields(Object fields);

  /// No description provided for @packageImportRemindersTitle.
  ///
  /// In es, this message translates to:
  /// **'Textos de avisos'**
  String get packageImportRemindersTitle;

  /// No description provided for @packageImportReminderWindowStart.
  ///
  /// In es, this message translates to:
  /// **'Al empezar la ventana'**
  String get packageImportReminderWindowStart;

  /// No description provided for @packageImportReminderLastCall.
  ///
  /// In es, this message translates to:
  /// **'Última llamada'**
  String get packageImportReminderLastCall;

  /// No description provided for @packageImportReminderInactive.
  ///
  /// In es, this message translates to:
  /// **'Sin actividad'**
  String get packageImportReminderInactive;

  /// No description provided for @packageImportWarningsTitle.
  ///
  /// In es, this message translates to:
  /// **'Advertencias'**
  String get packageImportWarningsTitle;

  /// No description provided for @packageImportWarningAppBlocksRemoved.
  ///
  /// In es, this message translates to:
  /// **'Se quitaron bloques internos de la aplicación del contenido. Cantidad: {count}'**
  String packageImportWarningAppBlocksRemoved(int count);

  /// No description provided for @packageImportWarningModeReset.
  ///
  /// In es, this message translates to:
  /// **'El paquete pedía el modo «{mode}»; empieza en «recordatorio» y puedes cambiarlo después.'**
  String packageImportWarningModeReset(Object mode);

  /// No description provided for @packageImportWarningExtraTemplates.
  ///
  /// In es, this message translates to:
  /// **'Otras actividades del paquete no se aplican. Cantidad: {count}'**
  String packageImportWarningExtraTemplates(int count);

  /// No description provided for @packageImportWarningSuspicious.
  ///
  /// In es, this message translates to:
  /// **'Las instrucciones parecen intentar cambiar las reglas del asistente. Léelas con atención o bórralas.'**
  String get packageImportWarningSuspicious;

  /// No description provided for @packageImportWarningInstructionsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No quedó texto en las instrucciones tras quitar los bloques internos.'**
  String get packageImportWarningInstructionsEmpty;

  /// No description provided for @packageImportSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar acompañante'**
  String get packageImportSave;

  /// No description provided for @packageImportSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el acompañante.'**
  String get packageImportSaveFailed;

  /// No description provided for @packageImportProblemField.
  ///
  /// In es, this message translates to:
  /// **'Campo: {field}'**
  String packageImportProblemField(Object field);

  /// No description provided for @packageImportProblemEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay nada que importar: el texto o el archivo está vacío.'**
  String get packageImportProblemEmpty;

  /// No description provided for @packageImportProblemTooLarge.
  ///
  /// In es, this message translates to:
  /// **'El contenido es demasiado grande para ser un acompañante.'**
  String get packageImportProblemTooLarge;

  /// No description provided for @packageImportProblemBadEncoding.
  ///
  /// In es, this message translates to:
  /// **'El texto está dañado o incompleto: no tiene un formato válido.'**
  String get packageImportProblemBadEncoding;

  /// No description provided for @packageImportProblemBadCompression.
  ///
  /// In es, this message translates to:
  /// **'El contenido está dañado y no se pudo descomprimir.'**
  String get packageImportProblemBadCompression;

  /// No description provided for @packageImportProblemTooLargeExpanded.
  ///
  /// In es, this message translates to:
  /// **'El contenido ocupa demasiado al abrirlo y se rechazó por seguridad.'**
  String get packageImportProblemTooLargeExpanded;

  /// No description provided for @packageImportProblemMalformed.
  ///
  /// In es, this message translates to:
  /// **'El contenido no se pudo leer: no es un acompañante válido.'**
  String get packageImportProblemMalformed;

  /// No description provided for @packageImportProblemNotAPackage.
  ///
  /// In es, this message translates to:
  /// **'Esto no es un acompañante de TrackIA.'**
  String get packageImportProblemNotAPackage;

  /// No description provided for @packageImportProblemUnsupportedVersion.
  ///
  /// In es, this message translates to:
  /// **'Este acompañante es de una versión más nueva. Actualiza TrackIA para importarlo.'**
  String get packageImportProblemUnsupportedVersion;

  /// No description provided for @packageImportProblemChecksumMismatch.
  ///
  /// In es, this message translates to:
  /// **'El contenido cambió o se dañó: la comprobación de integridad falló.'**
  String get packageImportProblemChecksumMismatch;

  /// No description provided for @packageImportProblemForbiddenField.
  ///
  /// In es, this message translates to:
  /// **'El contenido incluye un dato que nunca debe viajar (claves, chats, memoria…). No se importó.'**
  String get packageImportProblemForbiddenField;

  /// No description provided for @packageImportProblemUnknownField.
  ///
  /// In es, this message translates to:
  /// **'El contenido incluye un campo que esta versión no admite. No se importó.'**
  String get packageImportProblemUnknownField;

  /// No description provided for @packageImportProblemMissingField.
  ///
  /// In es, this message translates to:
  /// **'Falta un campo obligatorio en el contenido.'**
  String get packageImportProblemMissingField;

  /// No description provided for @packageImportProblemInvalidField.
  ///
  /// In es, this message translates to:
  /// **'Un campo del contenido no es válido o supera su límite.'**
  String get packageImportProblemInvalidField;

  /// No description provided for @importedTrustWarning.
  ///
  /// In es, this message translates to:
  /// **'Este acompañante es importado: confirma antes de que actúe.'**
  String get importedTrustWarning;

  /// No description provided for @importedTrustConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get importedTrustConfirm;

  /// No description provided for @importedTrustSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Editar tu hoja de Google Sheets?'**
  String get importedTrustSheetTitle;

  /// No description provided for @importedTrustSheetTarget.
  ///
  /// In es, this message translates to:
  /// **'Hoja: {sheet} · Pestaña: {tab}'**
  String importedTrustSheetTarget(String sheet, String tab);

  /// No description provided for @importedTrustCellLine.
  ///
  /// In es, this message translates to:
  /// **'{cell}: «{before}» → «{after}»'**
  String importedTrustCellLine(String cell, String before, String after);

  /// No description provided for @importedTrustEmptyValue.
  ///
  /// In es, this message translates to:
  /// **'(vacía)'**
  String get importedTrustEmptyValue;

  /// No description provided for @importedTrustCancelledSheet.
  ///
  /// In es, this message translates to:
  /// **'Acción cancelada: no se editó la hoja de Google Sheets.'**
  String get importedTrustCancelledSheet;

  /// No description provided for @importedTrustActivityTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Preparar esta actividad?'**
  String get importedTrustActivityTitle;

  /// No description provided for @importedTrustActivityRest.
  ///
  /// In es, this message translates to:
  /// **'Descanso: {seconds} s'**
  String importedTrustActivityRest(int seconds);

  /// No description provided for @importedTrustActivityDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración de la actividad: {seconds} s'**
  String importedTrustActivityDuration(int seconds);

  /// No description provided for @importedTrustActivityTargetSets.
  ///
  /// In es, this message translates to:
  /// **'Series objetivo: {count}'**
  String importedTrustActivityTargetSets(int count);

  /// No description provided for @importedTrustActivityFields.
  ///
  /// In es, this message translates to:
  /// **'Campos: {fields}'**
  String importedTrustActivityFields(String fields);

  /// No description provided for @importedTrustCancelledActivity.
  ///
  /// In es, this message translates to:
  /// **'Acción cancelada: no se preparó la actividad «{name}».'**
  String importedTrustCancelledActivity(String name);

  /// No description provided for @importedTrustLabel.
  ///
  /// In es, this message translates to:
  /// **'Importado'**
  String get importedTrustLabel;

  /// No description provided for @importedTrustSwitch.
  ///
  /// In es, this message translates to:
  /// **'Confiar en este acompañante'**
  String get importedTrustSwitch;

  /// No description provided for @importedTrustSwitchHelp.
  ///
  /// In es, this message translates to:
  /// **'Mientras no confíes en él, pedirá confirmación antes de editar tu hoja o preparar actividades.'**
  String get importedTrustSwitchHelp;

  /// No description provided for @importedTrustDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Confiar en este acompañante?'**
  String get importedTrustDialogTitle;

  /// No description provided for @importedTrustDialogBody.
  ///
  /// In es, this message translates to:
  /// **'Dejará de pedir confirmación antes de editar tu hoja o preparar actividades. Hazlo solo si confías en quien te lo compartió.'**
  String get importedTrustDialogBody;

  /// No description provided for @importedTrustDialogConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confiar'**
  String get importedTrustDialogConfirm;

  /// No description provided for @importedTrustSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el cambio. Inténtalo de nuevo.'**
  String get importedTrustSaveError;

  /// No description provided for @packageQrTitle.
  ///
  /// In es, this message translates to:
  /// **'Código QR del acompañante'**
  String get packageQrTitle;

  /// No description provided for @packageQrNote.
  ///
  /// In es, this message translates to:
  /// **'Quien lo escanee verá una vista previa antes de guardar nada.'**
  String get packageQrNote;

  /// No description provided for @packageQrShareFile.
  ///
  /// In es, this message translates to:
  /// **'Compartir archivo'**
  String get packageQrShareFile;

  /// No description provided for @packageQrClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get packageQrClose;

  /// No description provided for @packageQrTooLarge.
  ///
  /// In es, this message translates to:
  /// **'Es demasiado grande para un QR: se comparte como archivo.'**
  String get packageQrTooLarge;

  /// No description provided for @packageScanTitle.
  ///
  /// In es, this message translates to:
  /// **'Escanear acompañante'**
  String get packageScanTitle;

  /// No description provided for @packageScanHint.
  ///
  /// In es, this message translates to:
  /// **'Apunta la cámara al código QR del acompañante.'**
  String get packageScanHint;

  /// No description provided for @packageScanTorch.
  ///
  /// In es, this message translates to:
  /// **'Linterna'**
  String get packageScanTorch;

  /// No description provided for @packageScanPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'No hay permiso para usar la cámara. Puedes importar el acompañante desde un archivo o pegando el texto.'**
  String get packageScanPermissionDenied;

  /// No description provided for @packageScanCameraError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo usar la cámara. Puedes importar el acompañante desde un archivo o pegando el texto.'**
  String get packageScanCameraError;

  /// No description provided for @packageScanUseFile.
  ///
  /// In es, this message translates to:
  /// **'Importar desde archivo o texto'**
  String get packageScanUseFile;
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
