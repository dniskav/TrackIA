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
    return 'Racha (días): $days';
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

  @override
  String appVersion(Object version) {
    return 'Versión $version';
  }

  @override
  String get activityIdleOtherActive => 'Otro acompañante activo';

  @override
  String get activityIdleNoActivity => 'Sin actividad';

  @override
  String get activityIdleEndOther =>
      'Termina la otra actividad para iniciar aquí';

  @override
  String get activityIdleRegisterAnytime => 'Registra una cuando quieras';

  @override
  String get activityNewActivity => 'Nueva actividad';

  @override
  String get activityIdleRecord => 'Registrar';

  @override
  String get activityRestLabel => 'Descanso';

  @override
  String get activityRestDone => 'Descanso terminado';

  @override
  String get activityRestPaused => 'Descanso pausado';

  @override
  String get activityRestPause => 'Pausar';

  @override
  String get activityRestContinue => 'Continuar';

  @override
  String get activityRestStart => 'Iniciar descanso';

  @override
  String get activityRestRestart => 'Reiniciar descanso';

  @override
  String activityRestAdjust(int seconds) {
    return '${seconds}s · Ajustar';
  }

  @override
  String get activityRestNotice =>
      'Aviso con esta pantalla abierta; el tiempo sigue al salir.';

  @override
  String get activityRestDurationTitle => 'Tiempo de descanso';

  @override
  String get activityRestSecondsLabel => 'Segundos';

  @override
  String get activityRestRangeHint =>
      'Entre 5 y 1800 segundos. Al aplicar, el contador queda listo para empezar.';

  @override
  String get activityRestApply => 'Aplicar';

  @override
  String get activityDialogNameTitle => 'Nombre de la actividad';

  @override
  String get activityDialogSaveName => 'Guardar nombre';

  @override
  String get activityDialogRestRange => 'Entre 0 y 1800';

  @override
  String get activityDialogWhatToDo => '¿Qué vas a hacer?';

  @override
  String get activityDialogYourActivities => 'Tus actividades';

  @override
  String get activityDialogInstantRecord => 'Registro puntual';

  @override
  String get activityDialogYourActivity => 'Tu actividad';

  @override
  String get activityDialogFromCurrentWorkout => 'Del entrenamiento actual';

  @override
  String activityDialogSetsProgress(
    Object done,
    Object target,
    Object repsMin,
    Object repsMax,
  ) {
    return '$done/$target series · $repsMin–$repsMax reps';
  }

  @override
  String get activityDialogRepeat => 'Volver a hacer';

  @override
  String activityDialogRoutineSets(Object routine, int sets) {
    return '$routine · $sets series';
  }

  @override
  String get activityDialogEndTitle => 'Terminar actividad';

  @override
  String get activityDialogDate => 'Fecha';

  @override
  String get activityDialogTime => 'Hora';

  @override
  String get activityBuilderNameRequired =>
      'Escribe un nombre para la actividad.';

  @override
  String get activityBuilderOnlyIntegers => 'Escribe solo números enteros.';

  @override
  String activityBuilderRange(Object what, int min, int max) {
    return '$what va de $min a $max.';
  }

  @override
  String get activityBuilderWhatDuration => 'La duración';

  @override
  String get activityBuilderWhatRest => 'El descanso';

  @override
  String get activityBuilderWhatSegments => 'Los tramos previstos';

  @override
  String get activityBuilderWhatCycles => 'Los ciclos previstos';

  @override
  String get activityBuilderDurationRequired =>
      'Indica la duración en minutos.';

  @override
  String get activityBuilderSegmentNamesPair =>
      'Indica singular y plural del tramo, o deja los dos vacíos.';

  @override
  String get activityBuilderFromTemplate => 'Empezar desde una plantilla';

  @override
  String get activityBuilderHowMeasured => '¿Cómo se mide?';

  @override
  String get activityBuilderInstantTitle => 'Puntual';

  @override
  String get activityBuilderInstantDetail => 'Un registro sin cronómetro';

  @override
  String get activityBuilderFreeTitle => 'Libre';

  @override
  String get activityBuilderFreeDetail => 'Cronómetro, sin cuenta atrás';

  @override
  String get activityBuilderTimedTitle => 'Con duración';

  @override
  String get activityBuilderTimedDetail => 'Cuenta atrás de un tiempo fijo';

  @override
  String get activityBuilderSegmentsTitle => 'Por tramos';

  @override
  String get activityBuilderSegmentsDetail => 'Varios tramos con descanso';

  @override
  String get activityBuilderDuration => 'Duración (minutos)';

  @override
  String get activityBuilderSegmentHelper => 'Opcional: de cada tramo';

  @override
  String get activityBuilderPlannedSegments => 'Tramos previstos (opcional)';

  @override
  String get activityBuilderRestBetween => 'Descanso entre tramos (segundos)';

  @override
  String get activityBuilderRestHelper => '90 es un minuto y medio';

  @override
  String get activityBuilderPlannedCycles => 'Ciclos previstos (opcional)';

  @override
  String get activityBuilderSegmentSingular => 'Un tramo se llama';

  @override
  String get activityBuilderSegmentPlural => 'Varios se llaman';

  @override
  String get activityBuilderWhatToNote => '¿Qué quieres anotar? (opcional)';

  @override
  String activityBuilderRemoveField(Object label) {
    return 'Quitar $label';
  }

  @override
  String get activityBuilderMaxFields => 'Máximo 12 campos';

  @override
  String get activityBuilderAddField => 'Añadir campo';

  @override
  String get activityBuilderSaveInActivities => 'Guardar en tus actividades';

  @override
  String get activityBuilderSaveInActivitiesHelp =>
      'Para repetirla sin volver a crearla.';

  @override
  String get activityBuilderPrepare => 'Preparar actividad';

  @override
  String get activityBuilderNewField => 'Nuevo campo';

  @override
  String get activityBuilderFieldNameRequired =>
      'Escribe un nombre de campo de hasta 80 caracteres.';

  @override
  String get activityBuilderFieldName => 'Nombre del campo';

  @override
  String get activityBuilderFieldType => 'Tipo';

  @override
  String get activityBuilderFieldUnit => 'Unidad (opcional)';

  @override
  String get activityBuilderOptions => 'Opciones';

  @override
  String get activityBuilderOptionsHelp => 'Separadas por comas';

  @override
  String get activityBuilderScaleMin => 'Mínimo';

  @override
  String get activityBuilderScaleMax => 'Máximo';

  @override
  String get activityBuilderScaleRange =>
      'Escribe el mínimo y el máximo de la escala.';

  @override
  String get activityBuilderAggregate => 'Cómo cuenta';

  @override
  String get activityBuilderCountSingular => 'Se cuenta como (uno)';

  @override
  String get activityBuilderCountSingularHelp => 'Opcional, p. ej. libro';

  @override
  String get activityBuilderCountPlural => 'Se cuenta como (varios)';

  @override
  String get activityBuilderCountPluralHelp => 'Opcional, p. ej. libros';

  @override
  String get activityBuilderAdd => 'Añadir';

  @override
  String get aiPerReadError =>
      'No se pudo leer la configuración por acompañante.';

  @override
  String get aiPerSaveError => 'No se pudo guardar el cambio.';

  @override
  String get aiPerTitle => 'Por acompañante';

  @override
  String get aiPerNoProvider =>
      'Conecta primero un proveedor para poder elegir un modelo distinto en cada acompañante.';

  @override
  String get aiPerHelp =>
      'Cada acompañante usa tu proveedor, o un modelo propio de ese mismo proveedor.';

  @override
  String get aiPerDefault => 'Por defecto';

  @override
  String aiPerDialogTitle(Object name) {
    return 'IA de $name';
  }

  @override
  String aiPerDialogHelp(Object service) {
    return 'Usa $service con la clave de tu perfil. Solo cambia el modelo de este acompañante.';
  }

  @override
  String get aiPerUseDefault => 'Usar el predeterminado';

  @override
  String get aiSetAndroidFileAccess =>
      'Android no entregó acceso al archivo seleccionado.';

  @override
  String get aiSetGgufTitle => 'Modelo GGUF';

  @override
  String aiSetLocalContextHelp(Object context) {
    return 'TrackIA recomienda $context para sus instrucciones, historial y datos. La recomendación es para las necesidades de la app, no para el límite de este GGUF. Si el modelo no soporta el tamaño elegido, puede fallar; tú decides si bajarlo.';
  }

  @override
  String aiSetModelsCountChatGpt(int count) {
    return 'Modelos disponibles para esta cuenta: $count. La prueba de conexión confirma el acceso al elegido.';
  }

  @override
  String aiSetCatalogCountApi(int count) {
    return '$count modelos obtenidos del proveedor. La prueba de conexión confirma si tu clave puede usar el elegido.';
  }

  @override
  String get aiSetCatalogErrorChatGpt =>
      'No se pudo obtener el catálogo de esta cuenta. Comprueba la conexión e inténtalo de nuevo.';

  @override
  String get aiSetCatalogErrorApi =>
      'No se pudo obtener el catálogo. Puedes volver a intentarlo o indicar el modelo manualmente.';

  @override
  String get transferSheetReadError => 'No se pudo leer la hoja.';

  @override
  String get transferSheetTooLarge => 'La hoja supera 20 MB.';

  @override
  String get transferSheetLoadError =>
      'No se pudo cargar la hoja. Vuelve a intentarlo.';

  @override
  String get transferSheetLoaded =>
      'Hoja cargada. Pendiente de interpretación por la IA.';

  @override
  String get transferFileTooLarge => 'El archivo supera 20 MB.';

  @override
  String get transferSheetSelectedError =>
      'No se pudo leer la hoja seleccionada.';

  @override
  String get transferFileReadError => 'No se pudo leer o compartir el archivo.';

  @override
  String get transferDefaultSheetName => 'Hoja cargada';

  @override
  String get transferShareSubject => 'Copia de seguridad TrackIA';

  @override
  String get transferShareText =>
      'Guarda este archivo en Drive o en un lugar seguro.';

  @override
  String get transferRestoreTitle => '¿Restaurar esta copia?';

  @override
  String transferRestoreBody(int workouts, int routines, Object active) {
    String _temp0 = intl.Intl.pluralLogic(
      workouts,
      locale: localeName,
      other: '$workouts sesiones',
      one: '1 sesión',
    );
    String _temp1 = intl.Intl.pluralLogic(
      routines,
      locale: localeName,
      other: '$routines rutinas',
      one: '1 rutina',
    );
    return 'Contiene $_temp0 y $_temp1$active. Sustituirá todos los datos que hay ahora en este teléfono. Guarda antes una copia actual si quieres conservarlos.';
  }

  @override
  String get transferRestoreActive => ', incluida una sesión en curso';

  @override
  String get transferRestoreAction => 'Restaurar';

  @override
  String get transferRestored =>
      'Copia restaurada. Sesiones y rutinas actualizadas.';

  @override
  String get transferNoAccessSheet =>
      'No se pudo leer esa hoja. En Google Sheets usa «Enviar una copia» como Excel o CSV y elige TrackIA.';

  @override
  String get transferHeadline => 'Tu historial, bajo tu control';

  @override
  String get transferIntro =>
      'Guarda una copia fuera de este móvil para recuperarla o pasarla a otro teléfono.';

  @override
  String get transferBackupTitle => 'Copia de seguridad';

  @override
  String get transferBackupHelp =>
      'Incluye historial, rutinas y sesión en curso.';

  @override
  String get transferSheetsTitle => 'Histórico de Google Sheets';

  @override
  String get transferSheetsHelpAndroid =>
      'Carga tu hoja y pestaña con autorización de Google, o elige una copia Excel o CSV. Se conservan las celdas originales; la IA podrá interpretar tu formato cuando esté conectada.';

  @override
  String get transferSheetsHelpOther =>
      'Carga una copia Excel o CSV. Se conservan las celdas originales, pendientes de interpretación por la IA.';

  @override
  String get transferImportSheets => 'Importar desde Google Sheets';

  @override
  String get transferChooseFileAndroid => 'Elegir archivo del móvil o Drive';

  @override
  String get transferChooseFileOther => 'Elegir copia XLSX o CSV';

  @override
  String transferWorkoutSubtitle(Object date, int exercises, int sets) {
    return '$date · $exercises ejercicios · $sets series';
  }

  @override
  String get transferNoColumnWorkout => 'Sin columna · Entrenamiento';

  @override
  String get transferChooseColumn => 'Elegir columna';

  @override
  String get transferCsvReviewError => 'No se pudo revisar el CSV.';

  @override
  String get transferImportSessionsTitle => '¿Importar estas sesiones?';

  @override
  String transferImportSessionsBody(int count, int sets, int errors) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones',
      one: '1 sesión',
    );
    return 'Se añadirán $_temp0 con $sets series. Filas omitidas por error: $errors.';
  }

  @override
  String get transferImportAction => 'Importar';

  @override
  String get transferImportError => 'No se pudo importar.';

  @override
  String get transferImportSheetTitle => 'Importar hoja';

  @override
  String transferImportedSummary(int added, int duplicates) {
    return 'Sesiones importadas: $added · Duplicadas omitidas: $duplicates';
  }

  @override
  String transferRowsFound(int count) {
    return '$count filas encontradas';
  }

  @override
  String get transferMapHelp =>
      'Asocia las columnas de tu hoja. Una fila representa una serie.';

  @override
  String get transferDate => 'Fecha';

  @override
  String get transferSessionOptional => 'Sesión (opcional)';

  @override
  String get transferExercise => 'Ejercicio';

  @override
  String get transferWeightKg => 'Peso (kg)';

  @override
  String get transferReps => 'Repeticiones';

  @override
  String get transferReviewImport => 'Revisar importación';

  @override
  String transferPreviewSummary(
    int newCount,
    int duplicateCount,
    int errorCount,
  ) {
    return 'Sesiones nuevas: $newCount · Duplicadas: $duplicateCount · Filas con error: $errorCount';
  }

  @override
  String transferValidRows(int valid, int total) {
    return '$valid series válidas de $total filas.';
  }

  @override
  String get transferAllSessions => 'Todas las sesiones';

  @override
  String transferSeeSessions(int count) {
    return 'Ver las $count sesiones';
  }

  @override
  String get transferErrorRows => 'Filas con errores';

  @override
  String transferSeeErrors(int count) {
    return 'Ver los $count errores';
  }

  @override
  String get transferImportNew => 'Importar sesiones nuevas';

  @override
  String get transferCloseAction => 'Cerrar';

  @override
  String get chatAttachVoiceError =>
      'No se pudo reconocer la voz. Comprueba el permiso de micrófono o escribe tu mensaje.';

  @override
  String get chatAttachVoiceUnavailable =>
      'El reconocimiento de voz no está disponible. Revisa el permiso de micrófono y el servicio de voz del teléfono.';

  @override
  String get chatAttachDictationStart => 'No se pudo iniciar el dictado.';

  @override
  String get chatAttachCamera => 'Cámara';

  @override
  String get chatAttachPhotos => 'Fotos';

  @override
  String get chatAttachPdf => 'Documento PDF';

  @override
  String get chatAttachPdfHint => 'Necesita un modelo que admita documentos';

  @override
  String get chatAttachAudio => 'Archivo de audio';

  @override
  String get chatAttachAudioHint =>
      'Requiere un modelo de Gemini que admita audio';

  @override
  String get chatAttachSpreadsheet => 'Hoja Excel o CSV';

  @override
  String get chatAttachSheet => 'Google Sheets / Drive';

  @override
  String get chatAttachNeedsAi =>
      'Conecta la IA para enviar imágenes, documentos o audio. Puedes cargar una hoja sin IA.';

  @override
  String get chatAttachPhotoTooLarge => 'La foto supera 4 MB.';

  @override
  String get chatAttachPhotoFormat => 'Elige una foto JPG, PNG o WebP.';

  @override
  String get chatAttachPhotoEmpty =>
      'La foto debe tener contenido y no superar 4 MB.';

  @override
  String get chatAttachAudioNeedsGemini =>
      'Para enviar un archivo de audio configura un modelo de Gemini con audio. Puedes usar el micrófono del chat para dictar el mensaje.';

  @override
  String get chatAttachTooLarge => 'El adjunto supera 4 MB.';

  @override
  String get chatAttachUnreadable => 'No se pudo leer el adjunto.';

  @override
  String get chatAttachFormat => 'Formato de adjunto no compatible.';

  @override
  String get chatAttachInvalidPdf => 'El archivo no contiene un PDF válido.';

  @override
  String get chatAttachOpenFailed => 'No se pudo abrir el adjunto.';

  @override
  String get chatAttachRecoveredTooLarge =>
      'La foto recuperada supera 4 MB. Elige una más pequeña.';

  @override
  String get chatMenuCompanionsError =>
      'No se pudieron cargar los acompañantes.';

  @override
  String get chatMenuMore => 'Más opciones';

  @override
  String get chatMenuTraining => 'Rutinas e historial';

  @override
  String get chatMenuProgress => 'Progreso';

  @override
  String get chatMenuSheet => 'Hoja cargada';

  @override
  String get chatMenuRecover => 'Recuperar preparación';

  @override
  String get chatSendFocusTooLong => 'El registro supera 8000 caracteres.';

  @override
  String get chatSendSavedNoAi =>
      'Registro guardado en el móvil. La IA no está disponible para interpretarlo.';

  @override
  String get chatSendSavedNoProvider =>
      'Registro guardado en el móvil. Configura el proveedor para consultar al asistente.';

  @override
  String get chatSendAssistantError =>
      'No se pudo consultar al asistente. Revisa el registro local.';

  @override
  String get chatSendQueueUnavailable =>
      'La cola durable no está disponible. Conserva el texto y vuelve a abrir el chat.';

  @override
  String get chatSendTooLong => 'El mensaje supera 8000 caracteres.';

  @override
  String get chatSendConfigureProvider =>
      'Configura el proveedor con el botón de ajustes para empezar.';

  @override
  String get chatSendSaveError =>
      'No se pudo guardar el mensaje en el móvil. Conserva el texto y vuelve a intentarlo.';

  @override
  String get chatSendProposalIncomplete =>
      'El modelo envió una propuesta incompleta. Pídele que prepare de nuevo el ejercicio para mostrar Iniciar.';

  @override
  String get chatSendAnswerSaveError =>
      'La respuesta llegó, pero no se pudo guardar la conversación en el móvil.';

  @override
  String get chatSendFailed =>
      'No se pudo completar la conversación. Puedes volver a intentarlo.';

  @override
  String get chatMsgOnlyLastEditable =>
      'Solo se puede editar el último mensaje. Escribe una corrección como mensaje nuevo.';

  @override
  String get chatMsgPending => 'Pendiente de envío';

  @override
  String get chatMsgSending => 'Enviando';

  @override
  String get chatMsgAnswered => 'Respondido';

  @override
  String get chatMsgFailed => 'No aceptado; puedes reenviar';

  @override
  String get chatMsgUncertain =>
      'Resultado incierto; reenvío bloqueado hasta revisar';

  @override
  String get chatMsgHistory => 'Historial';

  @override
  String get chatMsgResend => 'Reenviar';

  @override
  String get chatMsgAiNotReady => 'La IA no está lista.';

  @override
  String get chatMsgSendInProgress => 'Hay un envío en curso.';

  @override
  String get chatMsgChangedWhileEditing =>
      'El mensaje cambió mientras lo editabas. Revisa el historial.';

  @override
  String get chatMsgSaveNotSent =>
      'Edición guardada, pero no se pudo enviar ahora. Usa Reenviar cuando puedas.';

  @override
  String get chatMsgSavedOnly =>
      'Edición guardada. Usa Reenviar para enviar esta versión.';

  @override
  String get chatMsgLengthError => 'Escribe un mensaje de 1 a 8000 caracteres.';

  @override
  String get chatMsgEditError =>
      'No se pudo guardar la edición; el original se conserva.';

  @override
  String get chatMsgHistoryTitle => 'Historial de versiones';

  @override
  String chatMsgVersion(int n) {
    return 'Versión $n';
  }

  @override
  String chatMsgVersionCurrent(int n) {
    return 'Versión $n · actual';
  }

  @override
  String get chatMsgClose => 'Cerrar';

  @override
  String get chatMsgHistoryError => 'No se pudo abrir el historial.';

  @override
  String get chatMsgEditTitle => 'Editar mensaje';

  @override
  String get chatMsgEditLabel => 'Texto corregido';

  @override
  String get chatMsgEditHelper =>
      'La versión original se conserva en el historial.';

  @override
  String chatMsgSendBlocked(Object reason) {
    return 'No se puede enviar ahora: $reason';
  }

  @override
  String get chatMsgSaveAndSend => 'Guardar y enviar';

  @override
  String get chatSheetReloadError => 'No se pudo recuperar la hoja cargada.';

  @override
  String get chatSheetAndroidOnly =>
      'La conexión con Google Sheets está disponible en Android.';

  @override
  String get chatSheetSaveError =>
      'No se pudo guardar la hoja en el móvil. La copia anterior se conserva.';

  @override
  String get chatSheetInterpretPending =>
      'La respuesta llegó, pero la hoja sigue pendiente de interpretación en el móvil.';

  @override
  String get chatSheetRefreshError =>
      'No se pudo actualizar la hoja. La copia anterior se conserva.';

  @override
  String get chatSheetRemoveError => 'No se pudo quitar la copia de la hoja.';

  @override
  String chatSheetDialogBody(
    Object title,
    int rows,
    Object date,
    Object status,
  ) {
    return '$title · $rows filas\nÚltima lectura: $date.\n\n$status';
  }

  @override
  String get chatSheetStatusPending =>
      'Pendiente de interpretación por la IA. No se han importado entrenamientos.';

  @override
  String get chatSheetStatusAnalyzed =>
      'El asistente ha analizado esta copia; no se han importado entrenamientos.';

  @override
  String get chatSheetRemove => 'Quitar del contexto';

  @override
  String get chatSheetChange => 'Cambiar hoja';

  @override
  String get chatSheetRefresh => 'Actualizar hoja';

  @override
  String chatSheetLabel(Object title) {
    return 'Hoja · $title';
  }

  @override
  String chatProposalRepeated(int seconds) {
    return 'Series / tramos · ${seconds}s de descanso';
  }

  @override
  String chatProposalContinuous(int seconds) {
    return 'Actividad continua · ${seconds}s de descanso';
  }

  @override
  String chatSheetPendingInfo(Object name) {
    return '«$name» cargada · pendiente de interpretación. Los datos originales se conservan.';
  }

  @override
  String get chatGameFocusOpen =>
      'Termina la actividad abierta en el otro acompañante antes de preparar esta.';

  @override
  String get chatGamePrepareError =>
      'No se pudo preparar la actividad. Vuelve a intentarlo.';

  @override
  String chatGameGoalTitle(Object goal) {
    return 'Meta propuesta: $goal';
  }

  @override
  String chatGameAchievementTitle(Object title) {
    return 'Logro propuesto: $title';
  }

  @override
  String get chatGameCopyTitle => 'Textos de recordatorio propuestos';

  @override
  String get chatDeliveryQueueError =>
      'No se pudo abrir la cola durable del chat. No se enviarán mensajes por un almacenamiento alternativo.';

  @override
  String get chatDeliveryRestoredPending =>
      'Tu mensaje quedó guardado sin respuesta. Puedes volver a enviarlo.';

  @override
  String get chatDeliveryUncertain =>
      'Hay un envío con resultado incierto. No se reenviará automáticamente; revisa el historial antes de decidir.';

  @override
  String get chatDeliveryBacklog =>
      'Tienes mensajes guardados sin respuesta. Usa Reenviar cuando quieras; no se enviarán automáticamente.';

  @override
  String get chatDeliveryOtherChat =>
      'El mensaje pertenece a otro chat y no se enviará aquí.';

  @override
  String get chatDeliveryNotSafe => 'Este mensaje no es seguro de reenviar.';

  @override
  String get chatDeliveryStateChanged =>
      'El mensaje ya cambió de estado; no se hizo otro envío.';

  @override
  String get chatDeliveryUncertainSend =>
      'El resultado del envío es incierto. No se reenviará automáticamente; comprueba si llegó una respuesta.';

  @override
  String get chatDeliveryFailed =>
      'No se pudo completar la conversación. El mensaje permanece guardado; no se hará un reenvío automático.';

  @override
  String get chatArchiveIncompleteDirective =>
      'El modelo pidió archivar con datos incompletos. El chat sigue abierto.';

  @override
  String get chatArchiveDoneAuto =>
      'El asistente archivó el chat. Puedes consultarlo en Chats archivados.';

  @override
  String get chatArchiveDone =>
      'Chat archivado. El contexto activo se ha liberado.';

  @override
  String get chatArchiveViewAction => 'Ver archivos';

  @override
  String get chatArchiveError =>
      'No se pudo archivar. La conversación y los entrenamientos se conservan.';

  @override
  String get chatArchiveSyncInvalid =>
      'La propuesta de envío no es válida. Usa Enviar a Google Sheets en el menú.';

  @override
  String get chatArchiveRecalled =>
      'Archivo disponible para tu próximo mensaje al asistente.';

  @override
  String get chatArchiveReadError => 'No se pudo consultar el archivo.';

  @override
  String get chatDraftSaveError =>
      'No se pudo guardar el borrador. Conserva el texto y vuelve a intentarlo.';

  @override
  String get chatLoadError => 'No se pudo recuperar la conversación anterior.';

  @override
  String get chatLoadSheetError =>
      'No se pudo recuperar la hoja guardada. Vuelve a cargarla desde Google Sheets.';

  @override
  String get chatPersistTooLarge =>
      'El chat supera 20 MB; no se pudo guardar completo.';

  @override
  String get creatorCreate => 'Crear';

  @override
  String get creatorCreateFailed =>
      'No se pudo crear el acompañante. No se guardó nada.';

  @override
  String get creatorAssistedTitle => 'Crear con ayuda de la IA';

  @override
  String get creatorAiTitle => 'Con ayuda de la IA';

  @override
  String get creatorAiReadySubtitle =>
      'Cuéntale qué quieres seguir y te propone un acompañante.';

  @override
  String get creatorAiNotReadySubtitle =>
      'Necesitas conectar y verificar un proveedor de IA.';

  @override
  String get creatorOpenAiSettings => 'Abrir Ajustes de IA';

  @override
  String get creatorManualTitle => 'A mano';

  @override
  String get creatorManualSubtitle =>
      'Elige nombre, icono, color, modo y aviso tú mismo.';

  @override
  String get creatorNewTitle => 'Nuevo acompañante';

  @override
  String get creatorEditProposalTitle => 'Editar propuesta';

  @override
  String get creatorNameLength =>
      'Escribe un nombre de entre 1 y 40 caracteres.';

  @override
  String get creatorLevelReminderTitle => 'Solo recordatorio';

  @override
  String get creatorLevelReminderDetail => 'Te avisa y ya.';

  @override
  String get creatorLevelGoalsTitle => 'Metas y rachas';

  @override
  String get creatorLevelGoalsDetail =>
      'Recomendado: metas y rachas, sin logros.';

  @override
  String get creatorLevelGameTitle => 'Juego completo';

  @override
  String get creatorLevelGameDetail => 'Metas, rachas y logros.';

  @override
  String creatorActivityLabel(Object name) {
    return 'Qué anotas: $name';
  }

  @override
  String get creatorRemoveActivity => 'Quitar actividad';

  @override
  String creatorGoalLabel(Object text) {
    return 'Meta: $text';
  }

  @override
  String get creatorRemoveGoal => 'Quitar meta';

  @override
  String get creatorRemind => 'Recordarme';

  @override
  String get creatorDecideOnStart => 'lo decides al empezar';

  @override
  String get creatorPunctualSuffix => ' · registro puntual';

  @override
  String get creatorNoGoal => 'sin meta';

  @override
  String get creatorNoReminder => 'sin aviso';

  @override
  String creatorReminderLabel(Object text) {
    return 'Aviso: $text';
  }

  @override
  String creatorLevelLabel(Object text) {
    return 'Nivel: $text';
  }

  @override
  String get creatorDiscard => 'Descartar';

  @override
  String get creatorNoAiConnected => 'No hay una IA conectada.';

  @override
  String get creatorConversationFailed =>
      'No se pudo completar la conversación. Puedes volver a intentarlo.';

  @override
  String get creatorInputHint => 'Escribe aquí';

  @override
  String get creatorPromptHelper => 'Se usan cuando conectes un proveedor.';

  @override
  String get creatorLevelSection => 'Nivel';

  @override
  String get proposalIgnore => 'Ignorar';

  @override
  String get proposalAdd => 'Añadir';

  @override
  String get proposalUseTexts => 'Usar estos textos';

  @override
  String get proposalSuggestLater => 'Ahora no';

  @override
  String get proposalSuggestNever => 'No volver a sugerir';

  @override
  String get proposalLockedTitle =>
      'Propuesta de la IA sobre datos fijados por ti';

  @override
  String get proposalApply => 'Aplicar';

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
  String get proposalLockLabel => 'Fijado por ti. Toca para liberar';

  @override
  String get homeNewWorkoutTitle => 'Nuevo entrenamiento';

  @override
  String get homeSessionNameLabel => 'Nombre de la sesión';

  @override
  String get homeWorkout => 'Entrenamiento';

  @override
  String get homeAddExerciseTitle => 'Añadir ejercicio';

  @override
  String get homeExerciseNameLabel => 'Nombre del ejercicio';

  @override
  String get homeAdd => 'Añadir';

  @override
  String get homeBack => 'Volver';

  @override
  String get homeYourSession => 'Tu sesión';

  @override
  String get homeAssistantTooltip => 'Asistente TrackIA';

  @override
  String get homeReload => 'Recargar';

  @override
  String get homeLoadLog => 'Cargar bitácora';

  @override
  String get homeHeroTitle => 'Tu esfuerzo.\nTu progreso.';

  @override
  String get homeHeroSubtitle =>
      'Una serie a la vez. Lleva el registro de lo que haces hoy.';

  @override
  String get homeNextSession => 'TU PRÓXIMA SESIÓN';

  @override
  String get homeInProgress => 'SESIÓN EN CURSO';

  @override
  String get homeReadyQuestion => '¿Vamos a entrenar?';

  @override
  String get homeAddExercisesHint =>
      'Añade tus ejercicios y registra cada serie.';

  @override
  String homeActivitiesRecords(int activities, int records) {
    return 'Actividades: $activities · Registros: $records';
  }

  @override
  String get homeStartWorkout => 'Empezar entrenamiento';

  @override
  String get homeContinueWorkout => 'Continuar entrenamiento';

  @override
  String get homeCompletedSessions => 'sesiones completas';

  @override
  String get homeRecords => 'registros';

  @override
  String get homeLastActivity => 'ÚLTIMA ACTIVIDAD';

  @override
  String get homeEmptyHistoryTitle => 'Aquí empieza tu historia';

  @override
  String get homeEmptyHistorySubtitle =>
      'Tu primer entrenamiento aparecerá aquí cuando lo finalices.';

  @override
  String get homeSavedOffline => 'Guardado en este dispositivo · Sin conexión';

  @override
  String get homeJourneyTitle => 'Tu recorrido';

  @override
  String get homeEverySessionCounts => 'Cada sesión cuenta.';

  @override
  String get homeNoSessionsTitle => 'Todavía no hay sesiones';

  @override
  String get homeNoSessionsSubtitle =>
      'Finaliza un entrenamiento y consulta aquí todos sus ejercicios y series.';

  @override
  String get homeStatusInProgress => 'EN CURSO';

  @override
  String get homeStatusCompleted => 'COMPLETADO';

  @override
  String homeFinishedAt(Object date) {
    return 'Finalizó: $date';
  }

  @override
  String homeFinishRecorded(Object date) {
    return 'Cierre registrado: $date';
  }

  @override
  String homeFinishRecordedByUser(Object date) {
    return 'Cierre registrado: $date · hora elegida por ti';
  }

  @override
  String get homeTimeKeptWarning =>
      'Horario conservado con aviso. Puedes revisarlo más adelante.';

  @override
  String get homeTimeKeptWarningShort => 'Horario conservado con aviso.';

  @override
  String get homeActivities => 'actividades';

  @override
  String homeIntervalsRepeated(int count) {
    return 'Series / tramos: $count';
  }

  @override
  String homeIntervals(int count) {
    return 'Tramos: $count';
  }

  @override
  String get homeNotStarted => 'Sin iniciar';

  @override
  String homeEndedAt(Object date) {
    return 'Fin: $date';
  }

  @override
  String homeDraft(Object draft) {
    return 'Borrador: $draft';
  }

  @override
  String get homeFinishWorkout => 'Finalizar entrenamiento';

  @override
  String get homeAddSetToFinish =>
      'Registra al menos una serie para finalizar.';

  @override
  String get homeEachSetSaved => 'Cada serie se guarda al pulsar Guardar.';

  @override
  String get homeDiscardTitle => '¿Descartar sesión?';

  @override
  String get homeDiscardBody =>
      'Se eliminarán esta sesión y todas sus series. Esta acción no se puede deshacer.';

  @override
  String get homeDiscard => 'Descartar';

  @override
  String get homeDiscardSession => 'Descartar sesión';

  @override
  String get homeSavedWellDone => 'Sesión guardada. Buen trabajo.';

  @override
  String get homeViewHistory => 'Ver historial';

  @override
  String homeDeleteExerciseTooltip(Object name) {
    return 'Eliminar ejercicio $name';
  }

  @override
  String get homeDeleteExerciseTitle => '¿Eliminar ejercicio?';

  @override
  String homeDeleteExerciseBody(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series',
      one: '1 serie',
    );
    return 'Se eliminará $name y sus $_temp0.';
  }

  @override
  String get homeDelete => 'Eliminar';

  @override
  String homeTargetProgress(
    int done,
    int target,
    Object repsMin,
    Object repsMax,
  ) {
    return 'Series registradas: $done de $target · $repsMin–$repsMax reps';
  }

  @override
  String get homeNoPreviousSession => 'Sin sesión anterior registrada';

  @override
  String homeLastTime(Object date) {
    return 'Última vez · $date';
  }

  @override
  String get homeNoSetsYet => 'Todavía no has registrado series.';

  @override
  String get homeSetHeader => 'SERIE';

  @override
  String get homeKgHeader => 'KG';

  @override
  String get homeRepsHeader => 'REPS';

  @override
  String homeSetOptionsTooltip(int number) {
    return 'Opciones de la serie $number';
  }

  @override
  String homeSetDeleteBody(Object weight, int reps) {
    String _temp0 = intl.Intl.pluralLogic(
      reps,
      locale: localeName,
      other: '$reps repeticiones',
      one: '1 repetición',
    );
    return '$weight kg × $_temp0.';
  }

  @override
  String homeWeightReps(Object weight, int reps) {
    return '$weight kg × $reps';
  }

  @override
  String get homeEditSet => 'Editar serie';

  @override
  String get homeDeleteSet => 'Eliminar serie';

  @override
  String get homeAddSet => 'Añadir serie';

  @override
  String homeRest(int seconds) {
    return 'Descansar ${seconds}s';
  }

  @override
  String get homeFirstSetTitle => 'Prepara tu primera serie';

  @override
  String get homeFirstSetSubtitle =>
      'Añade un ejercicio para empezar a registrar peso y repeticiones.';

  @override
  String get homeFinishSession => 'Finalizar entreno';

  @override
  String get homeTabToday => 'Hoy';

  @override
  String get homeTabRoutines => 'Rutinas';

  @override
  String get homeTabHistory => 'Historial';

  @override
  String get homeSessionStarted =>
      'Entreno iniciado. Puedes abrir Entrenamiento para registrar.';

  @override
  String get homeSessionStartFailed => 'No se pudo iniciar el entreno.';

  @override
  String get homeActiveSessionChanged =>
      'La sesión activa ha cambiado. Revísala.';

  @override
  String get homeSavedSheetPending =>
      'Entreno guardado en el móvil. El envío a Google Sheets queda pendiente de confirmación.';

  @override
  String get homeSavedSheetNotUpdated =>
      'Entreno guardado en el móvil. Google Sheets no se ha actualizado.';

  @override
  String get homeFinishFailed => 'No se pudo finalizar el entreno.';

  @override
  String get homeReviewFinishTitle => 'Revisar hora de finalización';

  @override
  String homeFinishIssuesBody(Object issues) {
    return '$issues\n\n¿Quieres guardar la hora elegida tal cual? Los registros se conservarán para revisarlos después si lo deseas.';
  }

  @override
  String get homeBackAndFix => 'Volver y corregir';

  @override
  String get homeSaveThatTime => 'Guardar esa hora';

  @override
  String get homeDate => 'Fecha';

  @override
  String get homeTime => 'Hora';

  @override
  String get homeStartSession => 'Iniciar entreno';

  @override
  String get homeOptionYes => 'Sí';

  @override
  String get homeOptionNo => 'No';

  @override
  String get homeBoolYes => 'sí';

  @override
  String get homeBoolNo => 'no';

  @override
  String get homeNoteOptional => 'Nota (opcional)';

  @override
  String homeNumberInvalid(Object label) {
    return '$label: escribe un número.';
  }

  @override
  String get homeNoteOrValueRequired => 'Anota algún valor o escribe una nota.';

  @override
  String get homeSessionFinished => 'Sesión terminada';

  @override
  String get homeSummaryEmpty => 'Sin novedades esta vez. Seguimos.';

  @override
  String get homeNewAchievement => 'Logro nuevo';

  @override
  String get homeDone => 'Listo';

  @override
  String get homeSuggestionSquat => 'Sentadilla';

  @override
  String get homeSuggestionBench => 'Press banca';

  @override
  String get homeSuggestionRow => 'Remo';

  @override
  String get homeNewSet => 'Nueva serie';

  @override
  String get homeWeightLabel => 'Peso (kg)';

  @override
  String get homeWeightHint => 'Ej. 20,5';

  @override
  String get homeRepsLabel => 'Repeticiones';

  @override
  String get homeRepsHint => 'Ej. 10';

  @override
  String get homeZeroWeightHint => 'Usa 0 kg si entrenas sin carga externa.';

  @override
  String get homeExercisesLabel => 'EJERCICIOS';

  @override
  String get homeDeleteSetTitle => '¿Eliminar serie?';

  @override
  String get accountsConnectError => 'No se pudo conectar con Google.';

  @override
  String get accountsSwitchError =>
      'No se pudo cambiar de cuenta. Tus datos se conservan.';

  @override
  String get accountsDescription =>
      'Cada cuenta tiene su conversación, configuración de IA, hoja y entrenamientos en este móvil. El histórico anterior permanece en el perfil local. Conectar no copia ni sube esos datos.';

  @override
  String get accountsConnectAnother => 'Conectar otra cuenta de Google';

  @override
  String get accountsActiveProfile => 'Perfil activo';

  @override
  String get accountsReconnectProfile => 'Volver a este perfil con Google';

  @override
  String get accountsDisconnect => 'Desconectar y volver al perfil local';

  @override
  String get accountsDisconnectNotice =>
      'Desconectar conserva los datos de cada perfil en este móvil. No borra archivos de Google ni revoca el acceso desde tu cuenta de Google.';

  @override
  String get appearanceSaveError =>
      'No se pudo guardar el tema. Vuelve a intentarlo.';

  @override
  String get appearanceIntro =>
      'Elige cómo quieres ver TrackIA. La elección se guarda en este móvil.';

  @override
  String get appearanceSystemHint => 'Usar el tema del dispositivo';

  @override
  String get archiveSearchLabel => 'Buscar por título o resumen';

  @override
  String get archiveRecoverError =>
      'No se pudo recuperar el chat. El archivo se conserva.';

  @override
  String get archiveEmpty => 'Todavía no hay chats archivados.';

  @override
  String archiveChatSubtitle(Object date, Object count) {
    return '$date · $count mensajes';
  }

  @override
  String get archiveAutomaticTag => 'archivado por el asistente';

  @override
  String get archiveContinuityTitle => 'Resumen de continuidad';

  @override
  String archiveReasonLine(Object reason) {
    return 'Motivo del asistente: $reason';
  }

  @override
  String get archiveConsultFromChat => 'Consultar desde el chat';

  @override
  String get archiveYou => 'Tú';

  @override
  String archiveAttachmentKept(Object name) {
    return 'Adjunto conservado: $name';
  }

  @override
  String get notifUnsupported =>
      'Los avisos de descanso solo están disponibles en Android.';

  @override
  String get notifDndActive => 'No molestar está activo';

  @override
  String get notifDndTotalSilence =>
      'Estás en «Silencio total»: Android bloquea los avisos, incluso como alarma.';

  @override
  String get notifDndAlarm =>
      'Los avisos de descanso suenan como alarma. Los demás avisos no sonarían ni vibrarían.';

  @override
  String get notifDndPlain =>
      'Ahora mismo los avisos de descanso no sonarían ni vibrarían.';

  @override
  String get notifEnabledTitle => 'Avisos de actividad y descanso';

  @override
  String get notifEnabledSubtitle =>
      'Actividad lista, tramo en marcha, fin de tramo y fin de descanso.';

  @override
  String get notifAlarmStyleTitle => 'Tratar como alarma';

  @override
  String get notifAlarmStyleSubtitle =>
      'El fin de descanso y de tramo suenan y vibran aunque No molestar esté en modo Prioridad.';

  @override
  String get notifChannelBlockedTitle => 'Android bloquea el canal de alarma';

  @override
  String get notifChannelBlockedSubtitle =>
      'Actívalo en los ajustes del canal.';

  @override
  String get notifExactTitle => 'Permitir avisos puntuales';

  @override
  String get notifExactSubtitle =>
      'Sin este permiso Android puede retrasar el aviso.';

  @override
  String get notifCheck => 'Comprobar';

  @override
  String get notifTest => 'Probar aviso';

  @override
  String get notifTestAlarm => 'Probar con No molestar activo';

  @override
  String get notifOpenDnd => 'Abrir ajustes de No molestar';

  @override
  String get notifSilenceNote =>
      'En «Silencio total» Android bloquea todo, incluidas las alarmas. Ahí solo ayuda permitirlas en los ajustes de tu móvil.';

  @override
  String get progressLoadError => 'No se pudo calcular el progreso.';

  @override
  String get progressMonth1 => 'enero';

  @override
  String get progressMonth2 => 'febrero';

  @override
  String get progressMonth3 => 'marzo';

  @override
  String get progressMonth4 => 'abril';

  @override
  String get progressMonth5 => 'mayo';

  @override
  String get progressMonth6 => 'junio';

  @override
  String get progressMonth7 => 'julio';

  @override
  String get progressMonth8 => 'agosto';

  @override
  String get progressMonth9 => 'septiembre';

  @override
  String get progressMonth10 => 'octubre';

  @override
  String get progressMonth11 => 'noviembre';

  @override
  String get progressMonth12 => 'diciembre';

  @override
  String progressDayStatus(int day, Object month, Object status) {
    return '$day de $month: $status';
  }

  @override
  String get progressDayDone => 'cumplido';

  @override
  String get progressDayPending => 'pendiente';

  @override
  String get progressDayMissed => 'sin cumplir';

  @override
  String progressTitle(Object name) {
    return 'Progreso · $name';
  }

  @override
  String progressStreakCurrent(int n) {
    return 'Racha actual (días): $n';
  }

  @override
  String progressStreakBest(int best) {
    return 'Mejor racha: $best';
  }

  @override
  String progressFreeDays(int used, int total) {
    return 'Días libres esta semana: $used/$total';
  }

  @override
  String get progressGoalToday => 'Meta de hoy';

  @override
  String get progressGoalWeek => 'Meta de la semana';

  @override
  String progressGoalValues(Object value, Object target) {
    return '$value de $target';
  }

  @override
  String get progressLastFourWeeks => 'Últimas 4 semanas';

  @override
  String progressAchievementUnlocked(Object title) {
    return '$title, desbloqueado';
  }

  @override
  String progressAchievementLocked(Object title, int percent) {
    return '$title, bloqueado, $percent % de progreso';
  }

  @override
  String progressAchievementsTitle(int unlocked, int total) {
    return 'Logros · $unlocked de $total';
  }

  @override
  String get progressAchievementsEmptyPlay =>
      'Tus logros aparecerán al terminar tu primera actividad.';

  @override
  String progressAchievementsEmptyEnable(Object place) {
    return 'Activa el modo Juego y los logros en «$place».';
  }

  @override
  String get routinesTitle => 'Tus rutinas';

  @override
  String get routinesSubtitle => 'Prepara una vez. Entrena a tu ritmo.';

  @override
  String get routinesCreate => 'Crear rutina';

  @override
  String get routinesEmptyTitle => 'Tu próxima sesión, preparada';

  @override
  String get routinesEmptyBody =>
      'Crea, por ejemplo, «Pierna A» con tus ejercicios, series y rango de repeticiones.';

  @override
  String routinesOptionsTooltip(Object name) {
    return 'Opciones de $name';
  }

  @override
  String get routinesDeleteTitle => '¿Eliminar rutina?';

  @override
  String routinesDeleteBody(Object name) {
    return 'Se eliminará «$name». Tus entrenamientos guardados y la sesión en curso se conservarán.';
  }

  @override
  String get routinesEditMenu => 'Editar rutina';

  @override
  String get routinesDeleteMenu => 'Eliminar rutina';

  @override
  String get routinesDelete => 'Eliminar';

  @override
  String get routinesTrain => 'Entrenar';

  @override
  String get routinesContinueSession => 'Continuar sesión activa';

  @override
  String get routinesNeedExercise => 'Añade al menos un ejercicio.';

  @override
  String get routinesNameLabel => 'Nombre de la rutina';

  @override
  String get routinesNameHint => 'Ej. Pierna A';

  @override
  String get routinesEditorHelp =>
      'Define tus objetivos. Las series se registrarán cuando entrenes.';

  @override
  String routinesMoveUp(int n) {
    return 'Subir ejercicio $n';
  }

  @override
  String routinesMoveDown(int n) {
    return 'Bajar ejercicio $n';
  }

  @override
  String routinesEditExercise(int n) {
    return 'Editar ejercicio $n';
  }

  @override
  String routinesRemoveExercise(int n) {
    return 'Quitar ejercicio $n';
  }

  @override
  String get routinesAddExercise => 'Añadir ejercicio a rutina';

  @override
  String get routinesSaving => 'Guardando…';

  @override
  String get routinesSave => 'Guardar rutina';

  @override
  String get routinesLeaveTitle => '¿Salir sin guardar?';

  @override
  String get routinesLeaveBody => 'Los cambios en esta rutina se perderán.';

  @override
  String get routinesKeepEditing => 'Seguir editando';

  @override
  String get routinesDiscard => 'Descartar cambios';

  @override
  String get routinesBack => 'Volver';

  @override
  String get routinesExerciseDialogTitle => 'Ejercicio de rutina';

  @override
  String get routinesEditTargetTitle => 'Editar objetivo';

  @override
  String get routinesExerciseLabel => 'Ejercicio';

  @override
  String get routinesExerciseHint => 'Ej. Sentadilla';

  @override
  String get routinesTargetSets => 'Series previstas';

  @override
  String get routinesRepsMin => 'Reps mín.';

  @override
  String get routinesRepsMax => 'Reps máx.';

  @override
  String get routinesRestSeconds => 'Descanso (segundos)';

  @override
  String get routinesSaveExercise => 'Guardar ejercicio';

  @override
  String get focusCounterSaveError =>
      'No se pudo guardar el contador. Vuelve a intentarlo.';

  @override
  String get focusResultSaveError =>
      'No se pudo guardar el resultado. Conserva el texto y vuelve a intentarlo.';

  @override
  String get focusSaveActivityError => 'No se pudo guardar en tus actividades.';

  @override
  String get focusRecordSaveError =>
      'No se pudo guardar el registro. Vuelve a intentarlo.';

  @override
  String get focusReviewTimeTitle => 'Revisar hora';

  @override
  String get focusReviewTimeBody =>
      'La hora elegida no coincide con los registros. ¿Guardar esa hora y conservarlos?';

  @override
  String get focusBack => 'Volver';

  @override
  String get focusSaveThatTime => 'Guardar esa hora';

  @override
  String get focusRunning => 'En marcha';

  @override
  String get focusReady => 'Listo';

  @override
  String get focusRest => 'Descanso';

  @override
  String focusRepeatedRest(Object progress, Object segments) {
    return '$progress $segments · Descanso';
  }

  @override
  String focusSegmentCount(Object segment, int count) {
    return '$segment $count';
  }

  @override
  String focusSegmentCountOfTarget(Object segment, int count, int target) {
    return '$segment $count de $target';
  }

  @override
  String get focusSegmentSerie => 'serie';

  @override
  String get focusSegmentTramo => 'tramo';

  @override
  String get focusSegmentSeries => 'series';

  @override
  String get focusSegmentTramos => 'tramos';

  @override
  String focusRemoveField(Object label) {
    return 'Quitar $label';
  }

  @override
  String focusAddField(Object label) {
    return 'Añadir $label';
  }

  @override
  String get datePatternLongWeekday => 'EEEE, d \'de\' MMMM';

  @override
  String get datePatternLongDateTime => 'd \'de\' MMMM · HH:mm';

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
  String get builderTypeNumber => 'Número';

  @override
  String get builderTypeScale => 'Escala';

  @override
  String get builderTypeText => 'Texto';

  @override
  String get builderTypeChoice => 'Opción';

  @override
  String get builderTypeBoolean => 'Sí o no';

  @override
  String get builderAggSum => 'Sumar';

  @override
  String get builderAggMax => 'Mejor marca';

  @override
  String get builderAggAvg => 'Promedio';

  @override
  String get builderAggDistinct => 'Contar distintos';

  @override
  String get builderAggCountTrue => 'Contar síes';

  @override
  String get builderAggNone => 'Solo notas';

  @override
  String get proposalLabelActivitySeconds => 'Duración por tramo';

  @override
  String get proposalLabelTargetCycles => 'Ciclos previstos';

  @override
  String get proposalLabelUnitCycles => 'ciclos';

  @override
  String get proposalLabelUnitSeconds => 's';

  @override
  String get creatorStaticGreeting =>
      'Cuéntame qué quieres seguir y te ayudo a crear tu acompañante.';

  @override
  String get creatorStaticDayLetters => 'L,M,X,J,V,S,D';

  @override
  String get proposalGameSuggestion =>
      'Llevas varios días seguidos cumpliendo. ¿Quieres activar el modo Juego para ver metas, rachas y logros?';

  @override
  String reminderPhraseWindowStartCheer1(Object nombre, Object meta) {
    return '$nombre te espera: hoy toca $meta.';
  }

  @override
  String reminderPhraseWindowStartCheer2(Object nombre) {
    return '$nombre te espera hoy.';
  }

  @override
  String reminderPhraseWindowStartNeutral1(Object meta) {
    return 'Es buen momento para tu actividad. Meta de hoy: $meta.';
  }

  @override
  String get reminderPhraseWindowStartNeutral2 =>
      'Es buen momento para tu actividad.';

  @override
  String reminderPhraseLastCallCheer1(Object minimo, Object racha) {
    return 'Última llamada: con $minimo mantienes tu racha de $racha días.';
  }

  @override
  String reminderPhraseLastCallCheer2(Object faltan) {
    return 'No pierdas la racha: te faltan $faltan esta semana.';
  }

  @override
  String get reminderPhraseLastCallCheer3 => 'Última llamada para hoy.';

  @override
  String reminderPhraseLastCallNeutral1(Object minimo) {
    return 'Aún estás a tiempo hoy. Con $minimo basta.';
  }

  @override
  String reminderPhraseLastCallNeutral2(Object faltan) {
    return 'Te faltan $faltan esta semana.';
  }

  @override
  String get reminderPhraseLastCallNeutral3 => 'Aún estás a tiempo hoy.';

  @override
  String reminderPhraseInactiveGymbroCheer(Object dias) {
    return 'Amigo, llevamos $dias días sin entrenar. Vamos a movernos un poco.';
  }

  @override
  String reminderPhraseInactiveCheer1(Object dias) {
    return 'Llevamos $dias días sin vernos. ¿Algo corto hoy?';
  }

  @override
  String get reminderPhraseInactiveCheer2 => '¿Algo corto hoy?';

  @override
  String reminderPhraseInactiveNeutral1(Object dias) {
    return 'Llevas $dias días sin registrar.';
  }

  @override
  String get reminderPhraseInactiveNeutral2 =>
      'Hace unos días que no registras.';

  @override
  String get reminderPhraseMinimumSessionOne => '1 sesión';

  @override
  String reminderPhraseMinimumSessions(Object n) {
    return '$n sesiones';
  }

  @override
  String reminderPhraseMinimumMinutes(Object n) {
    return '$n min';
  }

  @override
  String reminderPhraseMinimumField(Object n, Object campo) {
    return '$n $campo';
  }

  @override
  String memoryTitle(Object name) {
    return 'Memoria de $name';
  }

  @override
  String get memoryIntro =>
      'Lo que este acompañante recuerda de ti. Puedes revisarlo, editarlo o borrarlo cuando quieras. Se trata como información tuya, nunca como instrucciones.';

  @override
  String get memoryOpen => 'Memoria del acompañante';

  @override
  String get memoryOpenHelp =>
      'Ver, editar y borrar lo que recuerda, y la copia en la nube.';

  @override
  String get memoryEmpty => 'Aún no hay recuerdos guardados.';

  @override
  String get memoryLoadError => 'No se pudieron cargar los recuerdos.';

  @override
  String get memoryActionError =>
      'No se pudo completar la acción. Tus recuerdos no han cambiado.';

  @override
  String get memoryStatusActive => 'Activo';

  @override
  String get memoryStatusPending => 'Pendiente de confirmar';

  @override
  String get memorySourceExplicit => 'Lo pediste tú';

  @override
  String get memorySourceInferred => 'Sugerido por la IA';

  @override
  String get memorySourceEdited => 'Editado por ti';

  @override
  String get memoryConfirm => 'Confirmar';

  @override
  String get memoryConfirmed => 'Recuerdo confirmado.';

  @override
  String get memoryEdit => 'Editar';

  @override
  String get memoryEditTitle => 'Editar recuerdo';

  @override
  String get memoryEditLabel => 'Recuerdo';

  @override
  String get memoryEditEmpty => 'El recuerdo no puede estar vacío.';

  @override
  String get memoryEditTooLong =>
      'El recuerdo no puede superar 2000 caracteres.';

  @override
  String get memoryEdited => 'Recuerdo guardado.';

  @override
  String get memoryDeleteLocalAction => 'Borrar del móvil';

  @override
  String get memoryDeleteLocalTitle => '¿Borrar este recuerdo del móvil?';

  @override
  String get memoryDeleteLocalBody =>
      'Se borrará solo de este móvil y el acompañante dejará de usarlo. No borra la copia que tengas en la nube; para eso usa «Borrar en la nube».';

  @override
  String get memoryDeletedLocal =>
      'Recuerdo borrado de este móvil. La copia en la nube no se ha tocado.';

  @override
  String get memoryCloudTitle => 'Copia en la nube';

  @override
  String get memoryCloudHelp =>
      'Opcional y solo cuando tú lo pidas. Se guardan los recuerdos activos de este acompañante, sin chats ni claves. No está cifrada de extremo a extremo.';

  @override
  String get memoryCloudUnavailable =>
      'Google Drive aún no está conectado en esta versión';

  @override
  String get memoryCloudNoAccount =>
      'Conecta una cuenta de Google para usar la copia en la nube.';

  @override
  String memoryCloudAccount(Object account) {
    return 'Cuenta: $account';
  }

  @override
  String memoryCloudLastCopy(Object date, int revision) {
    return 'Última copia vista: $date (revisión $revision)';
  }

  @override
  String get memoryCloudSave => 'Guardar en la nube';

  @override
  String get memoryCloudLoad => 'Cargar de la nube';

  @override
  String get memoryCloudDelete => 'Borrar en la nube';

  @override
  String get memoryCloudSaveTitle => '¿Guardar en la nube?';

  @override
  String memoryCloudSaveBody(Object account, int count) {
    return 'Se subirán a la cuenta $account los recuerdos activos de este acompañante. Recuerdos a subir: $count. Los pendientes de confirmar no se suben. Si la copia de la nube cambió, no se sobrescribe.';
  }

  @override
  String memoryCloudSaved(Object account) {
    return 'Copia guardada en la cuenta $account.';
  }

  @override
  String memoryCloudLoaded(int count) {
    return 'Copia cargada. Recuerdos añadidos: $count.';
  }

  @override
  String get memoryCloudLoadCancelled =>
      'Carga cancelada. No se ha cambiado nada.';

  @override
  String get memoryCloudDeleteTitle => '¿Borrar la copia en la nube?';

  @override
  String memoryCloudDeleteBody(Object account, Object date) {
    return 'Se borrará de la cuenta $account la copia de este acompañante (guardada el $date). No borra los recuerdos de este móvil. No se puede deshacer.';
  }

  @override
  String memoryCloudDeleted(Object account) {
    return 'Copia borrada de la cuenta $account. Los recuerdos de este móvil no se han tocado.';
  }

  @override
  String get memoryCloudDeleteCancelled =>
      'Borrado cancelado. No se ha cambiado nada.';

  @override
  String get memoryCloudNotFound =>
      'No hay copia en la nube para este acompañante.';

  @override
  String get memoryCloudConflict =>
      'La copia de la nube es distinta de la última que viste. No se ha modificado nada; usa «Cargar de la nube» para revisarla.';

  @override
  String get memoryCloudUncertain =>
      'No se pudo confirmar el resultado; puede que la operación sí se haya aplicado. Cárgala de nuevo para comprobarlo antes de repetir.';

  @override
  String get memoryCloudCancelled =>
      'Operación cancelada. No se ha cambiado nada.';

  @override
  String get memoryCloudDenied =>
      'Google no concedió el permiso. No se ha cambiado nada.';

  @override
  String get memoryCloudFailed =>
      'No se pudo completar la operación con la nube. No se ha cambiado nada en tus recuerdos locales.';

  @override
  String get memoryPreviewTitle => 'Vista previa de la copia';

  @override
  String memoryPreviewFrom(Object account, Object date) {
    return 'Cuenta $account, copia del $date';
  }

  @override
  String memoryPreviewAdd(int count) {
    return 'Se añadirían: $count';
  }

  @override
  String memoryPreviewSkip(int count) {
    return 'Se omiten (ya existen): $count';
  }

  @override
  String memoryPreviewConflict(int count) {
    return 'En conflicto (no se aplican): $count';
  }

  @override
  String get memoryPreviewConflictHelp =>
      'Los conflictos no se resuelven solos: tus recuerdos locales se conservan tal cual.';

  @override
  String get memoryPreviewNothing => 'No hay nada que añadir.';

  @override
  String get memoryPreviewApply => 'Añadir recuerdos';

  @override
  String get agreementTitle => 'Acuerdos de apoyo';

  @override
  String get agreementNew => 'Nuevo acuerdo';

  @override
  String get agreementEmpty =>
      'Aún no tienes acuerdos. Crea uno con el botón Nuevo acuerdo; solo se anota lo que tú registres.';

  @override
  String get agreementLoadError => 'No se pudieron cargar los acuerdos.';

  @override
  String get agreementSaveError =>
      'No se pudo guardar el cambio. El acuerdo sigue como estaba.';

  @override
  String get agreementStatusActive => 'Activos';

  @override
  String get agreementStatusPaused => 'En pausa';

  @override
  String get agreementStatusCompleted => 'Finalizados';

  @override
  String get agreementObjectiveLabel => 'Objetivo';

  @override
  String get agreementUnitLabel => 'Unidad (opcional)';

  @override
  String get agreementMeasureLabel => 'Medida';

  @override
  String get agreementMeasureOptionalLabel => 'Medida (opcional)';

  @override
  String get agreementConsent =>
      'Acepto crear este acuerdo. Solo se anotará lo que yo registre.';

  @override
  String get agreementErrorObjective =>
      'Escribe un objetivo (hasta 2000 caracteres).';

  @override
  String get agreementErrorMeasure =>
      'La medida debe ser un número finito igual o mayor que 0.';

  @override
  String get agreementErrorConsent => 'Marca la casilla para crear el acuerdo.';

  @override
  String get agreementCancel => 'Cancelar';

  @override
  String get agreementCreate => 'Crear';

  @override
  String get agreementSave => 'Guardar';

  @override
  String get agreementModify => 'Modificar';

  @override
  String get agreementPause => 'Pausar';

  @override
  String get agreementResume => 'Reanudar';

  @override
  String get agreementComplete => 'Finalizar';

  @override
  String get agreementCompleteTitle => '¿Finalizar el acuerdo?';

  @override
  String get agreementCompleteBody =>
      'Un acuerdo finalizado ya no se puede modificar ni admite más avances. El historial se conserva.';

  @override
  String get agreementRecordProgress => 'Registrar avance';

  @override
  String get agreementRecord => 'Registrar';

  @override
  String get agreementAmountLabel => 'Cantidad (opcional)';

  @override
  String get agreementNoteLabel => 'Nota (opcional)';

  @override
  String get agreementReminderLabel => 'Aviso';

  @override
  String get agreementEventsTitle => 'Avances anotados';

  @override
  String get agreementNoEvents => 'Aún no hay avances anotados.';

  @override
  String get agreementChangesTitle => 'Historial de cambios';

  @override
  String get agreementNoChanges => 'Sin cambios desde la creación.';

  @override
  String agreementRevisionLabel(int n) {
    return 'Revisión $n';
  }

  @override
  String get packageShareRow => 'Compartir acompañante';

  @override
  String get packageShareRowHelp =>
      'Crea un archivo .trackia con la configuración de este acompañante, sin tus datos.';

  @override
  String get packageShareTitle => '¿Compartir este acompañante?';

  @override
  String get packageShareIncludes =>
      'Se comparte: nombre, icono, color, descripción, instrucciones de estilo, modo, plantillas de actividad y textos de avisos.';

  @override
  String get packageShareExcludes =>
      'No se comparte: claves de IA, chats, memoria, hoja de Google, cuentas ni tus datos.';

  @override
  String get packageShareReceiverNote =>
      'Quien lo reciba podrá importarlo y revisarlo antes de usarlo.';

  @override
  String get packageShareTemplatesLimited =>
      'Solo se incluyen las 5 primeras plantillas de actividad.';

  @override
  String get packageShareConfirm => 'Compartir';

  @override
  String get packageShareInstructionsTooLong =>
      'Las instrucciones superan los 4000 caracteres que admite compartir. Acórtalas e inténtalo de nuevo. No se ha compartido nada.';

  @override
  String get packageShareInvalid =>
      'Este acompañante tiene datos que no se pueden compartir. No se ha compartido nada.';

  @override
  String get packageShareWriteError =>
      'No se pudo preparar el archivo para compartir. No se ha compartido nada.';

  @override
  String get packageImportTitle => 'Importar acompañante';

  @override
  String get packageImportIntro =>
      'Elige un archivo .trackia o pega el texto que te compartieron. Se mostrará una vista previa antes de guardar nada.';

  @override
  String get packageImportPickFile => 'Elegir archivo';

  @override
  String get packageImportPasteLabel => 'Texto del acompañante';

  @override
  String get packageImportPreviewButton => 'Ver vista previa';

  @override
  String get packageImportFileError => 'No se pudo leer el archivo.';

  @override
  String get packageImportExternalNotice =>
      'Este contenido viene de fuera: revísalo antes de guardarlo.';

  @override
  String get packageImportModeNote =>
      'Se guardará en modo «recordatorio», sin permisos ni conexiones. Podrás cambiarlo después.';

  @override
  String get packageImportActivityTitle => 'Actividad que traería';

  @override
  String packageImportActivityFields(Object fields) {
    return 'Campos: $fields';
  }

  @override
  String get packageImportRemindersTitle => 'Textos de avisos';

  @override
  String get packageImportReminderWindowStart => 'Al empezar la ventana';

  @override
  String get packageImportReminderLastCall => 'Última llamada';

  @override
  String get packageImportReminderInactive => 'Sin actividad';

  @override
  String get packageImportWarningsTitle => 'Advertencias';

  @override
  String packageImportWarningAppBlocksRemoved(int count) {
    return 'Se quitaron bloques internos de la aplicación del contenido. Cantidad: $count';
  }

  @override
  String packageImportWarningModeReset(Object mode) {
    return 'El paquete pedía el modo «$mode»; empieza en «recordatorio» y puedes cambiarlo después.';
  }

  @override
  String packageImportWarningExtraTemplates(int count) {
    return 'Otras actividades del paquete no se aplican. Cantidad: $count';
  }

  @override
  String get packageImportWarningSuspicious =>
      'Las instrucciones parecen intentar cambiar las reglas del asistente. Léelas con atención o bórralas.';

  @override
  String get packageImportWarningInstructionsEmpty =>
      'No quedó texto en las instrucciones tras quitar los bloques internos.';

  @override
  String get packageImportSave => 'Guardar acompañante';

  @override
  String get packageImportSaveFailed => 'No se pudo guardar el acompañante.';

  @override
  String packageImportProblemField(Object field) {
    return 'Campo: $field';
  }

  @override
  String get packageImportProblemEmpty =>
      'No hay nada que importar: el texto o el archivo está vacío.';

  @override
  String get packageImportProblemTooLarge =>
      'El contenido es demasiado grande para ser un acompañante.';

  @override
  String get packageImportProblemBadEncoding =>
      'El texto está dañado o incompleto: no tiene un formato válido.';

  @override
  String get packageImportProblemBadCompression =>
      'El contenido está dañado y no se pudo descomprimir.';

  @override
  String get packageImportProblemTooLargeExpanded =>
      'El contenido ocupa demasiado al abrirlo y se rechazó por seguridad.';

  @override
  String get packageImportProblemMalformed =>
      'El contenido no se pudo leer: no es un acompañante válido.';

  @override
  String get packageImportProblemNotAPackage =>
      'Esto no es un acompañante de TrackIA.';

  @override
  String get packageImportProblemUnsupportedVersion =>
      'Este acompañante es de una versión más nueva. Actualiza TrackIA para importarlo.';

  @override
  String get packageImportProblemChecksumMismatch =>
      'El contenido cambió o se dañó: la comprobación de integridad falló.';

  @override
  String get packageImportProblemForbiddenField =>
      'El contenido incluye un dato que nunca debe viajar (claves, chats, memoria…). No se importó.';

  @override
  String get packageImportProblemUnknownField =>
      'El contenido incluye un campo que esta versión no admite. No se importó.';

  @override
  String get packageImportProblemMissingField =>
      'Falta un campo obligatorio en el contenido.';

  @override
  String get packageImportProblemInvalidField =>
      'Un campo del contenido no es válido o supera su límite.';

  @override
  String get importedTrustWarning =>
      'Este acompañante es importado: confirma antes de que actúe.';

  @override
  String get importedTrustConfirm => 'Confirmar';

  @override
  String get importedTrustSheetTitle => '¿Editar tu hoja de Google Sheets?';

  @override
  String importedTrustSheetTarget(String sheet, String tab) {
    return 'Hoja: $sheet · Pestaña: $tab';
  }

  @override
  String importedTrustCellLine(String cell, String before, String after) {
    return '$cell: «$before» → «$after»';
  }

  @override
  String get importedTrustEmptyValue => '(vacía)';

  @override
  String get importedTrustCancelledSheet =>
      'Acción cancelada: no se editó la hoja de Google Sheets.';

  @override
  String get importedTrustActivityTitle => '¿Preparar esta actividad?';

  @override
  String importedTrustActivityRest(int seconds) {
    return 'Descanso: $seconds s';
  }

  @override
  String importedTrustActivityDuration(int seconds) {
    return 'Duración de la actividad: $seconds s';
  }

  @override
  String importedTrustActivityTargetSets(int count) {
    return 'Series objetivo: $count';
  }

  @override
  String importedTrustActivityFields(String fields) {
    return 'Campos: $fields';
  }

  @override
  String importedTrustCancelledActivity(String name) {
    return 'Acción cancelada: no se preparó la actividad «$name».';
  }

  @override
  String get importedTrustLabel => 'Importado';

  @override
  String get importedTrustSwitch => 'Confiar en este acompañante';

  @override
  String get importedTrustSwitchHelp =>
      'Mientras no confíes en él, pedirá confirmación antes de editar tu hoja o preparar actividades.';

  @override
  String get importedTrustDialogTitle => '¿Confiar en este acompañante?';

  @override
  String get importedTrustDialogBody =>
      'Dejará de pedir confirmación antes de editar tu hoja o preparar actividades. Hazlo solo si confías en quien te lo compartió.';

  @override
  String get importedTrustDialogConfirm => 'Confiar';

  @override
  String get importedTrustSaveError =>
      'No se pudo guardar el cambio. Inténtalo de nuevo.';

  @override
  String get packageQrTitle => 'Código QR del acompañante';

  @override
  String get packageQrNote =>
      'Quien lo escanee verá una vista previa antes de guardar nada.';

  @override
  String get packageQrShareFile => 'Compartir archivo';

  @override
  String get packageQrClose => 'Cerrar';

  @override
  String get packageQrTooLarge =>
      'Es demasiado grande para un QR: se comparte como archivo.';

  @override
  String get packageScanTitle => 'Escanear acompañante';

  @override
  String get packageScanHint =>
      'Apunta la cámara al código QR del acompañante.';

  @override
  String get packageScanTorch => 'Linterna';

  @override
  String get packageScanPermissionDenied =>
      'No hay permiso para usar la cámara. Puedes importar el acompañante desde un archivo o pegando el texto.';

  @override
  String get packageScanCameraError =>
      'No se pudo usar la cámara. Puedes importar el acompañante desde un archivo o pegando el texto.';

  @override
  String get packageScanUseFile => 'Importar desde archivo o texto';

  @override
  String get restScreenSharedCopyUnreadable =>
      'No se pudo leer la copia compartida.';

  @override
  String get restScreenSharedCopyOpenError =>
      'No se pudo abrir la copia compartida.';

  @override
  String restScreenCompanionsLoadDetail(Object error) {
    return 'No se pudieron cargar los acompañantes: $error';
  }

  @override
  String restScreenTimerLabel(Object label) {
    return 'Tiempo: $label';
  }
}
