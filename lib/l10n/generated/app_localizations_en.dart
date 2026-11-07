// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TrackIA';

  @override
  String get languageSystem => 'Device language';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languagePreference => 'Language';

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get welcomeHelpTitle => 'Help and welcome';

  @override
  String welcomeStep(Object current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String get welcomeSlide1Title => 'Welcome';

  @override
  String get welcomeSlide1Body =>
      'Talk with your AI assistant to plan an activity, ask questions, and review your progress. You decide when to start.';

  @override
  String get welcomeSlide2Title => 'Speak or type';

  @override
  String get welcomeSlide2Body =>
      'Chat supports text, dictation, and attachments. To use AI, connect a provider from the menu. Your local records stay available if the connection drops.';

  @override
  String get welcomeSlide3Title => 'Manage your activity';

  @override
  String get welcomeSlide3Body =>
      'Choose or create an activity. Preparing it does not start the timer: tap Start when ready and Stop at the end of each segment.';

  @override
  String get welcomeSlide4Title => 'Keep your data';

  @override
  String get welcomeSlide4Body =>
      'Your records are stored on this device. You can connect Google Sheets at any time and review each send status.';

  @override
  String get welcomeSlide5Title => 'Your companions';

  @override
  String get welcomeSlide5Body =>
      'Choose GymBro, Focus, Calm, or Journal. Edit their instructions, create more, and connect a different Google sheet or tab for each one.';

  @override
  String get welcomeSlide6Title => 'Modes and reminders';

  @override
  String get welcomeSlide6Body =>
      'Each companion has a mode. Open its menu (⋮) and tap “Modes and reminders”: Reminder only alerts you at your chosen time; Game adds goals, streaks, and achievements. For rest alerts even when Do Not Disturb is on, go to Settings → Reminders.';

  @override
  String get welcomeSaveErrorTitle => 'Could not save your choice';

  @override
  String get welcomeSaveErrorBody =>
      'You can try again or continue. If you continue, the welcome guide may appear the next time you open the app.';

  @override
  String get retry => 'Retry';

  @override
  String get continueWithoutSaving => 'Continue without saving';

  @override
  String get welcomeNeverAgain => 'Don\'t show again';

  @override
  String get welcomeNeverAgainHelp =>
      'If unchecked, this guide appears when you open the app. You can change this in Help.';

  @override
  String get skip => 'Skip';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get start => 'Start';

  @override
  String get welcomeAutoShow => 'Show welcome on open';

  @override
  String get devicePreferenceSaved => 'Your choice is saved on this device.';

  @override
  String get showWelcome => 'View welcome guide';

  @override
  String get savePreferenceError => 'Could not save the preference.';

  @override
  String get companionsTitle => 'Your companions';

  @override
  String get companionsDescription =>
      'Choose who to work with. Each companion keeps its own conversation and can use a different Google sheet or tab.';

  @override
  String get companionsEmpty =>
      'You don\'t have any companions yet. Create one to get started.';

  @override
  String get createCompanion => 'Create companion';

  @override
  String companionOptions(Object name) {
    return 'Options for $name';
  }

  @override
  String companionProgress(Object name) {
    return 'Progress for $name';
  }

  @override
  String companionStreak(int days) {
    return 'Streak (days): $days';
  }

  @override
  String get remindersPaused => 'Reminders paused';

  @override
  String get resume => 'Resume';

  @override
  String get edit => 'Edit';

  @override
  String get modeAndNotices => 'Modes and reminders';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String companionDeleteTitle(Object name) {
    return 'Delete $name?';
  }

  @override
  String get companionDeleteBody =>
      'Its chat, files, and local Sheets connection will be deleted. The Google sheet and activity records will not be deleted.';

  @override
  String companionDeleteError(Object error) {
    return 'Could not delete: $error';
  }

  @override
  String companionSaveError(Object error) {
    return 'Could not save: $error';
  }

  @override
  String get companionLoadError => 'Couldn\'t load companions. Tap to retry.';

  @override
  String get createCompanionTitle => 'Create companion';

  @override
  String get editCompanionTitle => 'Edit companion';

  @override
  String get companionName => 'Name';

  @override
  String get companionPurpose => 'What is it for?';

  @override
  String get companionInstructions => 'Instructions for AI (optional)';

  @override
  String get companionInstructionsHelp => 'Used when you connect a provider.';

  @override
  String get icon => 'Icon';

  @override
  String get color => 'Color';

  @override
  String get settings => 'Settings';

  @override
  String get assistant => 'Assistant';

  @override
  String get artificialIntelligence => 'Artificial intelligence';

  @override
  String get yourData => 'Your data';

  @override
  String get accountAndData => 'Account and data';

  @override
  String get localProfile => 'Local profile';

  @override
  String get exportImport => 'Export and import';

  @override
  String get appSection => 'App';

  @override
  String get notices => 'Reminders';

  @override
  String get enabled => 'On';

  @override
  String get disabled => 'Off';

  @override
  String get appearance => 'Appearance';

  @override
  String get helpWelcome => 'Help and welcome';

  @override
  String get verified => 'Verified';

  @override
  String get notConnected => 'Not connected';

  @override
  String get notVerified => 'Not verified';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get checking => 'Checking…';

  @override
  String get automatic => 'Automatic';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String companionSettingsTitle(Object name) {
    return 'Modes and reminders · $name';
  }

  @override
  String get mode => 'Mode';

  @override
  String get reminderMode => 'Reminder';

  @override
  String get reminderModeDetail => 'Only alerts you at the time you choose.';

  @override
  String get gameMode => 'Game';

  @override
  String get gameModeDetail =>
      'Goals, streaks, and achievements, along with reminders.';

  @override
  String get goals => 'Goals';

  @override
  String get streaks => 'Streaks';

  @override
  String get achievements => 'Achievements';

  @override
  String get encouragementMessages => 'Encouragement messages';

  @override
  String get freeDaysPerWeek => 'Free days per week';

  @override
  String get freeDaysHelp => 'They don\'t break a streak.';

  @override
  String get dailyNotice => 'Daily reminder';

  @override
  String get remindersPausedDetail =>
      'Seven scheduled days passed without recording activity.';

  @override
  String get remindAboutActivity => 'Remind me about this activity';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get from => 'From';

  @override
  String get until => 'Until';

  @override
  String get lastCall => 'Last call';

  @override
  String get lastCallTime => 'Last call time';

  @override
  String get neutral => 'Neutral';

  @override
  String get motivating => 'Encouraging';

  @override
  String get minimumForDay => 'Minimum for the day';

  @override
  String get quantity => 'Amount';

  @override
  String get sessions => 'sessions';

  @override
  String get minutes => 'minutes';

  @override
  String get preview => 'Preview';

  @override
  String get putGoal => 'Set a goal';

  @override
  String get whatToMeasure => 'What to measure';

  @override
  String get timeMinutes => 'Time (minutes)';

  @override
  String get sessionCount => 'Sessions';

  @override
  String get perDay => 'per day';

  @override
  String get perWeek => 'per week';

  @override
  String get target => 'Target';

  @override
  String get minimumStreakOptional => 'Minimum to keep a streak (optional)';

  @override
  String get chooseTime => 'Choose a time';

  @override
  String get goalMustBePositive => 'The goal must be a number greater than 0.';

  @override
  String get minimumMustBePositive =>
      'The minimum must be a number greater than 0.';

  @override
  String get companionSettingsLoadError => 'Couldn\'t load settings.';

  @override
  String get companionSettingsSaveError => 'Couldn\'t save settings.';

  @override
  String get aiNotConnected => 'AI not connected';

  @override
  String get chooseProviderAndModel => 'Choose a provider and model.';

  @override
  String get connect => 'Connect';

  @override
  String get aiNotVerified => 'AI not verified';

  @override
  String get verifyConnectionAssistant =>
      'Test the connection to activate the assistant.';

  @override
  String get verify => 'Verify';

  @override
  String get aiUnavailable => 'AI unavailable';

  @override
  String get reviewProviderRetry => 'Review the provider and try again.';

  @override
  String get review => 'Review';

  @override
  String get waitingPhraseOne => 'I’m here when you’re ready.';

  @override
  String get waitingPhraseTwo => 'Take your time; we can continue here.';

  @override
  String get waitingPhraseThree => 'Whenever you’re ready, we’ll continue.';

  @override
  String get waitingPhraseFour => 'You can keep writing whenever it suits you.';

  @override
  String get logoDescription => 'TrackIA logo';

  @override
  String get chatArchive => 'Archive chat';

  @override
  String get chatArchives => 'Archived chats';

  @override
  String get chatSendToSheets => 'Send to Google Sheets';

  @override
  String get chatAiProvider => 'AI provider';

  @override
  String get chatConfigureAi => 'Set up AI';

  @override
  String get chatVerifyConnection => 'Verify connection · uses your API';

  @override
  String get chatTraining => 'Training';

  @override
  String get chatLoadSheets => 'Load Google Sheets';

  @override
  String get chatSheetPending => 'Interpret sheet with AI';

  @override
  String get chatWelcomePrompt =>
      'What would you like to do today? Tell me and we’ll plan it together.';

  @override
  String get chatLoadDataPrompt =>
      'Load your data with + whenever you like. AI can interpret its format once connected.';

  @override
  String get chatPrepareActivity => 'Prepare';

  @override
  String get chatWaitingModel => 'Waiting for the model…';

  @override
  String get chatDeferredArchive =>
      'The assistant will archive this chat when you return to the end.';

  @override
  String get chatGoLatest => 'Go to latest message';

  @override
  String get chatListening => 'Listening… Review the text and tap Send.';

  @override
  String get chatAttach => 'Attach';

  @override
  String get chatComposeHint => 'Type or dictate your message…';

  @override
  String get chatConnectAiHint => 'Connect AI to get started';

  @override
  String get chatStopDictation => 'Stop dictation';

  @override
  String get chatDictate => 'Dictate message';

  @override
  String get chatSend => 'Send';

  @override
  String get chatAssistantImageAlt => 'Image';

  @override
  String get chatInputDirections => 'Message text direction';

  @override
  String get activityStart => 'Start';

  @override
  String get activityStop => 'Stop';

  @override
  String get activityFinish => 'Finish';

  @override
  String get activityFinishDay => 'Finish day';

  @override
  String get activityChooseAnother => 'Choose another activity';

  @override
  String get activitySubtractCycle => 'Subtract cycle';

  @override
  String get activityAddCycle => 'Add completed cycle';

  @override
  String get activityNoticesOff => 'Notices are off';

  @override
  String get activityEnableNotices => 'Enable';

  @override
  String get activityCycles => 'Cycles';

  @override
  String get aiUnavailableFocus =>
      'AI unavailable · you can stop and save notes locally';

  @override
  String get activityRestInProgress => 'Rest in progress';

  @override
  String get activityRestChangeNoticePrompt =>
      'Do you also want to change the notice that is already scheduled?';

  @override
  String get activityKeepNotice => 'Keep notice';

  @override
  String get activityChangeNotice => 'Change notice';

  @override
  String get personalityInstructions => 'Personality and instructions';

  @override
  String get personalityInstructionsHelp =>
      'Describe the tone and how you want this companion to support you. This only affects its AI responses.';

  @override
  String get personalitySuggestionTone => 'Use a warm, clear tone.';

  @override
  String get personalitySuggestionAsk =>
      'Ask brief questions when details are missing.';

  @override
  String get personalitySuggestionAccuracy =>
      'Do not invent information or progress I have not shared.';

  @override
  String get personalityTooLong =>
      'Personality instructions cannot exceed 4,000 characters.';

  @override
  String get personalityDraftTitle => 'Personality draft';

  @override
  String get personalityDraftAccept => 'Use draft';

  @override
  String get personalityDraftButton => 'Help me write it';

  @override
  String get personalityDraftError =>
      'Could not generate a draft. Check the AI connection and try again.';

  @override
  String get activityTargetTitle => 'Set target';

  @override
  String get activityTargetLabel => 'Sets (empty to clear)';

  @override
  String get activityTargetInvalid =>
      'Enter a target from 1 to 100, or leave it empty.';

  @override
  String get activityTargetEditTooltip => 'Edit set target';

  @override
  String activityTargetPreservedProgress(Object target, Object completed) {
    return 'Target: $target. You keep all $completed completed sets.';
  }

  @override
  String get activityTargetUpdated => 'Target updated.';

  @override
  String get activityNoTarget => 'no target';

  @override
  String activityTargetChangedEvent(Object target) {
    return 'You changed the set target to $target';
  }

  @override
  String get chatTargetProposalAmbiguous =>
      'The target was not changed: the proposal is ambiguous or does not match an active activity.';

  @override
  String get chatTargetConfirmTitle => 'Change set target';

  @override
  String get chatTargetRemovePrompt => 'Do you want to remove the target?';

  @override
  String chatTargetSetPrompt(Object target) {
    return 'Do you want to set the target to $target sets?';
  }

  @override
  String chatTargetSetPromptWithProgress(Object target, Object completed) {
    return 'Do you want to set the target to $target sets? You have completed $completed; all progress will be kept.';
  }

  @override
  String get chatTargetConfirmButton => 'Change';

  @override
  String get chatTargetSavedNoTarget => 'Target saved: no target.';

  @override
  String chatTargetSaved(Object target) {
    return 'Target saved: $target sets.';
  }

  @override
  String chatTargetSavedWithProgress(Object target, Object completed) {
    return 'Target saved: $target sets. You keep all $completed completed sets.';
  }

  @override
  String get chatTargetStale =>
      'The target was not changed. The activity may have changed; review it and try again.';

  @override
  String get sheetsTitle => 'Your Google Sheets';

  @override
  String get sheetsChooseTitle => 'Choose your workout sheet';

  @override
  String get sheetsSearch => 'Search by name';

  @override
  String get sheetsSearchTooltip => 'Search';

  @override
  String get sheetsConnect => 'Connect to Google';

  @override
  String get sheetsReconnect => 'Change account or authorize again';

  @override
  String get sheetsNoResults =>
      'No sheets found. Try another name or switch accounts.';

  @override
  String get sheetsLoadMore => 'Load more sheets';

  @override
  String get dataTitle => 'Your data';

  @override
  String get dataCreateBackup => 'Create and share backup';

  @override
  String get dataRestoreBackup => 'Restore backup';

  @override
  String get aiProviderTitle => 'AI provider';

  @override
  String get aiConnectTitle => 'Connect your assistant';

  @override
  String get aiProviderLabel => 'Provider';

  @override
  String get sheetChooseTab => 'Choose the tab with your workouts';

  @override
  String get sheetReview => 'Review sheet';

  @override
  String sheetRowsRead(Object count) {
    return '$count rows read. The full tab will be loaded; the first 12 rows are shown here.';
  }

  @override
  String sheetRowsReadPreview(Object count) {
    return '$count rows read. Preview:';
  }

  @override
  String get sheetLoadPending =>
      'The sheet will be saved on this device, pending interpretation. AI is not needed to load it. Once connected, you can ask it to interpret the layout. Loading does not create workouts or send cells to the provider.';

  @override
  String get sheetSendToAi =>
      'When you tap Load and analyze, these cells will be sent to the configured AI provider. Rows are kept as shown and are not converted into workouts.';

  @override
  String get sheetReadOnlyGoogle =>
      'This is a read-only copy. To get later changes, use Refresh sheet in chat.';

  @override
  String get sheetReadOnlyFile =>
      'This is a read-only copy of the file. Load it again to get changes.';

  @override
  String get sheetsConnecting => 'Connecting to Google…';

  @override
  String get sheetsAuthorizeProgress =>
      'Choose your account and authorize Google read access…';

  @override
  String get sheetsSearchProgress => 'Searching for your sheets…';

  @override
  String sheetsLoadingTabs(Object name) {
    return 'Loading tabs in $name…';
  }

  @override
  String sheetsReadingTab(Object name) {
    return 'Reading $name…';
  }

  @override
  String get sheetsReadError => 'Could not read the sheet. Try again.';

  @override
  String get sheetsGoogleError => 'Could not connect to Google.';

  @override
  String get sheetsRetry => 'Reload sheets';

  @override
  String get sheetsPartial =>
      'Google returned partial search results. Search by sheet name.';

  @override
  String get sheetsAuthIncomplete =>
      'Google did not complete authorization. Tap Connect to Google to try again; your sheets have not been loaded.';

  @override
  String get sheetsSearchAccountChanged =>
      'The account changed during the search. Reconnect to continue.';

  @override
  String get sheetsChooseAccountChanged =>
      'The account changed while selecting. Reconnect to continue.';

  @override
  String get sheetsReadAccountChanged =>
      'The account changed while reading. No data was loaded.';

  @override
  String get sheetsNoTabs => 'This sheet has no available tabs.';

  @override
  String get sheetsReadRowsIntro =>
      'rows read. The full tab will be loaded; the first 12 rows are shown here.';

  @override
  String get syncTitle => 'Send to Google Sheets';

  @override
  String get syncIntro =>
      'Connect Google and choose your sheet once. Chat can check the latest data and send results; you can also review a manual send here.';

  @override
  String get syncNoSessions =>
      'There are no completed sessions to send. You can test the connection without starting an activity.';

  @override
  String get syncWorkout => 'Workout';

  @override
  String get syncConnectWrite => 'Connect Google and allow writing';

  @override
  String syncDestinationAccount(Object email) {
    return 'Destination account: $email';
  }

  @override
  String get syncCheckConnection => 'Check connection';

  @override
  String get syncDisconnect => 'Disconnect this sheet';

  @override
  String get syncChangeAccount => 'Change destination account';

  @override
  String get syncCreateNew => 'Create a new sheet';

  @override
  String get syncNewSheetName => 'New sheet name';

  @override
  String get syncCreateDrive => 'Create sheet in my Google Drive';

  @override
  String get syncSheet => 'Google sheet';

  @override
  String get syncTab => 'Tab';

  @override
  String get syncInstructions => 'Sheet preferences or notes';

  @override
  String get syncInstructionsHint => 'E.g. use the October block, total loads';

  @override
  String get syncAllowOverwrite => 'Allow updating cells that contain data';

  @override
  String get syncOverwriteHelp =>
      'The review shows the old and new values. Formulas are preserved.';

  @override
  String get syncAutomatic => 'Automatically send sessions when finished';

  @override
  String get syncAutomaticChatHelp =>
      'Chat sends remain available when automatic sending is paused.';

  @override
  String get syncAutomaticActivityHelp =>
      'Activity records do not identify their companion yet; you can request sends and edits from chat.';

  @override
  String get syncSavePreferences => 'Save connection and preferences';

  @override
  String get syncReviewLoadChat => 'Review and load sheet in chat';

  @override
  String get syncDiagnostics => 'Connection diagnostics';

  @override
  String get syncDiagnosticsHelp =>
      'Test the selected tab without starting an activity. The write test uses a temporary tab and does not change your workouts.';

  @override
  String get syncTestRead => 'Test reading with AI';

  @override
  String get syncTestWrite => 'Test writing with AI';

  @override
  String get syncPrepare => 'Prepare and review send';

  @override
  String get syncNoSheet => 'Choose a sheet and a tab.';

  @override
  String get syncNoValidWorkout =>
      'Choose a sheet, a tab, and a completed workout.';

  @override
  String get syncSessionUnavailable => 'The session is no longer available.';

  @override
  String get syncConnectionError =>
      'Could not retrieve the saved sheet. You can choose another.';

  @override
  String get syncOperationError =>
      'Could not complete the operation. Try again.';

  @override
  String get syncGoogleUnconfirmed => 'Google did not confirm the operation.';

  @override
  String get syncNameInvalid => 'Enter a name up to 80 characters long.';

  @override
  String get syncLoadChatTitle => 'Review sheet for chat';

  @override
  String get syncConfirmLoad => 'Confirm and load';

  @override
  String syncReadConfirmed(Object count, Object answer) {
    return 'Read confirmed: $count rows received from Google. Model response: $answer';
  }

  @override
  String syncWriteConfirmed(Object marker) {
    return 'Write confirmed: the model suggested “$marker”, Google accepted the test, and the temporary tab was deleted. No workouts were sent.';
  }

  @override
  String get syncSentConfirmed =>
      'Workout sent to Google Sheets. Receipt verified; sending again will not duplicate it.';

  @override
  String get syncReturnChat => 'Return to chat';

  @override
  String syncDestination(Object name, Object tab) {
    return 'Destination: $name / $tab';
  }

  @override
  String get syncReceiptNote =>
      'Google will also save a receipt of the send to prevent duplicates.';

  @override
  String syncReviewCount(Object count) {
    return '$count cells. The app will check they have not changed since this review.';
  }

  @override
  String get syncOriginalData => 'View original workout data';

  @override
  String get syncConfirmSend => 'Confirm and send to Google Sheets';

  @override
  String get syncDiscard => 'Discard proposal';

  @override
  String get sheetNoTabs => 'This sheet has no available tabs.';

  @override
  String get sheetsLoad => 'Load sheet';

  @override
  String get sheetsLoadAnalyze => 'Load and analyze';

  @override
  String get rowLabel => 'Row';

  @override
  String get syncProposedSessionInvalid =>
      'The proposed session is not finished or does not belong to this profile. Choose a valid session.';

  @override
  String get syncConnectionSaved =>
      'Connection saved. Chat will read the current sheet and can send results without asking for authorization each time.';

  @override
  String get syncIdentityUnconfirmed =>
      'Could not confirm the selected Google account.';

  @override
  String get sheetAllRowsWillLoad => 'All rows in the tab will be loaded.';

  @override
  String get syncAccountChangedReview =>
      'The account changed while you reviewed the tab. The previous sheet is preserved; reconnect to load it.';

  @override
  String syncLoadedIntoChat(Object name, Object tab) {
    return 'Sheet loaded in chat: $name / $tab.';
  }

  @override
  String get syncConfigureAi => 'Set up AI first to test model access.';

  @override
  String get syncModelEmpty => 'The model returned no response.';

  @override
  String get syncInvalidMarker =>
      'The model responded but did not provide a valid test marker.';

  @override
  String get syncWorkoutChanged =>
      'The workout changed. Prepare the send again to review the current data.';

  @override
  String get syncRefreshAfterSendFailed =>
      'Send confirmed. The chat copy could not be refreshed; reload the sheet to see its latest data.';

  @override
  String syncReceiptSent(Object workout, Object id, Object name, Object tab) {
    return 'Google Sheets confirmed: workout “$workout” ($id) sent to “$name / $tab”. Google receipt confirms the send.';
  }

  @override
  String syncReceiptCreated(Object name, Object tab) {
    return 'Google Sheets confirmed: sheet “$name” created, tab “$tab”. Progress has not been sent yet.';
  }

  @override
  String get sheetsAssistantIntro =>
      'Connect your account, choose the sheet and tab, and review the data before sharing it with your assistant.';

  @override
  String get sheetsImportIntro =>
      'TrackIA uses Google authorization to read your sheets. Data is saved on this device when you confirm the import.';

  @override
  String get sheetsErrorExpired =>
      'Google authorization expired. Reconnect your account.';

  @override
  String get sheetsErrorPermission =>
      'Google does not allow this operation. Check access and sheet permissions.';

  @override
  String get sheetsErrorAccount =>
      'The read does not match the authorized account. Reconnect from your profile.';

  @override
  String get sheetsErrorNotFound =>
      'The sheet is no longer available to this account.';

  @override
  String get sheetsErrorRateLimit =>
      'Google received too many requests. Wait a moment and try again.';

  @override
  String get sheetsErrorNetwork =>
      'Could not confirm the operation with Google. Local progress is preserved; retrying will check the receipt.';

  @override
  String get sheetsErrorTooLarge =>
      'The tab is over 20 MB. Choose a smaller tab.';

  @override
  String get sheetsErrorGeneric =>
      'Google could not complete the operation. Try again.';

  @override
  String get sheetsErrorBusy =>
      'A Google operation is already in progress. Wait for it to finish.';

  @override
  String syncBeforeValue(Object value) {
    return 'Before: $value';
  }

  @override
  String get syncEmptyCell => '(empty)';

  @override
  String get syncDisconnected =>
      'Sheet disconnected. Local data and pending sends are preserved.';

  @override
  String get aiProviderDescription =>
      'Choose a cloud provider or run a model locally on this device. Local models can work offline; performance depends on available memory and the model.';

  @override
  String get aiConfigReadError => 'Could not read the saved configuration.';

  @override
  String aiModelImportError(Object error) {
    return 'Could not import the GGUF file: $error';
  }

  @override
  String get aiMemoryAvailableNow => 'Available now';

  @override
  String get aiMemoryAfterModel => 'After model and projector';

  @override
  String get aiMemoryAfterContext => 'After + selected context';

  @override
  String aiMemoryContextEstimate(
    Object context,
    Object minimum,
    Object maximum,
  ) {
    return 'The $context context would use approximately $minimum–$maximum of RAM.';
  }

  @override
  String aiMemoryShortfall(Object amount) {
    return 'The estimate exceeds available memory by $amount.';
  }

  @override
  String get aiMemoryEstimateHelp =>
      'Approximate estimate for model weights and projector; the selected context adds memory use, which varies by model.';

  @override
  String get aiConnectedChooseModel =>
      'Account connected. Choose a model and test the connection to use the assistant.';

  @override
  String get aiIdentityConnected =>
      'Identity connected. You can separately authorize use of your ChatGPT plan.';

  @override
  String get aiChatGptDisconnected => 'ChatGPT session disconnected.';

  @override
  String get aiChatGptRemoteRevocationUnconfirmed =>
      'Signed out on this device. Remote revocation was not confirmed; also disconnect TrackIA in ChatGPT settings.';

  @override
  String aiOperationError(Object details) {
    return 'Could not complete the operation$details';
  }

  @override
  String aiOperationDetails(Object error) {
    return ': $error';
  }

  @override
  String get aiNoModelImported => 'No model imported.';

  @override
  String get aiSelectImportGguf => 'Select / import .gguf model';

  @override
  String get aiLocalContextTitle => 'Local model context';

  @override
  String aiLocalContextHelp(Object context) {
    return 'TrackIA recommends $context for its instructions, history, and data. This recommendation covers the app’s needs, not this GGUF’s limit. If the model does not support the selected size, it may fail; you can lower it.';
  }

  @override
  String aiContextSelected(Object context) {
    return 'Selected: $context';
  }

  @override
  String get aiUseRecommendation => 'Use recommendation';

  @override
  String get aiVisualProjector => 'Vision projector (optional)';

  @override
  String get aiProjectorHelp =>
      'Add this to use images. MiniCPM‑V requires the matching mmproj GGUF file.';

  @override
  String get aiNoProjector => 'No vision projector.';

  @override
  String get aiSelectProjector => 'Select mmproj projector';

  @override
  String get aiMemoryHelp =>
      'Available memory is shown separately. The 8192-token recommendation reflects TrackIA’s needs; the GGUF may not support it, and you can choose another size.';

  @override
  String get aiRecalculateMemory => 'Recalculate available memory';

  @override
  String get aiApiBase => 'API base URL';

  @override
  String get aiHttpsExample =>
      'HTTPS, for example https://your-provider.com/v1';

  @override
  String get aiChatGptPlanHelp =>
      'Use your plan if your account and workspace are eligible. Usage counts toward shared limits. This does not provide access to your ChatGPT conversations.';

  @override
  String get aiChatGptAccount => 'ChatGPT account';

  @override
  String get aiChatGptConnectedPlan => 'Connected · plan usage authorized';

  @override
  String get aiChatGptConnectedIdentity => 'Connected · identity only';

  @override
  String get aiChatGptNotConnected => 'ChatGPT not connected';

  @override
  String get aiContinueChatGpt => 'Continue with ChatGPT';

  @override
  String get aiReviewPlanPermission => 'Review plan usage permission';

  @override
  String get aiAuthorizePlan => 'Authorize use of my ChatGPT plan';

  @override
  String get aiAddAccount => 'Add another account or workspace';

  @override
  String get aiViewUsagePermissions => 'View usage and permissions in ChatGPT';

  @override
  String get aiDisconnectChatGpt => 'Disconnect ChatGPT';

  @override
  String get aiCancelConnection => 'Cancel connection';

  @override
  String get aiApiKey => 'API key';

  @override
  String get aiHideKey => 'Hide key';

  @override
  String get aiShowKey => 'Show key';

  @override
  String get aiFetchModels => 'Get / refresh models';

  @override
  String get aiLoadingModels => 'Loading models…';

  @override
  String get aiModelLabel => 'Model';

  @override
  String get aiChooseCatalogModel => 'Choose a model from the catalog';

  @override
  String aiCurrentModelPreserved(Object model) {
    return 'Current model: $model. It is kept even if it does not appear in the catalog.';
  }

  @override
  String get aiHideManualId => 'Hide manual identifier';

  @override
  String get aiEnterManualModel => 'Enter model manually';

  @override
  String get aiModelIdentifier => 'Model identifier';

  @override
  String get aiOpenCodeNotice =>
      'Go is intended for coding agents. This connection identifies itself as TrackIA; check with your provider that this use is supported. It will not switch automatically to Zen or another service.';

  @override
  String get aiApiSettings => 'API settings';

  @override
  String get aiHttpsBase => 'HTTPS base URL';

  @override
  String get aiProtocol => 'Model-compatible format';

  @override
  String get aiConfigSaved => 'Configuration saved.';

  @override
  String get aiSaveLocalModel => 'Save local model';

  @override
  String get aiSaveProvider => 'Save provider';

  @override
  String aiProviderResponded(Object answer) {
    return 'Provider response:\n$answer';
  }

  @override
  String get aiTestLocalModel => 'Test model on this device';

  @override
  String get aiTestChatGpt => 'Test connection · uses my ChatGPT plan';

  @override
  String get aiTestApi => 'Test connection · uses your API';

  @override
  String get aiConfigDeleted => 'Configuration and key deleted.';

  @override
  String get aiDeleteConfig => 'Delete configuration and key';

  @override
  String appVersion(Object version) {
    return 'Version $version';
  }

  @override
  String get activityIdleOtherActive => 'Another companion is active';

  @override
  String get activityIdleNoActivity => 'No activity';

  @override
  String get activityIdleEndOther => 'End the other activity to start here';

  @override
  String get activityIdleRegisterAnytime => 'Log one whenever you like';

  @override
  String get activityNewActivity => 'New activity';

  @override
  String get activityIdleRecord => 'Log';

  @override
  String get activityRestLabel => 'Rest';

  @override
  String get activityRestDone => 'Rest finished';

  @override
  String get activityRestPaused => 'Rest paused';

  @override
  String get activityRestPause => 'Pause';

  @override
  String get activityRestContinue => 'Continue';

  @override
  String get activityRestStart => 'Start rest';

  @override
  String get activityRestRestart => 'Restart rest';

  @override
  String activityRestAdjust(int seconds) {
    return '${seconds}s · Adjust';
  }

  @override
  String get activityRestNotice =>
      'Alert with this screen open; time keeps running when you leave.';

  @override
  String get activityRestDurationTitle => 'Rest time';

  @override
  String get activityRestSecondsLabel => 'Seconds';

  @override
  String get activityRestRangeHint =>
      'Between 5 and 1800 seconds. When applied, the timer is ready to start.';

  @override
  String get activityRestApply => 'Apply';

  @override
  String get activityDialogNameTitle => 'Activity name';

  @override
  String get activityDialogSaveName => 'Save name';

  @override
  String get activityDialogRestRange => 'Between 0 and 1800';

  @override
  String get activityDialogWhatToDo => 'What are you going to do?';

  @override
  String get activityDialogYourActivities => 'Your activities';

  @override
  String get activityDialogInstantRecord => 'One-off record';

  @override
  String get activityDialogYourActivity => 'Your activity';

  @override
  String get activityDialogFromCurrentWorkout => 'From the current workout';

  @override
  String activityDialogSetsProgress(
    Object done,
    Object target,
    Object repsMin,
    Object repsMax,
  ) {
    return '$done/$target sets · $repsMin–$repsMax reps';
  }

  @override
  String get activityDialogRepeat => 'Repeat';

  @override
  String activityDialogRoutineSets(Object routine, int sets) {
    return '$routine · $sets sets';
  }

  @override
  String get activityDialogEndTitle => 'End activity';

  @override
  String get activityDialogDate => 'Date';

  @override
  String get activityDialogTime => 'Time';

  @override
  String get activityBuilderNameRequired => 'Enter a name for the activity.';

  @override
  String get activityBuilderOnlyIntegers => 'Enter whole numbers only.';

  @override
  String activityBuilderRange(Object what, int min, int max) {
    return '$what must be from $min to $max.';
  }

  @override
  String get activityBuilderWhatDuration => 'Duration';

  @override
  String get activityBuilderWhatRest => 'Rest';

  @override
  String get activityBuilderWhatSegments => 'Planned segments';

  @override
  String get activityBuilderWhatCycles => 'Planned cycles';

  @override
  String get activityBuilderDurationRequired =>
      'Enter the duration in minutes.';

  @override
  String get activityBuilderSegmentNamesPair =>
      'Enter the singular and plural names of a segment, or leave both empty.';

  @override
  String get activityBuilderFromTemplate => 'Start from a template';

  @override
  String get activityBuilderHowMeasured => 'How is it measured?';

  @override
  String get activityBuilderInstantTitle => 'One-off';

  @override
  String get activityBuilderInstantDetail => 'A record without a timer';

  @override
  String get activityBuilderFreeTitle => 'Open';

  @override
  String get activityBuilderFreeDetail => 'Stopwatch, no countdown';

  @override
  String get activityBuilderTimedTitle => 'Timed';

  @override
  String get activityBuilderTimedDetail => 'Countdown of a fixed time';

  @override
  String get activityBuilderSegmentsTitle => 'In segments';

  @override
  String get activityBuilderSegmentsDetail => 'Several segments with rest';

  @override
  String get activityBuilderDuration => 'Duration (minutes)';

  @override
  String get activityBuilderSegmentHelper => 'Optional: for each segment';

  @override
  String get activityBuilderPlannedSegments => 'Planned segments (optional)';

  @override
  String get activityBuilderRestBetween => 'Rest between segments (seconds)';

  @override
  String get activityBuilderRestHelper => '90 is a minute and a half';

  @override
  String get activityBuilderPlannedCycles => 'Planned cycles (optional)';

  @override
  String get activityBuilderSegmentSingular => 'One segment is called';

  @override
  String get activityBuilderSegmentPlural => 'Several are called';

  @override
  String get activityBuilderWhatToNote =>
      'What do you want to note? (optional)';

  @override
  String activityBuilderRemoveField(Object label) {
    return 'Remove $label';
  }

  @override
  String get activityBuilderMaxFields => 'Maximum 12 fields';

  @override
  String get activityBuilderAddField => 'Add field';

  @override
  String get activityBuilderSaveInActivities => 'Save to your activities';

  @override
  String get activityBuilderSaveInActivitiesHelp =>
      'To repeat it without creating it again.';

  @override
  String get activityBuilderPrepare => 'Prepare activity';

  @override
  String get activityBuilderNewField => 'New field';

  @override
  String get activityBuilderFieldNameRequired =>
      'Enter a field name of up to 80 characters.';

  @override
  String get activityBuilderFieldName => 'Field name';

  @override
  String get activityBuilderFieldType => 'Type';

  @override
  String get activityBuilderFieldUnit => 'Unit (optional)';

  @override
  String get activityBuilderOptions => 'Options';

  @override
  String get activityBuilderOptionsHelp => 'Separated by commas';

  @override
  String get activityBuilderScaleMin => 'Minimum';

  @override
  String get activityBuilderScaleMax => 'Maximum';

  @override
  String get activityBuilderScaleRange =>
      'Enter the minimum and maximum of the scale.';

  @override
  String get activityBuilderAggregate => 'How it counts';

  @override
  String get activityBuilderCountSingular => 'Counted as (one)';

  @override
  String get activityBuilderCountSingularHelp => 'Optional, e.g. book';

  @override
  String get activityBuilderCountPlural => 'Counted as (many)';

  @override
  String get activityBuilderCountPluralHelp => 'Optional, e.g. books';

  @override
  String get activityBuilderAdd => 'Add';

  @override
  String get aiPerReadError => 'Could not read the per-companion settings.';

  @override
  String get aiPerSaveError => 'Could not save the change.';

  @override
  String get aiPerTitle => 'Per companion';

  @override
  String get aiPerNoProvider =>
      'Connect a provider first to choose a different model for each companion.';

  @override
  String get aiPerHelp =>
      'Each companion uses your provider, or its own model from that same provider.';

  @override
  String get aiPerDefault => 'Default';

  @override
  String aiPerDialogTitle(Object name) {
    return 'AI for $name';
  }

  @override
  String aiPerDialogHelp(Object service) {
    return 'Uses $service with your profile\'s key. It only changes this companion\'s model.';
  }

  @override
  String get aiPerUseDefault => 'Use default';

  @override
  String get aiSetAndroidFileAccess =>
      'Android did not provide access to the selected file.';

  @override
  String get aiSetGgufTitle => 'GGUF model';

  @override
  String aiSetLocalContextHelp(Object context) {
    return 'TrackIA recommends $context for its instructions, history and data. The recommendation covers the app\'s needs, not this GGUF\'s limit. If the model does not support the chosen size, it may fail; you decide whether to lower it.';
  }

  @override
  String aiSetModelsCountChatGpt(int count) {
    return 'Models available for this account: $count. The connection test confirms access to the one you pick.';
  }

  @override
  String aiSetCatalogCountApi(int count) {
    return '$count models fetched from the provider. The connection test confirms whether your key can use the one you pick.';
  }

  @override
  String get aiSetCatalogErrorChatGpt =>
      'Could not load the model list for this account. Check the connection and try again.';

  @override
  String get aiSetCatalogErrorApi =>
      'Could not load the model list. You can try again or enter the model manually.';

  @override
  String get transferSheetReadError => 'Could not read the sheet.';

  @override
  String get transferSheetTooLarge => 'The sheet is larger than 20 MB.';

  @override
  String get transferSheetLoadError => 'Could not load the sheet. Try again.';

  @override
  String get transferSheetLoaded =>
      'Sheet loaded. Waiting for the AI to interpret it.';

  @override
  String get transferFileTooLarge => 'The file is larger than 20 MB.';

  @override
  String get transferSheetSelectedError => 'Could not read the selected sheet.';

  @override
  String get transferFileReadError => 'Could not read or share the file.';

  @override
  String get transferDefaultSheetName => 'Loaded sheet';

  @override
  String get transferShareSubject => 'TrackIA backup';

  @override
  String get transferShareText => 'Save this file to Drive or somewhere safe.';

  @override
  String get transferRestoreTitle => 'Restore this backup?';

  @override
  String transferRestoreBody(int workouts, int routines, Object active) {
    String _temp0 = intl.Intl.pluralLogic(
      workouts,
      locale: localeName,
      other: '$workouts sessions',
      one: '1 session',
    );
    String _temp1 = intl.Intl.pluralLogic(
      routines,
      locale: localeName,
      other: '$routines routines',
      one: '1 routine',
    );
    return 'It contains $_temp0 and $_temp1$active. It will replace all the data currently on this phone. Save a current backup first if you want to keep it.';
  }

  @override
  String get transferRestoreActive => ', including a session in progress';

  @override
  String get transferRestoreAction => 'Restore';

  @override
  String get transferRestored =>
      'Backup restored. Sessions and routines updated.';

  @override
  String get transferNoAccessSheet =>
      'Could not read that sheet. In Google Sheets, use “Send a copy” as Excel or CSV and choose TrackIA.';

  @override
  String get transferHeadline => 'Your history, under your control';

  @override
  String get transferIntro =>
      'Keep a copy off this phone so you can restore it or move it to another phone.';

  @override
  String get transferBackupTitle => 'Backup';

  @override
  String get transferBackupHelp =>
      'Includes history, routines and the session in progress.';

  @override
  String get transferSheetsTitle => 'Google Sheets history';

  @override
  String get transferSheetsHelpAndroid =>
      'Load your sheet and tab with Google\'s permission, or choose an Excel or CSV copy. The original cells are kept; the AI will be able to interpret your format once connected.';

  @override
  String get transferSheetsHelpOther =>
      'Load an Excel or CSV copy. The original cells are kept, pending interpretation by the AI.';

  @override
  String get transferImportSheets => 'Import from Google Sheets';

  @override
  String get transferChooseFileAndroid =>
      'Choose a file from the phone or Drive';

  @override
  String get transferChooseFileOther => 'Choose an XLSX or CSV copy';

  @override
  String transferWorkoutSubtitle(Object date, int exercises, int sets) {
    return '$date · $exercises exercises · $sets sets';
  }

  @override
  String get transferNoColumnWorkout => 'No column · Workout';

  @override
  String get transferChooseColumn => 'Choose column';

  @override
  String get transferCsvReviewError => 'Could not check the CSV.';

  @override
  String get transferImportSessionsTitle => 'Import these sessions?';

  @override
  String transferImportSessionsBody(int count, int sets, int errors) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0 will be added with $sets sets. Rows skipped due to errors: $errors.';
  }

  @override
  String get transferImportAction => 'Import';

  @override
  String get transferImportError => 'Could not import.';

  @override
  String get transferImportSheetTitle => 'Import sheet';

  @override
  String transferImportedSummary(int added, int duplicates) {
    return 'Sessions imported: $added · Duplicates skipped: $duplicates';
  }

  @override
  String transferRowsFound(int count) {
    return '$count rows found';
  }

  @override
  String get transferMapHelp =>
      'Match your sheet\'s columns. One row is one set.';

  @override
  String get transferDate => 'Date';

  @override
  String get transferSessionOptional => 'Session (optional)';

  @override
  String get transferExercise => 'Exercise';

  @override
  String get transferWeightKg => 'Weight (kg)';

  @override
  String get transferReps => 'Reps';

  @override
  String get transferReviewImport => 'Review import';

  @override
  String transferPreviewSummary(
    int newCount,
    int duplicateCount,
    int errorCount,
  ) {
    return 'New sessions: $newCount · Duplicates: $duplicateCount · Rows with errors: $errorCount';
  }

  @override
  String transferValidRows(int valid, int total) {
    return '$valid valid sets from $total rows.';
  }

  @override
  String get transferAllSessions => 'All sessions';

  @override
  String transferSeeSessions(int count) {
    return 'View all $count sessions';
  }

  @override
  String get transferErrorRows => 'Rows with errors';

  @override
  String transferSeeErrors(int count) {
    return 'View all $count errors';
  }

  @override
  String get transferImportNew => 'Import new sessions';

  @override
  String get transferCloseAction => 'Close';

  @override
  String get chatAttachVoiceError =>
      'Couldn\'t recognize speech. Check the microphone permission or type your message.';

  @override
  String get chatAttachVoiceUnavailable =>
      'Speech recognition isn\'t available. Check the microphone permission and the phone\'s speech service.';

  @override
  String get chatAttachDictationStart => 'Couldn\'t start dictation.';

  @override
  String get chatAttachCamera => 'Camera';

  @override
  String get chatAttachPhotos => 'Photos';

  @override
  String get chatAttachPdf => 'PDF document';

  @override
  String get chatAttachPdfHint => 'Needs a model that supports documents';

  @override
  String get chatAttachAudio => 'Audio file';

  @override
  String get chatAttachAudioHint =>
      'Requires a Gemini model that supports audio';

  @override
  String get chatAttachSpreadsheet => 'Excel or CSV sheet';

  @override
  String get chatAttachSheet => 'Google Sheets / Drive';

  @override
  String get chatAttachNeedsAi =>
      'Connect AI to send images, documents or audio. You can load a sheet without AI.';

  @override
  String get chatAttachPhotoTooLarge => 'The photo is larger than 4 MB.';

  @override
  String get chatAttachPhotoFormat => 'Choose a JPG, PNG or WebP photo.';

  @override
  String get chatAttachPhotoEmpty =>
      'The photo must have content and be no larger than 4 MB.';

  @override
  String get chatAttachAudioNeedsGemini =>
      'To send an audio file, set up a Gemini model with audio. You can use the chat microphone to dictate your message.';

  @override
  String get chatAttachTooLarge => 'The attachment is larger than 4 MB.';

  @override
  String get chatAttachUnreadable => 'Couldn\'t read the attachment.';

  @override
  String get chatAttachFormat => 'Unsupported attachment format.';

  @override
  String get chatAttachInvalidPdf => 'The file doesn\'t contain a valid PDF.';

  @override
  String get chatAttachOpenFailed => 'Couldn\'t open the attachment.';

  @override
  String get chatAttachRecoveredTooLarge =>
      'The recovered photo is larger than 4 MB. Choose a smaller one.';

  @override
  String get chatMenuCompanionsError => 'Couldn\'t load the companions.';

  @override
  String get chatMenuMore => 'More options';

  @override
  String get chatMenuTraining => 'Routines and history';

  @override
  String get chatMenuProgress => 'Progress';

  @override
  String get chatMenuSheet => 'Loaded sheet';

  @override
  String get chatMenuRecover => 'Recover preparation';

  @override
  String get chatSendFocusTooLong =>
      'The entry is longer than 8000 characters.';

  @override
  String get chatSendSavedNoAi =>
      'Entry saved on the phone. AI isn\'t available to interpret it.';

  @override
  String get chatSendSavedNoProvider =>
      'Entry saved on the phone. Set up the provider to ask the assistant.';

  @override
  String get chatSendAssistantError =>
      'Couldn\'t reach the assistant. Check the local record.';

  @override
  String get chatSendQueueUnavailable =>
      'The durable queue isn\'t available. Keep your text and reopen the chat.';

  @override
  String get chatSendTooLong => 'The message is longer than 8000 characters.';

  @override
  String get chatSendConfigureProvider =>
      'Set up the provider with the settings button to start.';

  @override
  String get chatSendSaveError =>
      'Couldn\'t save the message on the phone. Keep your text and try again.';

  @override
  String get chatSendProposalIncomplete =>
      'The model sent an incomplete proposal. Ask it to prepare the exercise again so Start appears.';

  @override
  String get chatSendAnswerSaveError =>
      'The reply arrived, but the conversation couldn\'t be saved on the phone.';

  @override
  String get chatSendFailed =>
      'Couldn\'t complete the conversation. You can try again.';

  @override
  String get chatMsgOnlyLastEditable =>
      'Only the last message can be edited. Write a correction as a new message.';

  @override
  String get chatMsgPending => 'Waiting to send';

  @override
  String get chatMsgSending => 'Sending';

  @override
  String get chatMsgAnswered => 'Answered';

  @override
  String get chatMsgFailed => 'Not accepted; you can resend';

  @override
  String get chatMsgUncertain =>
      'Uncertain result; resending blocked until reviewed';

  @override
  String get chatMsgHistory => 'History';

  @override
  String get chatMsgResend => 'Resend';

  @override
  String get chatMsgAiNotReady => 'AI isn\'t ready.';

  @override
  String get chatMsgSendInProgress => 'A send is in progress.';

  @override
  String get chatMsgChangedWhileEditing =>
      'The message changed while you were editing it. Check the history.';

  @override
  String get chatMsgSaveNotSent =>
      'Edit saved, but it couldn\'t be sent now. Use Resend when you can.';

  @override
  String get chatMsgSavedOnly => 'Edit saved. Use Resend to send this version.';

  @override
  String get chatMsgLengthError => 'Write a message of 1 to 8000 characters.';

  @override
  String get chatMsgEditError =>
      'Couldn\'t save the edit; the original is kept.';

  @override
  String get chatMsgHistoryTitle => 'Version history';

  @override
  String chatMsgVersion(int n) {
    return 'Version $n';
  }

  @override
  String chatMsgVersionCurrent(int n) {
    return 'Version $n · current';
  }

  @override
  String get chatMsgClose => 'Close';

  @override
  String get chatMsgHistoryError => 'Couldn\'t open the history.';

  @override
  String get chatMsgEditTitle => 'Edit message';

  @override
  String get chatMsgEditLabel => 'Corrected text';

  @override
  String get chatMsgEditHelper =>
      'The original version is kept in the history.';

  @override
  String chatMsgSendBlocked(Object reason) {
    return 'Can\'t send right now: $reason';
  }

  @override
  String get chatMsgSaveAndSend => 'Save and send';

  @override
  String get chatSheetReloadError => 'Couldn\'t recover the loaded sheet.';

  @override
  String get chatSheetAndroidOnly =>
      'The Google Sheets connection is available on Android.';

  @override
  String get chatSheetSaveError =>
      'Couldn\'t save the sheet on the phone. The previous copy is kept.';

  @override
  String get chatSheetInterpretPending =>
      'The reply arrived, but the sheet is still waiting to be interpreted on the phone.';

  @override
  String get chatSheetRefreshError =>
      'Couldn\'t update the sheet. The previous copy is kept.';

  @override
  String get chatSheetRemoveError => 'Couldn\'t remove the sheet copy.';

  @override
  String chatSheetDialogBody(
    Object title,
    int rows,
    Object date,
    Object status,
  ) {
    return '$title · $rows rows\nLast read: $date.\n\n$status';
  }

  @override
  String get chatSheetStatusPending =>
      'Waiting for AI interpretation. No workouts have been imported.';

  @override
  String get chatSheetStatusAnalyzed =>
      'The assistant has analyzed this copy; no workouts have been imported.';

  @override
  String get chatSheetRemove => 'Remove from context';

  @override
  String get chatSheetChange => 'Change sheet';

  @override
  String get chatSheetRefresh => 'Update sheet';

  @override
  String chatSheetLabel(Object title) {
    return 'Sheet · $title';
  }

  @override
  String chatProposalRepeated(int seconds) {
    return 'Sets / intervals · ${seconds}s rest';
  }

  @override
  String chatProposalContinuous(int seconds) {
    return 'Continuous activity · ${seconds}s rest';
  }

  @override
  String chatSheetPendingInfo(Object name) {
    return '«$name» loaded · waiting for interpretation. The original data is kept.';
  }

  @override
  String get chatGameFocusOpen =>
      'Finish the activity open with the other companion before preparing this one.';

  @override
  String get chatGamePrepareError =>
      'Couldn\'t prepare the activity. Try again.';

  @override
  String chatGameGoalTitle(Object goal) {
    return 'Proposed goal: $goal';
  }

  @override
  String chatGameAchievementTitle(Object title) {
    return 'Proposed achievement: $title';
  }

  @override
  String get chatGameCopyTitle => 'Proposed reminder texts';

  @override
  String get chatDeliveryQueueError =>
      'Couldn\'t open the chat\'s durable queue. Messages won\'t be sent through alternative storage.';

  @override
  String get chatDeliveryRestoredPending =>
      'Your message was saved without a reply. You can send it again.';

  @override
  String get chatDeliveryUncertain =>
      'A send has an uncertain result. It won\'t be resent automatically; check the history before deciding.';

  @override
  String get chatDeliveryBacklog =>
      'You have saved messages without a reply. Use Resend when you want; they won\'t be sent automatically.';

  @override
  String get chatDeliveryOtherChat =>
      'The message belongs to another chat and won\'t be sent here.';

  @override
  String get chatDeliveryNotSafe => 'This message isn\'t safe to resend.';

  @override
  String get chatDeliveryStateChanged =>
      'The message has already changed status; no other send was made.';

  @override
  String get chatDeliveryUncertainSend =>
      'The send result is uncertain. It won\'t be resent automatically; check whether a reply arrived.';

  @override
  String get chatDeliveryFailed =>
      'Couldn\'t complete the conversation. The message stays saved; it won\'t be resent automatically.';

  @override
  String get chatArchiveIncompleteDirective =>
      'The model asked to archive with incomplete data. The chat stays open.';

  @override
  String get chatArchiveDoneAuto =>
      'The assistant archived the chat. You can view it in Archived chats.';

  @override
  String get chatArchiveDone =>
      'Chat archived. The active context has been cleared.';

  @override
  String get chatArchiveViewAction => 'View archives';

  @override
  String get chatArchiveError =>
      'Couldn\'t archive. The conversation and workouts are kept.';

  @override
  String get chatArchiveSyncInvalid =>
      'The sending proposal isn\'t valid. Use Send to Google Sheets in the menu.';

  @override
  String get chatArchiveRecalled =>
      'Archive available for your next message to the assistant.';

  @override
  String get chatArchiveReadError => 'Couldn\'t open the archive.';

  @override
  String get chatDraftSaveError =>
      'Couldn\'t save the draft. Keep your text and try again.';

  @override
  String get chatLoadError => 'Couldn\'t recover the previous conversation.';

  @override
  String get chatLoadSheetError =>
      'Couldn\'t recover the saved sheet. Load it again from Google Sheets.';

  @override
  String get chatPersistTooLarge =>
      'The chat is over 20 MB; it couldn\'t be saved in full.';

  @override
  String get creatorCreate => 'Create';

  @override
  String get creatorCreateFailed =>
      'The companion couldn\'t be created. Nothing was saved.';

  @override
  String get creatorAssistedTitle => 'Create with AI help';

  @override
  String get creatorAiTitle => 'With AI help';

  @override
  String get creatorAiReadySubtitle =>
      'Tell it what you want to keep up with and it will suggest a companion.';

  @override
  String get creatorAiNotReadySubtitle =>
      'You need to connect and verify an AI provider.';

  @override
  String get creatorOpenAiSettings => 'Open AI settings';

  @override
  String get creatorManualTitle => 'By hand';

  @override
  String get creatorManualSubtitle =>
      'Choose the name, icon, colour, mode and notice yourself.';

  @override
  String get creatorNewTitle => 'New companion';

  @override
  String get creatorEditProposalTitle => 'Edit proposal';

  @override
  String get creatorNameLength =>
      'Enter a name of between 1 and 40 characters.';

  @override
  String get creatorLevelReminderTitle => 'Reminder only';

  @override
  String get creatorLevelReminderDetail => 'It just reminds you.';

  @override
  String get creatorLevelGoalsTitle => 'Goals and streaks';

  @override
  String get creatorLevelGoalsDetail =>
      'Recommended: goals and streaks, no achievements.';

  @override
  String get creatorLevelGameTitle => 'Full game';

  @override
  String get creatorLevelGameDetail => 'Goals, streaks and achievements.';

  @override
  String creatorActivityLabel(Object name) {
    return 'What you log: $name';
  }

  @override
  String get creatorRemoveActivity => 'Remove activity';

  @override
  String creatorGoalLabel(Object text) {
    return 'Goal: $text';
  }

  @override
  String get creatorRemoveGoal => 'Remove goal';

  @override
  String get creatorRemind => 'Remind me';

  @override
  String get creatorDecideOnStart => 'you decide when you start';

  @override
  String get creatorPunctualSuffix => ' · one-off entry';

  @override
  String get creatorNoGoal => 'no goal';

  @override
  String get creatorNoReminder => 'no notice';

  @override
  String creatorReminderLabel(Object text) {
    return 'Notice: $text';
  }

  @override
  String creatorLevelLabel(Object text) {
    return 'Level: $text';
  }

  @override
  String get creatorDiscard => 'Discard';

  @override
  String get creatorNoAiConnected => 'No AI is connected.';

  @override
  String get creatorConversationFailed =>
      'The conversation couldn\'t be completed. You can try again.';

  @override
  String get creatorInputHint => 'Type here';

  @override
  String get creatorPromptHelper =>
      'They are used once you connect a provider.';

  @override
  String get creatorLevelSection => 'Level';

  @override
  String get proposalIgnore => 'Ignore';

  @override
  String get proposalAdd => 'Add';

  @override
  String get proposalUseTexts => 'Use these texts';

  @override
  String get proposalSuggestLater => 'Not now';

  @override
  String get proposalSuggestNever => 'Don\'t suggest again';

  @override
  String get proposalLockedTitle => 'AI proposal about data you locked';

  @override
  String get proposalApply => 'Apply';

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
  String get proposalLockLabel => 'Locked by you. Tap to release';

  @override
  String get homeNewWorkoutTitle => 'New workout';

  @override
  String get homeSessionNameLabel => 'Session name';

  @override
  String get homeWorkout => 'Workout';

  @override
  String get homeAddExerciseTitle => 'Add exercise';

  @override
  String get homeExerciseNameLabel => 'Exercise name';

  @override
  String get homeAdd => 'Add';

  @override
  String get homeBack => 'Back';

  @override
  String get homeYourSession => 'Your session';

  @override
  String get homeAssistantTooltip => 'TrackIA assistant';

  @override
  String get homeReload => 'Reload';

  @override
  String get homeLoadLog => 'Load log';

  @override
  String get homeHeroTitle => 'Your effort.\nYour progress.';

  @override
  String get homeHeroSubtitle =>
      'One set at a time. Keep track of what you do today.';

  @override
  String get homeNextSession => 'YOUR NEXT SESSION';

  @override
  String get homeInProgress => 'SESSION IN PROGRESS';

  @override
  String get homeReadyQuestion => 'Ready to train?';

  @override
  String get homeAddExercisesHint => 'Add your exercises and log every set.';

  @override
  String homeActivitiesRecords(int activities, int records) {
    return 'Activities: $activities · Records: $records';
  }

  @override
  String get homeStartWorkout => 'Start workout';

  @override
  String get homeContinueWorkout => 'Continue workout';

  @override
  String get homeCompletedSessions => 'completed sessions';

  @override
  String get homeRecords => 'records';

  @override
  String get homeLastActivity => 'LAST ACTIVITY';

  @override
  String get homeEmptyHistoryTitle => 'Your story starts here';

  @override
  String get homeEmptyHistorySubtitle =>
      'Your first workout will appear here when you finish it.';

  @override
  String get homeSavedOffline => 'Saved on this device · Offline';

  @override
  String get homeJourneyTitle => 'Your journey';

  @override
  String get homeEverySessionCounts => 'Every session counts.';

  @override
  String get homeNoSessionsTitle => 'No sessions yet';

  @override
  String get homeNoSessionsSubtitle =>
      'Finish a workout and check all its exercises and sets here.';

  @override
  String get homeStatusInProgress => 'IN PROGRESS';

  @override
  String get homeStatusCompleted => 'COMPLETED';

  @override
  String homeFinishedAt(Object date) {
    return 'Finished: $date';
  }

  @override
  String homeFinishRecorded(Object date) {
    return 'End recorded: $date';
  }

  @override
  String homeFinishRecordedByUser(Object date) {
    return 'End recorded: $date · time chosen by you';
  }

  @override
  String get homeTimeKeptWarning =>
      'Time kept with a warning. You can review it later.';

  @override
  String get homeTimeKeptWarningShort => 'Time kept with a warning.';

  @override
  String get homeActivities => 'activities';

  @override
  String homeIntervalsRepeated(int count) {
    return 'Sets / segments: $count';
  }

  @override
  String homeIntervals(int count) {
    return 'Segments: $count';
  }

  @override
  String get homeNotStarted => 'Not started';

  @override
  String homeEndedAt(Object date) {
    return 'End: $date';
  }

  @override
  String homeDraft(Object draft) {
    return 'Draft: $draft';
  }

  @override
  String get homeFinishWorkout => 'Finish workout';

  @override
  String get homeAddSetToFinish => 'Log at least one set to finish.';

  @override
  String get homeEachSetSaved => 'Each set is saved when you tap Save.';

  @override
  String get homeDiscardTitle => 'Discard session?';

  @override
  String get homeDiscardBody =>
      'This session and all its sets will be deleted. This action cannot be undone.';

  @override
  String get homeDiscard => 'Discard';

  @override
  String get homeDiscardSession => 'Discard session';

  @override
  String get homeSavedWellDone => 'Session saved. Well done.';

  @override
  String get homeViewHistory => 'View history';

  @override
  String homeDeleteExerciseTooltip(Object name) {
    return 'Delete exercise $name';
  }

  @override
  String get homeDeleteExerciseTitle => 'Delete exercise?';

  @override
  String homeDeleteExerciseBody(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$name and its $_temp0 will be deleted.';
  }

  @override
  String get homeDelete => 'Delete';

  @override
  String homeTargetProgress(
    int done,
    int target,
    Object repsMin,
    Object repsMax,
  ) {
    return 'Sets logged: $done of $target · $repsMin–$repsMax reps';
  }

  @override
  String get homeNoPreviousSession => 'No previous session recorded';

  @override
  String homeLastTime(Object date) {
    return 'Last time · $date';
  }

  @override
  String get homeNoSetsYet => 'You haven\'t logged any sets yet.';

  @override
  String get homeSetHeader => 'SET';

  @override
  String get homeKgHeader => 'KG';

  @override
  String get homeRepsHeader => 'REPS';

  @override
  String homeSetOptionsTooltip(int number) {
    return 'Set $number options';
  }

  @override
  String homeSetDeleteBody(Object weight, int reps) {
    String _temp0 = intl.Intl.pluralLogic(
      reps,
      locale: localeName,
      other: '$reps reps',
      one: '1 rep',
    );
    return '$weight kg × $_temp0.';
  }

  @override
  String homeWeightReps(Object weight, int reps) {
    return '$weight kg × $reps';
  }

  @override
  String get homeEditSet => 'Edit set';

  @override
  String get homeDeleteSet => 'Delete set';

  @override
  String get homeAddSet => 'Add set';

  @override
  String homeRest(int seconds) {
    return 'Rest ${seconds}s';
  }

  @override
  String get homeFirstSetTitle => 'Get your first set ready';

  @override
  String get homeFirstSetSubtitle =>
      'Add an exercise to start logging weight and reps.';

  @override
  String get homeFinishSession => 'Finish session';

  @override
  String get homeTabToday => 'Today';

  @override
  String get homeTabRoutines => 'Routines';

  @override
  String get homeTabHistory => 'History';

  @override
  String get homeSessionStarted =>
      'Workout started. You can open Workout to log sets.';

  @override
  String get homeSessionStartFailed => 'Could not start the workout.';

  @override
  String get homeActiveSessionChanged =>
      'The active session has changed. Please review it.';

  @override
  String get homeSavedSheetPending =>
      'Workout saved on the phone. Sending to Google Sheets is pending confirmation.';

  @override
  String get homeSavedSheetNotUpdated =>
      'Workout saved on the phone. Google Sheets was not updated.';

  @override
  String get homeFinishFailed => 'Could not finish the workout.';

  @override
  String get homeReviewFinishTitle => 'Review end time';

  @override
  String homeFinishIssuesBody(Object issues) {
    return '$issues\n\nDo you want to save the chosen time as it is? Records will be kept so you can review them later if you wish.';
  }

  @override
  String get homeBackAndFix => 'Go back and fix';

  @override
  String get homeSaveThatTime => 'Save that time';

  @override
  String get homeDate => 'Date';

  @override
  String get homeTime => 'Time';

  @override
  String get homeStartSession => 'Start workout';

  @override
  String get homeOptionYes => 'Yes';

  @override
  String get homeOptionNo => 'No';

  @override
  String get homeBoolYes => 'yes';

  @override
  String get homeBoolNo => 'no';

  @override
  String get homeNoteOptional => 'Note (optional)';

  @override
  String homeNumberInvalid(Object label) {
    return '$label: enter a number.';
  }

  @override
  String get homeNoteOrValueRequired => 'Enter a value or write a note.';

  @override
  String get homeSessionFinished => 'Session finished';

  @override
  String get homeSummaryEmpty => 'Nothing new this time. Keep going.';

  @override
  String get homeNewAchievement => 'New achievement';

  @override
  String get homeDone => 'Done';

  @override
  String get homeSuggestionSquat => 'Squat';

  @override
  String get homeSuggestionBench => 'Bench press';

  @override
  String get homeSuggestionRow => 'Row';

  @override
  String get homeNewSet => 'New set';

  @override
  String get homeWeightLabel => 'Weight (kg)';

  @override
  String get homeWeightHint => 'e.g. 20.5';

  @override
  String get homeRepsLabel => 'Repetitions';

  @override
  String get homeRepsHint => 'e.g. 10';

  @override
  String get homeZeroWeightHint =>
      'Use 0 kg if you train without external load.';

  @override
  String get homeExercisesLabel => 'EXERCISES';

  @override
  String get homeDeleteSetTitle => 'Delete set?';

  @override
  String get accountsConnectError => 'Could not connect to Google.';

  @override
  String get accountsSwitchError =>
      'Could not switch accounts. Your data is kept.';

  @override
  String get accountsDescription =>
      'Each account has its own conversation, AI settings, sheet and workouts on this phone. Previous history stays in the local profile. Connecting does not copy or upload that data.';

  @override
  String get accountsConnectAnother => 'Connect another Google account';

  @override
  String get accountsActiveProfile => 'Active profile';

  @override
  String get accountsReconnectProfile =>
      'Switch back to this profile with Google';

  @override
  String get accountsDisconnect => 'Disconnect and return to the local profile';

  @override
  String get accountsDisconnectNotice =>
      'Disconnecting keeps each profile\'s data on this phone. It does not delete Google files or revoke access from your Google account.';

  @override
  String get appearanceSaveError => 'Could not save the theme. Try again.';

  @override
  String get appearanceIntro =>
      'Choose how you want to see TrackIA. Your choice is saved on this phone.';

  @override
  String get appearanceSystemHint => 'Use the device theme';

  @override
  String get archiveSearchLabel => 'Search by title or summary';

  @override
  String get archiveRecoverError =>
      'Could not recover the chat. The archive is kept.';

  @override
  String get archiveEmpty => 'There are no archived chats yet.';

  @override
  String archiveChatSubtitle(Object date, Object count) {
    return '$date · $count messages';
  }

  @override
  String get archiveAutomaticTag => 'archived by the assistant';

  @override
  String get archiveContinuityTitle => 'Continuity summary';

  @override
  String archiveReasonLine(Object reason) {
    return 'Assistant\'s reason: $reason';
  }

  @override
  String get archiveConsultFromChat => 'Ask from chat';

  @override
  String get archiveYou => 'You';

  @override
  String archiveAttachmentKept(Object name) {
    return 'Attachment kept: $name';
  }

  @override
  String get notifUnsupported => 'Rest alerts are only available on Android.';

  @override
  String get notifDndActive => 'Do not disturb is on';

  @override
  String get notifDndTotalSilence =>
      'You are on «Total silence»: Android blocks alerts, even as alarms.';

  @override
  String get notifDndAlarm =>
      'Rest alerts sound as alarms. Other alerts would not sound or vibrate.';

  @override
  String get notifDndPlain =>
      'Right now rest alerts would not sound or vibrate.';

  @override
  String get notifEnabledTitle => 'Activity and rest alerts';

  @override
  String get notifEnabledSubtitle =>
      'Activity ready, segment running, segment end and rest end.';

  @override
  String get notifAlarmStyleTitle => 'Treat as alarm';

  @override
  String get notifAlarmStyleSubtitle =>
      'Rest and segment ends sound and vibrate even when Do not disturb is in Priority mode.';

  @override
  String get notifChannelBlockedTitle => 'Android blocks the alarm channel';

  @override
  String get notifChannelBlockedSubtitle =>
      'Turn it on in the channel settings.';

  @override
  String get notifExactTitle => 'Allow exact alerts';

  @override
  String get notifExactSubtitle =>
      'Without this permission Android may delay the alert.';

  @override
  String get notifCheck => 'Check';

  @override
  String get notifTest => 'Test alert';

  @override
  String get notifTestAlarm => 'Test with Do not disturb on';

  @override
  String get notifOpenDnd => 'Open Do not disturb settings';

  @override
  String get notifSilenceNote =>
      'On «Total silence», Android blocks everything, including alarms. There, the only fix is allowing them in your phone\'s settings.';

  @override
  String get progressLoadError => 'Could not calculate progress.';

  @override
  String get progressMonth1 => 'January';

  @override
  String get progressMonth2 => 'February';

  @override
  String get progressMonth3 => 'March';

  @override
  String get progressMonth4 => 'April';

  @override
  String get progressMonth5 => 'May';

  @override
  String get progressMonth6 => 'June';

  @override
  String get progressMonth7 => 'July';

  @override
  String get progressMonth8 => 'August';

  @override
  String get progressMonth9 => 'September';

  @override
  String get progressMonth10 => 'October';

  @override
  String get progressMonth11 => 'November';

  @override
  String get progressMonth12 => 'December';

  @override
  String progressDayStatus(int day, Object month, Object status) {
    return '$month $day: $status';
  }

  @override
  String get progressDayDone => 'done';

  @override
  String get progressDayPending => 'pending';

  @override
  String get progressDayMissed => 'missed';

  @override
  String progressTitle(Object name) {
    return 'Progress · $name';
  }

  @override
  String progressStreakCurrent(int n) {
    return 'Current streak (days): $n';
  }

  @override
  String progressStreakBest(int best) {
    return 'Best streak: $best';
  }

  @override
  String progressFreeDays(int used, int total) {
    return 'Rest days this week: $used/$total';
  }

  @override
  String get progressGoalToday => 'Today\'s goal';

  @override
  String get progressGoalWeek => 'This week\'s goal';

  @override
  String progressGoalValues(Object value, Object target) {
    return '$value of $target';
  }

  @override
  String get progressLastFourWeeks => 'Last 4 weeks';

  @override
  String progressAchievementUnlocked(Object title) {
    return '$title, unlocked';
  }

  @override
  String progressAchievementLocked(Object title, int percent) {
    return '$title, locked, $percent% progress';
  }

  @override
  String progressAchievementsTitle(int unlocked, int total) {
    return 'Achievements · $unlocked of $total';
  }

  @override
  String get progressAchievementsEmptyPlay =>
      'Your achievements will appear when you finish your first activity.';

  @override
  String progressAchievementsEmptyEnable(Object place) {
    return 'Turn on Game mode and achievements in «$place».';
  }

  @override
  String get routinesTitle => 'Your routines';

  @override
  String get routinesSubtitle => 'Set up once. Train at your pace.';

  @override
  String get routinesCreate => 'Create routine';

  @override
  String get routinesEmptyTitle => 'Your next session, ready';

  @override
  String get routinesEmptyBody =>
      'For example, create «Leg A» with your exercises, sets and rep range.';

  @override
  String routinesOptionsTooltip(Object name) {
    return 'Options for $name';
  }

  @override
  String get routinesDeleteTitle => 'Delete routine?';

  @override
  String routinesDeleteBody(Object name) {
    return '«$name» will be deleted. Your saved workouts and the current session will be kept.';
  }

  @override
  String get routinesEditMenu => 'Edit routine';

  @override
  String get routinesDeleteMenu => 'Delete routine';

  @override
  String get routinesDelete => 'Delete';

  @override
  String get routinesTrain => 'Train';

  @override
  String get routinesContinueSession => 'Continue active session';

  @override
  String get routinesNeedExercise => 'Add at least one exercise.';

  @override
  String get routinesNameLabel => 'Routine name';

  @override
  String get routinesNameHint => 'E.g. Leg A';

  @override
  String get routinesEditorHelp =>
      'Set your targets. Sets will be recorded when you train.';

  @override
  String routinesMoveUp(int n) {
    return 'Move exercise $n up';
  }

  @override
  String routinesMoveDown(int n) {
    return 'Move exercise $n down';
  }

  @override
  String routinesEditExercise(int n) {
    return 'Edit exercise $n';
  }

  @override
  String routinesRemoveExercise(int n) {
    return 'Remove exercise $n';
  }

  @override
  String get routinesAddExercise => 'Add exercise to routine';

  @override
  String get routinesSaving => 'Saving…';

  @override
  String get routinesSave => 'Save routine';

  @override
  String get routinesLeaveTitle => 'Leave without saving?';

  @override
  String get routinesLeaveBody => 'Changes to this routine will be lost.';

  @override
  String get routinesKeepEditing => 'Keep editing';

  @override
  String get routinesDiscard => 'Discard changes';

  @override
  String get routinesBack => 'Back';

  @override
  String get routinesExerciseDialogTitle => 'Routine exercise';

  @override
  String get routinesEditTargetTitle => 'Edit target';

  @override
  String get routinesExerciseLabel => 'Exercise';

  @override
  String get routinesExerciseHint => 'E.g. Squat';

  @override
  String get routinesTargetSets => 'Planned sets';

  @override
  String get routinesRepsMin => 'Min reps';

  @override
  String get routinesRepsMax => 'Max reps';

  @override
  String get routinesRestSeconds => 'Rest (seconds)';

  @override
  String get routinesSaveExercise => 'Save exercise';

  @override
  String get focusCounterSaveError => 'Could not save the counter. Try again.';

  @override
  String get focusResultSaveError =>
      'Could not save the result. Keep the text and try again.';

  @override
  String get focusSaveActivityError => 'Could not save to your activities.';

  @override
  String get focusRecordSaveError => 'Could not save the record. Try again.';

  @override
  String get focusReviewTimeTitle => 'Check time';

  @override
  String get focusReviewTimeBody =>
      'The chosen time does not match the records. Save that time and keep them?';

  @override
  String get focusBack => 'Back';

  @override
  String get focusSaveThatTime => 'Save that time';

  @override
  String get focusRunning => 'In progress';

  @override
  String get focusReady => 'Ready';

  @override
  String get focusRest => 'Rest';

  @override
  String focusRepeatedRest(Object progress, Object segments) {
    return '$progress $segments · Rest';
  }

  @override
  String focusSegmentCount(Object segment, int count) {
    return '$segment $count';
  }

  @override
  String focusSegmentCountOfTarget(Object segment, int count, int target) {
    return '$segment $count of $target';
  }

  @override
  String get focusSegmentSerie => 'set';

  @override
  String get focusSegmentTramo => 'segment';

  @override
  String get focusSegmentSeries => 'sets';

  @override
  String get focusSegmentTramos => 'segments';

  @override
  String focusRemoveField(Object label) {
    return 'Remove $label';
  }

  @override
  String focusAddField(Object label) {
    return 'Add $label';
  }

  @override
  String get datePatternLongWeekday => 'EEEE, MMMM d';

  @override
  String get datePatternLongDateTime => 'MMMM d · HH:mm';

  @override
  String get datePatternShortDateTime => 'MMM d, yyyy · HH:mm';

  @override
  String get datePatternShortDate => 'MMM d';

  @override
  String get datePatternNumericDate => 'M/d/yyyy';

  @override
  String get datePatternNumericDateTime => 'M/d/yyyy HH:mm';

  @override
  String get datePatternNumericDateTimeSeconds => 'M/d/yyyy HH:mm:ss';

  @override
  String get datePatternPaddedDateTime => 'MM/dd/yyyy HH:mm';

  @override
  String get builderTypeNumber => 'Number';

  @override
  String get builderTypeScale => 'Scale';

  @override
  String get builderTypeText => 'Text';

  @override
  String get builderTypeChoice => 'Option';

  @override
  String get builderTypeBoolean => 'Yes or no';

  @override
  String get builderAggSum => 'Sum';

  @override
  String get builderAggMax => 'Personal best';

  @override
  String get builderAggAvg => 'Average';

  @override
  String get builderAggDistinct => 'Count distinct';

  @override
  String get builderAggCountTrue => 'Count yes';

  @override
  String get builderAggNone => 'Notes only';

  @override
  String get proposalLabelActivitySeconds => 'Interval duration';

  @override
  String get proposalLabelTargetCycles => 'Planned cycles';

  @override
  String get proposalLabelUnitCycles => 'cycles';

  @override
  String get proposalLabelUnitSeconds => 's';

  @override
  String get creatorStaticGreeting =>
      'Tell me what you want to keep up with and I\'ll help you create your companion.';

  @override
  String get creatorStaticDayLetters => 'M,T,W,T,F,S,S';

  @override
  String get proposalGameSuggestion =>
      'You\'ve kept up for several days in a row. Do you want to turn on Game mode to see goals, streaks and achievements?';

  @override
  String reminderPhraseWindowStartCheer1(Object nombre, Object meta) {
    return '$nombre is waiting for you: today\'s goal is $meta.';
  }

  @override
  String reminderPhraseWindowStartCheer2(Object nombre) {
    return '$nombre is waiting for you today.';
  }

  @override
  String reminderPhraseWindowStartNeutral1(Object meta) {
    return 'It\'s a good time for your activity. Today\'s goal: $meta.';
  }

  @override
  String get reminderPhraseWindowStartNeutral2 =>
      'It\'s a good time for your activity.';

  @override
  String reminderPhraseLastCallCheer1(Object minimo, Object racha) {
    return 'Last call: with $minimo you keep your $racha-day streak.';
  }

  @override
  String reminderPhraseLastCallCheer2(Object faltan) {
    return 'Don\'t lose your streak: $faltan to go this week.';
  }

  @override
  String get reminderPhraseLastCallCheer3 => 'Last call for today.';

  @override
  String reminderPhraseLastCallNeutral1(Object minimo) {
    return 'You still have time today. $minimo is enough.';
  }

  @override
  String reminderPhraseLastCallNeutral2(Object faltan) {
    return '$faltan to go this week.';
  }

  @override
  String get reminderPhraseLastCallNeutral3 => 'You still have time today.';

  @override
  String reminderPhraseInactiveGymbroCheer(Object dias) {
    return 'Buddy, we\'ve gone $dias days without training. Let\'s move a little.';
  }

  @override
  String reminderPhraseInactiveCheer1(Object dias) {
    return 'We haven\'t seen each other in $dias days. Something short today?';
  }

  @override
  String get reminderPhraseInactiveCheer2 => 'Something short today?';

  @override
  String reminderPhraseInactiveNeutral1(Object dias) {
    return 'You haven\'t logged anything for $dias days.';
  }

  @override
  String get reminderPhraseInactiveNeutral2 =>
      'You haven\'t logged anything in a few days.';

  @override
  String get reminderPhraseMinimumSessionOne => '1 session';

  @override
  String reminderPhraseMinimumSessions(Object n) {
    return '$n sessions';
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
    return '$name\'s memory';
  }

  @override
  String get memoryIntro =>
      'What this companion remembers about you. You can review, edit or delete it at any time. It is treated as information about you, never as instructions.';

  @override
  String get memoryOpen => 'Companion memory';

  @override
  String get memoryOpenHelp =>
      'View, edit and delete what it remembers, and the cloud copy.';

  @override
  String get memoryEmpty => 'No memories saved yet.';

  @override
  String get memoryLoadError => 'Could not load the memories.';

  @override
  String get memoryActionError =>
      'The action could not be completed. Your memories have not changed.';

  @override
  String get memoryStatusActive => 'Active';

  @override
  String get memoryStatusPending => 'Waiting for confirmation';

  @override
  String get memorySourceExplicit => 'You asked for it';

  @override
  String get memorySourceInferred => 'Suggested by the AI';

  @override
  String get memorySourceEdited => 'Edited by you';

  @override
  String get memoryConfirm => 'Confirm';

  @override
  String get memoryConfirmed => 'Memory confirmed.';

  @override
  String get memoryEdit => 'Edit';

  @override
  String get memoryEditTitle => 'Edit memory';

  @override
  String get memoryEditLabel => 'Memory';

  @override
  String get memoryEditEmpty => 'The memory cannot be empty.';

  @override
  String get memoryEditTooLong => 'The memory cannot exceed 2000 characters.';

  @override
  String get memoryEdited => 'Memory saved.';

  @override
  String get memoryDeleteLocalAction => 'Delete from this phone';

  @override
  String get memoryDeleteLocalTitle => 'Delete this memory from this phone?';

  @override
  String get memoryDeleteLocalBody =>
      'It will be deleted from this phone only and the companion will stop using it. It does not delete any copy you have in the cloud; use \"Delete from the cloud\" for that.';

  @override
  String get memoryDeletedLocal =>
      'Memory deleted from this phone. The cloud copy was not touched.';

  @override
  String get memoryCloudTitle => 'Cloud copy';

  @override
  String get memoryCloudHelp =>
      'Optional and only when you ask. Active memories of this companion are saved, without chats or keys. It is not end-to-end encrypted.';

  @override
  String get memoryCloudUnavailable =>
      'Google Drive is not connected yet in this version';

  @override
  String get memoryCloudNoAccount =>
      'Connect a Google account to use the cloud copy.';

  @override
  String memoryCloudAccount(Object account) {
    return 'Account: $account';
  }

  @override
  String memoryCloudLastCopy(Object date, int revision) {
    return 'Last copy seen: $date (revision $revision)';
  }

  @override
  String get memoryCloudSave => 'Save to the cloud';

  @override
  String get memoryCloudLoad => 'Load from the cloud';

  @override
  String get memoryCloudDelete => 'Delete from the cloud';

  @override
  String get memoryCloudSaveTitle => 'Save to the cloud?';

  @override
  String memoryCloudSaveBody(Object account, int count) {
    return 'The active memories of this companion will be uploaded to the account $account. Memories to upload: $count. Those waiting for confirmation are not uploaded. If the cloud copy changed, it is not overwritten.';
  }

  @override
  String memoryCloudSaved(Object account) {
    return 'Copy saved to the account $account.';
  }

  @override
  String memoryCloudLoaded(int count) {
    return 'Copy loaded. Memories added: $count.';
  }

  @override
  String get memoryCloudLoadCancelled => 'Load cancelled. Nothing was changed.';

  @override
  String get memoryCloudDeleteTitle => 'Delete the cloud copy?';

  @override
  String memoryCloudDeleteBody(Object account, Object date) {
    return 'The copy of this companion in the account $account (saved on $date) will be deleted. It does not delete the memories on this phone. This cannot be undone.';
  }

  @override
  String memoryCloudDeleted(Object account) {
    return 'Copy deleted from the account $account. The memories on this phone were not touched.';
  }

  @override
  String get memoryCloudDeleteCancelled =>
      'Deletion cancelled. Nothing was changed.';

  @override
  String get memoryCloudNotFound =>
      'There is no cloud copy for this companion.';

  @override
  String get memoryCloudConflict =>
      'The cloud copy differs from the last one you saw. Nothing was changed; use \"Load from the cloud\" to review it.';

  @override
  String get memoryCloudUncertain =>
      'The result could not be confirmed; the operation may have been applied. Load again to check before repeating.';

  @override
  String get memoryCloudCancelled =>
      'Operation cancelled. Nothing was changed.';

  @override
  String get memoryCloudDenied =>
      'Google did not grant permission. Nothing was changed.';

  @override
  String get memoryCloudFailed =>
      'The cloud operation could not be completed. Your local memories were not changed.';

  @override
  String get memoryPreviewTitle => 'Copy preview';

  @override
  String memoryPreviewFrom(Object account, Object date) {
    return 'Account $account, copy from $date';
  }

  @override
  String memoryPreviewAdd(int count) {
    return 'Would be added: $count';
  }

  @override
  String memoryPreviewSkip(int count) {
    return 'Skipped (already exist): $count';
  }

  @override
  String memoryPreviewConflict(int count) {
    return 'In conflict (not applied): $count';
  }

  @override
  String get memoryPreviewConflictHelp =>
      'Conflicts are never resolved automatically: your local memories stay as they are.';

  @override
  String get memoryPreviewNothing => 'There is nothing to add.';

  @override
  String get memoryPreviewApply => 'Add memories';

  @override
  String get agreementTitle => 'Support agreements';

  @override
  String get agreementNew => 'New agreement';

  @override
  String get agreementEmpty =>
      'You have no agreements yet. Create one with the New agreement button; only what you record is tracked.';

  @override
  String get agreementLoadError => 'Couldn\'t load the agreements.';

  @override
  String get agreementSaveError =>
      'Couldn\'t save the change. The agreement is unchanged.';

  @override
  String get agreementStatusActive => 'Active';

  @override
  String get agreementStatusPaused => 'Paused';

  @override
  String get agreementStatusCompleted => 'Completed';

  @override
  String get agreementObjectiveLabel => 'Goal';

  @override
  String get agreementUnitLabel => 'Unit (optional)';

  @override
  String get agreementMeasureLabel => 'Measure';

  @override
  String get agreementMeasureOptionalLabel => 'Measure (optional)';

  @override
  String get agreementConsent =>
      'I agree to create this agreement. Only what I record will be tracked.';

  @override
  String get agreementErrorObjective => 'Enter a goal (up to 2000 characters).';

  @override
  String get agreementErrorMeasure =>
      'The measure must be a finite number, 0 or greater.';

  @override
  String get agreementErrorConsent => 'Tick the box to create the agreement.';

  @override
  String get agreementCancel => 'Cancel';

  @override
  String get agreementCreate => 'Create';

  @override
  String get agreementSave => 'Save';

  @override
  String get agreementModify => 'Edit';

  @override
  String get agreementPause => 'Pause';

  @override
  String get agreementResume => 'Resume';

  @override
  String get agreementComplete => 'Complete';

  @override
  String get agreementCompleteTitle => 'Complete the agreement?';

  @override
  String get agreementCompleteBody =>
      'A completed agreement can no longer be edited or receive progress. The history is kept.';

  @override
  String get agreementRecordProgress => 'Record progress';

  @override
  String get agreementRecord => 'Record';

  @override
  String get agreementAmountLabel => 'Amount (optional)';

  @override
  String get agreementNoteLabel => 'Note (optional)';

  @override
  String get agreementReminderLabel => 'Notice';

  @override
  String get agreementEventsTitle => 'Recorded progress';

  @override
  String get agreementNoEvents => 'No progress recorded yet.';

  @override
  String get agreementChangesTitle => 'Change history';

  @override
  String get agreementNoChanges => 'No changes since creation.';

  @override
  String agreementRevisionLabel(int n) {
    return 'Revision $n';
  }

  @override
  String get packageShareRow => 'Share companion';

  @override
  String get packageShareRowHelp =>
      'Creates a .trackia file with this companion\'s setup, without your data.';

  @override
  String get packageShareTitle => 'Share this companion?';

  @override
  String get packageShareIncludes =>
      'Shared: name, icon, color, description, style instructions, mode, activity templates and reminder texts.';

  @override
  String get packageShareExcludes =>
      'Not shared: AI keys, chats, memory, Google sheet, accounts or your data.';

  @override
  String get packageShareReceiverNote =>
      'The person who receives it can import it and review it before using it.';

  @override
  String get packageShareTemplatesLimited =>
      'Only the first 5 activity templates are included.';

  @override
  String get packageShareConfirm => 'Share';

  @override
  String get packageShareInstructionsTooLong =>
      'The instructions exceed the 4000 characters allowed for sharing. Shorten them and try again. Nothing was shared.';

  @override
  String get packageShareInvalid =>
      'This companion has data that cannot be shared. Nothing was shared.';

  @override
  String get packageShareWriteError =>
      'The file could not be prepared for sharing. Nothing was shared.';

  @override
  String get packageImportTitle => 'Import companion';

  @override
  String get packageImportIntro =>
      'Choose a .trackia file or paste the text you were sent. You will see a preview before anything is saved.';

  @override
  String get packageImportPickFile => 'Choose file';

  @override
  String get packageImportPasteLabel => 'Companion text';

  @override
  String get packageImportPreviewButton => 'Show preview';

  @override
  String get packageImportFileError => 'The file could not be read.';

  @override
  String get packageImportExternalNotice =>
      'This content comes from outside: review it before saving it.';

  @override
  String get packageImportModeNote =>
      'It will be saved in «reminder» mode, with no permissions or connections. You can change that later.';

  @override
  String get packageImportActivityTitle => 'Activity it would bring';

  @override
  String packageImportActivityFields(Object fields) {
    return 'Fields: $fields';
  }

  @override
  String get packageImportRemindersTitle => 'Reminder texts';

  @override
  String get packageImportReminderWindowStart => 'When the window starts';

  @override
  String get packageImportReminderLastCall => 'Last call';

  @override
  String get packageImportReminderInactive => 'No activity';

  @override
  String get packageImportWarningsTitle => 'Warnings';

  @override
  String packageImportWarningAppBlocksRemoved(int count) {
    return 'Internal app blocks were removed from the content. Count: $count';
  }

  @override
  String packageImportWarningModeReset(Object mode) {
    return 'The package asked for «$mode» mode; it starts as «reminder» and you can change it later.';
  }

  @override
  String packageImportWarningExtraTemplates(int count) {
    return 'Other activities in the package are not applied. Count: $count';
  }

  @override
  String get packageImportWarningSuspicious =>
      'The instructions seem to try to change the assistant\'s rules. Read them carefully or delete them.';

  @override
  String get packageImportWarningInstructionsEmpty =>
      'No text was left in the instructions after removing the internal blocks.';

  @override
  String get packageImportSave => 'Save companion';

  @override
  String get packageImportSaveFailed => 'The companion could not be saved.';

  @override
  String packageImportProblemField(Object field) {
    return 'Field: $field';
  }

  @override
  String get packageImportProblemEmpty =>
      'Nothing to import: the text or file is empty.';

  @override
  String get packageImportProblemTooLarge =>
      'The content is too large to be a companion.';

  @override
  String get packageImportProblemBadEncoding =>
      'The text is damaged or incomplete: it is not in a valid format.';

  @override
  String get packageImportProblemBadCompression =>
      'The content is damaged and could not be decompressed.';

  @override
  String get packageImportProblemTooLargeExpanded =>
      'The content is too large once opened and was rejected for safety.';

  @override
  String get packageImportProblemMalformed =>
      'The content could not be read: it is not a valid companion.';

  @override
  String get packageImportProblemNotAPackage =>
      'This is not a TrackIA companion.';

  @override
  String get packageImportProblemUnsupportedVersion =>
      'This companion is from a newer version. Update TrackIA to import it.';

  @override
  String get packageImportProblemChecksumMismatch =>
      'The content changed or was damaged: the integrity check failed.';

  @override
  String get packageImportProblemForbiddenField =>
      'The content includes data that must never travel (keys, chats, memory…). It was not imported.';

  @override
  String get packageImportProblemUnknownField =>
      'The content includes a field this version does not accept. It was not imported.';

  @override
  String get packageImportProblemMissingField =>
      'A required field is missing from the content.';

  @override
  String get packageImportProblemInvalidField =>
      'A field in the content is not valid or exceeds its limit.';

  @override
  String get importedTrustWarning =>
      'This companion is imported: confirm before it acts.';

  @override
  String get importedTrustConfirm => 'Confirm';

  @override
  String get importedTrustSheetTitle => 'Edit your Google Sheet?';

  @override
  String importedTrustSheetTarget(String sheet, String tab) {
    return 'Sheet: $sheet · Tab: $tab';
  }

  @override
  String importedTrustCellLine(String cell, String before, String after) {
    return '$cell: “$before” → “$after”';
  }

  @override
  String get importedTrustEmptyValue => '(empty)';

  @override
  String get importedTrustCancelledSheet =>
      'Action cancelled: the Google Sheet was not edited.';

  @override
  String get importedTrustActivityTitle => 'Prepare this activity?';

  @override
  String importedTrustActivityRest(int seconds) {
    return 'Rest: $seconds s';
  }

  @override
  String importedTrustActivityDuration(int seconds) {
    return 'Activity duration: $seconds s';
  }

  @override
  String importedTrustActivityTargetSets(int count) {
    return 'Target sets: $count';
  }

  @override
  String importedTrustActivityFields(String fields) {
    return 'Fields: $fields';
  }

  @override
  String importedTrustCancelledActivity(String name) {
    return 'Action cancelled: the activity “$name” was not prepared.';
  }

  @override
  String get importedTrustLabel => 'Imported';

  @override
  String get importedTrustSwitch => 'Trust this companion';

  @override
  String get importedTrustSwitchHelp =>
      'Until you trust it, it asks for confirmation before editing your sheet or preparing activities.';

  @override
  String get importedTrustDialogTitle => 'Trust this companion?';

  @override
  String get importedTrustDialogBody =>
      'It will stop asking for confirmation before editing your sheet or preparing activities. Do it only if you trust whoever shared it.';

  @override
  String get importedTrustDialogConfirm => 'Trust';

  @override
  String get importedTrustSaveError =>
      'The change could not be saved. Try again.';

  @override
  String get packageQrTitle => 'Companion QR code';

  @override
  String get packageQrNote =>
      'Whoever scans it will see a preview before saving anything.';

  @override
  String get packageQrShareFile => 'Share file';

  @override
  String get packageQrClose => 'Close';

  @override
  String get packageQrTooLarge =>
      'It is too large for a QR code: it is shared as a file.';

  @override
  String get packageScanTitle => 'Scan companion';

  @override
  String get packageScanHint => 'Point the camera at the companion\'s QR code.';

  @override
  String get packageScanTorch => 'Flashlight';

  @override
  String get packageScanPermissionDenied =>
      'Camera permission was not granted. You can import the companion from a file or by pasting the text.';

  @override
  String get packageScanCameraError =>
      'The camera could not be used. You can import the companion from a file or by pasting the text.';

  @override
  String get packageScanUseFile => 'Import from file or text';

  @override
  String get restScreenSharedCopyUnreadable =>
      'The shared copy could not be read.';

  @override
  String get restScreenSharedCopyOpenError =>
      'The shared copy could not be opened.';

  @override
  String restScreenCompanionsLoadDetail(Object error) {
    return 'Companions could not be loaded: $error';
  }

  @override
  String restScreenTimerLabel(Object label) {
    return 'Time: $label';
  }

  @override
  String get aiStatusChecking => 'Checking AI…';

  @override
  String get aiStatusUnconfigured =>
      'Set up your provider and model to use the assistant. You can load your data first.';

  @override
  String get aiStatusUnverified =>
      'Verify the model connection to enable the assistant and activities.';

  @override
  String aiStatusVerified(Object model) {
    return 'AI verified · $model';
  }

  @override
  String aiStatusCatalogReason(Object reason) {
    return 'AI configured · the catalog could not be updated: $reason';
  }

  @override
  String get aiStatusCatalogFailed =>
      'AI configured · the catalog could not be updated. You can keep sending messages.';

  @override
  String get aiStatusUnreachable =>
      'Could not check the connection to the AI. Try again or review the provider. Your data is kept.';

  @override
  String get aiStatusRequestFailed =>
      'The last request failed. You can retry with the same model; your records are kept.';

  @override
  String get ruleUnitMin => 'min';

  @override
  String get ruleUnitSessions => 'sessions';

  @override
  String get ruleSessionOne => '1 session';

  @override
  String get ruleMetricTime => 'Time';

  @override
  String get ruleMetricSessions => 'Sessions';

  @override
  String ruleMetricMax(String label) {
    return 'Maximum of $label';
  }

  @override
  String ruleMetricAvg(String label) {
    return 'Average of $label';
  }

  @override
  String ruleMetricDistinct(String label) {
    return 'Distinct $label';
  }

  @override
  String ruleMetricCountTrue(String label) {
    return 'Times: $label';
  }

  @override
  String get rulePerDay => 'per day';

  @override
  String get rulePerWeek => 'per week';

  @override
  String get rulePerSession => 'per session';

  @override
  String get rulePerTotal => 'in total';

  @override
  String ruleGoalMinimum(String value) {
    return '(minimum $value)';
  }

  @override
  String get ruleGoalDaily => 'a day';

  @override
  String get ruleGoalWeekly => 'a week';

  @override
  String get ruleStreakOne => '1-day streak';

  @override
  String ruleStreakDays(int n) {
    return '$n-day streak';
  }

  @override
  String ruleAtLeast(String metric, String amount, String per) {
    return '$metric ≥ $amount $per';
  }

  @override
  String get ruleDaysAll => 'Every day';

  @override
  String get ruleDaysWeekdays => 'Monday to Friday';

  @override
  String get ruleDaysWeekend => 'Weekends';

  @override
  String get ruleDayMon => 'Mon';

  @override
  String get ruleDayTue => 'Tue';

  @override
  String get ruleDayWed => 'Wed';

  @override
  String get ruleDayThu => 'Thu';

  @override
  String get ruleDayFri => 'Fri';

  @override
  String get ruleDaySat => 'Sat';

  @override
  String get ruleDaySun => 'Sun';

  @override
  String ruleReminderLastCall(String time) {
    return '· last call $time';
  }

  @override
  String durationHours(int h) {
    return '$h h';
  }

  @override
  String durationHoursMinutes(int h, int m) {
    return '$h h $m min';
  }

  @override
  String durationMinutes(int m) {
    return '$m min';
  }

  @override
  String durationSeconds(int s) {
    return '$s s';
  }
}
