// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionGeneral => 'General';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get sectionSecurity => 'Security';

  @override
  String get sectionBusiness => 'Business';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSomali => 'Somali';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceSystem => 'System Default';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get reminderNotifications => 'Reminder Notifications';

  @override
  String get paymentNotifications => 'Payment Notifications';

  @override
  String get notificationsDisclosure => 'Saved to your business preferences.';

  @override
  String get changePassword => 'Change Password';

  @override
  String get biometricLogin => 'Biometric Login';

  @override
  String get biometricNotSupported => 'Not supported on this device';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get defaultCreditLimit => 'Default Credit Limit';

  @override
  String get creditLimitReminderEnabled => 'Credit Limit Reminder';

  @override
  String get softLimitWarningThreshold => 'Soft Limit Warning Threshold (%)';

  @override
  String get whatsappReminderDays => 'WhatsApp Reminder Days';

  @override
  String get smsReminderDays => 'SMS Reminder Days';

  @override
  String get callReminderDays => 'Call Reminder Days';

  @override
  String get reminderDaysHint => 'Comma-separated days, e.g. 1, 3, 7';

  @override
  String get professionalCollectionThresholdDays =>
      'Professional Collection Threshold (Days)';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get settingsSavedSuccessfully => 'Settings updated successfully';

  @override
  String get couldNotLoadSettings => 'Could not load Settings.';

  @override
  String get retry => 'Retry';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get enterValidNumber => 'Enter a valid number';

  @override
  String get enterValueBetween0And100 => 'Enter a value between 0 and 100';

  @override
  String comingSoonMessage(String value) {
    return '$value — coming soon';
  }

  @override
  String get riskHigh => 'High';

  @override
  String get riskMedium => 'Medium';

  @override
  String get riskLow => 'Low';

  @override
  String get riskUnknown => 'Unknown';

  @override
  String get statusActive => 'Active';

  @override
  String get statusGoodStanding => 'Good Standing';

  @override
  String get statusLatePayer => 'Late Payer';

  @override
  String get statusHighRisk => 'High Risk';

  @override
  String get statusInCollection => 'In Collection';

  @override
  String get statusRecovered => 'Recovered';

  @override
  String get statusBlocked => 'Blocked';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get statusPartiallyPaid => 'Partially Paid';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusWrittenOff => 'Written Off';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusToday => 'Today';

  @override
  String get statusUpcoming => 'Upcoming';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get statusUnderReview => 'Under Review';

  @override
  String get statusNeedMoreInformation => 'Need More Information';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusFulfilled => 'Fulfilled';

  @override
  String get statusBroken => 'Broken';

  @override
  String get statusTrial => 'Trial';

  @override
  String get statusExpired => 'Expired';

  @override
  String get themeSwitchToLight => 'Switch to light mode';

  @override
  String get themeSwitchToDark => 'Switch to dark mode';

  @override
  String get navHome => 'Home';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navCases => 'Cases';

  @override
  String get navReminders => 'Reminders';

  @override
  String get navDocuments => 'Documents';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonViewAll => 'View All';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authEmailInvalid => 'Enter a valid email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String authPasswordMinLength(int minLength) {
    return 'Password must be at least $minLength characters';
  }

  @override
  String get authPasswordsMismatch => 'Passwords do not match';

  @override
  String get loginAppName => 'Deendoon';

  @override
  String get loginTagline => 'Smart Debt Recovery Assistant';

  @override
  String get loginForgotPasswordLink => 'Forgot password?';

  @override
  String get loginSubmitButton => 'Log In';

  @override
  String get loginCreateAccountPrompt =>
      'Don\'t have an account? Create Account';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordInstructions =>
      'Enter the email associated with your account and we\'ll send you a link to reset your password.';

  @override
  String get forgotPasswordSubmitButton => 'Send Reset Link';

  @override
  String get forgotPasswordHaveCodeLink => 'I already have a reset code';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerBusinessNameLabel => 'Business Name';

  @override
  String get registerBusinessNameRequired => 'Business name is required';

  @override
  String get registerFullNameLabel => 'Full Name';

  @override
  String get registerFullNameRequired => 'Full name is required';

  @override
  String get registerPhoneLabel => 'Phone Number';

  @override
  String get registerPhoneValidatorRequired => 'Phone number is required';

  @override
  String get registerConfirmPasswordLabel => 'Confirm Password';

  @override
  String get registerConfirmPasswordRequired => 'Confirm your password';

  @override
  String get registerSubmitButton => 'Create Account';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordCodeLabel => 'Reset Code';

  @override
  String get resetPasswordCodeHelper => 'The code sent to your email';

  @override
  String get resetPasswordCodeRequired => 'Reset code is required';

  @override
  String get resetPasswordNewPasswordLabel => 'New Password';

  @override
  String get resetPasswordConfirmLabel => 'Confirm New Password';

  @override
  String get resetPasswordSubmitButton => 'Reset Password';

  @override
  String get dashboardTodaysOverview => 'Today\'s Overview';

  @override
  String get dashboardQuickActions => 'Quick Actions';

  @override
  String get dashboardBusinessHealthTitle => 'Business Health';

  @override
  String get dashboardGreetingFallbackName => 'there';

  @override
  String get dashboardGreetingMorning => 'Good Morning';

  @override
  String get dashboardGreetingAfternoon => 'Good Afternoon';

  @override
  String get dashboardGreetingEvening => 'Good Evening';

  @override
  String get quickActionAddCase => 'Add Case';

  @override
  String get quickActionRecordPayment => 'Record Payment';

  @override
  String get quickActionAddReminder => 'Add Reminder';

  @override
  String get quickActionGlobalSearch => 'Global Search';

  @override
  String get kpiOverviewTitle => 'KPI Overview';

  @override
  String get kpiLoadError => 'Could not load KPIs.';

  @override
  String get kpiTotalOutstanding => 'Total Outstanding';

  @override
  String kpiCollectedPeriod(String period) {
    return 'Collected ($period)';
  }

  @override
  String get kpiOverdueAmount => 'Overdue Amount';

  @override
  String get kpiHighRiskCustomers => 'High Risk Customers';

  @override
  String kpiTrendVsLastMonth(String trend) {
    return '$trend vs last month';
  }

  @override
  String get kpiSelectPeriodTitle => 'Select Period';

  @override
  String get kpiPeriodToday => 'Today';

  @override
  String get kpiPeriodYesterday => 'Yesterday';

  @override
  String get kpiPeriodThisWeek => 'This Week';

  @override
  String get kpiPeriodLastWeek => 'Last Week';

  @override
  String get kpiPeriodThisMonth => 'This Month';

  @override
  String get kpiPeriodLastMonth => 'Last Month';

  @override
  String get kpiPeriodThisQuarter => 'This Quarter';

  @override
  String get kpiPeriodLastQuarter => 'Last Quarter';

  @override
  String get kpiPeriodThisYear => 'This Year';

  @override
  String get kpiPeriodLastYear => 'Last Year';

  @override
  String get kpiPeriodCustomLabel => 'Custom Date Range';

  @override
  String get statusHealthy => 'Healthy';

  @override
  String get statusNeedsAttention => 'Needs Attention';

  @override
  String get statusAtRisk => 'At Risk';

  @override
  String get statusNeutralBaseline => 'Neutral Baseline';

  @override
  String get businessHealthSubtextHealthy => 'You are doing great!';

  @override
  String get businessHealthSubtextNeedsAttention => 'Some areas need review.';

  @override
  String get businessHealthSubtextAtRisk => 'Immediate attention recommended.';

  @override
  String get businessHealthSubtextNeutralBaseline => 'Not enough data yet.';

  @override
  String get businessHealthLoadError => 'Could not load Business Health.';

  @override
  String get professionalCollectionTitle => 'Professional Collection';

  @override
  String get professionalCollectionLoadError =>
      'Could not load Professional Collection summary.';

  @override
  String get professionalCollectionEmptyState =>
      'No cases submitted to Deendoon yet';

  @override
  String get professionalCollectionLatestRequestLabel => 'Latest Request';

  @override
  String get professionalCollectionListLoadError =>
      'Could not load Professional Collection Requests.';

  @override
  String get professionalCollectionListEmptyState =>
      'No Professional Collection Requests yet';

  @override
  String get professionalCollectionListEmptyFilteredState =>
      'No requests match this filter';

  @override
  String get professionalCollectionDetailTitle =>
      'Professional Collection Request';

  @override
  String get professionalCollectionDetailLoadError =>
      'Could not load this Professional Collection Request.';

  @override
  String get professionalCollectionSubmittedByLabel => 'Submitted By';

  @override
  String get professionalCollectionActionedByLabel => 'Actioned By';

  @override
  String get professionalCollectionSubmittedOnLabel => 'Submitted On';

  @override
  String get professionalCollectionClosedOnLabel => 'Closed On';

  @override
  String get professionalCollectionDeclarationAcceptedLabel =>
      'Declaration Accepted';

  @override
  String get professionalCollectionDeclarationAcceptedByLabel =>
      'Declaration Accepted By';

  @override
  String get professionalCollectionReasonsForTransferHeading =>
      'Reasons for Transfer';

  @override
  String get professionalCollectionNoReasonsRecorded =>
      'No reasons recorded for this Request.';

  @override
  String get professionalCollectionRequestedServicesHeading =>
      'Requested Services';

  @override
  String get professionalCollectionNoRequestedServicesRecorded =>
      'No requested services recorded for this Request.';

  @override
  String get professionalCollectionNoNotesRecorded =>
      'No notes were added to this Request.';

  @override
  String get professionalCollectionViewCaseButton => 'View Collection Case';

  @override
  String get professionalCollectionViewTimelineButton => 'View Timeline';

  @override
  String get professionalCollectionViewMessagesButton => 'View Messages';

  @override
  String get professionalCollectionTimelineTitle => 'Timeline';

  @override
  String get professionalCollectionTimelineLoadError =>
      'Could not load the timeline.';

  @override
  String get professionalCollectionTimelineEmptyState =>
      'No timeline events yet';

  @override
  String professionalCollectionTimelineOutcomeLabel(String outcome) {
    return 'Outcome: $outcome';
  }

  @override
  String get professionalCollectionDocumentsEmptyState =>
      'No documents linked to this Request yet';

  @override
  String get professionalCollectionAttachmentsLoadError =>
      'Could not load attachments.';

  @override
  String get professionalCollectionAttachmentsEmptyState =>
      'No attachments yet';

  @override
  String get professionalCollectionUploadAttachmentButton =>
      'Upload Attachment';

  @override
  String get professionalCollectionUploadUnavailableMessage =>
      'Uploading is not available at this stage of the Request.';

  @override
  String get professionalCollectionMessagesTitle => 'Messages';

  @override
  String get professionalCollectionMessagesLoadError =>
      'Could not load messages.';

  @override
  String get professionalCollectionMessagesEmptyState => 'No messages yet';

  @override
  String get professionalCollectionMessagesClosedNotice =>
      'This Professional Collection Request is closed — new messages are not accepted.';

  @override
  String get professionalCollectionMessageInputHint => 'Type a message';

  @override
  String get professionalCollectionMessageSenderYou => 'You';

  @override
  String get professionalCollectionMessageSenderTeam => 'Deendoon Team';

  @override
  String get professionalCollectionSubmitSheetTitle =>
      'Submit to Professional Collection';

  @override
  String get professionalCollectionSubmitSheetDescription =>
      'This hands the case off to the Deendoon recovery team for review. Your current plan stays active — this is a request, not an approval.';

  @override
  String get professionalCollectionReasonForTransferHeading =>
      'Reason for Transfer';

  @override
  String get professionalCollectionNoActiveReasonsConfigured =>
      'No active Reasons for Transfer are configured for this tenant yet.';

  @override
  String get professionalCollectionReasonsLoadError =>
      'Could not load Reasons for Transfer.';

  @override
  String get professionalCollectionNoActiveServicesConfigured =>
      'No active Requested Services are configured for this tenant yet.';

  @override
  String get professionalCollectionServicesLoadError =>
      'Could not load Requested Services.';

  @override
  String get professionalCollectionDeclarationConfirmLabel =>
      'I confirm the Client Declaration for this hand-off.';

  @override
  String get professionalCollectionSubmitReasonsRequiredValidator =>
      'Select at least one Reason for Transfer.';

  @override
  String get professionalCollectionSubmitServicesRequiredValidator =>
      'Select at least one Requested Service.';

  @override
  String get professionalCollectionSubmitDeclarationRequiredValidator =>
      'You must accept the Client Declaration to submit.';

  @override
  String get professionalCollectionSubmitButton => 'Submit Request';

  @override
  String get recentCasesTitle => 'Recent Cases';

  @override
  String get recentCasesLoadError => 'Could not load recent cases.';

  @override
  String get recentCasesEmptyState => 'No recent activity';

  @override
  String get todaysOverviewLoadError => 'Could not load today\'s overview.';

  @override
  String get todaysOverviewRemindersDueToday => 'Reminders Due Today';

  @override
  String get todaysOverviewPaymentsDue => 'Payments Due';

  @override
  String get todaysOverviewClientVisits => 'Client Visits';

  @override
  String get todaysOverviewFollowUps => 'Follow-ups';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Save';

  @override
  String get customerAddTitle => 'Add Customer';

  @override
  String get customerEditTitle => 'Edit Customer';

  @override
  String get customerDetailsTitle => 'Customer Details';

  @override
  String get customerReadOnlyTooltip => 'This customer is read-only';

  @override
  String get customerDetailLoadError => 'Could not load this customer.';

  @override
  String get creditLimitLabel => 'Credit Limit';

  @override
  String get creditLimitHint => '0.00';

  @override
  String get creditLimitRequiredValidator => 'Enter a credit limit';

  @override
  String get creditLimitInvalidValidator => 'Enter a valid credit limit';

  @override
  String get customerListTitle => 'Customers';

  @override
  String get customerListSelectTitle => 'Select Customer';

  @override
  String get customerListShowArchivedFilter => 'Show Archived';

  @override
  String get customerListLoadError => 'Could not load customers.';

  @override
  String get customerListEmptyState => 'No customers yet';

  @override
  String customerListEmptySearchState(String search) {
    return 'No customers match \"$search\"';
  }

  @override
  String get customerRestoredSuccessfully => 'Customer restored successfully';

  @override
  String get customerArchiveTitle => 'Archive Customer';

  @override
  String get customerArchiveDialogContent =>
      'This customer will no longer appear in the default list. This can be undone later.';

  @override
  String get customerArchiveConfirmButton => 'Archive';

  @override
  String get customerArchivedSuccessfully => 'Customer archived successfully';

  @override
  String get customerStatementGeneratedSuccessfully =>
      'Statement generated successfully';

  @override
  String get customerDetailRecentPaymentsHeading => 'Recent Payments';

  @override
  String get customerDetailViewDebtsButton => 'View Debts';

  @override
  String get customerDetailAttachmentsButton => 'Attachments';

  @override
  String get customerDetailGenerateStatementButton => 'Generate Statement';

  @override
  String get customerReadOnlyBannerTitle => 'Read-only Customer';

  @override
  String get customerReadOnlyBannerMessage =>
      'Your tenant is over its plan\'s customer limit, so this customer cannot be edited, archived, or have documents generated. It remains fully viewable. Upgrade your plan to restore full access.';

  @override
  String get customerReadOnlyBannerUpgradeButton => 'Upgrade Plan';

  @override
  String get addEditCustomerNameLabel => 'Name';

  @override
  String get addEditCustomerNameRequired => 'Enter the customer\'s name';

  @override
  String get addEditCustomerPhoneLabel => 'Phone';

  @override
  String get addEditCustomerPhoneRequired => 'Enter a phone number';

  @override
  String get addEditCustomerAddressLabel => 'Address (Optional)';

  @override
  String get addEditCustomerContinueButton => 'Continue';

  @override
  String get addEditCustomerDuplicateTitle => 'Possible Duplicate';

  @override
  String get addEditCustomerViewExistingButton => 'View Existing Customer';

  @override
  String get customerDocumentsLoadError => 'Could not load documents.';

  @override
  String get customerDocumentsEmptyState => 'No documents yet';

  @override
  String get documentTypeReceipt => 'Receipt';

  @override
  String get documentTypeDemandLetter => 'Demand Letter';

  @override
  String get documentTypeStatement => 'Statement';

  @override
  String get documentTypeInvoice => 'Invoice';

  @override
  String get documentTabAll => 'All';

  @override
  String get documentListTitleAll => 'All Documents';

  @override
  String get documentTabInvoices => 'Invoices';

  @override
  String get documentTabReceipts => 'Receipts';

  @override
  String get documentTabLetters => 'Letters';

  @override
  String get documentTabOther => 'Other';

  @override
  String get documentSearchHint => 'Search documents...';

  @override
  String get documentRecentDocumentsHeading => 'Recent Documents';

  @override
  String get documentEmptyInvoices => 'No invoices yet';

  @override
  String get documentEmptyReceipts => 'No receipts yet';

  @override
  String get documentEmptyLetters => 'No letters yet';

  @override
  String get documentEmptyStatements => 'No statements yet';

  @override
  String get documentEmptyStatementsCaption =>
      'Account statements will appear here once generated.';

  @override
  String get documentHistoryTitle => 'Document History';

  @override
  String get documentHistoryLoadError =>
      'Could not load this document\'s history.';

  @override
  String get documentHistoryEmptyState => 'No history yet';

  @override
  String get documentHistorySystemLabel => 'System';

  @override
  String get documentEventGenerated => 'Generated';

  @override
  String get documentEventDownloaded => 'Downloaded';

  @override
  String get documentEventRegenerated => 'Regenerated';

  @override
  String get documentPreviewFallbackTitle => 'Document';

  @override
  String get documentDownloadTooltip => 'Download';

  @override
  String get documentShareTooltip => 'Share';

  @override
  String get documentHistoryTooltip => 'History';

  @override
  String get documentPreviewLoadError => 'Could not load this document.';

  @override
  String get documentPreviewRenderError => 'Could not render this document.';

  @override
  String get documentShareTitle => 'Share Document';

  @override
  String get documentSharedSuccessMessage => 'Document shared successfully';

  @override
  String get documentStorageUsageTitle => 'Storage Usage';

  @override
  String get documentStorageUsageLoadError => 'Could not load storage usage.';

  @override
  String documentStorageUsageLabel(String used, String total) {
    return '$used of $total used';
  }

  @override
  String get documentSizeUnitBytes => 'B';

  @override
  String get documentSizeUnitKb => 'KB';

  @override
  String get documentSizeUnitMb => 'MB';

  @override
  String get documentSizeUnitGb => 'GB';

  @override
  String get customerCasesLoadError => 'Could not load cases.';

  @override
  String get customerCasesEmptyState => 'No collection cases yet';

  @override
  String get customerCardRestoreButton => 'Restore';

  @override
  String get customerCardArchivedBadge => 'Archived';

  @override
  String get customerInfoChangeStatusTooltip => 'Change Customer Status';

  @override
  String get customerInfoEditCreditLimitTooltip => 'Edit Credit Limit';

  @override
  String get customerInfoOutstandingBalanceLabel => 'Outstanding Balance';

  @override
  String get customerInfoRemainingCreditLabel => 'Remaining Credit';

  @override
  String get customerInfoCreditScoreLabel => 'Credit Score';

  @override
  String get customerSearchHint => 'Search by name or phone';

  @override
  String get customerPaymentsLoadError => 'Could not load recent payments.';

  @override
  String get customerPaymentsEmptyState => 'No recent payments';

  @override
  String get customerPaymentsMethodNotRecorded => 'Method not recorded';

  @override
  String get creditLimitSheetTitle => 'Credit Limit';

  @override
  String get customerStatusSheetTitle => 'Customer Status';

  @override
  String get debtListTitle => 'Debts';

  @override
  String get debtListSelectTitle => 'Select Debt';

  @override
  String get debtListFilterAll => 'All';

  @override
  String get debtListLoadError => 'Could not load debts.';

  @override
  String get debtListEmptyState => 'No debts yet';

  @override
  String get debtListEmptyFilteredState => 'No debts with this status';

  @override
  String get addEditDebtAddTitle => 'Add Debt';

  @override
  String get addEditDebtEditTitle => 'Edit Debt';

  @override
  String get debtDetailTitle => 'Debt Details';

  @override
  String get debtDetailLoadError => 'Could not load this debt.';

  @override
  String debtDetailGenerateSuccessMessage(String label) {
    return '$label generated successfully';
  }

  @override
  String debtDetailGenerateErrorMessage(String label) {
    return 'Could not generate $label';
  }

  @override
  String get debtDetailInvoiceAttachedSuccess =>
      'Invoice attached successfully';

  @override
  String get debtDetailCustomerInfoHeading => 'Customer Information';

  @override
  String get debtDetailCustomerLoadError =>
      'Could not load the customer for this debt.';

  @override
  String get debtDetailSummaryHeading => 'Debt Summary';

  @override
  String get promiseToPayTitle => 'Promise to Pay';

  @override
  String get debtDetailCaseOpenedSuccess => 'Case opened successfully';

  @override
  String get debtDetailOpenCaseButton => 'Open Case';

  @override
  String get debtDetailLogReminderHeading => 'Log Reminder';

  @override
  String get debtDetailLogWhatsAppButton => 'Log WhatsApp';

  @override
  String get debtDetailLogSmsButton => 'Log SMS';

  @override
  String get debtDetailLogCallButton => 'Log Call';

  @override
  String debtDetailReminderPresetLabel(String referenceNumber) {
    return 'Debt $referenceNumber';
  }

  @override
  String get debtDetailPaymentHistoryHeading => 'Payment History';

  @override
  String get debtDetailFollowUpTimelineHeading => 'Follow-up Timeline';

  @override
  String get debtDetailPromiseToPayHistoryHeading => 'Promise to Pay History';

  @override
  String get debtDetailGenerateDocumentsHeading => 'Generate Documents';

  @override
  String get debtDetailRelatedDocumentsHeading => 'Related Documents';

  @override
  String get debtScanInvoiceButton => 'Scan Invoice';

  @override
  String get debtUploadInvoiceButton => 'Upload Invoice';

  @override
  String get debtDetailRelatedCaseHeading => 'Related Case';

  @override
  String get addEditDebtDueDateRequiredError => 'Select a due date.';

  @override
  String addEditDebtInvoiceUploadFailedMessage(String message) {
    return 'Debt saved, but the invoice failed: $message';
  }

  @override
  String get addEditDebtCreditLimitExceededTitle => 'Credit Limit Exceeded';

  @override
  String get addEditDebtAmountLabel => 'Amount';

  @override
  String get addEditDebtAmountRequiredValidator => 'Enter an amount';

  @override
  String get addEditDebtAmountInvalidValidator => 'Enter a valid amount';

  @override
  String get addEditDebtDueDateHeading => 'Due Date';

  @override
  String get addEditDebtSelectDueDateButton => 'Select Due Date';

  @override
  String get addEditDebtInvoiceHeading => 'Invoice (Optional)';

  @override
  String get addEditDebtRemoveInvoiceTooltip => 'Remove selected invoice';

  @override
  String get addEditDebtNotesHeading => 'Notes';

  @override
  String get addEditDebtNotesHint => 'Optional notes';

  @override
  String get debtOriginalAmountLabel => 'Original Amount';

  @override
  String get debtRemainingBalanceLabel => 'Remaining Balance';

  @override
  String debtCardDueDateLabel(String dueDate) {
    return 'Due $dueDate';
  }

  @override
  String debtCardOverdueDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days overdue',
      one: '$days day overdue',
    );
    return '$_temp0';
  }

  @override
  String get debtSummaryDaysOverdueLabel => 'Days Overdue';

  @override
  String get debtPaymentHistoryLoadError => 'Could not load payment history.';

  @override
  String get debtPaymentHistoryEmptyState => 'No payments recorded yet';

  @override
  String get debtDocumentsLoadError => 'Could not load related documents.';

  @override
  String get debtTimelineLoadError => 'Could not load the follow-up timeline.';

  @override
  String get debtTimelineStageDebtCreated => 'Debt Created';

  @override
  String get debtTimelineStageWhatsappReminder => 'WhatsApp Reminder';

  @override
  String get debtTimelineStageSmsReminder => 'SMS Reminder';

  @override
  String get debtTimelineStagePhoneCall => 'Phone Call';

  @override
  String get debtTimelineStagePayment => 'Payment';

  @override
  String get debtRelatedCaseLoadError => 'Could not load the related case.';

  @override
  String get debtRelatedCaseEmptyState =>
      'No collection case has been opened for this debt yet';

  @override
  String get promiseToPaySheetDateLabel => 'Promised Date';

  @override
  String get promiseToPaySheetSaveButton => 'Save Promise';

  @override
  String get promiseToPayHistoryLoadError =>
      'Could not load Promise to Pay history.';

  @override
  String get promiseToPayHistoryEmptyState => 'No promises to pay recorded yet';

  @override
  String promiseToPayHistoryPromisedLabel(String date) {
    return 'Promised $date';
  }

  @override
  String promiseToPayHistoryRecordedLabel(String date) {
    return 'Recorded $date';
  }

  @override
  String get logReminderCallLabel => 'Call';

  @override
  String logReminderSheetTitle(String label) {
    return 'Log $label';
  }

  @override
  String get logReminderDetailsLabel => 'Details (optional)';

  @override
  String get recordPaymentDateLabel => 'Payment Date';

  @override
  String get recordPaymentMethodLabel => 'Payment Method (optional)';

  @override
  String get recordPaymentNotesLabel => 'Notes (optional)';

  @override
  String get recordPaymentSaveButton => 'Save Payment';

  @override
  String get caseListTabHighRisk => 'High Risk';

  @override
  String get caseListTabFollowUp => 'Follow Up';

  @override
  String get caseListTabPromiseDue => 'Promise Due';

  @override
  String get caseListBrowseCustomersTooltip => 'Browse Customers';

  @override
  String get caseListProfessionalRequestsTooltip =>
      'Professional Collection Requests';

  @override
  String get caseListEmptyFilteredState => 'No cases match this filter';

  @override
  String get caseDetailTitle => 'Case Details';

  @override
  String get caseDetailLoadError => 'Could not load this case.';

  @override
  String get caseDetailNoCustomerMessage =>
      'This case has no associated customer to display.';

  @override
  String get caseDetailCustomerLoadError =>
      'Could not load the customer for this case.';

  @override
  String get caseDetailCustomerSummaryHeading => 'Customer Summary';

  @override
  String get caseDetailDebtLoadError =>
      'Could not load the debt for this case.';

  @override
  String get caseDetailCaseSummaryHeading => 'Case Summary';

  @override
  String get caseDetailAddFollowUpButton => 'Add Follow-up';

  @override
  String get caseDetailMarkContactedButton => 'Mark Contacted';

  @override
  String get caseDetailRecordVisitButton => 'Record Visit';

  @override
  String get caseDetailSubmitProfessionalCollectionButton =>
      'Submit to Professional Collection';

  @override
  String get caseDetailClosedMessage =>
      'This case is closed — no further activity, follow-up, or closure actions apply.';

  @override
  String get caseDetailTimelineHeading => 'Timeline';

  @override
  String get caseNotesEditTitle => 'Edit Notes';

  @override
  String get caseDetailNoNotesMessage => 'No notes yet.';

  @override
  String caseDetailReminderPresetLabel(String referenceNumber) {
    return 'Case $referenceNumber';
  }

  @override
  String get caseDetailRelatedPaymentsHeading => 'Related Payments';

  @override
  String get professionalCollectionRequestSubmittedSuccess =>
      'Professional Collection Request submitted successfully';

  @override
  String get closeCaseTitle => 'Close Case';

  @override
  String get closeCaseSheetReasonLabel => 'Closure Outcome';

  @override
  String get closeCaseSheetReasonRequiredValidator => 'Enter a closure outcome';

  @override
  String get editCaseNotesSaveButton => 'Save Notes';

  @override
  String get caseCardUnknownCustomer => 'Unknown customer';

  @override
  String get caseCardOutstandingLabel => 'Outstanding';

  @override
  String get caseUnassignedLabel => 'Unassigned';

  @override
  String get caseSummaryOutstandingAmountLabel => 'Outstanding Amount';

  @override
  String get caseSummaryAssignedOfficerLabel => 'Assigned Officer';

  @override
  String caseSummaryOfficerLabel(String officerId) {
    return 'Officer $officerId';
  }

  @override
  String get caseSummaryLastActivityLabel => 'Last Activity';

  @override
  String get caseTimelineLoadError => 'Could not load the case timeline.';

  @override
  String get caseTimelineEmptyState => 'No activity recorded yet';

  @override
  String get collectionStageLabel => 'Collection Stage';

  @override
  String collectionStageValueLabel(int stage) {
    return 'Stage $stage of 6';
  }

  @override
  String get reminderListCalendarTooltip => 'Calendar';

  @override
  String get reminderScheduleTitle => 'Schedule Reminder';

  @override
  String get reminderFilterPayments => 'Payments';

  @override
  String get reminderListLoadError => 'Could not load reminders.';

  @override
  String get reminderListEmptyFilteredState => 'Nothing due in this filter';

  @override
  String get reminderListEmptyState => 'Nothing due';

  @override
  String get reminderCardCompleteButton => 'Complete';

  @override
  String get reminderSummaryLoadError => 'Could not load the summary.';

  @override
  String get reminderSummaryDueTodayLabel => 'Due Today';

  @override
  String get reminderTypeBadgeVisit => 'VISIT';

  @override
  String get reminderTypeBadgeFollowUp => 'FOLLOW-UP';

  @override
  String get reminderTypeBadgePayment => 'PAYMENT';

  @override
  String get reminderTypeBadgeRenewal => 'RENEWAL';

  @override
  String get reminderTypeBadgePromise => 'PROMISE';

  @override
  String get customerPickerSheetEmptyState => 'No customers found';

  @override
  String get reminderDetailDeleteDialogTitle => 'Delete Reminder';

  @override
  String get reminderDetailDeleteDialogContent =>
      'This reminder will no longer appear in any view. This cannot be undone.';

  @override
  String get reminderDetailDeleteButton => 'Delete';

  @override
  String get reminderDetailNoAddressMessage =>
      'No customer name or address available to navigate to.';

  @override
  String get reminderDetailMapsOpenError => 'Could not open maps.';

  @override
  String get reminderDetailTitle => 'Reminder Details';

  @override
  String get reminderDetailLoadError => 'Could not load this reminder.';

  @override
  String get reminderDetailTypeLabel => 'Type';

  @override
  String get reminderDetailAmountDueLabel => 'Amount Due';

  @override
  String get reminderDetailRelatedCaseLabel => 'Related Case';

  @override
  String get reminderDetailViewCaseLabel => 'View Case';

  @override
  String get reminderDetailCreatedByLabel => 'Created By';

  @override
  String reminderDetailCreatedByValue(String userId) {
    return 'User $userId';
  }

  @override
  String get reminderDetailCreatedOnLabel => 'Created On';

  @override
  String get reminderDetailNoNotesMessage => 'No notes added';

  @override
  String get reminderDetailNavigateButton => 'Navigate';

  @override
  String get reminderDetailCheckedInLabel => 'Checked In';

  @override
  String get reminderDetailCheckInButton => 'Check In';

  @override
  String get reminderDetailLogVisitOutcomeLabel => 'Log Visit Outcome';

  @override
  String get reminderDetailSnoozeButton => 'Snooze';

  @override
  String get reminderDetailMarkCompletedButton => 'Mark as Completed';

  @override
  String get reminderDetailWhatsAppButton => 'WhatsApp';

  @override
  String get reminderDetailSmsButton => 'SMS';

  @override
  String get reminderDetailRescheduleButton => 'Reschedule';

  @override
  String get reminderDetailLogVisitOutcomeHint =>
      'What happened during this visit?';

  @override
  String get reminderDetailVisitOutcomeSavedMessage => 'Visit outcome saved.';

  @override
  String get reminderSnoozeSheetTitle => 'Snooze Reminder';

  @override
  String get reminderSnoozeOneHour => '1 Hour';

  @override
  String get reminderSnoozeTomorrow => 'Tomorrow';

  @override
  String get reminderSnoozeNextWeek => 'Next Week';

  @override
  String get reminderSnoozePickDateTime => 'Pick Date & Time';

  @override
  String reminderSnoozedUntilMessage(String date) {
    return 'Snoozed until $date.';
  }

  @override
  String get reminderNoPhoneNumberMessage =>
      'No phone number available for this customer.';

  @override
  String get reminderCouldNotOpenDialerMessage =>
      'Could not open the phone dialer.';

  @override
  String get reminderTypeClientVisit => 'Client Visit';

  @override
  String get reminderTypeFollowUpCall => 'Follow-up Call';

  @override
  String get reminderTypePaymentDue => 'Payment Due';

  @override
  String get reminderTypeContractRenewal => 'Contract Renewal';

  @override
  String get reminderTimingOneDayBefore => '1 day before';

  @override
  String get reminderTimingSameDay => 'Same day';

  @override
  String get reminderTimingOneHourBefore => '1 hour before';

  @override
  String get reminderTimingCustomTime => 'Custom time';

  @override
  String get reminderDeliveryInApp => 'In-App Notification';

  @override
  String get reminderDeliveryPush => 'Push Notification';

  @override
  String get reminderDeliveryWhatsApp => 'WhatsApp Message';

  @override
  String get reminderDeliverySms => 'SMS Message';

  @override
  String get reminderScheduleTypeRequiredValidator => 'Select a reminder type.';

  @override
  String get reminderScheduleCustomerRequiredValidator => 'Select a customer.';

  @override
  String get reminderScheduleCustomFireRequiredValidator =>
      'Select a custom fire date/time.';

  @override
  String get reminderScheduleCustomFireBeforeDueValidator =>
      'Custom fire time must be on or before the due date.';

  @override
  String get reminderScheduleDeliveryMethodRequiredValidator =>
      'Select at least one delivery method.';

  @override
  String get reminderScheduleRescheduleLoadingTitle => 'Reschedule';

  @override
  String get reminderScheduleRescheduleTitle => 'Reschedule Reminder';

  @override
  String get reminderScheduleTypeHeading => 'Reminder Type';

  @override
  String get reminderScheduleRelatedToHeading => 'Related To';

  @override
  String get reminderScheduleTimingHeading =>
      'When should this reminder be sent?';

  @override
  String get reminderScheduleSelectCustomFireTimeButton =>
      'Select Custom Fire Time';

  @override
  String get reminderScheduleDeliveryMethodsHeading => 'Delivery Methods';

  @override
  String get messagePreviewTitle => 'Send Reminder';

  @override
  String get messagePreviewWhatsAppOpenError => 'Could not open WhatsApp.';

  @override
  String get messagePreviewMessagingAppOpenError =>
      'Could not open the messaging app.';

  @override
  String get messagePreviewUnknownRecipient => 'Unknown recipient';

  @override
  String get messagePreviewTemplatesLoadError =>
      'Could not load message templates.';

  @override
  String get messagePreviewEmptyTemplatesState =>
      'No templates available for this channel';

  @override
  String get messagePreviewUseTemplateHeading => 'Use Template';

  @override
  String get messagePreviewSendViaWhatsAppButton => 'Send via WhatsApp';

  @override
  String get messagePreviewSendViaSmsButton => 'Send via SMS';

  @override
  String get notificationMarkAllReadButton => 'Mark all read';

  @override
  String get notificationFilterAll => 'All';

  @override
  String get notificationListLoadError => 'Could not load notifications.';

  @override
  String get notificationListEmptyState => 'No notifications yet';

  @override
  String notificationListEmptyFilteredState(String type) {
    return 'No $type notifications';
  }

  @override
  String get notificationTypeFallback => 'Notification';

  @override
  String get notificationDetailRelatedToLabel => 'Related to';

  @override
  String get notificationDetailReferenceIdLabel => 'Reference ID';

  @override
  String get notificationDetailReceivedLabel => 'Received';

  @override
  String get notificationDetailStatusLabel => 'Status';

  @override
  String get notificationDetailStatusRead => 'Read';

  @override
  String get notificationDetailStatusUnread => 'Unread';

  @override
  String get notificationDetailOpenButton => 'Open';

  @override
  String get notificationTypeCreditLimitReached => 'Credit Limit Reached';

  @override
  String get notificationTypePaymentReceived => 'Payment Received';

  @override
  String get notificationTypeDocumentAvailable => 'Document Available';

  @override
  String get notificationTypeCollectionAssignment => 'Collection Assignment';

  @override
  String get notificationTypeReminderSent => 'Reminder Sent';

  @override
  String get notificationTypePromiseToPayDue => 'Promise to Pay Due';

  @override
  String get notificationTypeCollectionRequestUpdate =>
      'Collection Request Update';

  @override
  String get notificationTypeSubscriptionUpdate => 'Subscription Update';

  @override
  String get notificationTypeStorageAddonUpdate => 'Storage Add-on Update';

  @override
  String get globalSearchTitle => 'Global Search';

  @override
  String get globalSearchHint =>
      'Search customers, debts, payments, documents, cases';

  @override
  String get globalSearchCategoryAll => 'All';

  @override
  String get globalSearchCategoryCustomers => 'Customers';

  @override
  String get globalSearchCategoryDebts => 'Debts';

  @override
  String get globalSearchCategoryPayments => 'Payments';

  @override
  String get globalSearchCategoryDocuments => 'Documents';

  @override
  String get globalSearchCategoryCases => 'Cases';

  @override
  String get globalSearchErrorMessage => 'Could not complete the search.';

  @override
  String get globalSearchNoResultsTitle => 'No results found';

  @override
  String globalSearchNoResultsMessage(String query) {
    return 'Nothing matched \"$query\". Try a different search term.';
  }

  @override
  String get globalSearchDeendoonTitle => 'Search Deendoon';

  @override
  String get globalSearchDeendoonMessage =>
      'Find customers, debts, payments, documents, and cases.';

  @override
  String get globalSearchRecentSearchesHeading => 'Recent Searches';

  @override
  String get globalSearchClearButton => 'Clear';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarPreviousMonthTooltip => 'Previous month';

  @override
  String get calendarNextMonthTooltip => 'Next month';

  @override
  String get monthJan => 'January';

  @override
  String get monthFeb => 'February';

  @override
  String get monthMar => 'March';

  @override
  String get monthApr => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'June';

  @override
  String get monthJul => 'July';

  @override
  String get monthAug => 'August';

  @override
  String get monthSep => 'September';

  @override
  String get monthOct => 'October';

  @override
  String get monthNov => 'November';

  @override
  String get monthDec => 'December';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get calendarWeekdayMonday => 'Monday';

  @override
  String get calendarWeekdayTuesday => 'Tuesday';

  @override
  String get calendarWeekdayWednesday => 'Wednesday';

  @override
  String get calendarWeekdayThursday => 'Thursday';

  @override
  String get calendarWeekdayFriday => 'Friday';

  @override
  String get calendarWeekdaySaturday => 'Saturday';

  @override
  String get calendarWeekdaySunday => 'Sunday';

  @override
  String get calendarLoadError => 'Could not load calendar data.';

  @override
  String get calendarEmptyStateTitle => 'No events';

  @override
  String get calendarEmptyStateMessage =>
      'Nothing due, promised, or scheduled on this day.';

  @override
  String get calendarFollowUpWhatsApp => 'WhatsApp Follow-up';

  @override
  String get calendarFollowUpSms => 'SMS Follow-up';

  @override
  String get calendarFollowUpCallLogged => 'Call Logged';

  @override
  String get calendarEntryTitleDebtDue => 'Debt Due';

  @override
  String calendarEntryTitleDue(String label) {
    return 'Due: $label';
  }

  @override
  String get calendarEntryTitleFollowUpFallback => 'Follow-up';

  @override
  String get calendarEntryTitleReminderFallback => 'Reminder';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get analyticsTabOverview => 'Overview';

  @override
  String get analyticsTabReports => 'Reports';

  @override
  String get analyticsTabTrends => 'Trends';

  @override
  String get analyticsNotIncludedTitle => 'Analytics Not Included';

  @override
  String get analyticsNotIncludedMessage =>
      'Analytics and Reports are not included in your current plan. Upgrade your plan to unlock KPIs, Aging Analysis, Risk Distribution, Collections Trend, and every Report category.';

  @override
  String get analyticsUpgradePlanButton => 'Upgrade Plan';

  @override
  String get overviewSectionCollectionAnalytics => 'Collection Analytics';

  @override
  String get overviewSectionCollectionsTrend => 'Collections Trend';

  @override
  String get overviewSectionAgingAnalysis => 'Aging Analysis';

  @override
  String get overviewSectionRiskDistribution => 'Risk Distribution';

  @override
  String get overviewCollectionAnalyticsLoadError =>
      'Could not load Collection Analytics.';

  @override
  String get overviewCollectionsTrendLoadError =>
      'Could not load Collections Trend.';

  @override
  String get overviewAgingAnalysisLoadError => 'Could not load Aging Analysis.';

  @override
  String get overviewRiskDistributionLoadError =>
      'Could not load Risk Distribution.';

  @override
  String get overviewKpiCollectionRate => 'Collection Rate';

  @override
  String get overviewKpiTotalCollected => 'Total Collected';

  @override
  String get overviewKpiAverageDays => 'Average Days';

  @override
  String get overviewDonutTotalOutstanding => 'Total Outstanding';

  @override
  String get overviewDonutClassifiedCustomers => 'Classified Customers';

  @override
  String get overviewRiskLabelHigh => 'High Risk';

  @override
  String get overviewRiskLabelMedium => 'Medium Risk';

  @override
  String get overviewRiskLabelLow => 'Low Risk';

  @override
  String get paymentReportMethodNotRecorded => 'Method not recorded';

  @override
  String paymentReportDebtIdLabel(String debtId) {
    return 'Debt #$debtId';
  }

  @override
  String get dateRangeMonthJan => 'Jan';

  @override
  String get dateRangeMonthFeb => 'Feb';

  @override
  String get dateRangeMonthMar => 'Mar';

  @override
  String get dateRangeMonthApr => 'Apr';

  @override
  String get dateRangeMonthMay => 'May';

  @override
  String get dateRangeMonthJun => 'Jun';

  @override
  String get dateRangeMonthJul => 'Jul';

  @override
  String get dateRangeMonthAug => 'Aug';

  @override
  String get dateRangeMonthSep => 'Sep';

  @override
  String get dateRangeMonthOct => 'Oct';

  @override
  String get dateRangeMonthNov => 'Nov';

  @override
  String get dateRangeMonthDec => 'Dec';

  @override
  String get reportCategoryCustomers => 'Customers';

  @override
  String get reportCategoryDebts => 'Debts';

  @override
  String get reportCategoryCollectionCases => 'Collection Cases';

  @override
  String get reportCategoryPayments => 'Payments';

  @override
  String get reportCategoryCreditRisk => 'Credit Risk';

  @override
  String get reportExportTooltip => 'Export';

  @override
  String get reportDebtsTitle => 'Debts Report';

  @override
  String get reportDebtsEmptyState => 'No debts match this filter';

  @override
  String get reportCustomersTitle => 'Customers Report';

  @override
  String get reportCustomersEmptyState => 'No customers match this filter';

  @override
  String get reportRiskFilterAll => 'All Risk';

  @override
  String get reportCreditRiskTitle => 'Credit Risk Report';

  @override
  String get reportCreditRiskLoadError => 'Could not load credit risk report.';

  @override
  String get reportCollectionCasesTitle => 'Collection Cases Report';

  @override
  String get reportCollectionCasesLoadError =>
      'Could not load collection cases.';

  @override
  String get reportPaymentsTitle => 'Payments Report';

  @override
  String get reportPaymentsClearDateFilterTooltip => 'Clear date filter';

  @override
  String get reportPaymentsLoadError => 'Could not load payments.';

  @override
  String get reportPaymentsEmptyState => 'No payments in this range';

  @override
  String get averageDaysDetailDescription =>
      'Mean days between a debt\'s due date and the date it was fully paid, for debts paid within this period.';

  @override
  String get averageDaysDetailDebtsHeading => 'Debts Paid in This Period';

  @override
  String get averageDaysDetailEmptyState =>
      'No debts were paid off within this period.';

  @override
  String get collectionRateDetailFormulaCaption =>
      'Collected ÷ Amount Due in Period';

  @override
  String get collectionRateDetailDebtsHeading => 'Debts Due in This Period';

  @override
  String get collectionRateDetailEmptyState =>
      'No debts became due in this period.';

  @override
  String get agingBucketDebtsEmptyState => 'No debts in this bucket';

  @override
  String agingBucketDebtsShowingCountLabel(int shown, int total) {
    return 'Showing $shown of $total debts in this bucket.';
  }

  @override
  String get exportActionSheetTitle => 'Export as';

  @override
  String get exportFormatPdf => 'PDF';

  @override
  String get exportFormatExcel => 'Excel';

  @override
  String get exportFormatCsv => 'CSV';

  @override
  String exportSavedToPathMessage(String path) {
    return 'Saved to $path';
  }

  @override
  String get subscriptionTitle => 'Subscription';

  @override
  String get subscriptionLoadError => 'Could not load your subscription.';

  @override
  String get subscriptionManageStorageButton => 'Manage Storage';

  @override
  String get subscriptionAvailablePlansHeading => 'Available Plans';

  @override
  String get subscriptionRequestHistoryHeading => 'Request History';

  @override
  String subscriptionPlanChangeRequestSubmittedMessage(String planName) {
    return 'Plan change request to $planName submitted — status: Pending.';
  }

  @override
  String subscriptionRequestPlanChangeButton(String planName) {
    return 'Request Plan Change to $planName';
  }

  @override
  String get subscriptionMonthlyPriceLabel => 'Monthly Price';

  @override
  String get subscriptionTrialEndsLabel => 'Trial Ends';

  @override
  String get subscriptionStartDateLabel => 'Start Date';

  @override
  String get subscriptionExpiryDateLabel => 'Expiry Date';

  @override
  String get subscriptionCustomersLabel => 'Customers';

  @override
  String get storageUsedLabel => 'Storage Used';

  @override
  String get subscriptionStorageLimitLabel => 'Storage Limit';

  @override
  String get subscriptionUnlimitedLabel => 'Unlimited';

  @override
  String get subscriptionAnalyticsLabel => 'Analytics';

  @override
  String get subscriptionIncludedLabel => 'Included';

  @override
  String get subscriptionNotIncludedLabel => 'Not Included';

  @override
  String get subscriptionAccountStatusLabel => 'Account Status';

  @override
  String get subscriptionReadOnlyValueLabel => 'Read-only';

  @override
  String get subscriptionNormalValueLabel => 'Normal';

  @override
  String get subscriptionCustomerLimitReachedTitle => 'Customer Limit Reached';

  @override
  String get subscriptionCustomerLimitReachedMessage =>
      'You\'ve reached your current plan\'s customer limit, so adding new customers is blocked. Your existing data remains fully accessible. Upgrade your plan to add more customers.';

  @override
  String get subscriptionPlansLoadError => 'Could not load subscription plans.';

  @override
  String get subscriptionNoPlansAvailable => 'No plans available.';

  @override
  String get subscriptionCurrentPlanBadge => 'Current Plan';

  @override
  String get subscriptionPlanCustomerLimitLabel => 'Customer Limit';

  @override
  String get subscriptionChangeRequestHistoryLoadError =>
      'Could not load your subscription change request history.';

  @override
  String get subscriptionNoChangeRequestsMessage =>
      'No subscription change requests yet.';

  @override
  String get subscriptionLoadMoreButton => 'Load More';

  @override
  String get subscriptionChangeRequestCancelledMessage =>
      'Subscription Change Request cancelled.';

  @override
  String get subscriptionFromLabel => 'From';

  @override
  String get subscriptionPaymentReferenceLabel => 'Payment Reference';

  @override
  String get subscriptionRequestedOnLabel => 'Requested On';

  @override
  String get subscriptionReviewedOnLabel => 'Reviewed On';

  @override
  String get subscriptionRejectionReasonLabel => 'Rejection Reason';

  @override
  String get subscriptionCancelRequestButton => 'Cancel Request';

  @override
  String get subscriptionRequestPlanChangeSheetTitle => 'Request Plan Change';

  @override
  String subscriptionRequestPlanChangeDescription(
    String planName,
    String monthlyPrice,
  ) {
    return 'You are requesting a change to $planName ($monthlyPrice / month). This creates a pending request — your current plan stays active until a Platform Administrator approves it.';
  }

  @override
  String get subscriptionPaymentReferenceRequiredValidator =>
      'Payment reference is required';

  @override
  String get subscriptionPaymentReferenceMaxLengthValidator =>
      'Payment reference must be 100 characters or fewer';

  @override
  String get storageTitle => 'Storage';

  @override
  String storageAddonRequestSubmittedMessage(String label) {
    return 'Storage Add-on request for $label submitted — pending Platform Administrator approval.';
  }

  @override
  String get storageAddonRequestCancelledMessage =>
      'Storage Add-on request cancelled.';

  @override
  String get storageLoadError => 'Could not load your storage usage.';

  @override
  String get storageActiveAddonsHeading => 'Active Storage Add-ons';

  @override
  String get storageAvailablePackagesHeading => 'Available Storage Packages';

  @override
  String storageRequestAddonButton(String label) {
    return 'Request Storage Add-on ($label)';
  }

  @override
  String get storageOverviewHeading => 'Storage Overview';

  @override
  String get storageBaseAllowanceLabel => 'Base Storage Allowance';

  @override
  String get storageEffectiveAllowanceLabel => 'Effective Storage Allowance';

  @override
  String get storageRemainingAllowanceLabel => 'Remaining Storage';

  @override
  String get storageNoActiveAddonsMessage => 'No active storage add-ons.';

  @override
  String get storageSizeLabel => 'Size';

  @override
  String get storageStartedOnLabel => 'Started On';

  @override
  String get storageExpiresOnLabel => 'Expires On';

  @override
  String get storageRequestAddonSheetTitle => 'Request Storage Add-on';

  @override
  String storageRequestAddonDescription(String packageLabel) {
    return 'You are requesting the $packageLabel storage add-on. This creates a pending request — it does not increase your storage allowance until a Platform Administrator approves it. The exact monthly price will be confirmed once submitted.';
  }

  @override
  String get bulkImportTitle => 'Bulk Import';

  @override
  String get bulkImportSampleTemplateHeading => 'Sample Template';

  @override
  String get bulkImportUploadFileHeading => 'Upload File';

  @override
  String get bulkImportAcceptedFormats => 'Accepted formats: .xlsx, .xls';

  @override
  String get bulkImportSelectFilePrompt => 'Select Excel file';

  @override
  String get bulkImportButton => 'Import';

  @override
  String get bulkImportNoRowsFoundMessage =>
      'No rows found in the uploaded file.';

  @override
  String get bulkImportSummaryHeading => 'Import Summary';

  @override
  String get bulkImportImportedSuccessfullyLabel => 'Imported Successfully';

  @override
  String get bulkImportSkippedDuplicateLabel => 'Skipped (Duplicate)';

  @override
  String get bulkImportFailedLabel => 'Failed';

  @override
  String get bulkImportFailedRowsHeading => 'Failed Rows';

  @override
  String bulkImportRowLabel(int rowNumber) {
    return 'Row $rowNumber';
  }

  @override
  String get bulkImportDownloadTemplateButton => 'Download Sample Template';

  @override
  String get agingBucketCurrentLabel => 'Current';

  @override
  String get agingBucket1To30Label => '1–30 Days';

  @override
  String get agingBucket31To60Label => '31–60 Days';

  @override
  String get agingBucket61To90Label => '61–90 Days';

  @override
  String get agingBucketOver90Label => 'Over 90 Days';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountSectionLabel => 'ACCOUNT';

  @override
  String get accountLogout => 'Logout';

  @override
  String get profileTitle => 'Profile';

  @override
  String get businessProfileTitle => 'Business Profile';

  @override
  String get businessProfileLoadError =>
      'Could not load your business profile.';

  @override
  String get businessProfileLogoInvalidTypeError =>
      'Logo must be a JPEG or PNG image.';

  @override
  String get businessProfileLogoTooLargeError => 'Logo must be 2MB or smaller.';

  @override
  String get businessProfileUpdatedSuccess =>
      'Business Profile updated successfully';

  @override
  String get businessProfileCompanyNameLabel => 'Company Name';

  @override
  String get businessProfileCompanyNameRequired => 'Company name is required';

  @override
  String get businessProfileContactEmailLabel => 'Contact Email';

  @override
  String get businessProfileContactEmailInvalid =>
      'Enter a valid email address';

  @override
  String get businessProfileContactPhoneLabel => 'Contact Phone';

  @override
  String get businessProfileAddressLabel => 'Business Address';

  @override
  String get businessProfileLogoNewSelected => 'New logo selected';

  @override
  String get businessProfileLogoOnFile => 'Logo on file — tap to replace';

  @override
  String get businessProfileLogoTapToAdd => 'Tap to add a logo';

  @override
  String get changePasswordCurrentLabel => 'Current Password';

  @override
  String get changePasswordCurrentRequired => 'Current password is required';

  @override
  String get changePasswordNewRequired => 'New password is required';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutDeendoonAboutSectionLabel => 'ABOUT';

  @override
  String get aboutDeendoonOthersSectionLabel => 'OTHERS';

  @override
  String get aboutDeendoonNotPublishedMessage =>
      'Deendoon is not yet published on the App Store.';

  @override
  String get aboutDeendoonPlayStoreOpenError =>
      'Could not open the Play Store.';

  @override
  String get aboutDeendoonPrivacyPolicyLabel => 'Privacy Policy';

  @override
  String get aboutDeendoonTermsConditionsLabel => 'Terms & Conditions';

  @override
  String get aboutDeendoonContactSupportLabel => 'Contact Support';

  @override
  String get aboutDeendoonRateAppLabel => 'Rate the App';

  @override
  String get aboutDeendoonVersionLabel => 'Version';

  @override
  String get aboutDeendoonBuildNumberLabel => 'Build Number';

  @override
  String get aboutDeendoonCopyrightLabel => 'Copyright';

  @override
  String aboutDeendoonCopyrightValue(int year) {
    return '© $year Deendoon. All rights reserved.';
  }

  @override
  String get aboutDeendoonTagline => 'The Modern Assistant for\nDebt Recovery';

  @override
  String get aboutDeendoonIntroHeading => 'Introduction to DEENDOON';

  @override
  String get aboutDeendoonIntroParagraph1 =>
      'DEENDOON is an app that helps you easily manage your customers\' debts and recover the money owed to you.';

  @override
  String get aboutDeendoonIntroParagraph2 =>
      'You can record outstanding debts, track payments received and remaining balances, and schedule calls, WhatsApp messages, SMS, and important reminders. The app tells you who you\'ve followed up with and what to do next, so no debt gets forgotten.';

  @override
  String get aboutDeendoonIntroParagraph3 =>
      'If your own efforts aren\'t enough to recover a debt, you can request directly within the app for the Deendoon professional recovery team to represent you legally and professionally, contact the debtor, and work to recover your money.';

  @override
  String get aboutDeendoonBenefitsHeading => 'DEENDOON helps you to:';

  @override
  String get aboutDeendoonBenefit1 =>
      'Record and manage all your debts in one place.';

  @override
  String get aboutDeendoonBenefit2 =>
      'Send timely reminders to your customers.';

  @override
  String get aboutDeendoonBenefit3 =>
      'Track calls, WhatsApp messages, SMS, and appointments.';

  @override
  String get aboutDeendoonBenefit4 =>
      'Record payments received and remaining balances.';

  @override
  String get aboutDeendoonBenefit5 => 'Get clear reports on your debts.';

  @override
  String get aboutDeendoonBenefit6 =>
      'Improve the recovery of money owed to you and your business\'s cash flow.';

  @override
  String get aboutDeendoonConclusionHeading => 'Conclusion';

  @override
  String get aboutDeendoonConclusionParagraph =>
      'DEENDOON is a modern assistant that simplifies debt management and strengthens customer follow-up, so your business gets paid on time.';

  @override
  String get aboutDeendoonInfoHeading => 'Information';

  @override
  String get subscriptionNoPlanLabel => 'No Plan';

  @override
  String storageAddonTitleLabel(String package) {
    return '$package Storage Add-on';
  }

  @override
  String get addCaseEntrySheetExistingCustomer => 'Existing Customer';

  @override
  String get addCaseEntrySheetNewCustomer => 'New Customer';

  @override
  String get addCaseReviewTitle => 'Review';

  @override
  String get addCaseReviewCustomerHeading => 'Customer';

  @override
  String addCaseReviewCreditLimitLabel(String limit) {
    return 'Credit Limit: $limit';
  }

  @override
  String get addCaseReviewDebtHeading => 'Debt';

  @override
  String addCaseReviewAmountLabel(String amount) {
    return 'Amount: $amount';
  }

  @override
  String addCaseReviewDueDateLabel(String date) {
    return 'Due Date: $date';
  }

  @override
  String addCaseReviewNotesLabel(String notes) {
    return 'Notes: $notes';
  }

  @override
  String addCaseReviewInvoiceLabel(String filename) {
    return 'Invoice: $filename';
  }

  @override
  String get addCaseReviewCreateCustomerDebtButton => 'Create Customer & Debt';

  @override
  String get addCaseReviewCreateDebtButton => 'Create Debt';

  @override
  String get addCaseReviewTryAgainButton => 'Try Again';

  @override
  String addCaseReviewCustomerCreatedDebtFailedMessage(
    String name,
    String message,
  ) {
    return 'The customer \"$name\" was created successfully. Creating the debt failed: $message';
  }

  @override
  String get addCaseReviewOpenCustomerButton => 'Open Customer';

  @override
  String addCaseReviewDebtCreatedCaseFailedMessage(
    String referenceNumber,
    String message,
  ) {
    return 'Debt $referenceNumber was created successfully. Creating the Collection Case failed: $message';
  }

  @override
  String get addCaseReviewCaseLaterHint =>
      'You can open a Collection Case for this debt later from its Debt Details screen.';

  @override
  String get addCaseReviewOpenDebtButton => 'Open Debt';

  @override
  String overviewAgingLegendValue(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count debts · $amount',
      one: '$count debt · $amount',
    );
    return '$_temp0';
  }

  @override
  String overviewRiskLegendValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count customers',
      one: '$count customer',
    );
    return '$_temp0';
  }

  @override
  String get bulkImportUnsupportedFileTypeError =>
      'Unsupported file type. Only .xlsx and .xls files are supported.';
}
