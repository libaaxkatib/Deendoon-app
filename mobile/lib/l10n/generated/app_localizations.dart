import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_so.dart';

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
    Locale('en'),
    Locale('so'),
  ];

  /// Settings screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get sectionGeneral;

  /// No description provided for @sectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get sectionNotifications;

  /// No description provided for @sectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get sectionSecurity;

  /// No description provided for @sectionBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get sectionBusiness;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSomali.
  ///
  /// In en, this message translates to:
  /// **'Somali'**
  String get languageSomali;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get appearanceSystem;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @reminderNotifications.
  ///
  /// In en, this message translates to:
  /// **'Reminder Notifications'**
  String get reminderNotifications;

  /// No description provided for @paymentNotifications.
  ///
  /// In en, this message translates to:
  /// **'Payment Notifications'**
  String get paymentNotifications;

  /// No description provided for @notificationsDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Saved to your business preferences.'**
  String get notificationsDisclosure;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @biometricNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Not supported on this device'**
  String get biometricNotSupported;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @biometricLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Deendoon'**
  String get biometricLockTitle;

  /// No description provided for @biometricLockPromptReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to access your account'**
  String get biometricLockPromptReason;

  /// No description provided for @biometricLockFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Try again or use your password.'**
  String get biometricLockFailedMessage;

  /// No description provided for @usePasswordInstead.
  ///
  /// In en, this message translates to:
  /// **'Use Password Instead'**
  String get usePasswordInstead;

  /// No description provided for @biometricEnableFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not verify your biometrics. Please try again.'**
  String get biometricEnableFailedMessage;

  /// No description provided for @defaultCreditLimit.
  ///
  /// In en, this message translates to:
  /// **'Default Credit Limit'**
  String get defaultCreditLimit;

  /// No description provided for @creditLimitReminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit Reminder'**
  String get creditLimitReminderEnabled;

  /// No description provided for @softLimitWarningThreshold.
  ///
  /// In en, this message translates to:
  /// **'Soft Limit Warning Threshold (%)'**
  String get softLimitWarningThreshold;

  /// No description provided for @whatsappReminderDays.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Reminder Days'**
  String get whatsappReminderDays;

  /// No description provided for @smsReminderDays.
  ///
  /// In en, this message translates to:
  /// **'SMS Reminder Days'**
  String get smsReminderDays;

  /// No description provided for @callReminderDays.
  ///
  /// In en, this message translates to:
  /// **'Call Reminder Days'**
  String get callReminderDays;

  /// No description provided for @reminderDaysHint.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated days, e.g. 1, 3, 7'**
  String get reminderDaysHint;

  /// No description provided for @professionalCollectionThresholdDays.
  ///
  /// In en, this message translates to:
  /// **'Professional Collection Threshold (Days)'**
  String get professionalCollectionThresholdDays;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @settingsSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Settings updated successfully'**
  String get settingsSavedSuccessfully;

  /// No description provided for @couldNotLoadSettings.
  ///
  /// In en, this message translates to:
  /// **'Could not load Settings.'**
  String get couldNotLoadSettings;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @paginationLoadMoreError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more. Tap to retry.'**
  String get paginationLoadMoreError;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @enterValueBetween0And100.
  ///
  /// In en, this message translates to:
  /// **'Enter a value between 0 and 100'**
  String get enterValueBetween0And100;

  /// Shown for a tab/screen whose module isn't built yet
  ///
  /// In en, this message translates to:
  /// **'{value} — coming soon'**
  String comingSoonMessage(String value);

  /// No description provided for @riskHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get riskHigh;

  /// No description provided for @riskMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get riskMedium;

  /// No description provided for @riskLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get riskLow;

  /// No description provided for @riskUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get riskUnknown;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusGoodStanding.
  ///
  /// In en, this message translates to:
  /// **'Good Standing'**
  String get statusGoodStanding;

  /// No description provided for @statusLatePayer.
  ///
  /// In en, this message translates to:
  /// **'Late Payer'**
  String get statusLatePayer;

  /// No description provided for @statusHighRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get statusHighRisk;

  /// No description provided for @statusInCollection.
  ///
  /// In en, this message translates to:
  /// **'In Collection'**
  String get statusInCollection;

  /// No description provided for @statusRecovered.
  ///
  /// In en, this message translates to:
  /// **'Recovered'**
  String get statusRecovered;

  /// No description provided for @statusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get statusBlocked;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @statusPartiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get statusPartiallyPaid;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusWrittenOff.
  ///
  /// In en, this message translates to:
  /// **'Written Off'**
  String get statusWrittenOff;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @statusToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statusToday;

  /// No description provided for @statusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get statusUpcoming;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get statusSubmitted;

  /// No description provided for @statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get statusUnderReview;

  /// No description provided for @statusNeedMoreInformation.
  ///
  /// In en, this message translates to:
  /// **'Need More Information'**
  String get statusNeedMoreInformation;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Fulfilled'**
  String get statusFulfilled;

  /// No description provided for @statusBroken.
  ///
  /// In en, this message translates to:
  /// **'Broken'**
  String get statusBroken;

  /// No description provided for @statusTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get statusTrial;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @themeSwitchToLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get themeSwitchToLight;

  /// No description provided for @themeSwitchToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get themeSwitchToDark;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// No description provided for @navCases.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get navCases;

  /// No description provided for @navReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get navReminders;

  /// No description provided for @navDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get navDocuments;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get commonViewAll;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// Password validator error when the entered password is shorter than the minimum length
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {minLength} characters'**
  String authPasswordMinLength(int minLength);

  /// No description provided for @authPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsMismatch;

  /// No description provided for @passwordFieldShowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get passwordFieldShowTooltip;

  /// No description provided for @passwordFieldHideTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get passwordFieldHideTooltip;

  /// No description provided for @loginAppName.
  ///
  /// In en, this message translates to:
  /// **'Deendoon'**
  String get loginAppName;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Smart Debt Recovery Assistant'**
  String get loginTagline;

  /// No description provided for @loginForgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPasswordLink;

  /// No description provided for @loginSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginSubmitButton;

  /// No description provided for @loginCreateAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Create Account'**
  String get loginCreateAccountPrompt;

  /// No description provided for @authOrDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get authOrDivider;

  /// No description provided for @googleLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get googleLoginButton;

  /// No description provided for @googleLoginFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get googleLoginFailedMessage;

  /// No description provided for @googleLoginNotConfiguredMessage.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not available right now.'**
  String get googleLoginNotConfiguredMessage;

  /// No description provided for @googleRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Registration'**
  String get googleRegisterTitle;

  /// Instructions on the business-name-collection screen shown after a new Google sign-in, before the account is created
  ///
  /// In en, this message translates to:
  /// **'Almost done! Enter your business name to finish creating your Deendoon account for {email}.'**
  String googleRegisterInstructions(String email);

  /// No description provided for @googleRegisterPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (Optional)'**
  String get googleRegisterPhoneLabel;

  /// No description provided for @googleRegisterSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get googleRegisterSubmitButton;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter the email associated with your account and we\'ll send you a link to reset your password.'**
  String get forgotPasswordInstructions;

  /// No description provided for @forgotPasswordSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get forgotPasswordSubmitButton;

  /// No description provided for @forgotPasswordHaveCodeLink.
  ///
  /// In en, this message translates to:
  /// **'I already have a reset code'**
  String get forgotPasswordHaveCodeLink;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerBusinessNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get registerBusinessNameLabel;

  /// No description provided for @registerBusinessNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Business name is required'**
  String get registerBusinessNameRequired;

  /// No description provided for @registerFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get registerFullNameLabel;

  /// No description provided for @registerFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get registerFullNameRequired;

  /// No description provided for @registerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get registerPhoneLabel;

  /// No description provided for @registerPhoneValidatorRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get registerPhoneValidatorRequired;

  /// No description provided for @registerConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get registerConfirmPasswordLabel;

  /// No description provided for @registerConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get registerConfirmPasswordRequired;

  /// No description provided for @registerSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerSubmitButton;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset Code'**
  String get resetPasswordCodeLabel;

  /// No description provided for @resetPasswordCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'The code sent to your email'**
  String get resetPasswordCodeHelper;

  /// No description provided for @resetPasswordCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Reset code is required'**
  String get resetPasswordCodeRequired;

  /// No description provided for @resetPasswordNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get resetPasswordNewPasswordLabel;

  /// No description provided for @resetPasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get resetPasswordConfirmLabel;

  /// No description provided for @resetPasswordSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordSubmitButton;

  /// No description provided for @dashboardTodaysOverview.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Overview'**
  String get dashboardTodaysOverview;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardBusinessHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Health'**
  String get dashboardBusinessHealthTitle;

  /// No description provided for @dashboardGreetingFallbackName.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get dashboardGreetingFallbackName;

  /// No description provided for @dashboardGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get dashboardGreetingMorning;

  /// No description provided for @dashboardGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get dashboardGreetingAfternoon;

  /// No description provided for @dashboardGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get dashboardGreetingEvening;

  /// No description provided for @quickActionAddCase.
  ///
  /// In en, this message translates to:
  /// **'Add Case'**
  String get quickActionAddCase;

  /// No description provided for @quickActionRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get quickActionRecordPayment;

  /// No description provided for @quickActionAddReminder.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get quickActionAddReminder;

  /// No description provided for @quickActionGlobalSearch.
  ///
  /// In en, this message translates to:
  /// **'Global Search'**
  String get quickActionGlobalSearch;

  /// No description provided for @kpiOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'KPI Overview'**
  String get kpiOverviewTitle;

  /// No description provided for @kpiLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load KPIs.'**
  String get kpiLoadError;

  /// No description provided for @kpiTotalOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total Outstanding'**
  String get kpiTotalOutstanding;

  /// KPI card label for the Collected figure, scoped to the selected period
  ///
  /// In en, this message translates to:
  /// **'Collected ({period})'**
  String kpiCollectedPeriod(String period);

  /// No description provided for @kpiOverdueAmount.
  ///
  /// In en, this message translates to:
  /// **'Overdue Amount'**
  String get kpiOverdueAmount;

  /// No description provided for @kpiHighRiskCustomers.
  ///
  /// In en, this message translates to:
  /// **'High Risk Customers'**
  String get kpiHighRiskCustomers;

  /// KPI card trend delta compared with the previous month
  ///
  /// In en, this message translates to:
  /// **'{trend} vs last month'**
  String kpiTrendVsLastMonth(String trend);

  /// No description provided for @kpiSelectPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Period'**
  String get kpiSelectPeriodTitle;

  /// No description provided for @kpiPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get kpiPeriodToday;

  /// No description provided for @kpiPeriodYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get kpiPeriodYesterday;

  /// No description provided for @kpiPeriodThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get kpiPeriodThisWeek;

  /// No description provided for @kpiPeriodLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get kpiPeriodLastWeek;

  /// No description provided for @kpiPeriodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get kpiPeriodThisMonth;

  /// No description provided for @kpiPeriodLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get kpiPeriodLastMonth;

  /// No description provided for @kpiPeriodThisQuarter.
  ///
  /// In en, this message translates to:
  /// **'This Quarter'**
  String get kpiPeriodThisQuarter;

  /// No description provided for @kpiPeriodLastQuarter.
  ///
  /// In en, this message translates to:
  /// **'Last Quarter'**
  String get kpiPeriodLastQuarter;

  /// No description provided for @kpiPeriodThisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get kpiPeriodThisYear;

  /// No description provided for @kpiPeriodLastYear.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get kpiPeriodLastYear;

  /// No description provided for @kpiPeriodCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom Date Range'**
  String get kpiPeriodCustomLabel;

  /// No description provided for @statusHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get statusHealthy;

  /// No description provided for @statusNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get statusNeedsAttention;

  /// No description provided for @statusAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At Risk'**
  String get statusAtRisk;

  /// No description provided for @statusNeutralBaseline.
  ///
  /// In en, this message translates to:
  /// **'Neutral Baseline'**
  String get statusNeutralBaseline;

  /// No description provided for @businessHealthSubtextHealthy.
  ///
  /// In en, this message translates to:
  /// **'You are doing great!'**
  String get businessHealthSubtextHealthy;

  /// No description provided for @businessHealthSubtextNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Some areas need review.'**
  String get businessHealthSubtextNeedsAttention;

  /// No description provided for @businessHealthSubtextAtRisk.
  ///
  /// In en, this message translates to:
  /// **'Immediate attention recommended.'**
  String get businessHealthSubtextAtRisk;

  /// No description provided for @businessHealthSubtextNeutralBaseline.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet.'**
  String get businessHealthSubtextNeutralBaseline;

  /// No description provided for @businessHealthLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load Business Health.'**
  String get businessHealthLoadError;

  /// No description provided for @professionalCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Professional Collection'**
  String get professionalCollectionTitle;

  /// No description provided for @professionalCollectionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load Professional Collection summary.'**
  String get professionalCollectionLoadError;

  /// No description provided for @professionalCollectionEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No cases submitted to Deendoon yet'**
  String get professionalCollectionEmptyState;

  /// No description provided for @professionalCollectionLatestRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest Request'**
  String get professionalCollectionLatestRequestLabel;

  /// No description provided for @professionalCollectionListLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load Professional Collection Requests.'**
  String get professionalCollectionListLoadError;

  /// No description provided for @professionalCollectionListEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No Professional Collection Requests yet'**
  String get professionalCollectionListEmptyState;

  /// No description provided for @professionalCollectionListEmptyFilteredState.
  ///
  /// In en, this message translates to:
  /// **'No requests match this filter'**
  String get professionalCollectionListEmptyFilteredState;

  /// No description provided for @professionalCollectionDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Professional Collection Request'**
  String get professionalCollectionDetailTitle;

  /// No description provided for @professionalCollectionDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this Professional Collection Request.'**
  String get professionalCollectionDetailLoadError;

  /// No description provided for @professionalCollectionSubmittedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted By'**
  String get professionalCollectionSubmittedByLabel;

  /// No description provided for @professionalCollectionActionedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Actioned By'**
  String get professionalCollectionActionedByLabel;

  /// No description provided for @professionalCollectionSubmittedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted On'**
  String get professionalCollectionSubmittedOnLabel;

  /// No description provided for @professionalCollectionClosedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Closed On'**
  String get professionalCollectionClosedOnLabel;

  /// No description provided for @professionalCollectionDeclarationAcceptedLabel.
  ///
  /// In en, this message translates to:
  /// **'Declaration Accepted'**
  String get professionalCollectionDeclarationAcceptedLabel;

  /// No description provided for @professionalCollectionDeclarationAcceptedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Declaration Accepted By'**
  String get professionalCollectionDeclarationAcceptedByLabel;

  /// No description provided for @professionalCollectionReasonsForTransferHeading.
  ///
  /// In en, this message translates to:
  /// **'Reasons for Transfer'**
  String get professionalCollectionReasonsForTransferHeading;

  /// No description provided for @professionalCollectionNoReasonsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No reasons recorded for this Request.'**
  String get professionalCollectionNoReasonsRecorded;

  /// No description provided for @professionalCollectionRequestedServicesHeading.
  ///
  /// In en, this message translates to:
  /// **'Requested Services'**
  String get professionalCollectionRequestedServicesHeading;

  /// No description provided for @professionalCollectionNoRequestedServicesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No requested services recorded for this Request.'**
  String get professionalCollectionNoRequestedServicesRecorded;

  /// No description provided for @professionalCollectionNoNotesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No notes were added to this Request.'**
  String get professionalCollectionNoNotesRecorded;

  /// No description provided for @professionalCollectionViewCaseButton.
  ///
  /// In en, this message translates to:
  /// **'View Collection Case'**
  String get professionalCollectionViewCaseButton;

  /// No description provided for @professionalCollectionViewTimelineButton.
  ///
  /// In en, this message translates to:
  /// **'View Timeline'**
  String get professionalCollectionViewTimelineButton;

  /// No description provided for @professionalCollectionViewMessagesButton.
  ///
  /// In en, this message translates to:
  /// **'View Messages'**
  String get professionalCollectionViewMessagesButton;

  /// No description provided for @professionalCollectionTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get professionalCollectionTimelineTitle;

  /// No description provided for @professionalCollectionTimelineLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the timeline.'**
  String get professionalCollectionTimelineLoadError;

  /// No description provided for @professionalCollectionTimelineEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No timeline events yet'**
  String get professionalCollectionTimelineEmptyState;

  /// Professional Collection timeline event card, the outcome recorded by the Deendoon Recovery Team for that event
  ///
  /// In en, this message translates to:
  /// **'Outcome: {outcome}'**
  String professionalCollectionTimelineOutcomeLabel(String outcome);

  /// No description provided for @professionalCollectionDocumentsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No documents linked to this Request yet'**
  String get professionalCollectionDocumentsEmptyState;

  /// No description provided for @professionalCollectionAttachmentsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load attachments.'**
  String get professionalCollectionAttachmentsLoadError;

  /// No description provided for @professionalCollectionAttachmentsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No attachments yet'**
  String get professionalCollectionAttachmentsEmptyState;

  /// No description provided for @professionalCollectionUploadAttachmentButton.
  ///
  /// In en, this message translates to:
  /// **'Upload Attachment'**
  String get professionalCollectionUploadAttachmentButton;

  /// No description provided for @professionalCollectionUploadUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Uploading is not available at this stage of the Request.'**
  String get professionalCollectionUploadUnavailableMessage;

  /// No description provided for @attachmentDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Attachment'**
  String get attachmentDeleteTitle;

  /// No description provided for @attachmentDeleteDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This attachment will be permanently deleted. This cannot be undone.'**
  String get attachmentDeleteDialogContent;

  /// No description provided for @attachmentDeleteConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get attachmentDeleteConfirmButton;

  /// No description provided for @attachmentDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Attachment deleted successfully'**
  String get attachmentDeletedSuccessfully;

  /// No description provided for @professionalCollectionMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get professionalCollectionMessagesTitle;

  /// No description provided for @professionalCollectionMessagesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages.'**
  String get professionalCollectionMessagesLoadError;

  /// No description provided for @professionalCollectionMessagesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get professionalCollectionMessagesEmptyState;

  /// No description provided for @professionalCollectionMessagesClosedNotice.
  ///
  /// In en, this message translates to:
  /// **'This Professional Collection Request is closed — new messages are not accepted.'**
  String get professionalCollectionMessagesClosedNotice;

  /// No description provided for @professionalCollectionMessageInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get professionalCollectionMessageInputHint;

  /// No description provided for @professionalCollectionMessageSenderYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get professionalCollectionMessageSenderYou;

  /// No description provided for @professionalCollectionMessageSenderTeam.
  ///
  /// In en, this message translates to:
  /// **'Deendoon Team'**
  String get professionalCollectionMessageSenderTeam;

  /// No description provided for @professionalCollectionSubmitSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit to Professional Collection'**
  String get professionalCollectionSubmitSheetTitle;

  /// No description provided for @professionalCollectionSubmitSheetDescription.
  ///
  /// In en, this message translates to:
  /// **'This hands the case off to the Deendoon recovery team for review. Your current plan stays active — this is a request, not an approval.'**
  String get professionalCollectionSubmitSheetDescription;

  /// No description provided for @professionalCollectionReasonForTransferHeading.
  ///
  /// In en, this message translates to:
  /// **'Reason for Transfer'**
  String get professionalCollectionReasonForTransferHeading;

  /// No description provided for @professionalCollectionNoActiveReasonsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No active Reasons for Transfer are configured for this tenant yet.'**
  String get professionalCollectionNoActiveReasonsConfigured;

  /// No description provided for @professionalCollectionReasonsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load Reasons for Transfer.'**
  String get professionalCollectionReasonsLoadError;

  /// No description provided for @professionalCollectionNoActiveServicesConfigured.
  ///
  /// In en, this message translates to:
  /// **'No active Requested Services are configured for this tenant yet.'**
  String get professionalCollectionNoActiveServicesConfigured;

  /// No description provided for @professionalCollectionServicesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load Requested Services.'**
  String get professionalCollectionServicesLoadError;

  /// No description provided for @professionalCollectionDeclarationConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'I confirm the Client Declaration for this hand-off.'**
  String get professionalCollectionDeclarationConfirmLabel;

  /// No description provided for @professionalCollectionSubmitReasonsRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Select at least one Reason for Transfer.'**
  String get professionalCollectionSubmitReasonsRequiredValidator;

  /// No description provided for @professionalCollectionSubmitServicesRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Select at least one Requested Service.'**
  String get professionalCollectionSubmitServicesRequiredValidator;

  /// No description provided for @professionalCollectionSubmitDeclarationRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'You must accept the Client Declaration to submit.'**
  String get professionalCollectionSubmitDeclarationRequiredValidator;

  /// No description provided for @professionalCollectionSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get professionalCollectionSubmitButton;

  /// No description provided for @recentCasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Cases'**
  String get recentCasesTitle;

  /// No description provided for @recentCasesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load recent cases.'**
  String get recentCasesLoadError;

  /// No description provided for @recentCasesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get recentCasesEmptyState;

  /// No description provided for @todaysOverviewLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load today\'s overview.'**
  String get todaysOverviewLoadError;

  /// No description provided for @todaysOverviewRemindersDueToday.
  ///
  /// In en, this message translates to:
  /// **'Reminders Due Today'**
  String get todaysOverviewRemindersDueToday;

  /// No description provided for @todaysOverviewPaymentsDue.
  ///
  /// In en, this message translates to:
  /// **'Payments Due'**
  String get todaysOverviewPaymentsDue;

  /// No description provided for @todaysOverviewClientVisits.
  ///
  /// In en, this message translates to:
  /// **'Client Visits'**
  String get todaysOverviewClientVisits;

  /// No description provided for @todaysOverviewFollowUps.
  ///
  /// In en, this message translates to:
  /// **'Follow-ups'**
  String get todaysOverviewFollowUps;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @customerAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get customerAddTitle;

  /// No description provided for @customerEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get customerEditTitle;

  /// No description provided for @customerDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customerDetailsTitle;

  /// No description provided for @customerReadOnlyTooltip.
  ///
  /// In en, this message translates to:
  /// **'This customer is read-only'**
  String get customerReadOnlyTooltip;

  /// No description provided for @customerDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this customer.'**
  String get customerDetailLoadError;

  /// No description provided for @creditLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit'**
  String get creditLimitLabel;

  /// No description provided for @creditLimitHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get creditLimitHint;

  /// No description provided for @creditLimitRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter a credit limit'**
  String get creditLimitRequiredValidator;

  /// No description provided for @creditLimitInvalidValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid credit limit'**
  String get creditLimitInvalidValidator;

  /// No description provided for @customerListTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customerListTitle;

  /// No description provided for @customerListSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get customerListSelectTitle;

  /// No description provided for @customerListShowArchivedFilter.
  ///
  /// In en, this message translates to:
  /// **'Show Archived'**
  String get customerListShowArchivedFilter;

  /// No description provided for @customerListLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load customers.'**
  String get customerListLoadError;

  /// No description provided for @customerListEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get customerListEmptyState;

  /// Customer list empty state when a search query returns no results
  ///
  /// In en, this message translates to:
  /// **'No customers match \"{search}\"'**
  String customerListEmptySearchState(String search);

  /// No description provided for @customerRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Customer restored successfully'**
  String get customerRestoredSuccessfully;

  /// No description provided for @customerArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Customer'**
  String get customerArchiveTitle;

  /// No description provided for @customerArchiveDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This customer will no longer appear in the default list. This can be undone later.'**
  String get customerArchiveDialogContent;

  /// No description provided for @customerArchiveConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get customerArchiveConfirmButton;

  /// No description provided for @customerArchivedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Customer archived successfully'**
  String get customerArchivedSuccessfully;

  /// No description provided for @customerStatementGeneratedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Statement generated successfully'**
  String get customerStatementGeneratedSuccessfully;

  /// No description provided for @customerDetailRecentPaymentsHeading.
  ///
  /// In en, this message translates to:
  /// **'Recent Payments'**
  String get customerDetailRecentPaymentsHeading;

  /// No description provided for @customerDetailViewDebtsButton.
  ///
  /// In en, this message translates to:
  /// **'View Debts'**
  String get customerDetailViewDebtsButton;

  /// No description provided for @customerDetailAttachmentsButton.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get customerDetailAttachmentsButton;

  /// No description provided for @customerDetailGenerateStatementButton.
  ///
  /// In en, this message translates to:
  /// **'Generate Statement'**
  String get customerDetailGenerateStatementButton;

  /// No description provided for @customerReadOnlyBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Read-only Customer'**
  String get customerReadOnlyBannerTitle;

  /// No description provided for @customerReadOnlyBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Your tenant is over its plan\'s customer limit, so this customer cannot be edited, archived, or have documents generated. It remains fully viewable. Upgrade your plan to restore full access.'**
  String get customerReadOnlyBannerMessage;

  /// No description provided for @customerReadOnlyBannerUpgradeButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get customerReadOnlyBannerUpgradeButton;

  /// No description provided for @addEditCustomerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get addEditCustomerNameLabel;

  /// No description provided for @addEditCustomerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the customer\'s name'**
  String get addEditCustomerNameRequired;

  /// No description provided for @addEditCustomerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get addEditCustomerPhoneLabel;

  /// No description provided for @addEditCustomerPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number'**
  String get addEditCustomerPhoneRequired;

  /// No description provided for @addEditCustomerAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (Optional)'**
  String get addEditCustomerAddressLabel;

  /// No description provided for @addEditCustomerContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get addEditCustomerContinueButton;

  /// No description provided for @addEditCustomerDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible Duplicate'**
  String get addEditCustomerDuplicateTitle;

  /// No description provided for @addEditCustomerViewExistingButton.
  ///
  /// In en, this message translates to:
  /// **'View Existing Customer'**
  String get addEditCustomerViewExistingButton;

  /// No description provided for @addEditCustomerPhoneNumbersLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Numbers'**
  String get addEditCustomerPhoneNumbersLabel;

  /// No description provided for @addEditCustomerPhonePrimaryBadge.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get addEditCustomerPhonePrimaryBadge;

  /// No description provided for @addEditCustomerSetPrimaryButton.
  ///
  /// In en, this message translates to:
  /// **'Set Primary'**
  String get addEditCustomerSetPrimaryButton;

  /// No description provided for @addEditCustomerRemovePhoneButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get addEditCustomerRemovePhoneButton;

  /// No description provided for @addEditCustomerAddPhoneButton.
  ///
  /// In en, this message translates to:
  /// **'Add Phone'**
  String get addEditCustomerAddPhoneButton;

  /// No description provided for @addEditCustomerMaxPhoneNumbersMessage.
  ///
  /// In en, this message translates to:
  /// **'You can add up to 3 phone numbers.'**
  String get addEditCustomerMaxPhoneNumbersMessage;

  /// No description provided for @phoneNumberPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Phone Number'**
  String get phoneNumberPickerTitle;

  /// No description provided for @phoneNumberPickerContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get phoneNumberPickerContinueButton;

  /// No description provided for @customerDocumentsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load documents.'**
  String get customerDocumentsLoadError;

  /// No description provided for @customerDocumentsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get customerDocumentsEmptyState;

  /// No description provided for @documentTypeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get documentTypeReceipt;

  /// No description provided for @documentTypeDemandLetter.
  ///
  /// In en, this message translates to:
  /// **'Demand Letter'**
  String get documentTypeDemandLetter;

  /// No description provided for @documentTypeStatement.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get documentTypeStatement;

  /// No description provided for @documentTypeInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get documentTypeInvoice;

  /// No description provided for @documentTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get documentTabAll;

  /// No description provided for @documentListTitleAll.
  ///
  /// In en, this message translates to:
  /// **'All Documents'**
  String get documentListTitleAll;

  /// No description provided for @documentTabInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get documentTabInvoices;

  /// No description provided for @documentTabReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get documentTabReceipts;

  /// No description provided for @documentTabLetters.
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get documentTabLetters;

  /// No description provided for @documentTabOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get documentTabOther;

  /// No description provided for @documentSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search documents...'**
  String get documentSearchHint;

  /// No description provided for @documentRecentDocumentsHeading.
  ///
  /// In en, this message translates to:
  /// **'Recent Documents'**
  String get documentRecentDocumentsHeading;

  /// No description provided for @documentEmptyInvoices.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet'**
  String get documentEmptyInvoices;

  /// No description provided for @documentEmptyReceipts.
  ///
  /// In en, this message translates to:
  /// **'No receipts yet'**
  String get documentEmptyReceipts;

  /// No description provided for @documentEmptyLetters.
  ///
  /// In en, this message translates to:
  /// **'No letters yet'**
  String get documentEmptyLetters;

  /// No description provided for @documentEmptyStatements.
  ///
  /// In en, this message translates to:
  /// **'No statements yet'**
  String get documentEmptyStatements;

  /// No description provided for @documentEmptyStatementsCaption.
  ///
  /// In en, this message translates to:
  /// **'Account statements will appear here once generated.'**
  String get documentEmptyStatementsCaption;

  /// No description provided for @documentHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Document History'**
  String get documentHistoryTitle;

  /// No description provided for @documentHistoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this document\'s history.'**
  String get documentHistoryLoadError;

  /// No description provided for @documentHistoryEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get documentHistoryEmptyState;

  /// No description provided for @documentHistorySystemLabel.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get documentHistorySystemLabel;

  /// No description provided for @documentEventGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get documentEventGenerated;

  /// No description provided for @documentEventDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get documentEventDownloaded;

  /// No description provided for @documentEventRegenerated.
  ///
  /// In en, this message translates to:
  /// **'Regenerated'**
  String get documentEventRegenerated;

  /// No description provided for @documentPreviewFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentPreviewFallbackTitle;

  /// No description provided for @documentDownloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get documentDownloadTooltip;

  /// No description provided for @documentShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get documentShareTooltip;

  /// No description provided for @documentHistoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get documentHistoryTooltip;

  /// No description provided for @documentPreviewLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this document.'**
  String get documentPreviewLoadError;

  /// No description provided for @documentPreviewRenderError.
  ///
  /// In en, this message translates to:
  /// **'Could not render this document.'**
  String get documentPreviewRenderError;

  /// No description provided for @documentShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Document'**
  String get documentShareTitle;

  /// No description provided for @documentSharedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Document shared successfully'**
  String get documentSharedSuccessMessage;

  /// No description provided for @documentStorageUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage Usage'**
  String get documentStorageUsageTitle;

  /// No description provided for @documentStorageUsageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load storage usage.'**
  String get documentStorageUsageLoadError;

  /// Storage Usage card caption, e.g. "1.2 MB of 10.0 GB used"
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} used'**
  String documentStorageUsageLabel(String used, String total);

  /// No description provided for @documentSizeUnitBytes.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get documentSizeUnitBytes;

  /// No description provided for @documentSizeUnitKb.
  ///
  /// In en, this message translates to:
  /// **'KB'**
  String get documentSizeUnitKb;

  /// No description provided for @documentSizeUnitMb.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get documentSizeUnitMb;

  /// No description provided for @documentSizeUnitGb.
  ///
  /// In en, this message translates to:
  /// **'GB'**
  String get documentSizeUnitGb;

  /// No description provided for @customerCasesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load cases.'**
  String get customerCasesLoadError;

  /// No description provided for @customerCasesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No collection cases yet'**
  String get customerCasesEmptyState;

  /// No description provided for @customerCardRestoreButton.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get customerCardRestoreButton;

  /// No description provided for @customerCardArchivedBadge.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get customerCardArchivedBadge;

  /// No description provided for @customerInfoChangeStatusTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change Customer Status'**
  String get customerInfoChangeStatusTooltip;

  /// No description provided for @customerInfoEditCreditLimitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit Credit Limit'**
  String get customerInfoEditCreditLimitTooltip;

  /// No description provided for @customerInfoOutstandingBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Balance'**
  String get customerInfoOutstandingBalanceLabel;

  /// No description provided for @customerInfoRemainingCreditLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining Credit'**
  String get customerInfoRemainingCreditLabel;

  /// No description provided for @customerInfoCreditScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit Score'**
  String get customerInfoCreditScoreLabel;

  /// No description provided for @customerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone'**
  String get customerSearchHint;

  /// No description provided for @customerPaymentsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load recent payments.'**
  String get customerPaymentsLoadError;

  /// No description provided for @customerPaymentsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No recent payments'**
  String get customerPaymentsEmptyState;

  /// No description provided for @customerPaymentsMethodNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Method not recorded'**
  String get customerPaymentsMethodNotRecorded;

  /// No description provided for @creditLimitSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit'**
  String get creditLimitSheetTitle;

  /// No description provided for @customerStatusSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Status'**
  String get customerStatusSheetTitle;

  /// No description provided for @debtListTitle.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get debtListTitle;

  /// No description provided for @debtListSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Debt'**
  String get debtListSelectTitle;

  /// No description provided for @debtListFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get debtListFilterAll;

  /// No description provided for @debtListLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load debts.'**
  String get debtListLoadError;

  /// No description provided for @debtListEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No debts yet'**
  String get debtListEmptyState;

  /// No description provided for @debtListEmptyFilteredState.
  ///
  /// In en, this message translates to:
  /// **'No debts with this status'**
  String get debtListEmptyFilteredState;

  /// No description provided for @debtListShowArchivedFilter.
  ///
  /// In en, this message translates to:
  /// **'Show Archived'**
  String get debtListShowArchivedFilter;

  /// No description provided for @debtRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Debt restored successfully'**
  String get debtRestoredSuccessfully;

  /// No description provided for @debtCardRestoreButton.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get debtCardRestoreButton;

  /// No description provided for @debtCardArchivedBadge.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get debtCardArchivedBadge;

  /// No description provided for @addEditDebtAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Debt'**
  String get addEditDebtAddTitle;

  /// No description provided for @addEditDebtEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Debt'**
  String get addEditDebtEditTitle;

  /// No description provided for @debtDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt Details'**
  String get debtDetailTitle;

  /// No description provided for @debtDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this debt.'**
  String get debtDetailLoadError;

  /// No description provided for @debtArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Debt'**
  String get debtArchiveTitle;

  /// No description provided for @debtArchiveDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This debt will no longer appear in the default list. This can be undone later.'**
  String get debtArchiveDialogContent;

  /// No description provided for @debtArchiveConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get debtArchiveConfirmButton;

  /// No description provided for @debtArchivedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Debt archived successfully'**
  String get debtArchivedSuccessfully;

  /// Shown after a document (e.g. Statement) is generated from the Debt Detail screen
  ///
  /// In en, this message translates to:
  /// **'{label} generated successfully'**
  String debtDetailGenerateSuccessMessage(String label);

  /// Shown when generating a document from the Debt Detail screen fails
  ///
  /// In en, this message translates to:
  /// **'Could not generate {label}'**
  String debtDetailGenerateErrorMessage(String label);

  /// No description provided for @debtDetailInvoiceAttachedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invoice attached successfully'**
  String get debtDetailInvoiceAttachedSuccess;

  /// No description provided for @debtDetailCustomerInfoHeading.
  ///
  /// In en, this message translates to:
  /// **'Customer Information'**
  String get debtDetailCustomerInfoHeading;

  /// No description provided for @debtDetailCustomerLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the customer for this debt.'**
  String get debtDetailCustomerLoadError;

  /// No description provided for @debtDetailSummaryHeading.
  ///
  /// In en, this message translates to:
  /// **'Debt Summary'**
  String get debtDetailSummaryHeading;

  /// No description provided for @promiseToPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Promise to Pay'**
  String get promiseToPayTitle;

  /// No description provided for @debtDetailCaseOpenedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Case opened successfully'**
  String get debtDetailCaseOpenedSuccess;

  /// No description provided for @debtDetailOpenCaseButton.
  ///
  /// In en, this message translates to:
  /// **'Open Case'**
  String get debtDetailOpenCaseButton;

  /// No description provided for @debtDetailLogReminderHeading.
  ///
  /// In en, this message translates to:
  /// **'Log Reminder'**
  String get debtDetailLogReminderHeading;

  /// No description provided for @debtDetailLogWhatsAppButton.
  ///
  /// In en, this message translates to:
  /// **'Log WhatsApp'**
  String get debtDetailLogWhatsAppButton;

  /// No description provided for @debtDetailLogSmsButton.
  ///
  /// In en, this message translates to:
  /// **'Log SMS'**
  String get debtDetailLogSmsButton;

  /// No description provided for @debtDetailLogCallButton.
  ///
  /// In en, this message translates to:
  /// **'Log Call'**
  String get debtDetailLogCallButton;

  /// Label shown for a reminder created from a Debt's context, identifying which debt it relates to
  ///
  /// In en, this message translates to:
  /// **'Debt {referenceNumber}'**
  String debtDetailReminderPresetLabel(String referenceNumber);

  /// No description provided for @debtDetailPaymentHistoryHeading.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get debtDetailPaymentHistoryHeading;

  /// No description provided for @debtDetailFollowUpTimelineHeading.
  ///
  /// In en, this message translates to:
  /// **'Follow-up Timeline'**
  String get debtDetailFollowUpTimelineHeading;

  /// No description provided for @debtDetailPromiseToPayHistoryHeading.
  ///
  /// In en, this message translates to:
  /// **'Promise to Pay History'**
  String get debtDetailPromiseToPayHistoryHeading;

  /// No description provided for @debtDetailGenerateDocumentsHeading.
  ///
  /// In en, this message translates to:
  /// **'Generate Documents'**
  String get debtDetailGenerateDocumentsHeading;

  /// No description provided for @debtDetailRelatedDocumentsHeading.
  ///
  /// In en, this message translates to:
  /// **'Related Documents'**
  String get debtDetailRelatedDocumentsHeading;

  /// No description provided for @debtScanInvoiceButton.
  ///
  /// In en, this message translates to:
  /// **'Scan Invoice'**
  String get debtScanInvoiceButton;

  /// No description provided for @debtUploadInvoiceButton.
  ///
  /// In en, this message translates to:
  /// **'Upload Invoice'**
  String get debtUploadInvoiceButton;

  /// No description provided for @debtDetailRelatedCaseHeading.
  ///
  /// In en, this message translates to:
  /// **'Related Case'**
  String get debtDetailRelatedCaseHeading;

  /// No description provided for @addEditDebtDueDateRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Select a due date.'**
  String get addEditDebtDueDateRequiredError;

  /// Snackbar shown when the Debt itself saved successfully but the attached invoice upload afterward failed
  ///
  /// In en, this message translates to:
  /// **'Debt saved, but the invoice failed: {message}'**
  String addEditDebtInvoiceUploadFailedMessage(String message);

  /// No description provided for @addEditDebtCreditLimitExceededTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit Exceeded'**
  String get addEditDebtCreditLimitExceededTitle;

  /// No description provided for @addEditDebtAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get addEditDebtAmountLabel;

  /// No description provided for @addEditDebtAmountRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get addEditDebtAmountRequiredValidator;

  /// No description provided for @addEditDebtAmountInvalidValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get addEditDebtAmountInvalidValidator;

  /// No description provided for @addEditDebtDueDateHeading.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get addEditDebtDueDateHeading;

  /// No description provided for @addEditDebtSelectDueDateButton.
  ///
  /// In en, this message translates to:
  /// **'Select Due Date'**
  String get addEditDebtSelectDueDateButton;

  /// No description provided for @addEditDebtInvoiceHeading.
  ///
  /// In en, this message translates to:
  /// **'Invoice (Optional)'**
  String get addEditDebtInvoiceHeading;

  /// No description provided for @addEditDebtRemoveInvoiceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove selected invoice'**
  String get addEditDebtRemoveInvoiceTooltip;

  /// No description provided for @addEditDebtNotesHeading.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get addEditDebtNotesHeading;

  /// No description provided for @addEditDebtNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes'**
  String get addEditDebtNotesHint;

  /// No description provided for @debtOriginalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Original Amount'**
  String get debtOriginalAmountLabel;

  /// No description provided for @debtRemainingBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining Balance'**
  String get debtRemainingBalanceLabel;

  /// Debt card due date line
  ///
  /// In en, this message translates to:
  /// **'Due {dueDate}'**
  String debtCardDueDateLabel(String dueDate);

  /// Debt card days-overdue badge
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{{days} day overdue} other{{days} days overdue}}'**
  String debtCardOverdueDays(int days);

  /// No description provided for @debtSummaryDaysOverdueLabel.
  ///
  /// In en, this message translates to:
  /// **'Days Overdue'**
  String get debtSummaryDaysOverdueLabel;

  /// No description provided for @debtPaymentHistoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load payment history.'**
  String get debtPaymentHistoryLoadError;

  /// No description provided for @debtPaymentHistoryEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet'**
  String get debtPaymentHistoryEmptyState;

  /// No description provided for @debtDocumentsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load related documents.'**
  String get debtDocumentsLoadError;

  /// No description provided for @debtTimelineLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the follow-up timeline.'**
  String get debtTimelineLoadError;

  /// No description provided for @debtTimelineStageDebtCreated.
  ///
  /// In en, this message translates to:
  /// **'Debt Created'**
  String get debtTimelineStageDebtCreated;

  /// No description provided for @debtTimelineStageWhatsappReminder.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Reminder'**
  String get debtTimelineStageWhatsappReminder;

  /// No description provided for @debtTimelineStageSmsReminder.
  ///
  /// In en, this message translates to:
  /// **'SMS Reminder'**
  String get debtTimelineStageSmsReminder;

  /// No description provided for @debtTimelineStagePhoneCall.
  ///
  /// In en, this message translates to:
  /// **'Phone Call'**
  String get debtTimelineStagePhoneCall;

  /// No description provided for @debtTimelineStagePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get debtTimelineStagePayment;

  /// No description provided for @debtRelatedCaseLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the related case.'**
  String get debtRelatedCaseLoadError;

  /// No description provided for @debtRelatedCaseEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No collection case has been opened for this debt yet'**
  String get debtRelatedCaseEmptyState;

  /// No description provided for @promiseToPaySheetDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Promised Date'**
  String get promiseToPaySheetDateLabel;

  /// No description provided for @promiseToPaySheetSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Promise'**
  String get promiseToPaySheetSaveButton;

  /// No description provided for @promiseToPayHistoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load Promise to Pay history.'**
  String get promiseToPayHistoryLoadError;

  /// No description provided for @promiseToPayHistoryEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No promises to pay recorded yet'**
  String get promiseToPayHistoryEmptyState;

  /// Promise to Pay history entry, the date the customer promised to pay by
  ///
  /// In en, this message translates to:
  /// **'Promised {date}'**
  String promiseToPayHistoryPromisedLabel(String date);

  /// Promise to Pay history entry, the date the promise was recorded
  ///
  /// In en, this message translates to:
  /// **'Recorded {date}'**
  String promiseToPayHistoryRecordedLabel(String date);

  /// No description provided for @logReminderCallLabel.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get logReminderCallLabel;

  /// Log Reminder sheet title and submit button, e.g. "Log WhatsApp Reminder"
  ///
  /// In en, this message translates to:
  /// **'Log {label}'**
  String logReminderSheetTitle(String label);

  /// No description provided for @logReminderDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get logReminderDetailsLabel;

  /// No description provided for @recordPaymentDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get recordPaymentDateLabel;

  /// No description provided for @recordPaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method (optional)'**
  String get recordPaymentMethodLabel;

  /// No description provided for @recordPaymentNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get recordPaymentNotesLabel;

  /// No description provided for @recordPaymentSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Payment'**
  String get recordPaymentSaveButton;

  /// No description provided for @caseListTabHighRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get caseListTabHighRisk;

  /// No description provided for @caseListTabFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow Up'**
  String get caseListTabFollowUp;

  /// No description provided for @caseListTabPromiseDue.
  ///
  /// In en, this message translates to:
  /// **'Promise Due'**
  String get caseListTabPromiseDue;

  /// No description provided for @caseListBrowseCustomersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Browse Customers'**
  String get caseListBrowseCustomersTooltip;

  /// No description provided for @caseListProfessionalRequestsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Professional Collection Requests'**
  String get caseListProfessionalRequestsTooltip;

  /// No description provided for @caseListEmptyFilteredState.
  ///
  /// In en, this message translates to:
  /// **'No cases match this filter'**
  String get caseListEmptyFilteredState;

  /// No description provided for @caseDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Case Details'**
  String get caseDetailTitle;

  /// No description provided for @caseDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this case.'**
  String get caseDetailLoadError;

  /// No description provided for @caseDetailNoCustomerMessage.
  ///
  /// In en, this message translates to:
  /// **'This case has no associated customer to display.'**
  String get caseDetailNoCustomerMessage;

  /// No description provided for @caseDetailCustomerLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the customer for this case.'**
  String get caseDetailCustomerLoadError;

  /// No description provided for @caseDetailCustomerSummaryHeading.
  ///
  /// In en, this message translates to:
  /// **'Customer Summary'**
  String get caseDetailCustomerSummaryHeading;

  /// No description provided for @caseDetailDebtLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the debt for this case.'**
  String get caseDetailDebtLoadError;

  /// No description provided for @caseDetailCaseSummaryHeading.
  ///
  /// In en, this message translates to:
  /// **'Case Summary'**
  String get caseDetailCaseSummaryHeading;

  /// No description provided for @caseDetailAddFollowUpButton.
  ///
  /// In en, this message translates to:
  /// **'Add Follow-up'**
  String get caseDetailAddFollowUpButton;

  /// No description provided for @caseDetailMarkContactedButton.
  ///
  /// In en, this message translates to:
  /// **'Mark Contacted'**
  String get caseDetailMarkContactedButton;

  /// No description provided for @caseDetailRecordVisitButton.
  ///
  /// In en, this message translates to:
  /// **'Record Visit'**
  String get caseDetailRecordVisitButton;

  /// No description provided for @caseDetailSubmitProfessionalCollectionButton.
  ///
  /// In en, this message translates to:
  /// **'Submit to Professional Collection'**
  String get caseDetailSubmitProfessionalCollectionButton;

  /// No description provided for @caseDetailClosedMessage.
  ///
  /// In en, this message translates to:
  /// **'This case is closed — no further activity, follow-up, or closure actions apply.'**
  String get caseDetailClosedMessage;

  /// No description provided for @caseDetailTimelineHeading.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get caseDetailTimelineHeading;

  /// No description provided for @caseNotesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Notes'**
  String get caseNotesEditTitle;

  /// No description provided for @caseDetailNoNotesMessage.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get caseDetailNoNotesMessage;

  /// Label shown for a reminder created from a Collection Case's context, identifying which case it relates to
  ///
  /// In en, this message translates to:
  /// **'Case {referenceNumber}'**
  String caseDetailReminderPresetLabel(String referenceNumber);

  /// No description provided for @caseDetailRelatedPaymentsHeading.
  ///
  /// In en, this message translates to:
  /// **'Related Payments'**
  String get caseDetailRelatedPaymentsHeading;

  /// No description provided for @professionalCollectionRequestSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Professional Collection Request submitted successfully'**
  String get professionalCollectionRequestSubmittedSuccess;

  /// No description provided for @closeCaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close Case'**
  String get closeCaseTitle;

  /// No description provided for @closeCaseSheetReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Closure Outcome'**
  String get closeCaseSheetReasonLabel;

  /// No description provided for @closeCaseSheetReasonRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter a closure outcome'**
  String get closeCaseSheetReasonRequiredValidator;

  /// No description provided for @editCaseNotesSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Notes'**
  String get editCaseNotesSaveButton;

  /// No description provided for @caseCardUnknownCustomer.
  ///
  /// In en, this message translates to:
  /// **'Unknown customer'**
  String get caseCardUnknownCustomer;

  /// No description provided for @caseCardOutstandingLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get caseCardOutstandingLabel;

  /// No description provided for @caseUnassignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get caseUnassignedLabel;

  /// No description provided for @caseSummaryOutstandingAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Amount'**
  String get caseSummaryOutstandingAmountLabel;

  /// No description provided for @caseSummaryAssignedOfficerLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned Officer'**
  String get caseSummaryAssignedOfficerLabel;

  /// Case Summary card value shown for the assigned officer, an id-only reference (no officer display name is resolvable)
  ///
  /// In en, this message translates to:
  /// **'Officer {officerId}'**
  String caseSummaryOfficerLabel(String officerId);

  /// No description provided for @caseSummaryLastActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Activity'**
  String get caseSummaryLastActivityLabel;

  /// No description provided for @caseTimelineLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the case timeline.'**
  String get caseTimelineLoadError;

  /// No description provided for @caseTimelineEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded yet'**
  String get caseTimelineEmptyState;

  /// No description provided for @collectionStageLabel.
  ///
  /// In en, this message translates to:
  /// **'Collection Stage'**
  String get collectionStageLabel;

  /// Collection Stage card value, e.g. "Stage 3 of 6"
  ///
  /// In en, this message translates to:
  /// **'Stage {stage} of 6'**
  String collectionStageValueLabel(int stage);

  /// No description provided for @reminderListCalendarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get reminderListCalendarTooltip;

  /// No description provided for @reminderScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Reminder'**
  String get reminderScheduleTitle;

  /// No description provided for @reminderFilterPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get reminderFilterPayments;

  /// No description provided for @reminderListLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load reminders.'**
  String get reminderListLoadError;

  /// No description provided for @reminderListEmptyFilteredState.
  ///
  /// In en, this message translates to:
  /// **'Nothing due in this filter'**
  String get reminderListEmptyFilteredState;

  /// No description provided for @reminderListEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Nothing due'**
  String get reminderListEmptyState;

  /// No description provided for @reminderCardCompleteButton.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get reminderCardCompleteButton;

  /// No description provided for @reminderSummaryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the summary.'**
  String get reminderSummaryLoadError;

  /// No description provided for @reminderSummaryDueTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get reminderSummaryDueTodayLabel;

  /// No description provided for @reminderTypeBadgeVisit.
  ///
  /// In en, this message translates to:
  /// **'VISIT'**
  String get reminderTypeBadgeVisit;

  /// No description provided for @reminderTypeBadgeFollowUp.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW-UP'**
  String get reminderTypeBadgeFollowUp;

  /// No description provided for @reminderTypeBadgePayment.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT'**
  String get reminderTypeBadgePayment;

  /// No description provided for @reminderTypeBadgeRenewal.
  ///
  /// In en, this message translates to:
  /// **'RENEWAL'**
  String get reminderTypeBadgeRenewal;

  /// No description provided for @reminderTypeBadgePromise.
  ///
  /// In en, this message translates to:
  /// **'PROMISE'**
  String get reminderTypeBadgePromise;

  /// No description provided for @customerPickerSheetEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get customerPickerSheetEmptyState;

  /// No description provided for @reminderDetailDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder'**
  String get reminderDetailDeleteDialogTitle;

  /// No description provided for @reminderDetailDeleteDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This reminder will no longer appear in any view. This cannot be undone.'**
  String get reminderDetailDeleteDialogContent;

  /// No description provided for @reminderDetailDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get reminderDetailDeleteButton;

  /// No description provided for @reminderDetailNoAddressMessage.
  ///
  /// In en, this message translates to:
  /// **'No customer name or address available to navigate to.'**
  String get reminderDetailNoAddressMessage;

  /// No description provided for @reminderDetailMapsOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open maps.'**
  String get reminderDetailMapsOpenError;

  /// No description provided for @reminderDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder Details'**
  String get reminderDetailTitle;

  /// No description provided for @reminderDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this reminder.'**
  String get reminderDetailLoadError;

  /// No description provided for @reminderDetailTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get reminderDetailTypeLabel;

  /// No description provided for @reminderDetailAmountDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount Due'**
  String get reminderDetailAmountDueLabel;

  /// No description provided for @reminderDetailRelatedCaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Related Case'**
  String get reminderDetailRelatedCaseLabel;

  /// No description provided for @reminderDetailViewCaseLabel.
  ///
  /// In en, this message translates to:
  /// **'View Case'**
  String get reminderDetailViewCaseLabel;

  /// No description provided for @reminderDetailCreatedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Created By'**
  String get reminderDetailCreatedByLabel;

  /// Reminder Details 'Created By' value, shown as a raw user id (no name-resolution endpoint available)
  ///
  /// In en, this message translates to:
  /// **'User {userId}'**
  String reminderDetailCreatedByValue(String userId);

  /// No description provided for @reminderDetailCreatedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Created On'**
  String get reminderDetailCreatedOnLabel;

  /// No description provided for @reminderDetailNoNotesMessage.
  ///
  /// In en, this message translates to:
  /// **'No notes added'**
  String get reminderDetailNoNotesMessage;

  /// No description provided for @reminderDetailNavigateButton.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get reminderDetailNavigateButton;

  /// No description provided for @reminderDetailCheckedInLabel.
  ///
  /// In en, this message translates to:
  /// **'Checked In'**
  String get reminderDetailCheckedInLabel;

  /// No description provided for @reminderDetailCheckInButton.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get reminderDetailCheckInButton;

  /// No description provided for @reminderDetailLogVisitOutcomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Log Visit Outcome'**
  String get reminderDetailLogVisitOutcomeLabel;

  /// No description provided for @reminderDetailSnoozeButton.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get reminderDetailSnoozeButton;

  /// No description provided for @reminderDetailMarkCompletedButton.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get reminderDetailMarkCompletedButton;

  /// No description provided for @reminderDetailWhatsAppButton.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get reminderDetailWhatsAppButton;

  /// No description provided for @reminderDetailSmsButton.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get reminderDetailSmsButton;

  /// No description provided for @reminderDetailRescheduleButton.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reminderDetailRescheduleButton;

  /// No description provided for @reminderDetailLogVisitOutcomeHint.
  ///
  /// In en, this message translates to:
  /// **'What happened during this visit?'**
  String get reminderDetailLogVisitOutcomeHint;

  /// No description provided for @reminderDetailVisitOutcomeSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Visit outcome saved.'**
  String get reminderDetailVisitOutcomeSavedMessage;

  /// No description provided for @reminderSnoozeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Snooze Reminder'**
  String get reminderSnoozeSheetTitle;

  /// No description provided for @reminderSnoozeOneHour.
  ///
  /// In en, this message translates to:
  /// **'1 Hour'**
  String get reminderSnoozeOneHour;

  /// No description provided for @reminderSnoozeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get reminderSnoozeTomorrow;

  /// No description provided for @reminderSnoozeNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next Week'**
  String get reminderSnoozeNextWeek;

  /// No description provided for @reminderSnoozePickDateTime.
  ///
  /// In en, this message translates to:
  /// **'Pick Date & Time'**
  String get reminderSnoozePickDateTime;

  /// Snackbar shown after a reminder is snoozed to a new due date
  ///
  /// In en, this message translates to:
  /// **'Snoozed until {date}.'**
  String reminderSnoozedUntilMessage(String date);

  /// No description provided for @reminderNoPhoneNumberMessage.
  ///
  /// In en, this message translates to:
  /// **'No phone number available for this customer.'**
  String get reminderNoPhoneNumberMessage;

  /// No description provided for @reminderCouldNotOpenDialerMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not open the phone dialer.'**
  String get reminderCouldNotOpenDialerMessage;

  /// No description provided for @reminderTypeClientVisit.
  ///
  /// In en, this message translates to:
  /// **'Client Visit'**
  String get reminderTypeClientVisit;

  /// No description provided for @reminderTypeFollowUpCall.
  ///
  /// In en, this message translates to:
  /// **'Follow-up Call'**
  String get reminderTypeFollowUpCall;

  /// No description provided for @reminderTypePaymentDue.
  ///
  /// In en, this message translates to:
  /// **'Payment Due'**
  String get reminderTypePaymentDue;

  /// No description provided for @reminderTypeContractRenewal.
  ///
  /// In en, this message translates to:
  /// **'Contract Renewal'**
  String get reminderTypeContractRenewal;

  /// No description provided for @reminderTimingOneDayBefore.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get reminderTimingOneDayBefore;

  /// No description provided for @reminderTimingSameDay.
  ///
  /// In en, this message translates to:
  /// **'Same day'**
  String get reminderTimingSameDay;

  /// No description provided for @reminderTimingOneHourBefore.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get reminderTimingOneHourBefore;

  /// No description provided for @reminderTimingCustomTime.
  ///
  /// In en, this message translates to:
  /// **'Custom time'**
  String get reminderTimingCustomTime;

  /// No description provided for @reminderDeliveryInApp.
  ///
  /// In en, this message translates to:
  /// **'In-App Notification'**
  String get reminderDeliveryInApp;

  /// No description provided for @reminderDeliveryPush.
  ///
  /// In en, this message translates to:
  /// **'Push Notification'**
  String get reminderDeliveryPush;

  /// No description provided for @reminderDeliveryWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Message'**
  String get reminderDeliveryWhatsApp;

  /// No description provided for @reminderDeliverySms.
  ///
  /// In en, this message translates to:
  /// **'SMS Message'**
  String get reminderDeliverySms;

  /// No description provided for @reminderScheduleTypeRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Select a reminder type.'**
  String get reminderScheduleTypeRequiredValidator;

  /// No description provided for @reminderScheduleCustomerRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Select a customer.'**
  String get reminderScheduleCustomerRequiredValidator;

  /// No description provided for @reminderScheduleCustomFireRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Select a custom fire date/time.'**
  String get reminderScheduleCustomFireRequiredValidator;

  /// No description provided for @reminderScheduleCustomFireBeforeDueValidator.
  ///
  /// In en, this message translates to:
  /// **'Custom fire time must be on or before the due date.'**
  String get reminderScheduleCustomFireBeforeDueValidator;

  /// No description provided for @reminderScheduleDeliveryMethodRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Select at least one delivery method.'**
  String get reminderScheduleDeliveryMethodRequiredValidator;

  /// No description provided for @reminderScheduleRescheduleLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reminderScheduleRescheduleLoadingTitle;

  /// No description provided for @reminderScheduleRescheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Reschedule Reminder'**
  String get reminderScheduleRescheduleTitle;

  /// No description provided for @reminderScheduleTypeHeading.
  ///
  /// In en, this message translates to:
  /// **'Reminder Type'**
  String get reminderScheduleTypeHeading;

  /// No description provided for @reminderScheduleRelatedToHeading.
  ///
  /// In en, this message translates to:
  /// **'Related To'**
  String get reminderScheduleRelatedToHeading;

  /// No description provided for @reminderScheduleTimingHeading.
  ///
  /// In en, this message translates to:
  /// **'When should this reminder be sent?'**
  String get reminderScheduleTimingHeading;

  /// No description provided for @reminderScheduleSelectCustomFireTimeButton.
  ///
  /// In en, this message translates to:
  /// **'Select Custom Fire Time'**
  String get reminderScheduleSelectCustomFireTimeButton;

  /// No description provided for @reminderScheduleDeliveryMethodsHeading.
  ///
  /// In en, this message translates to:
  /// **'Delivery Methods'**
  String get reminderScheduleDeliveryMethodsHeading;

  /// No description provided for @messagePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Reminder'**
  String get messagePreviewTitle;

  /// No description provided for @messagePreviewWhatsAppOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp.'**
  String get messagePreviewWhatsAppOpenError;

  /// No description provided for @messagePreviewMessagingAppOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the messaging app.'**
  String get messagePreviewMessagingAppOpenError;

  /// No description provided for @messagePreviewUnknownRecipient.
  ///
  /// In en, this message translates to:
  /// **'Unknown recipient'**
  String get messagePreviewUnknownRecipient;

  /// No description provided for @messagePreviewTemplatesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load message templates.'**
  String get messagePreviewTemplatesLoadError;

  /// No description provided for @messagePreviewEmptyTemplatesState.
  ///
  /// In en, this message translates to:
  /// **'No templates available for this channel'**
  String get messagePreviewEmptyTemplatesState;

  /// No description provided for @messagePreviewUseTemplateHeading.
  ///
  /// In en, this message translates to:
  /// **'Use Template'**
  String get messagePreviewUseTemplateHeading;

  /// No description provided for @messagePreviewSendViaWhatsAppButton.
  ///
  /// In en, this message translates to:
  /// **'Send via WhatsApp'**
  String get messagePreviewSendViaWhatsAppButton;

  /// No description provided for @messagePreviewSendViaSmsButton.
  ///
  /// In en, this message translates to:
  /// **'Send via SMS'**
  String get messagePreviewSendViaSmsButton;

  /// No description provided for @notificationMarkAllReadButton.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationMarkAllReadButton;

  /// No description provided for @notificationFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationFilterAll;

  /// No description provided for @notificationListLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications.'**
  String get notificationListLoadError;

  /// No description provided for @notificationListEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationListEmptyState;

  /// Notification list empty state when a type filter is active, e.g. "No Payment Received notifications"
  ///
  /// In en, this message translates to:
  /// **'No {type} notifications'**
  String notificationListEmptyFilteredState(String type);

  /// No description provided for @notificationTypeFallback.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationTypeFallback;

  /// No description provided for @notificationDetailRelatedToLabel.
  ///
  /// In en, this message translates to:
  /// **'Related to'**
  String get notificationDetailRelatedToLabel;

  /// No description provided for @notificationDetailReferenceIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference ID'**
  String get notificationDetailReferenceIdLabel;

  /// No description provided for @notificationDetailReceivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get notificationDetailReceivedLabel;

  /// No description provided for @notificationDetailStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get notificationDetailStatusLabel;

  /// No description provided for @notificationDetailStatusRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notificationDetailStatusRead;

  /// No description provided for @notificationDetailStatusUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationDetailStatusUnread;

  /// No description provided for @notificationDetailOpenButton.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notificationDetailOpenButton;

  /// No description provided for @notificationTypeCreditLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit Reached'**
  String get notificationTypeCreditLimitReached;

  /// No description provided for @notificationTypePaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get notificationTypePaymentReceived;

  /// No description provided for @notificationTypeDocumentAvailable.
  ///
  /// In en, this message translates to:
  /// **'Document Available'**
  String get notificationTypeDocumentAvailable;

  /// No description provided for @notificationTypeCollectionAssignment.
  ///
  /// In en, this message translates to:
  /// **'Collection Assignment'**
  String get notificationTypeCollectionAssignment;

  /// No description provided for @notificationTypeReminderSent.
  ///
  /// In en, this message translates to:
  /// **'Reminder Sent'**
  String get notificationTypeReminderSent;

  /// No description provided for @notificationTypePromiseToPayDue.
  ///
  /// In en, this message translates to:
  /// **'Promise to Pay Due'**
  String get notificationTypePromiseToPayDue;

  /// No description provided for @notificationTypeCollectionRequestUpdate.
  ///
  /// In en, this message translates to:
  /// **'Collection Request Update'**
  String get notificationTypeCollectionRequestUpdate;

  /// No description provided for @notificationTypeSubscriptionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Subscription Update'**
  String get notificationTypeSubscriptionUpdate;

  /// No description provided for @notificationTypeStorageAddonUpdate.
  ///
  /// In en, this message translates to:
  /// **'Storage Add-on Update'**
  String get notificationTypeStorageAddonUpdate;

  /// No description provided for @notificationTypeSupportTicketCreated.
  ///
  /// In en, this message translates to:
  /// **'Support Ticket Created'**
  String get notificationTypeSupportTicketCreated;

  /// No description provided for @notificationTypeSupportTicketReplied.
  ///
  /// In en, this message translates to:
  /// **'Support Ticket Reply'**
  String get notificationTypeSupportTicketReplied;

  /// No description provided for @notificationTypeSupportTicketStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Support Ticket Status Update'**
  String get notificationTypeSupportTicketStatusChanged;

  /// No description provided for @notificationTypeSupportTicketClosed.
  ///
  /// In en, this message translates to:
  /// **'Support Ticket Closed'**
  String get notificationTypeSupportTicketClosed;

  /// No description provided for @notificationTypeSupportTicketReopened.
  ///
  /// In en, this message translates to:
  /// **'Support Ticket Reopened'**
  String get notificationTypeSupportTicketReopened;

  /// No description provided for @notificationTypeAdminAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get notificationTypeAdminAnnouncement;

  /// No description provided for @notificationDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get notificationDeleteAction;

  /// No description provided for @globalSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Global Search'**
  String get globalSearchTitle;

  /// No description provided for @globalSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers, debts, payments, documents, cases'**
  String get globalSearchHint;

  /// No description provided for @globalSearchCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get globalSearchCategoryAll;

  /// No description provided for @globalSearchCategoryCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get globalSearchCategoryCustomers;

  /// No description provided for @globalSearchCategoryDebts.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get globalSearchCategoryDebts;

  /// No description provided for @globalSearchCategoryPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get globalSearchCategoryPayments;

  /// No description provided for @globalSearchCategoryDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get globalSearchCategoryDocuments;

  /// No description provided for @globalSearchCategoryCases.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get globalSearchCategoryCases;

  /// No description provided for @globalSearchErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the search.'**
  String get globalSearchErrorMessage;

  /// No description provided for @globalSearchNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get globalSearchNoResultsTitle;

  /// Global Search empty-results message, showing the query that returned nothing
  ///
  /// In en, this message translates to:
  /// **'Nothing matched \"{query}\". Try a different search term.'**
  String globalSearchNoResultsMessage(String query);

  /// No description provided for @globalSearchDeendoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Deendoon'**
  String get globalSearchDeendoonTitle;

  /// No description provided for @globalSearchDeendoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Find customers, debts, payments, documents, and cases.'**
  String get globalSearchDeendoonMessage;

  /// No description provided for @globalSearchRecentSearchesHeading.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get globalSearchRecentSearchesHeading;

  /// No description provided for @globalSearchClearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get globalSearchClearButton;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarPreviousMonthTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPreviousMonthTooltip;

  /// No description provided for @calendarNextMonthTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonthTooltip;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthDec;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @calendarWeekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get calendarWeekdayMonday;

  /// No description provided for @calendarWeekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get calendarWeekdayTuesday;

  /// No description provided for @calendarWeekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get calendarWeekdayWednesday;

  /// No description provided for @calendarWeekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get calendarWeekdayThursday;

  /// No description provided for @calendarWeekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get calendarWeekdayFriday;

  /// No description provided for @calendarWeekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get calendarWeekdaySaturday;

  /// No description provided for @calendarWeekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get calendarWeekdaySunday;

  /// No description provided for @calendarLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load calendar data.'**
  String get calendarLoadError;

  /// No description provided for @calendarEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get calendarEmptyStateTitle;

  /// No description provided for @calendarEmptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing due, promised, or scheduled on this day.'**
  String get calendarEmptyStateMessage;

  /// No description provided for @calendarFollowUpWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Follow-up'**
  String get calendarFollowUpWhatsApp;

  /// No description provided for @calendarFollowUpSms.
  ///
  /// In en, this message translates to:
  /// **'SMS Follow-up'**
  String get calendarFollowUpSms;

  /// No description provided for @calendarFollowUpCallLogged.
  ///
  /// In en, this message translates to:
  /// **'Call Logged'**
  String get calendarFollowUpCallLogged;

  /// No description provided for @calendarEntryTitleDebtDue.
  ///
  /// In en, this message translates to:
  /// **'Debt Due'**
  String get calendarEntryTitleDebtDue;

  /// Calendar agenda tile title for a due_date entry that carries a debt reference label
  ///
  /// In en, this message translates to:
  /// **'Due: {label}'**
  String calendarEntryTitleDue(String label);

  /// No description provided for @calendarEntryTitleFollowUpFallback.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get calendarEntryTitleFollowUpFallback;

  /// No description provided for @calendarEntryTitleReminderFallback.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get calendarEntryTitleReminderFallback;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get analyticsTabOverview;

  /// No description provided for @analyticsTabReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get analyticsTabReports;

  /// No description provided for @analyticsTabTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get analyticsTabTrends;

  /// No description provided for @analyticsNotIncludedTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics Not Included'**
  String get analyticsNotIncludedTitle;

  /// No description provided for @analyticsNotIncludedMessage.
  ///
  /// In en, this message translates to:
  /// **'Analytics and Reports are not included in your current plan. Upgrade your plan to unlock KPIs, Aging Analysis, Risk Distribution, Collections Trend, and every Report category.'**
  String get analyticsNotIncludedMessage;

  /// No description provided for @analyticsUpgradePlanButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get analyticsUpgradePlanButton;

  /// No description provided for @overviewSectionCollectionAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Collection Analytics'**
  String get overviewSectionCollectionAnalytics;

  /// No description provided for @overviewSectionCollectionsTrend.
  ///
  /// In en, this message translates to:
  /// **'Collections Trend'**
  String get overviewSectionCollectionsTrend;

  /// No description provided for @overviewSectionAgingAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Aging Analysis'**
  String get overviewSectionAgingAnalysis;

  /// No description provided for @overviewSectionRiskDistribution.
  ///
  /// In en, this message translates to:
  /// **'Risk Distribution'**
  String get overviewSectionRiskDistribution;

  /// No description provided for @overviewCollectionAnalyticsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load Collection Analytics.'**
  String get overviewCollectionAnalyticsLoadError;

  /// No description provided for @overviewCollectionsTrendLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load Collections Trend.'**
  String get overviewCollectionsTrendLoadError;

  /// No description provided for @overviewAgingAnalysisLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load Aging Analysis.'**
  String get overviewAgingAnalysisLoadError;

  /// No description provided for @overviewRiskDistributionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load Risk Distribution.'**
  String get overviewRiskDistributionLoadError;

  /// No description provided for @overviewKpiCollectionRate.
  ///
  /// In en, this message translates to:
  /// **'Collection Rate'**
  String get overviewKpiCollectionRate;

  /// No description provided for @overviewKpiTotalCollected.
  ///
  /// In en, this message translates to:
  /// **'Total Collected'**
  String get overviewKpiTotalCollected;

  /// No description provided for @overviewKpiAverageDays.
  ///
  /// In en, this message translates to:
  /// **'Average Days'**
  String get overviewKpiAverageDays;

  /// No description provided for @overviewDonutTotalOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total Outstanding'**
  String get overviewDonutTotalOutstanding;

  /// No description provided for @overviewDonutClassifiedCustomers.
  ///
  /// In en, this message translates to:
  /// **'Classified Customers'**
  String get overviewDonutClassifiedCustomers;

  /// No description provided for @overviewRiskLabelHigh.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get overviewRiskLabelHigh;

  /// No description provided for @overviewRiskLabelMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium Risk'**
  String get overviewRiskLabelMedium;

  /// No description provided for @overviewRiskLabelLow.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get overviewRiskLabelLow;

  /// No description provided for @paymentReportMethodNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Method not recorded'**
  String get paymentReportMethodNotRecorded;

  /// Reports > Payments card, the debt id the payment belongs to
  ///
  /// In en, this message translates to:
  /// **'Debt #{debtId}'**
  String paymentReportDebtIdLabel(String debtId);

  /// No description provided for @dateRangeMonthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get dateRangeMonthJan;

  /// No description provided for @dateRangeMonthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get dateRangeMonthFeb;

  /// No description provided for @dateRangeMonthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get dateRangeMonthMar;

  /// No description provided for @dateRangeMonthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get dateRangeMonthApr;

  /// No description provided for @dateRangeMonthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get dateRangeMonthMay;

  /// No description provided for @dateRangeMonthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get dateRangeMonthJun;

  /// No description provided for @dateRangeMonthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get dateRangeMonthJul;

  /// No description provided for @dateRangeMonthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get dateRangeMonthAug;

  /// No description provided for @dateRangeMonthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get dateRangeMonthSep;

  /// No description provided for @dateRangeMonthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get dateRangeMonthOct;

  /// No description provided for @dateRangeMonthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get dateRangeMonthNov;

  /// No description provided for @dateRangeMonthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dateRangeMonthDec;

  /// No description provided for @reportCategoryCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get reportCategoryCustomers;

  /// No description provided for @reportCategoryDebts.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get reportCategoryDebts;

  /// No description provided for @reportCategoryCollectionCases.
  ///
  /// In en, this message translates to:
  /// **'Collection Cases'**
  String get reportCategoryCollectionCases;

  /// No description provided for @reportCategoryPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get reportCategoryPayments;

  /// No description provided for @reportCategoryCreditRisk.
  ///
  /// In en, this message translates to:
  /// **'Credit Risk'**
  String get reportCategoryCreditRisk;

  /// No description provided for @reportExportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get reportExportTooltip;

  /// No description provided for @reportDebtsTitle.
  ///
  /// In en, this message translates to:
  /// **'Debts Report'**
  String get reportDebtsTitle;

  /// No description provided for @reportDebtsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No debts match this filter'**
  String get reportDebtsEmptyState;

  /// No description provided for @reportCustomersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers Report'**
  String get reportCustomersTitle;

  /// No description provided for @reportCustomersEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No customers match this filter'**
  String get reportCustomersEmptyState;

  /// No description provided for @reportRiskFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All Risk'**
  String get reportRiskFilterAll;

  /// No description provided for @reportCreditRiskTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit Risk Report'**
  String get reportCreditRiskTitle;

  /// No description provided for @reportCreditRiskLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load credit risk report.'**
  String get reportCreditRiskLoadError;

  /// No description provided for @reportCollectionCasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection Cases Report'**
  String get reportCollectionCasesTitle;

  /// No description provided for @reportCollectionCasesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load collection cases.'**
  String get reportCollectionCasesLoadError;

  /// No description provided for @reportPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments Report'**
  String get reportPaymentsTitle;

  /// No description provided for @reportPaymentsClearDateFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear date filter'**
  String get reportPaymentsClearDateFilterTooltip;

  /// No description provided for @reportPaymentsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load payments.'**
  String get reportPaymentsLoadError;

  /// No description provided for @reportPaymentsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No payments in this range'**
  String get reportPaymentsEmptyState;

  /// No description provided for @averageDaysDetailDescription.
  ///
  /// In en, this message translates to:
  /// **'Mean days between a debt\'s due date and the date it was fully paid, for debts paid within this period.'**
  String get averageDaysDetailDescription;

  /// No description provided for @averageDaysDetailDebtsHeading.
  ///
  /// In en, this message translates to:
  /// **'Debts Paid in This Period'**
  String get averageDaysDetailDebtsHeading;

  /// No description provided for @averageDaysDetailEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No debts were paid off within this period.'**
  String get averageDaysDetailEmptyState;

  /// No description provided for @collectionRateDetailFormulaCaption.
  ///
  /// In en, this message translates to:
  /// **'Collected ÷ Amount Due in Period'**
  String get collectionRateDetailFormulaCaption;

  /// No description provided for @collectionRateDetailDebtsHeading.
  ///
  /// In en, this message translates to:
  /// **'Debts Due in This Period'**
  String get collectionRateDetailDebtsHeading;

  /// No description provided for @collectionRateDetailEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No debts became due in this period.'**
  String get collectionRateDetailEmptyState;

  /// No description provided for @agingBucketDebtsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No debts in this bucket'**
  String get agingBucketDebtsEmptyState;

  /// Aging Bucket Debts screen, shown when the fetched debt list is a partial view of the bucket's total count
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total} debts in this bucket.'**
  String agingBucketDebtsShowingCountLabel(int shown, int total);

  /// No description provided for @exportActionSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Export as'**
  String get exportActionSheetTitle;

  /// No description provided for @exportFormatPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get exportFormatPdf;

  /// No description provided for @exportFormatExcel.
  ///
  /// In en, this message translates to:
  /// **'Excel'**
  String get exportFormatExcel;

  /// No description provided for @exportFormatCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get exportFormatCsv;

  /// Snackbar shown after a report export completes, with the local file path it was saved to
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String exportSavedToPathMessage(String path);

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your subscription.'**
  String get subscriptionLoadError;

  /// No description provided for @subscriptionManageStorageButton.
  ///
  /// In en, this message translates to:
  /// **'Manage Storage'**
  String get subscriptionManageStorageButton;

  /// No description provided for @subscriptionAvailablePlansHeading.
  ///
  /// In en, this message translates to:
  /// **'Available Plans'**
  String get subscriptionAvailablePlansHeading;

  /// No description provided for @subscriptionRequestHistoryHeading.
  ///
  /// In en, this message translates to:
  /// **'Request History'**
  String get subscriptionRequestHistoryHeading;

  /// Snackbar shown after a Subscription Plan Change Request is submitted from the Subscription screen
  ///
  /// In en, this message translates to:
  /// **'Plan change request to {planName} submitted — status: Pending.'**
  String subscriptionPlanChangeRequestSubmittedMessage(String planName);

  /// Button shown after selecting a plan on the Subscription screen, to request the change
  ///
  /// In en, this message translates to:
  /// **'Request Plan Change to {planName}'**
  String subscriptionRequestPlanChangeButton(String planName);

  /// No description provided for @subscriptionMonthlyPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly Price'**
  String get subscriptionMonthlyPriceLabel;

  /// No description provided for @subscriptionTrialEndsLabel.
  ///
  /// In en, this message translates to:
  /// **'Trial Ends'**
  String get subscriptionTrialEndsLabel;

  /// No description provided for @subscriptionStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get subscriptionStartDateLabel;

  /// No description provided for @subscriptionExpiryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get subscriptionExpiryDateLabel;

  /// No description provided for @subscriptionCustomersLabel.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get subscriptionCustomersLabel;

  /// No description provided for @storageUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage Used'**
  String get storageUsedLabel;

  /// No description provided for @subscriptionStorageLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage Limit'**
  String get subscriptionStorageLimitLabel;

  /// No description provided for @subscriptionUnlimitedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get subscriptionUnlimitedLabel;

  /// No description provided for @subscriptionAnalyticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get subscriptionAnalyticsLabel;

  /// No description provided for @subscriptionIncludedLabel.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get subscriptionIncludedLabel;

  /// No description provided for @subscriptionNotIncludedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not Included'**
  String get subscriptionNotIncludedLabel;

  /// No description provided for @subscriptionAccountStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get subscriptionAccountStatusLabel;

  /// No description provided for @subscriptionReadOnlyValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get subscriptionReadOnlyValueLabel;

  /// No description provided for @subscriptionNormalValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get subscriptionNormalValueLabel;

  /// No description provided for @subscriptionCustomerLimitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Limit Reached'**
  String get subscriptionCustomerLimitReachedTitle;

  /// No description provided for @subscriptionCustomerLimitReachedMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your current plan\'s customer limit, so adding new customers is blocked. Your existing data remains fully accessible. Upgrade your plan to add more customers.'**
  String get subscriptionCustomerLimitReachedMessage;

  /// No description provided for @subscriptionPlansLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load subscription plans.'**
  String get subscriptionPlansLoadError;

  /// No description provided for @subscriptionNoPlansAvailable.
  ///
  /// In en, this message translates to:
  /// **'No plans available.'**
  String get subscriptionNoPlansAvailable;

  /// No description provided for @subscriptionCurrentPlanBadge.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get subscriptionCurrentPlanBadge;

  /// No description provided for @subscriptionPlanCustomerLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer Limit'**
  String get subscriptionPlanCustomerLimitLabel;

  /// No description provided for @subscriptionChangeRequestHistoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your subscription change request history.'**
  String get subscriptionChangeRequestHistoryLoadError;

  /// No description provided for @subscriptionNoChangeRequestsMessage.
  ///
  /// In en, this message translates to:
  /// **'No subscription change requests yet.'**
  String get subscriptionNoChangeRequestsMessage;

  /// No description provided for @subscriptionLoadMoreButton.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get subscriptionLoadMoreButton;

  /// No description provided for @subscriptionChangeRequestCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Subscription Change Request cancelled.'**
  String get subscriptionChangeRequestCancelledMessage;

  /// No description provided for @subscriptionFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get subscriptionFromLabel;

  /// No description provided for @subscriptionPaymentReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Reference'**
  String get subscriptionPaymentReferenceLabel;

  /// No description provided for @subscriptionRequestedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested On'**
  String get subscriptionRequestedOnLabel;

  /// No description provided for @subscriptionReviewedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Reviewed On'**
  String get subscriptionReviewedOnLabel;

  /// No description provided for @subscriptionRejectionReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get subscriptionRejectionReasonLabel;

  /// No description provided for @subscriptionCancelRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get subscriptionCancelRequestButton;

  /// No description provided for @subscriptionRequestPlanChangeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Plan Change'**
  String get subscriptionRequestPlanChangeSheetTitle;

  /// Request Plan Change sheet description, confirming the target plan and its monthly price before submitting
  ///
  /// In en, this message translates to:
  /// **'You are requesting a change to {planName} ({monthlyPrice} / month). This creates a pending request — your current plan stays active until a Platform Administrator approves it.'**
  String subscriptionRequestPlanChangeDescription(
    String planName,
    String monthlyPrice,
  );

  /// No description provided for @subscriptionPaymentReferenceRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Payment reference is required'**
  String get subscriptionPaymentReferenceRequiredValidator;

  /// No description provided for @subscriptionPaymentReferenceMaxLengthValidator.
  ///
  /// In en, this message translates to:
  /// **'Payment reference must be 100 characters or fewer'**
  String get subscriptionPaymentReferenceMaxLengthValidator;

  /// No description provided for @storageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageTitle;

  /// Snackbar shown after a Storage Add-on request is submitted from the Storage screen
  ///
  /// In en, this message translates to:
  /// **'Storage Add-on request for {label} submitted — pending Platform Administrator approval.'**
  String storageAddonRequestSubmittedMessage(String label);

  /// No description provided for @storageAddonRequestCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Storage Add-on request cancelled.'**
  String get storageAddonRequestCancelledMessage;

  /// No description provided for @storageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your storage usage.'**
  String get storageLoadError;

  /// No description provided for @storageActiveAddonsHeading.
  ///
  /// In en, this message translates to:
  /// **'Active Storage Add-ons'**
  String get storageActiveAddonsHeading;

  /// No description provided for @storageAvailablePackagesHeading.
  ///
  /// In en, this message translates to:
  /// **'Available Storage Packages'**
  String get storageAvailablePackagesHeading;

  /// Button shown after selecting a storage package on the Storage screen, to request the add-on
  ///
  /// In en, this message translates to:
  /// **'Request Storage Add-on ({label})'**
  String storageRequestAddonButton(String label);

  /// No description provided for @storageOverviewHeading.
  ///
  /// In en, this message translates to:
  /// **'Storage Overview'**
  String get storageOverviewHeading;

  /// No description provided for @storageBaseAllowanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Base Storage Allowance'**
  String get storageBaseAllowanceLabel;

  /// No description provided for @storageEffectiveAllowanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective Storage Allowance'**
  String get storageEffectiveAllowanceLabel;

  /// No description provided for @storageRemainingAllowanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining Storage'**
  String get storageRemainingAllowanceLabel;

  /// No description provided for @storageNoActiveAddonsMessage.
  ///
  /// In en, this message translates to:
  /// **'No active storage add-ons.'**
  String get storageNoActiveAddonsMessage;

  /// No description provided for @storageSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get storageSizeLabel;

  /// No description provided for @storageStartedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Started On'**
  String get storageStartedOnLabel;

  /// No description provided for @storageExpiresOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires On'**
  String get storageExpiresOnLabel;

  /// No description provided for @storageRequestAddonSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Storage Add-on'**
  String get storageRequestAddonSheetTitle;

  /// Request Storage Add-on sheet description, confirming the target package before submitting
  ///
  /// In en, this message translates to:
  /// **'You are requesting the {packageLabel} storage add-on. This creates a pending request — it does not increase your storage allowance until a Platform Administrator approves it. The exact monthly price will be confirmed once submitted.'**
  String storageRequestAddonDescription(String packageLabel);

  /// No description provided for @bulkImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk Import'**
  String get bulkImportTitle;

  /// No description provided for @bulkImportSampleTemplateHeading.
  ///
  /// In en, this message translates to:
  /// **'Sample Template'**
  String get bulkImportSampleTemplateHeading;

  /// No description provided for @bulkImportUploadFileHeading.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get bulkImportUploadFileHeading;

  /// No description provided for @bulkImportAcceptedFormats.
  ///
  /// In en, this message translates to:
  /// **'Accepted formats: .xlsx, .xls'**
  String get bulkImportAcceptedFormats;

  /// No description provided for @bulkImportSelectFilePrompt.
  ///
  /// In en, this message translates to:
  /// **'Select Excel file'**
  String get bulkImportSelectFilePrompt;

  /// No description provided for @bulkImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get bulkImportButton;

  /// No description provided for @bulkImportNoRowsFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No rows found in the uploaded file.'**
  String get bulkImportNoRowsFoundMessage;

  /// No description provided for @bulkImportSummaryHeading.
  ///
  /// In en, this message translates to:
  /// **'Import Summary'**
  String get bulkImportSummaryHeading;

  /// No description provided for @bulkImportImportedSuccessfullyLabel.
  ///
  /// In en, this message translates to:
  /// **'Imported Successfully'**
  String get bulkImportImportedSuccessfullyLabel;

  /// No description provided for @bulkImportSkippedDuplicateLabel.
  ///
  /// In en, this message translates to:
  /// **'Skipped (Duplicate)'**
  String get bulkImportSkippedDuplicateLabel;

  /// No description provided for @bulkImportFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get bulkImportFailedLabel;

  /// No description provided for @bulkImportFailedRowsHeading.
  ///
  /// In en, this message translates to:
  /// **'Failed Rows'**
  String get bulkImportFailedRowsHeading;

  /// Failed row card heading in the Bulk Import summary, the 1-based row number from the uploaded file
  ///
  /// In en, this message translates to:
  /// **'Row {rowNumber}'**
  String bulkImportRowLabel(int rowNumber);

  /// No description provided for @bulkImportDownloadTemplateButton.
  ///
  /// In en, this message translates to:
  /// **'Download Sample Template'**
  String get bulkImportDownloadTemplateButton;

  /// No description provided for @agingBucketCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get agingBucketCurrentLabel;

  /// No description provided for @agingBucket1To30Label.
  ///
  /// In en, this message translates to:
  /// **'1–30 Days'**
  String get agingBucket1To30Label;

  /// No description provided for @agingBucket31To60Label.
  ///
  /// In en, this message translates to:
  /// **'31–60 Days'**
  String get agingBucket31To60Label;

  /// No description provided for @agingBucket61To90Label.
  ///
  /// In en, this message translates to:
  /// **'61–90 Days'**
  String get agingBucket61To90Label;

  /// No description provided for @agingBucketOver90Label.
  ///
  /// In en, this message translates to:
  /// **'Over 90 Days'**
  String get agingBucketOver90Label;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountSectionLabel;

  /// No description provided for @accountLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get accountLogout;

  /// No description provided for @accountCloseAccount.
  ///
  /// In en, this message translates to:
  /// **'Close Account'**
  String get accountCloseAccount;

  /// No description provided for @closeAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Close Account'**
  String get closeAccountTitle;

  /// No description provided for @closeAccountWarningHeading.
  ///
  /// In en, this message translates to:
  /// **'What happens when you close your account'**
  String get closeAccountWarningHeading;

  /// No description provided for @closeAccountWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Your account will be archived and your business will be suspended immediately. You will be signed out and will no longer be able to log in. Your customers, debts, payments, documents, and history are kept — nothing is deleted. To reopen your account, contact Deendoon Support.'**
  String get closeAccountWarningBody;

  /// No description provided for @closeAccountPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get closeAccountPasswordLabel;

  /// No description provided for @closeAccountPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get closeAccountPasswordRequired;

  /// No description provided for @closeAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Close My Account'**
  String get closeAccountButton;

  /// No description provided for @closeAccountConfirmDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Close your account?'**
  String get closeAccountConfirmDialogTitle;

  /// No description provided for @closeAccountConfirmDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will immediately sign you out and block access to your business. This cannot be undone by you — only Deendoon Support can reopen it.'**
  String get closeAccountConfirmDialogContent;

  /// No description provided for @closeAccountConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Yes, Close Account'**
  String get closeAccountConfirmButton;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @businessProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get businessProfileTitle;

  /// No description provided for @businessProfileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your business profile.'**
  String get businessProfileLoadError;

  /// No description provided for @businessProfileLogoInvalidTypeError.
  ///
  /// In en, this message translates to:
  /// **'Logo must be a JPEG or PNG image.'**
  String get businessProfileLogoInvalidTypeError;

  /// No description provided for @businessProfileLogoTooLargeError.
  ///
  /// In en, this message translates to:
  /// **'Logo must be 2MB or smaller.'**
  String get businessProfileLogoTooLargeError;

  /// No description provided for @businessProfileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Business Profile updated successfully'**
  String get businessProfileUpdatedSuccess;

  /// No description provided for @businessProfileCompanyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get businessProfileCompanyNameLabel;

  /// No description provided for @businessProfileCompanyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name is required'**
  String get businessProfileCompanyNameRequired;

  /// No description provided for @businessProfileContactEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Email'**
  String get businessProfileContactEmailLabel;

  /// No description provided for @businessProfileContactEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get businessProfileContactEmailInvalid;

  /// No description provided for @businessProfileContactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Phone'**
  String get businessProfileContactPhoneLabel;

  /// No description provided for @businessProfileAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Address'**
  String get businessProfileAddressLabel;

  /// No description provided for @businessProfileLogoNewSelected.
  ///
  /// In en, this message translates to:
  /// **'New logo selected'**
  String get businessProfileLogoNewSelected;

  /// No description provided for @businessProfileLogoOnFile.
  ///
  /// In en, this message translates to:
  /// **'Logo on file — tap to replace'**
  String get businessProfileLogoOnFile;

  /// No description provided for @businessProfileLogoTapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a logo'**
  String get businessProfileLogoTapToAdd;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordCurrentRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get changePasswordCurrentRequired;

  /// No description provided for @changePasswordNewRequired.
  ///
  /// In en, this message translates to:
  /// **'New password is required'**
  String get changePasswordNewRequired;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutDeendoonAboutSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get aboutDeendoonAboutSectionLabel;

  /// No description provided for @aboutDeendoonOthersSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'OTHERS'**
  String get aboutDeendoonOthersSectionLabel;

  /// No description provided for @aboutDeendoonNotPublishedMessage.
  ///
  /// In en, this message translates to:
  /// **'Deendoon is not yet published on the App Store.'**
  String get aboutDeendoonNotPublishedMessage;

  /// No description provided for @aboutDeendoonPlayStoreOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the Play Store.'**
  String get aboutDeendoonPlayStoreOpenError;

  /// No description provided for @aboutDeendoonPrivacyPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutDeendoonPrivacyPolicyLabel;

  /// No description provided for @aboutDeendoonTermsConditionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get aboutDeendoonTermsConditionsLabel;

  /// No description provided for @aboutDeendoonContactSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get aboutDeendoonContactSupportLabel;

  /// No description provided for @aboutDeendoonRateAppLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get aboutDeendoonRateAppLabel;

  /// No description provided for @aboutDeendoonVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutDeendoonVersionLabel;

  /// No description provided for @aboutDeendoonBuildNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get aboutDeendoonBuildNumberLabel;

  /// No description provided for @aboutDeendoonCopyrightLabel.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get aboutDeendoonCopyrightLabel;

  /// About Deendoon section, copyright line value showing the current year
  ///
  /// In en, this message translates to:
  /// **'© {year} Deendoon. All rights reserved.'**
  String aboutDeendoonCopyrightValue(int year);

  /// No description provided for @aboutDeendoonTagline.
  ///
  /// In en, this message translates to:
  /// **'The Modern Assistant for\nDebt Recovery'**
  String get aboutDeendoonTagline;

  /// No description provided for @aboutDeendoonIntroHeading.
  ///
  /// In en, this message translates to:
  /// **'Introduction to DEENDOON'**
  String get aboutDeendoonIntroHeading;

  /// No description provided for @aboutDeendoonIntroParagraph1.
  ///
  /// In en, this message translates to:
  /// **'DEENDOON is an app that helps you easily manage your customers\' debts and recover the money owed to you.'**
  String get aboutDeendoonIntroParagraph1;

  /// No description provided for @aboutDeendoonIntroParagraph2.
  ///
  /// In en, this message translates to:
  /// **'You can record outstanding debts, track payments received and remaining balances, and schedule calls, WhatsApp messages, SMS, and important reminders. The app tells you who you\'ve followed up with and what to do next, so no debt gets forgotten.'**
  String get aboutDeendoonIntroParagraph2;

  /// No description provided for @aboutDeendoonIntroParagraph3.
  ///
  /// In en, this message translates to:
  /// **'If your own efforts aren\'t enough to recover a debt, you can request directly within the app for the Deendoon professional recovery team to represent you legally and professionally, contact the debtor, and work to recover your money.'**
  String get aboutDeendoonIntroParagraph3;

  /// No description provided for @aboutDeendoonBenefitsHeading.
  ///
  /// In en, this message translates to:
  /// **'DEENDOON helps you to:'**
  String get aboutDeendoonBenefitsHeading;

  /// No description provided for @aboutDeendoonBenefit1.
  ///
  /// In en, this message translates to:
  /// **'Record and manage all your debts in one place.'**
  String get aboutDeendoonBenefit1;

  /// No description provided for @aboutDeendoonBenefit2.
  ///
  /// In en, this message translates to:
  /// **'Send timely reminders to your customers.'**
  String get aboutDeendoonBenefit2;

  /// No description provided for @aboutDeendoonBenefit3.
  ///
  /// In en, this message translates to:
  /// **'Track calls, WhatsApp messages, SMS, and appointments.'**
  String get aboutDeendoonBenefit3;

  /// No description provided for @aboutDeendoonBenefit4.
  ///
  /// In en, this message translates to:
  /// **'Record payments received and remaining balances.'**
  String get aboutDeendoonBenefit4;

  /// No description provided for @aboutDeendoonBenefit5.
  ///
  /// In en, this message translates to:
  /// **'Get clear reports on your debts.'**
  String get aboutDeendoonBenefit5;

  /// No description provided for @aboutDeendoonBenefit6.
  ///
  /// In en, this message translates to:
  /// **'Improve the recovery of money owed to you and your business\'s cash flow.'**
  String get aboutDeendoonBenefit6;

  /// No description provided for @aboutDeendoonConclusionHeading.
  ///
  /// In en, this message translates to:
  /// **'Conclusion'**
  String get aboutDeendoonConclusionHeading;

  /// No description provided for @aboutDeendoonConclusionParagraph.
  ///
  /// In en, this message translates to:
  /// **'DEENDOON is a modern assistant that simplifies debt management and strengthens customer follow-up, so your business gets paid on time.'**
  String get aboutDeendoonConclusionParagraph;

  /// No description provided for @aboutDeendoonInfoHeading.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get aboutDeendoonInfoHeading;

  /// No description provided for @subscriptionNoPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'No Plan'**
  String get subscriptionNoPlanLabel;

  /// No description provided for @storageAddonTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'{package} Storage Add-on'**
  String storageAddonTitleLabel(String package);

  /// No description provided for @addCaseEntrySheetExistingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Existing Customer'**
  String get addCaseEntrySheetExistingCustomer;

  /// No description provided for @addCaseEntrySheetNewCustomer.
  ///
  /// In en, this message translates to:
  /// **'New Customer'**
  String get addCaseEntrySheetNewCustomer;

  /// No description provided for @addCaseReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get addCaseReviewTitle;

  /// No description provided for @addCaseReviewCustomerHeading.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get addCaseReviewCustomerHeading;

  /// No description provided for @addCaseReviewCreditLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit: {limit}'**
  String addCaseReviewCreditLimitLabel(String limit);

  /// No description provided for @addCaseReviewDebtHeading.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get addCaseReviewDebtHeading;

  /// No description provided for @addCaseReviewAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount}'**
  String addCaseReviewAmountLabel(String amount);

  /// No description provided for @addCaseReviewDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Date: {date}'**
  String addCaseReviewDueDateLabel(String date);

  /// No description provided for @addCaseReviewNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes: {notes}'**
  String addCaseReviewNotesLabel(String notes);

  /// No description provided for @addCaseReviewInvoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice: {filename}'**
  String addCaseReviewInvoiceLabel(String filename);

  /// No description provided for @addCaseReviewCreateCustomerDebtButton.
  ///
  /// In en, this message translates to:
  /// **'Create Customer & Debt'**
  String get addCaseReviewCreateCustomerDebtButton;

  /// No description provided for @addCaseReviewCreateDebtButton.
  ///
  /// In en, this message translates to:
  /// **'Create Debt'**
  String get addCaseReviewCreateDebtButton;

  /// No description provided for @addCaseReviewTryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get addCaseReviewTryAgainButton;

  /// No description provided for @addCaseReviewCustomerCreatedDebtFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'The customer \"{name}\" was created successfully. Creating the debt failed: {message}'**
  String addCaseReviewCustomerCreatedDebtFailedMessage(
    String name,
    String message,
  );

  /// No description provided for @addCaseReviewOpenCustomerButton.
  ///
  /// In en, this message translates to:
  /// **'Open Customer'**
  String get addCaseReviewOpenCustomerButton;

  /// No description provided for @addCaseReviewDebtCreatedCaseFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Debt {referenceNumber} was created successfully. Creating the Collection Case failed: {message}'**
  String addCaseReviewDebtCreatedCaseFailedMessage(
    String referenceNumber,
    String message,
  );

  /// No description provided for @addCaseReviewCaseLaterHint.
  ///
  /// In en, this message translates to:
  /// **'You can open a Collection Case for this debt later from its Debt Details screen.'**
  String get addCaseReviewCaseLaterHint;

  /// No description provided for @addCaseReviewOpenDebtButton.
  ///
  /// In en, this message translates to:
  /// **'Open Debt'**
  String get addCaseReviewOpenDebtButton;

  /// Aging Analysis legend row: debt count and remaining balance for one bucket
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} debt · {amount}} other{{count} debts · {amount}}}'**
  String overviewAgingLegendValue(int count, String amount);

  /// Risk Distribution legend row: customer count for one risk segment
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} customer} other{{count} customers}}'**
  String overviewRiskLegendValue(int count);

  /// No description provided for @bulkImportUnsupportedFileTypeError.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type. Only .xlsx and .xls files are supported.'**
  String get bulkImportUnsupportedFileTypeError;

  /// No description provided for @supportTicketListTitle.
  ///
  /// In en, this message translates to:
  /// **'My Tickets'**
  String get supportTicketListTitle;

  /// No description provided for @supportTicketListLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your tickets.'**
  String get supportTicketListLoadError;

  /// No description provided for @supportTicketListEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No tickets yet.'**
  String get supportTicketListEmptyState;

  /// No description provided for @supportTicketListEmptyFilteredState.
  ///
  /// In en, this message translates to:
  /// **'No tickets match this status.'**
  String get supportTicketListEmptyFilteredState;

  /// No description provided for @supportTicketCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Ticket'**
  String get supportTicketCreateTitle;

  /// No description provided for @supportTicketCreateValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the subject and description.'**
  String get supportTicketCreateValidationError;

  /// No description provided for @supportTicketSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get supportTicketSubjectLabel;

  /// No description provided for @supportTicketSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe the issue'**
  String get supportTicketSubjectHint;

  /// No description provided for @supportTicketDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get supportTicketDescriptionLabel;

  /// No description provided for @supportTicketDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Give as much detail as you can'**
  String get supportTicketDescriptionHint;

  /// No description provided for @supportTicketPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get supportTicketPriorityLabel;

  /// No description provided for @supportTicketCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get supportTicketCategoryLabel;

  /// No description provided for @supportTicketSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Ticket'**
  String get supportTicketSubmitButton;

  /// No description provided for @supportTicketDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get supportTicketDetailTitle;

  /// No description provided for @supportTicketDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this ticket.'**
  String get supportTicketDetailLoadError;

  /// No description provided for @supportTicketClosedNotice.
  ///
  /// In en, this message translates to:
  /// **'This ticket is closed — new replies are not accepted.'**
  String get supportTicketClosedNotice;

  /// Shown on a closed ticket's detail screen
  ///
  /// In en, this message translates to:
  /// **'Closed on {date}'**
  String supportTicketClosedAtLabel(String date);

  /// Shown on a ticket that has been reopened at least once
  ///
  /// In en, this message translates to:
  /// **'Reopened on {date}'**
  String supportTicketReopenedAtLabel(String date);

  /// No description provided for @supportTicketAttachmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get supportTicketAttachmentsTitle;

  /// No description provided for @supportTicketAttachmentsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load attachments.'**
  String get supportTicketAttachmentsLoadError;

  /// No description provided for @supportTicketNoAttachments.
  ///
  /// In en, this message translates to:
  /// **'No attachments uploaded.'**
  String get supportTicketNoAttachments;

  /// No description provided for @supportTicketUploadButton.
  ///
  /// In en, this message translates to:
  /// **'Attach File'**
  String get supportTicketUploadButton;

  /// No description provided for @supportTicketConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get supportTicketConversationTitle;

  /// No description provided for @supportTicketConversationLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the conversation.'**
  String get supportTicketConversationLoadError;

  /// No description provided for @supportTicketNoRepliesYet.
  ///
  /// In en, this message translates to:
  /// **'No replies yet.'**
  String get supportTicketNoRepliesYet;

  /// No description provided for @supportTicketReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Type a reply'**
  String get supportTicketReplyHint;

  /// No description provided for @supportTicketMessageSenderYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get supportTicketMessageSenderYou;

  /// No description provided for @supportTicketMessageSenderDeendoon.
  ///
  /// In en, this message translates to:
  /// **'Deendoon Support'**
  String get supportTicketMessageSenderDeendoon;

  /// No description provided for @supportTicketPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get supportTicketPriorityLow;

  /// No description provided for @supportTicketPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get supportTicketPriorityMedium;

  /// No description provided for @supportTicketPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get supportTicketPriorityHigh;

  /// No description provided for @supportTicketPriorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get supportTicketPriorityUrgent;

  /// No description provided for @supportTicketCategoryTechnicalIssue.
  ///
  /// In en, this message translates to:
  /// **'Technical Issue'**
  String get supportTicketCategoryTechnicalIssue;

  /// No description provided for @supportTicketCategoryPaymentBilling.
  ///
  /// In en, this message translates to:
  /// **'Payment / Billing'**
  String get supportTicketCategoryPaymentBilling;

  /// No description provided for @supportTicketCategoryAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get supportTicketCategoryAccount;

  /// No description provided for @supportTicketCategorySubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get supportTicketCategorySubscription;

  /// No description provided for @supportTicketCategoryDebtRecovery.
  ///
  /// In en, this message translates to:
  /// **'Debt & Recovery'**
  String get supportTicketCategoryDebtRecovery;

  /// No description provided for @supportTicketCategoryProfessionalCollection.
  ///
  /// In en, this message translates to:
  /// **'Professional Collection'**
  String get supportTicketCategoryProfessionalCollection;

  /// No description provided for @supportTicketCategoryFeatureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get supportTicketCategoryFeatureRequest;

  /// No description provided for @supportTicketCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supportTicketCategoryOther;

  /// No description provided for @supportTicketContactCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Deendoon Support'**
  String get supportTicketContactCardTitle;

  /// No description provided for @supportTicketContactPhoneButton.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get supportTicketContactPhoneButton;

  /// No description provided for @supportTicketContactWhatsAppButton.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get supportTicketContactWhatsAppButton;

  /// No description provided for @supportTicketContactEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get supportTicketContactEmailButton;

  /// No description provided for @supportTicketContactLaunchError.
  ///
  /// In en, this message translates to:
  /// **'Could not open that. Please try again.'**
  String get supportTicketContactLaunchError;
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
      <String>['en', 'so'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'so':
      return AppLocalizationsSo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
