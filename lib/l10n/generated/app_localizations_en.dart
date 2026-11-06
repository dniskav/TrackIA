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
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Streak: # days',
      one: 'Streak: 1 day',
    );
    return '$_temp0';
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
}
