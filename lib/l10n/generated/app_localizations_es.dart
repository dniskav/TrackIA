// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'TrackIA';

  @override
  String get languageSystem => 'Idioma del dispositivo';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageArabic => 'Árabe';

  @override
  String get languagePreference => 'Idioma';

  @override
  String get welcomeTitle => 'Bienvenida';

  @override
  String get welcomeHelpTitle => 'Ayuda y bienvenida';

  @override
  String welcomeStep(Object current, Object total) {
    return 'Paso $current de $total';
  }

  @override
  String get welcomeSlide1Title => 'Bienvenido';

  @override
  String get welcomeSlide1Body =>
      'Conversa con tu asistente de IA para preparar una actividad, resolver dudas y revisar tu progreso. Tú decides cuándo empezar.';

  @override
  String get welcomeSlide2Title => 'Habla o escribe';

  @override
  String get welcomeSlide2Body =>
      'El chat admite texto, dictado y adjuntos. Para usar la IA, conecta un proveedor desde el menú. Si se corta la conexión, tus registros locales siguen disponibles.';

  @override
  String get welcomeSlide3Title => 'Controla tu actividad';

  @override
  String get welcomeSlide3Body =>
      'Elige o crea una actividad. Prepararla no inicia el reloj: pulsa Iniciar cuando estés listo y Parar al terminar cada tramo.';

  @override
  String get welcomeSlide4Title => 'Conserva tus datos';

  @override
  String get welcomeSlide4Body =>
      'Tus registros se guardan en el móvil. Puedes conectar Google Sheets cuando quieras y revisar el estado de cada envío.';

  @override
  String get welcomeSlide5Title => 'Tus acompañantes';

  @override
  String get welcomeSlide5Body =>
      'Elige GymBro, Enfoque, Calma o Diario. Puedes editar sus instrucciones, crear otros y conectar una hoja o pestaña de Google distinta para cada uno.';

  @override
  String get welcomeSlide6Title => 'Modo y avisos';

  @override
  String get welcomeSlide6Body =>
      'Cada acompañante tiene su modo. Abre su menú (⋮) y pulsa «Modo y avisos»: con Recordatorio solo te avisa a la hora que elijas; con Juego añade metas, rachas y logros. Para que los avisos de descanso suenen aunque tengas No molestar, ve a Ajustes → Avisos.';

  @override
  String get welcomeSaveErrorTitle => 'No se pudo guardar la elección';

  @override
  String get welcomeSaveErrorBody =>
      'Puedes volver a intentarlo o continuar. Si continúas, la bienvenida podría aparecer al abrir la app de nuevo.';

  @override
  String get retry => 'Reintentar';

  @override
  String get continueWithoutSaving => 'Continuar sin guardar';

  @override
  String get welcomeNeverAgain => 'No volver a mostrar';

  @override
  String get welcomeNeverAgainHelp =>
      'Si la dejas sin marcar, verás esta guía al abrir la app. Puedes cambiarlo en Ayuda.';

  @override
  String get skip => 'Omitir';

  @override
  String get previous => 'Anterior';

  @override
  String get next => 'Siguiente';

  @override
  String get start => 'Empezar';

  @override
  String get welcomeAutoShow => 'Mostrar bienvenida al abrir';

  @override
  String get devicePreferenceSaved =>
      'Tu elección se guarda en este dispositivo.';

  @override
  String get showWelcome => 'Ver bienvenida';

  @override
  String get savePreferenceError => 'No se pudo guardar la preferencia.';

  @override
  String get companionsTitle => 'Tus acompañantes';

  @override
  String get companionsDescription =>
      'Elige con quién trabajar. Cada uno conserva su conversación y puede usar una hoja o pestaña de Google distinta.';

  @override
  String get companionsEmpty =>
      'Aún no tienes acompañantes. Crea uno para empezar.';

  @override
  String get createCompanion => 'Crear acompañante';

  @override
  String companionOptions(Object name) {
    return 'Opciones de $name';
  }

  @override
  String companionProgress(Object name) {
    return 'Progreso de $name';
  }

  @override
  String companionStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Racha: # días',
      one: 'Racha: 1 día',
    );
    return '$_temp0';
  }

  @override
  String get remindersPaused => 'Recordatorios en pausa';

  @override
  String get resume => 'Reanudar';

  @override
  String get edit => 'Editar';

  @override
  String get modeAndNotices => 'Modo y avisos';

  @override
  String get delete => 'Borrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String companionDeleteTitle(Object name) {
    return '¿Borrar $name?';
  }

  @override
  String get companionDeleteBody =>
      'Se borrarán su chat, archivos y conexión local de Sheets. La hoja de Google y los registros de actividad no se borrarán.';

  @override
  String companionDeleteError(Object error) {
    return 'No se pudo borrar: $error';
  }

  @override
  String companionSaveError(Object error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String get companionLoadError =>
      'No se pudieron cargar los acompañantes. Pulsa para reintentar.';

  @override
  String get createCompanionTitle => 'Crear acompañante';

  @override
  String get editCompanionTitle => 'Editar acompañante';

  @override
  String get companionName => 'Nombre';

  @override
  String get companionPurpose => '¿Para qué sirve?';

  @override
  String get companionInstructions => 'Instrucciones para la IA (opcional)';

  @override
  String get companionInstructionsHelp =>
      'Se usan cuando conectes un proveedor.';

  @override
  String get icon => 'Icono';

  @override
  String get color => 'Color';

  @override
  String get settings => 'Ajustes';

  @override
  String get assistant => 'Asistente';

  @override
  String get artificialIntelligence => 'Inteligencia artificial';

  @override
  String get yourData => 'Tus datos';

  @override
  String get accountAndData => 'Cuenta y datos';

  @override
  String get localProfile => 'Perfil local';

  @override
  String get exportImport => 'Exportar e importar';

  @override
  String get appSection => 'App';

  @override
  String get notices => 'Avisos';

  @override
  String get enabled => 'Activados';

  @override
  String get disabled => 'Desactivados';

  @override
  String get appearance => 'Apariencia';

  @override
  String get helpWelcome => 'Ayuda y bienvenida';

  @override
  String get verified => 'Verificada';

  @override
  String get notConnected => 'Sin conectar';

  @override
  String get notVerified => 'Sin verificar';

  @override
  String get unavailable => 'No disponible';

  @override
  String get checking => 'Comprobando…';

  @override
  String get automatic => 'Automático';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String companionSettingsTitle(Object name) {
    return 'Modo y avisos · $name';
  }

  @override
  String get mode => 'Modo';

  @override
  String get reminderMode => 'Recordatorio';

  @override
  String get reminderModeDetail => 'Solo te avisa a la hora que elijas.';

  @override
  String get gameMode => 'Juego';

  @override
  String get gameModeDetail => 'Metas, rachas y logros, además de los avisos.';

  @override
  String get goals => 'Metas';

  @override
  String get streaks => 'Rachas';

  @override
  String get achievements => 'Logros';

  @override
  String get encouragementMessages => 'Mensajes de ánimo';

  @override
  String get freeDaysPerWeek => 'Días libres por semana';

  @override
  String get freeDaysHelp => 'No rompen la racha.';

  @override
  String get dailyNotice => 'Aviso diario';

  @override
  String get remindersPausedDetail =>
      'Pasaron 7 días programados sin registrar nada.';

  @override
  String get remindAboutActivity => 'Recordarme esta actividad';

  @override
  String get monday => 'lunes';

  @override
  String get tuesday => 'martes';

  @override
  String get wednesday => 'miércoles';

  @override
  String get thursday => 'jueves';

  @override
  String get friday => 'viernes';

  @override
  String get saturday => 'sábado';

  @override
  String get sunday => 'domingo';

  @override
  String get from => 'Desde';

  @override
  String get until => 'Hasta';

  @override
  String get lastCall => 'Última llamada';

  @override
  String get lastCallTime => 'Hora de la última llamada';

  @override
  String get neutral => 'Neutro';

  @override
  String get motivating => 'Motivador';

  @override
  String get minimumForDay => 'Mínimo para ese día';

  @override
  String get quantity => 'Cantidad';

  @override
  String get sessions => 'sesiones';

  @override
  String get minutes => 'minutos';

  @override
  String get preview => 'Así se verá';

  @override
  String get putGoal => 'Poner una meta';

  @override
  String get whatToMeasure => 'Qué medir';

  @override
  String get timeMinutes => 'Tiempo (minutos)';

  @override
  String get sessionCount => 'Sesiones';

  @override
  String get perDay => 'al día';

  @override
  String get perWeek => 'a la semana';

  @override
  String get target => 'Objetivo';

  @override
  String get minimumStreakOptional =>
      'Mínimo para mantener la racha (opcional)';

  @override
  String get chooseTime => 'Elige la hora';

  @override
  String get goalMustBePositive =>
      'El objetivo debe ser un número mayor que 0.';

  @override
  String get minimumMustBePositive =>
      'El mínimo debe ser un número mayor que 0.';

  @override
  String get companionSettingsLoadError => 'No se pudieron cargar los ajustes.';

  @override
  String get companionSettingsSaveError =>
      'No se pudieron guardar los ajustes.';

  @override
  String get aiNotConnected => 'IA sin conectar';

  @override
  String get chooseProviderAndModel => 'Elige un proveedor y un modelo.';

  @override
  String get connect => 'Conectar';

  @override
  String get aiNotVerified => 'IA sin verificar';

  @override
  String get verifyConnectionAssistant =>
      'Prueba la conexión para activar el asistente.';

  @override
  String get verify => 'Verificar';

  @override
  String get aiUnavailable => 'IA no disponible';

  @override
  String get reviewProviderRetry => 'Revisa el proveedor y vuelve a probar.';

  @override
  String get review => 'Revisar';

  @override
  String get waitingPhraseOne => 'Estoy aquí para ayudarte.';

  @override
  String get waitingPhraseTwo => 'Tómate un momento; aquí seguimos.';

  @override
  String get waitingPhraseThree => 'Cuando quieras, continuamos.';

  @override
  String get waitingPhraseFour =>
      'Puedes seguir escribiendo cuando te venga bien.';

  @override
  String get logoDescription => 'Logotipo de TrackIA';

  @override
  String get chatArchive => 'Archivar chat';

  @override
  String get chatArchives => 'Chats archivados';

  @override
  String get chatSendToSheets => 'Enviar a Google Sheets';

  @override
  String get chatAiProvider => 'Proveedor de IA';

  @override
  String get chatConfigureAi => 'Configurar IA';

  @override
  String get chatVerifyConnection => 'Verificar conexión · usa tu API';

  @override
  String get chatTraining => 'Entrenamiento';

  @override
  String get chatLoadSheets => 'Cargar Google Sheets';

  @override
  String get chatSheetPending => 'Interpretar hoja con IA';

  @override
  String get chatWelcomePrompt =>
      '¿Qué te gustaría hacer hoy? Cuéntame y lo organizamos juntos.';

  @override
  String get chatLoadDataPrompt =>
      'Carga tus datos con + cuando quieras. La IA podrá interpretar su formato cuando esté conectada.';

  @override
  String get chatPrepareActivity => 'Preparar';

  @override
  String get chatWaitingModel => 'Esperando al modelo…';

  @override
  String get chatDeferredArchive =>
      'El asistente archivará este chat cuando vuelvas al final.';

  @override
  String get chatGoLatest => 'Ir al último mensaje';

  @override
  String get chatListening => 'Escuchando… Revisa el texto y pulsa Enviar.';

  @override
  String get chatAttach => 'Adjuntar';

  @override
  String get chatComposeHint => 'Escribe o dicta tu mensaje…';

  @override
  String get chatConnectAiHint => 'Conecta tu IA para empezar';

  @override
  String get chatStopDictation => 'Terminar dictado';

  @override
  String get chatDictate => 'Dictar mensaje';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatAssistantImageAlt => 'Imagen';

  @override
  String get chatInputDirections => 'Dirección del texto del mensaje';

  @override
  String get activityStart => 'Iniciar';

  @override
  String get activityStop => 'Parar';

  @override
  String get activityFinish => 'Terminar';

  @override
  String get activityFinishDay => 'Finalizar día';

  @override
  String get activityChooseAnother => 'Elegir otra actividad';

  @override
  String get activitySubtractCycle => 'Restar ciclo';

  @override
  String get activityAddCycle => 'Añadir ciclo completado';

  @override
  String get activityNoticesOff => 'Avisos desactivados';

  @override
  String get activityEnableNotices => 'Activar';

  @override
  String get activityCycles => 'Ciclos';

  @override
  String get aiUnavailableFocus =>
      'IA no disponible · puedes parar y guardar notas localmente';

  @override
  String get activityRestInProgress => 'Descanso en curso';

  @override
  String get activityRestChangeNoticePrompt =>
      '¿Quieres cambiar también el aviso que ya está programado?';

  @override
  String get activityKeepNotice => 'Conservar aviso';

  @override
  String get activityChangeNotice => 'Cambiar aviso';

  @override
  String get personalityInstructions => 'Personalidad e instrucciones';

  @override
  String get personalityInstructionsHelp =>
      'Describe el tono y cómo quieres que te acompañe. Solo afecta a sus respuestas de IA.';

  @override
  String get personalitySuggestionTone => 'Usa un tono cercano y claro.';

  @override
  String get personalitySuggestionAsk =>
      'Haz preguntas breves cuando falten datos.';

  @override
  String get personalitySuggestionAccuracy =>
      'No inventes información ni avances que no haya contado.';

  @override
  String get personalityTooLong =>
      'La personalidad no puede superar los 4000 caracteres.';

  @override
  String get personalityDraftTitle => 'Propuesta de personalidad';

  @override
  String get personalityDraftAccept => 'Usar propuesta';

  @override
  String get personalityDraftButton => 'Ayúdame a redactarla';

  @override
  String get personalityDraftError =>
      'No se pudo generar la propuesta. Revisa la conexión de IA e inténtalo de nuevo.';

  @override
  String get activityTargetTitle => 'Objetivo de series';

  @override
  String get activityTargetLabel => 'Series (vacío para quitar)';

  @override
  String get activityTargetInvalid =>
      'Indica un objetivo entre 1 y 100, o déjalo vacío.';

  @override
  String get activityTargetEditTooltip => 'Editar objetivo de series';

  @override
  String activityTargetPreservedProgress(Object target, Object completed) {
    return 'Objetivo: $target. Conservas $completed series completadas.';
  }

  @override
  String get activityTargetUpdated => 'Objetivo actualizado.';

  @override
  String get activityNoTarget => 'sin objetivo';

  @override
  String activityTargetChangedEvent(Object target) {
    return 'Cambiaste el objetivo de series a $target';
  }

  @override
  String get chatTargetProposalAmbiguous =>
      'No se cambió el objetivo: la propuesta es ambigua o no corresponde a una actividad activa.';

  @override
  String get chatTargetConfirmTitle => 'Cambiar objetivo de series';

  @override
  String get chatTargetRemovePrompt => '¿Quieres quitar el objetivo?';

  @override
  String chatTargetSetPrompt(Object target) {
    return '¿Quieres fijar el objetivo en $target series?';
  }

  @override
  String chatTargetSetPromptWithProgress(Object target, Object completed) {
    return '¿Quieres fijar el objetivo en $target series? Ya has completado $completed; se conserva todo el progreso.';
  }

  @override
  String get chatTargetConfirmButton => 'Cambiar';

  @override
  String get chatTargetSavedNoTarget => 'Objetivo guardado: sin objetivo.';

  @override
  String chatTargetSaved(Object target) {
    return 'Objetivo guardado: $target series.';
  }

  @override
  String chatTargetSavedWithProgress(Object target, Object completed) {
    return 'Objetivo guardado: $target series. Conservas $completed series completadas.';
  }

  @override
  String get chatTargetStale =>
      'No se cambió el objetivo. La actividad puede haber cambiado; revísala y vuelve a intentarlo.';

  @override
  String get sheetsTitle => 'Tus hojas de Google Sheets';

  @override
  String get sheetsChooseTitle => 'Elige tu hoja de entrenamiento';

  @override
  String get sheetsSearch => 'Buscar por nombre';

  @override
  String get sheetsSearchTooltip => 'Buscar';

  @override
  String get sheetsConnect => 'Conectar con Google';

  @override
  String get sheetsReconnect => 'Cambiar cuenta o autorizar de nuevo';

  @override
  String get sheetsNoResults =>
      'No se encontraron hojas. Prueba otro nombre o cambia de cuenta.';

  @override
  String get sheetsLoadMore => 'Cargar más hojas';

  @override
  String get dataTitle => 'Tus datos';

  @override
  String get dataCreateBackup => 'Crear y compartir copia';

  @override
  String get dataRestoreBackup => 'Restaurar copia';

  @override
  String get aiProviderTitle => 'Proveedor de IA';

  @override
  String get aiConnectTitle => 'Conecta tu asistente';

  @override
  String get aiProviderLabel => 'Proveedor';

  @override
  String get sheetChooseTab => 'Elige la pestaña con tus entrenamientos';

  @override
  String get sheetReview => 'Revisar hoja';

  @override
  String sheetRowsRead(Object count) {
    return '$count filas leídas. Se cargará la pestaña completa; aquí se muestran las primeras 12 filas.';
  }

  @override
  String sheetRowsReadPreview(Object count) {
    return '$count filas leídas. Vista previa:';
  }

  @override
  String get sheetLoadPending =>
      'La hoja se guardará en este móvil, pendiente de interpretación. No necesitas IA para cargarla. Cuando esté conectada, podrás pedirle que interprete su estructura. No se crean entrenamientos ni se envían celdas al proveedor al cargar.';

  @override
  String get sheetSendToAi =>
      'Al pulsar Cargar y analizar, estas celdas se enviarán al proveedor de IA configurado. Las filas se conservan tal como aparecen, sin convertirlas en entrenamientos.';

  @override
  String get sheetReadOnlyGoogle =>
      'Es una copia de lectura: para traer cambios posteriores usa Actualizar hoja en el chat.';

  @override
  String get sheetReadOnlyFile =>
      'Es una copia de lectura del archivo. Para traer cambios, vuelve a cargarlo.';

  @override
  String get sheetsConnecting => 'Conectando con Google…';

  @override
  String get sheetsAuthorizeProgress =>
      'Elige tu cuenta y autoriza la lectura en Google…';

  @override
  String get sheetsSearchProgress => 'Buscando tus hojas…';

  @override
  String sheetsLoadingTabs(Object name) {
    return 'Cargando las pestañas de $name…';
  }

  @override
  String sheetsReadingTab(Object name) {
    return 'Leyendo $name…';
  }

  @override
  String get sheetsReadError => 'No se pudo leer la hoja. Vuelve a intentarlo.';

  @override
  String get sheetsGoogleError => 'No se pudo conectar con Google.';

  @override
  String get sheetsRetry => 'Volver a cargar las hojas';

  @override
  String get sheetsPartial =>
      'Google devolvió una búsqueda parcial. Busca la hoja por su nombre.';

  @override
  String get sheetsAuthIncomplete =>
      'Google no completó la autorización. Pulsa Conectar con Google para volver a intentarlo; aún no se han cargado tus hojas.';

  @override
  String get sheetsSearchAccountChanged =>
      'La cuenta cambió durante la búsqueda. Vuelve a conectar para continuar.';

  @override
  String get sheetsChooseAccountChanged =>
      'La cuenta cambió durante la selección. Vuelve a conectar para continuar.';

  @override
  String get sheetsReadAccountChanged =>
      'La cuenta cambió durante la lectura. No se cargaron los datos.';

  @override
  String get sheetsNoTabs => 'Esta hoja no tiene pestañas disponibles.';

  @override
  String get sheetsReadRowsIntro =>
      'filas leídas. Se cargará la pestaña completa; aquí se muestran las primeras 12 filas.';

  @override
  String get syncTitle => 'Enviar a Google Sheets';

  @override
  String get syncIntro =>
      'Conecta Google y elige tu hoja una vez. El chat podrá consultarla actualizada y enviar resultados; aquí también puedes revisar un envío manual.';

  @override
  String get syncNoSessions =>
      'No hay sesiones finalizadas para enviar. Puedes probar la conexión sin iniciar una actividad.';

  @override
  String get syncWorkout => 'Entrenamiento';

  @override
  String get syncConnectWrite => 'Conectar Google y permitir escritura';

  @override
  String syncDestinationAccount(Object email) {
    return 'Cuenta de destino: $email';
  }

  @override
  String get syncCheckConnection => 'Comprobar conexión';

  @override
  String get syncDisconnect => 'Desconectar esta hoja';

  @override
  String get syncChangeAccount => 'Cambiar cuenta de destino';

  @override
  String get syncCreateNew => 'Crear hoja nueva';

  @override
  String get syncNewSheetName => 'Nombre de la nueva hoja';

  @override
  String get syncCreateDrive => 'Crear hoja en mi Google Drive';

  @override
  String get syncSheet => 'Hoja de Google';

  @override
  String get syncTab => 'Pestaña';

  @override
  String get syncInstructions => 'Preferencias o aclaraciones sobre la hoja';

  @override
  String get syncInstructionsHint =>
      'Ej.: usa el bloque de octubre, cargas totales';

  @override
  String get syncAllowOverwrite => 'Permitir actualizar celdas con datos';

  @override
  String get syncOverwriteHelp =>
      'La revisión mostrará el valor anterior y el nuevo. Las fórmulas se conservan.';

  @override
  String get syncAutomatic => 'Enviar sesiones automáticamente al finalizar';

  @override
  String get syncAutomaticChatHelp =>
      'Los envíos del chat siguen disponibles aunque pauses los automáticos.';

  @override
  String get syncAutomaticActivityHelp =>
      'Por ahora los registros de actividad no identifican su acompañante; puedes pedir envíos y ediciones desde el chat.';

  @override
  String get syncSavePreferences => 'Guardar conexión y preferencias';

  @override
  String get syncReviewLoadChat => 'Revisar y cargar hoja en el chat';

  @override
  String get syncDiagnostics => 'Diagnóstico de la conexión';

  @override
  String get syncDiagnosticsHelp =>
      'Prueba la pestaña elegida sin iniciar una actividad. La escritura usa una pestaña temporal y no modifica tus entrenamientos.';

  @override
  String get syncTestRead => 'Probar lectura con IA';

  @override
  String get syncTestWrite => 'Probar escritura con IA';

  @override
  String get syncPrepare => 'Preparar y revisar envío';

  @override
  String get syncNoSheet => 'Elige una hoja y una pestaña.';

  @override
  String get syncNoValidWorkout =>
      'Elige una hoja, una pestaña y un entrenamiento finalizado.';

  @override
  String get syncSessionUnavailable => 'La sesión ya no está disponible.';

  @override
  String get syncConnectionError =>
      'No se pudo recuperar la hoja guardada. Puedes elegir otra.';

  @override
  String get syncOperationError =>
      'No se pudo completar la operación. Inténtalo de nuevo.';

  @override
  String get syncGoogleUnconfirmed => 'Google no confirmó la operación.';

  @override
  String get syncNameInvalid => 'Escribe un nombre de hasta 80 caracteres.';

  @override
  String get syncLoadChatTitle => 'Revisar hoja para el chat';

  @override
  String get syncConfirmLoad => 'Confirmar y cargar';

  @override
  String syncReadConfirmed(Object count, Object answer) {
    return 'Lectura confirmada: $count filas recibidas de Google. Respuesta del modelo: $answer';
  }

  @override
  String syncWriteConfirmed(Object marker) {
    return 'Escritura confirmada: el modelo propuso «$marker», Google aceptó la prueba y la pestaña temporal se eliminó. No se enviaron entrenamientos.';
  }

  @override
  String get syncSentConfirmed =>
      'Entrenamiento enviado a Google Sheets. Recibo comprobado; volver a enviarlo no lo duplica.';

  @override
  String get syncReturnChat => 'Volver al chat';

  @override
  String syncDestination(Object name, Object tab) {
    return 'Destino: $name / $tab';
  }

  @override
  String get syncReceiptNote =>
      'Google guardará también un recibo del envío para evitar duplicados.';

  @override
  String syncReviewCount(Object count) {
    return '$count celdas. Se comprobará que no hayan cambiado desde esta revisión.';
  }

  @override
  String get syncOriginalData => 'Ver datos originales del entrenamiento';

  @override
  String get syncConfirmSend => 'Confirmar y enviar a Google Sheets';

  @override
  String get syncDiscard => 'Descartar propuesta';

  @override
  String get sheetNoTabs => 'Esta hoja no tiene pestañas disponibles.';

  @override
  String get sheetsLoad => 'Cargar hoja';

  @override
  String get sheetsLoadAnalyze => 'Cargar y analizar';

  @override
  String get rowLabel => 'Fila';

  @override
  String get syncProposedSessionInvalid =>
      'La sesión propuesta no está finalizada o no pertenece a este perfil. Elige una sesión válida.';

  @override
  String get syncConnectionSaved =>
      'Conexión guardada. El chat leerá la hoja actual y podrá enviar los resultados sin pedir autorización en cada uso.';

  @override
  String get syncIdentityUnconfirmed =>
      'No se pudo confirmar la cuenta de Google seleccionada.';

  @override
  String get sheetAllRowsWillLoad =>
      'Se cargarán todas las filas de la pestaña.';

  @override
  String get syncAccountChangedReview =>
      'La cuenta cambió mientras revisabas la pestaña. La hoja anterior se conserva; vuelve a conectar para cargarla.';

  @override
  String syncLoadedIntoChat(Object name, Object tab) {
    return 'Hoja cargada en el chat: $name / $tab.';
  }

  @override
  String get syncConfigureAi =>
      'Configura primero la IA para probar el acceso desde el modelo.';

  @override
  String get syncModelEmpty => 'El modelo no devolvió una respuesta.';

  @override
  String get syncInvalidMarker =>
      'El modelo respondió, pero no dio un marcador válido para la prueba.';

  @override
  String get syncWorkoutChanged =>
      'El entrenamiento cambió. Prepara de nuevo el envío para revisar los datos actuales.';

  @override
  String get syncRefreshAfterSendFailed =>
      'Envío confirmado. No se pudo refrescar la copia del chat; vuelve a cargar la hoja para consultar sus nuevos datos.';

  @override
  String syncReceiptSent(Object workout, Object id, Object name, Object tab) {
    return 'Google Sheets confirmado: entrenamiento «$workout» ($id) enviado a «$name / $tab». El recibo de Google confirma el envío.';
  }

  @override
  String syncReceiptCreated(Object name, Object tab) {
    return 'Google Sheets confirmado: hoja «$name» creada, pestaña «$tab». El progreso aún no se ha enviado.';
  }

  @override
  String get sheetsAssistantIntro =>
      'Conecta tu cuenta, elige la hoja y su pestaña. Revisa los datos antes de compartirlos con tu asistente.';

  @override
  String get sheetsImportIntro =>
      'TrackIA usa la autorización de Google para leer tus hojas. Los datos se guardan en este móvil cuando confirmas la importación.';

  @override
  String get sheetsErrorExpired =>
      'La autorización de Google ha caducado. Vuelve a conectar tu cuenta.';

  @override
  String get sheetsErrorPermission =>
      'Google no permite esta operación. Comprueba el acceso y los permisos de la hoja.';

  @override
  String get sheetsErrorAccount =>
      'La lectura no corresponde a la cuenta autorizada. Vuelve a conectar desde tu perfil.';

  @override
  String get sheetsErrorNotFound =>
      'La hoja ya no está disponible para esta cuenta.';

  @override
  String get sheetsErrorRateLimit =>
      'Google ha recibido demasiadas solicitudes. Espera un momento y vuelve a intentarlo.';

  @override
  String get sheetsErrorNetwork =>
      'No se pudo confirmar la operación con Google. El progreso local se conserva; al reintentar se comprobará el recibo.';

  @override
  String get sheetsErrorTooLarge =>
      'La pestaña supera 20 MB. Elige una pestaña más pequeña.';

  @override
  String get sheetsErrorGeneric =>
      'Google no pudo completar la operación. Vuelve a intentarlo.';

  @override
  String get sheetsErrorBusy =>
      'Ya hay una operación con Google en curso. Espera a que termine.';

  @override
  String syncBeforeValue(Object value) {
    return 'Antes: $value';
  }

  @override
  String get syncEmptyCell => '(vacía)';

  @override
  String get syncDisconnected =>
      'Hoja desconectada. Los datos locales y los envíos pendientes se conservan.';

  @override
  String get aiProviderDescription =>
      'Elige un proveedor en la nube o ejecuta un modelo local en este móvil. Los modelos locales pueden funcionar sin conexión; el rendimiento depende de la memoria y del modelo elegido.';

  @override
  String get aiConfigReadError => 'No se pudo leer la configuración guardada.';

  @override
  String aiModelImportError(Object error) {
    return 'No se pudo importar el archivo GGUF: $error';
  }

  @override
  String get aiMemoryAvailableNow => 'Disponible ahora';

  @override
  String get aiMemoryAfterModel => 'Después de modelo y proyector';

  @override
  String get aiMemoryAfterContext => 'Después + contexto seleccionado';

  @override
  String aiMemoryContextEstimate(
    Object context,
    Object minimum,
    Object maximum,
  ) {
    return 'El contexto de $context añadiría aproximadamente $minimum–$maximum de RAM.';
  }

  @override
  String aiMemoryShortfall(Object amount) {
    return 'La estimación supera lo disponible por $amount.';
  }

  @override
  String get aiMemoryEstimateHelp =>
      'Estimación orientativa de pesos y proyector; el contexto elegido añade consumo y puede variar según el modelo.';

  @override
  String get aiConnectedChooseModel =>
      'Cuenta conectada. Elige un modelo y prueba la conexión para usar el asistente.';

  @override
  String get aiIdentityConnected =>
      'Identidad conectada. Puedes autorizar por separado el uso de tu plan ChatGPT.';

  @override
  String get aiChatGptDisconnected => 'Sesión ChatGPT desconectada.';

  @override
  String get aiChatGptRemoteRevocationUnconfirmed =>
      'Sesión desconectada en este móvil. No se confirmó la revocación remota; desconecta TrackIA también en los ajustes de ChatGPT.';

  @override
  String aiOperationError(Object details) {
    return 'No se pudo completar la operación$details';
  }

  @override
  String aiOperationDetails(Object error) {
    return ': $error';
  }

  @override
  String get aiNoModelImported => 'No hay modelo importado.';

  @override
  String get aiSelectImportGguf => 'Seleccionar / importar modelo .gguf';

  @override
  String get aiLocalContextTitle => 'Contexto del modelo local';

  @override
  String aiLocalContextHelp(Object context) {
    return 'TrackIA recomienda $context para sus instrucciones, historial y datos. La recomendación cubre las necesidades de la app, no el límite de este GGUF. Si el modelo no soporta el tamaño elegido, puede fallar; tú decides si bajarlo.';
  }

  @override
  String aiContextSelected(Object context) {
    return 'Seleccionado: $context';
  }

  @override
  String get aiUseRecommendation => 'Usar recomendación';

  @override
  String get aiVisualProjector => 'Proyector visual (opcional)';

  @override
  String get aiProjectorHelp =>
      'Añádelo para usar imágenes. MiniCPM‑V necesita el archivo mmproj GGUF correspondiente.';

  @override
  String get aiNoProjector => 'Sin proyector visual.';

  @override
  String get aiSelectProjector => 'Seleccionar proyector mmproj';

  @override
  String get aiMemoryHelp =>
      'La memoria disponible se informa aparte. La recomendación de 8192 tokens responde a lo que TrackIA necesita; el GGUF puede no soportarlo y tú puedes elegir otro tamaño.';

  @override
  String get aiRecalculateMemory => 'Volver a calcular memoria disponible';

  @override
  String get aiApiBase => 'URL base de la API';

  @override
  String get aiHttpsExample => 'HTTPS, por ejemplo https://tu-proveedor.com/v1';

  @override
  String get aiChatGptPlanHelp =>
      'Usa tu plan si tu cuenta y espacio son elegibles. El uso consume sus límites compartidos. No da acceso a tus conversaciones de ChatGPT.';

  @override
  String get aiChatGptAccount => 'Cuenta ChatGPT';

  @override
  String get aiChatGptConnectedPlan =>
      'Conectada · permiso de uso del plan concedido';

  @override
  String get aiChatGptConnectedIdentity => 'Conectada · solo identidad';

  @override
  String get aiChatGptNotConnected => 'ChatGPT sin conectar';

  @override
  String get aiContinueChatGpt => 'Continuar con ChatGPT';

  @override
  String get aiReviewPlanPermission => 'Revisar permiso de uso del plan';

  @override
  String get aiAuthorizePlan => 'Autorizar uso de mi plan ChatGPT';

  @override
  String get aiAddAccount => 'Añadir otra cuenta o espacio';

  @override
  String get aiViewUsagePermissions => 'Ver uso y permisos en ChatGPT';

  @override
  String get aiDisconnectChatGpt => 'Desconectar ChatGPT';

  @override
  String get aiCancelConnection => 'Cancelar conexión';

  @override
  String get aiApiKey => 'Clave API';

  @override
  String get aiHideKey => 'Ocultar clave';

  @override
  String get aiShowKey => 'Mostrar clave';

  @override
  String get aiFetchModels => 'Obtener / actualizar modelos';

  @override
  String get aiLoadingModels => 'Consultando modelos…';

  @override
  String get aiModelLabel => 'Modelo';

  @override
  String get aiChooseCatalogModel => 'Elige un modelo del catálogo';

  @override
  String aiCurrentModelPreserved(Object model) {
    return 'Modelo actual: $model. Se conserva aunque no aparezca en el catálogo.';
  }

  @override
  String get aiHideManualId => 'Ocultar identificador manual';

  @override
  String get aiEnterManualModel => 'Introducir modelo manualmente';

  @override
  String get aiModelIdentifier => 'Identificador del modelo';

  @override
  String get aiOpenCodeNotice =>
      'Go está orientado a agentes de programación. Esta conexión se identifica como TrackIA; comprueba con tu proveedor si admite este uso. No se cambia automáticamente a Zen ni a otro servicio.';

  @override
  String get aiApiSettings => 'Configuración de la API';

  @override
  String get aiHttpsBase => 'URL base HTTPS';

  @override
  String get aiProtocol => 'Formato compatible con el modelo';

  @override
  String get aiConfigSaved => 'Configuración guardada.';

  @override
  String get aiSaveLocalModel => 'Guardar modelo local';

  @override
  String get aiSaveProvider => 'Guardar proveedor';

  @override
  String aiProviderResponded(Object answer) {
    return 'El proveedor respondió:\n$answer';
  }

  @override
  String get aiTestLocalModel => 'Probar modelo en este móvil';

  @override
  String get aiTestChatGpt => 'Probar conexión · usa mi plan ChatGPT';

  @override
  String get aiTestApi => 'Probar conexión · usa tu API';

  @override
  String get aiConfigDeleted => 'Configuración y clave eliminadas.';

  @override
  String get aiDeleteConfig => 'Eliminar configuración y clave';
}
