// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Somali (`so`).
class AppLocalizationsSo extends AppLocalizations {
  AppLocalizationsSo([String locale = 'so']) : super(locale);

  @override
  String get settingsTitle => 'Dejinta';

  @override
  String get sectionGeneral => 'Guud';

  @override
  String get sectionNotifications => 'Ogeysiisyada';

  @override
  String get sectionSecurity => 'Amniga';

  @override
  String get sectionBusiness => 'Ganacsiga';

  @override
  String get language => 'Luqadda';

  @override
  String get languageEnglish => 'Ingiriisi';

  @override
  String get languageSomali => 'Soomaali';

  @override
  String get appearance => 'Muuqaalka';

  @override
  String get appearanceLight => 'Iftiin';

  @override
  String get appearanceDark => 'Madow';

  @override
  String get appearanceSystem => 'Nidaamka';

  @override
  String get pushNotifications => 'Ogeysiisyada Push';

  @override
  String get reminderNotifications => 'Ogeysiisyada Xasuusinta';

  @override
  String get paymentNotifications => 'Ogeysiisyada Lacag-bixinta';

  @override
  String get notificationsDisclosure =>
      'Waxaa lagu keydiyaa dejinta ganacsigaaga.';

  @override
  String get changePassword => 'Beddel Password-ka';

  @override
  String get biometricLogin => 'Gelitaanka Biometric-ka (Farta/Wejiga)';

  @override
  String get biometricNotSupported => 'Qalabkan lama taageero';

  @override
  String get comingSoon => 'Dhawaan';

  @override
  String get biometricLockTitle => 'Fur Deendoon';

  @override
  String get biometricLockPromptReason =>
      'Isticmaal biometric-kaaga si aad u gasho akoonkaaga';

  @override
  String get biometricLockFailedMessage =>
      'Xaqiijintu way fashilantay. Isku day mar kale ama isticmaal password-kaaga.';

  @override
  String get usePasswordInstead => 'Isticmaal Password-ka';

  @override
  String get biometricEnableFailedMessage =>
      'Lama xaqiijin karo biometric-kaaga. Fadlan isku day mar kale.';

  @override
  String get defaultCreditLimit => 'Xaddiga Deynta ee Caadiga ah';

  @override
  String get creditLimitReminderEnabled => 'Xasuusinta Xaddiga Deynta';

  @override
  String get softLimitWarningThreshold =>
      'Heerka Digniinta Xaddiga Jilicsan (%)';

  @override
  String get whatsappReminderDays => 'Maalmaha Xasuusinta WhatsApp';

  @override
  String get smsReminderDays => 'Maalmaha Xasuusinta SMS';

  @override
  String get callReminderDays => 'Maalmaha Xasuusinta Wicitaanka';

  @override
  String get reminderDaysHint => 'Maalmo kala saxeexan comma, tusaale 1, 3, 7';

  @override
  String get professionalCollectionThresholdDays =>
      'Maalmaha Xadka Ururinta Xirfadeed';

  @override
  String get saveChanges => 'Kaydi Isbeddellada';

  @override
  String get settingsSavedSuccessfully =>
      'Dejinta si guul leh ayaa loo cusboonaysiiyay';

  @override
  String get couldNotLoadSettings => 'Dejinta lama soo geli karin.';

  @override
  String get retry => 'Isku day mar kale';

  @override
  String get paginationLoadMoreError =>
      'Wax badan lama soo dejin karin. Taabo si aad mar kale u tijaabiso.';

  @override
  String get fieldRequired => 'Goobtan waa lagama maarmaan';

  @override
  String get enterValidNumber => 'Geli tiro sax ah';

  @override
  String get enterValueBetween0And100 => 'Geli qiime u dhexeeya 0 iyo 100';

  @override
  String comingSoonMessage(String value) {
    return '$value — Dhawaan';
  }

  @override
  String get riskHigh => 'Sare';

  @override
  String get riskMedium => 'Dhexdhexaad';

  @override
  String get riskLow => 'Hoose';

  @override
  String get riskUnknown => 'Aan La Garanayn';

  @override
  String get statusActive => 'Firfircoon';

  @override
  String get statusGoodStanding => 'Xaalad Fiican';

  @override
  String get statusLatePayer => 'Bixiye Daahsan';

  @override
  String get statusHighRisk => 'Khatar Sare';

  @override
  String get statusInCollection => 'Ururinta Daynta';

  @override
  String get statusRecovered => 'La Soo Celiyay';

  @override
  String get statusBlocked => 'La Xannibay';

  @override
  String get statusDraft => 'Qabyo';

  @override
  String get statusPending => 'Sugaya';

  @override
  String get statusOverdue => 'Dib u Dhacay';

  @override
  String get statusPartiallyPaid => 'Qayb Ahaan La Bixiyay';

  @override
  String get statusPaid => 'La Bixiyay';

  @override
  String get statusCancelled => 'La Joojiyay';

  @override
  String get statusWrittenOff => 'La Baabi\'iyay';

  @override
  String get statusOpen => 'Furan';

  @override
  String get statusClosed => 'Xiran';

  @override
  String get statusToday => 'Maanta';

  @override
  String get statusUpcoming => 'Soo Socda';

  @override
  String get statusCompleted => 'La Dhammeeyay';

  @override
  String get statusSubmitted => 'La Gudbiyay';

  @override
  String get statusUnderReview => 'Dib u Eegis';

  @override
  String get statusNeedMoreInformation =>
      'Macluumaad Dheeraad ah ayaa Loo Baahan Yahay';

  @override
  String get statusAccepted => 'La Aqbalay';

  @override
  String get statusAssigned => 'La U Xilsaaray';

  @override
  String get statusInProgress => 'Socda';

  @override
  String get statusFulfilled => 'La Buuxiyay';

  @override
  String get statusBroken => 'La Jebiyay';

  @override
  String get statusTrial => 'Tijaabo';

  @override
  String get statusExpired => 'Dhammaaday';

  @override
  String get statusResolved => 'La Xalliyay';

  @override
  String get themeSwitchToLight => 'U Beddel Muuqaalka Iftiinka';

  @override
  String get themeSwitchToDark => 'U Beddel Muuqaalka Madow';

  @override
  String get navHome => 'Guriga';

  @override
  String get navAnalytics => 'Falanqaynta';

  @override
  String get navCases => 'Kiisaska';

  @override
  String get navReminders => 'Xasuusinta';

  @override
  String get navDocuments => 'Dukumentiyada';

  @override
  String get commonLoading => 'Waa la soo raraya...';

  @override
  String get commonViewAll => 'Dhammaan Fiiri';

  @override
  String get authEmailLabel => 'Iimaylka';

  @override
  String get authEmailRequired => 'Iimaylka waa lagama maarmaan';

  @override
  String get authEmailInvalid => 'Geli iimayl sax ah';

  @override
  String get authPasswordLabel => 'Furaha Sirta ah';

  @override
  String get authPasswordRequired => 'Furaha sirta ah waa lagama maarmaan';

  @override
  String authPasswordMinLength(int minLength) {
    return 'Furaha sirta ah waa inuu ka kooban yahay ugu yaraan $minLength xaraf';
  }

  @override
  String get authPasswordsMismatch => 'Furayaasha sirta ahi isku mid ma aha';

  @override
  String get passwordFieldShowTooltip => 'Tus furaha sirta ah';

  @override
  String get passwordFieldHideTooltip => 'Qari furaha sirta ah';

  @override
  String get loginAppName => 'Deendoon';

  @override
  String get loginTagline => 'Kaaliyaha Caqliga Leh ee Soo-celinta Daymaha';

  @override
  String get loginRememberMeLabel => 'I Xasuuso';

  @override
  String get loginForgotPasswordLink => 'Furaha sirta ah ma xasuusan?';

  @override
  String get loginSubmitButton => 'Gal';

  @override
  String get loginCreateAccountPrompt => 'Akoon ma lihid? Samee Akoon';

  @override
  String get authOrDivider => 'AMA';

  @override
  String get googleLoginButton => 'Ku sii wad Google';

  @override
  String get googleLoginFailedMessage =>
      'Gelitaanka Google wuu fashilmay. Fadlan isku day mar kale.';

  @override
  String get googleLoginNotConfiguredMessage =>
      'Gelitaanka Google hadda lama heli karo.';

  @override
  String get googleRegisterTitle => 'Dhammee Diiwaangelintaada';

  @override
  String googleRegisterInstructions(String email) {
    return 'Ku dhawaad dhammaad! Geli magaca ganacsigaaga si aad u dhammaystirto abuurista akoonkaaga Deendoon ee $email.';
  }

  @override
  String get googleRegisterPhoneLabel => 'Lambarka Taleefanka (Ikhtiyaari)';

  @override
  String get googleRegisterSubmitButton => 'Dhammee Diiwaangelinta';

  @override
  String get forgotPasswordTitle => 'Furaha Sirta ah ma Xasuusan';

  @override
  String get forgotPasswordInstructions =>
      'Geli iimaylka la xiriira akoonkaaga, waxaanan kuu soo diri doonaa xiriiriye aad ku dib-u-dejiso furahaaga sirta ah.';

  @override
  String get forgotPasswordSubmitButton => 'Dir Xiriiriyaha Dib-u-dejinta';

  @override
  String get forgotPasswordHaveCodeLink =>
      'Waxaan hore u haystaa koodhka dib-u-dejinta';

  @override
  String get registerTitle => 'Samee Akoon';

  @override
  String get registerBusinessNameLabel => 'Magaca Ganacsiga';

  @override
  String get registerBusinessNameRequired =>
      'Magaca ganacsiga waa lagama maarmaan';

  @override
  String get registerFullNameLabel => 'Magaca Buuxa';

  @override
  String get registerFullNameRequired => 'Magaca buuxa waa lagama maarmaan';

  @override
  String get registerPhoneLabel => 'Lambarka Taleefanka';

  @override
  String get registerPhoneValidatorRequired =>
      'Lambarka taleefanka waa lagama maarmaan';

  @override
  String get registerConfirmPasswordLabel => 'Xaqiiji Furaha Sirta ah';

  @override
  String get registerConfirmPasswordRequired => 'Xaqiiji furahaaga sirta ah';

  @override
  String get registerSubmitButton => 'Samee Akoon';

  @override
  String get resetPasswordTitle => 'Dib u Deji Furaha Sirta ah';

  @override
  String get resetPasswordCodeLabel => 'Koodhka Dib-u-dejinta';

  @override
  String get resetPasswordCodeHelper => 'Koodhka lagu soo diray iimaylkaaga';

  @override
  String get resetPasswordCodeRequired =>
      'Koodhka dib-u-dejinta waa lagama maarmaan';

  @override
  String get resetPasswordNewPasswordLabel => 'Furaha Sirta ah ee Cusub';

  @override
  String get resetPasswordConfirmLabel => 'Xaqiiji Furaha Sirta ah ee Cusub';

  @override
  String get resetPasswordSubmitButton => 'Dib u Deji Furaha Sirta ah';

  @override
  String get dashboardTodaysOverview => 'Guudmarka Maanta';

  @override
  String get dashboardQuickActions => 'Ficillada Degdegga ah';

  @override
  String get dashboardBusinessHealthTitle => 'Caafimaadka Ganacsiga';

  @override
  String get dashboardGreetingFallbackName => 'Marhaba';

  @override
  String get dashboardGreetingMorning => 'Subax Wanaagsan';

  @override
  String get dashboardGreetingAfternoon => 'Galab Wanaagsan';

  @override
  String get dashboardGreetingEvening => 'Fiid Wanaagsan';

  @override
  String get quickActionAddCase => 'Ku Dar Kiis';

  @override
  String get quickActionRecordPayment => 'Diiwaan Geli Lacag-bixin';

  @override
  String get quickActionAddReminder => 'Ku Dar Xasuusin';

  @override
  String get quickActionGlobalSearch => 'Raadinta Guud';

  @override
  String get kpiOverviewTitle => 'Guudmarka Tirakoobyada (KPI)';

  @override
  String get kpiLoadError => 'Tirakoobyada (KPI) lama soo geli karin.';

  @override
  String get kpiTotalOutstanding => 'Wadarta Hadhaysa';

  @override
  String kpiCollectedPeriod(String period) {
    return 'La Ururiyay ($period)';
  }

  @override
  String get kpiOverdueAmount => 'Lacagta Dib u Dhacday';

  @override
  String get kpiHighRiskCustomers => 'Macaamiisha Khatarta Sare';

  @override
  String kpiTrendVsLastMonth(String trend) {
    return '$trend marka la barbardhigo bisha hore';
  }

  @override
  String get kpiSelectPeriodTitle => 'Dooro Muddada';

  @override
  String get kpiPeriodToday => 'Maanta';

  @override
  String get kpiPeriodYesterday => 'Shalay';

  @override
  String get kpiPeriodThisWeek => 'Toddobaadkan';

  @override
  String get kpiPeriodLastWeek => 'Toddobaadkii Hore';

  @override
  String get kpiPeriodThisMonth => 'Bishan';

  @override
  String get kpiPeriodLastMonth => 'Bishii Hore';

  @override
  String get kpiPeriodThisQuarter => 'Saddexdan Bilood';

  @override
  String get kpiPeriodLastQuarter => 'Saddexdii Bilood ee Hore';

  @override
  String get kpiPeriodThisYear => 'Sanadkan';

  @override
  String get kpiPeriodLastYear => 'Sanadkii Hore';

  @override
  String get kpiPeriodCustomLabel => 'Xilli La Doortay';

  @override
  String get statusHealthy => 'Caafimaad Qaba';

  @override
  String get statusNeedsAttention => 'U Baahan Dib u Eegis';

  @override
  String get statusAtRisk => 'Khatar Ku Jira';

  @override
  String get statusNeutralBaseline => 'Heer Dhexdhexaad ah';

  @override
  String get businessHealthSubtextHealthy => 'Si fiican ayaad u wadaa!';

  @override
  String get businessHealthSubtextNeedsAttention =>
      'Qaybo ka mid ah ayaa u baahan dib u eegis.';

  @override
  String get businessHealthSubtextAtRisk =>
      'Waxaa lagula talinayaa in aad isla markiiba wax ka qabato.';

  @override
  String get businessHealthSubtextNeutralBaseline =>
      'Xog ku filan weli lama helin.';

  @override
  String get businessHealthLoadError =>
      'Caafimaadka Ganacsiga lama soo geli karin.';

  @override
  String get professionalCollectionTitle => 'Ururinta Xirfadeed';

  @override
  String get professionalCollectionLoadError =>
      'Soo-koobka Ururinta Xirfadeed lama soo geli karin.';

  @override
  String get professionalCollectionEmptyState =>
      'Wali kiis Deendoon looma gudbin';

  @override
  String get professionalCollectionLatestRequestLabel =>
      'Codsigii ugu Dambeeyay';

  @override
  String get professionalCollectionListLoadError =>
      'Codsiyada Ururinta Xirfadeed lama soo geli karin.';

  @override
  String get professionalCollectionListEmptyState =>
      'Wali codsi Ururinta Xirfadeed ah ma jiro';

  @override
  String get professionalCollectionListEmptyFilteredState =>
      'Codsiyo u dhigma shaandhadan lama helin';

  @override
  String get professionalCollectionDetailTitle => 'Codsiga Ururinta Xirfadeed';

  @override
  String get professionalCollectionDetailLoadError =>
      'Codsigan Ururinta Xirfadeed lama soo geli karin.';

  @override
  String get professionalCollectionSubmittedByLabel => 'Waxaa Gudbiyay';

  @override
  String get professionalCollectionActionedByLabel => 'Waxaa Fuliyay';

  @override
  String get professionalCollectionSubmittedOnLabel => 'Waxaa La Gudbiyay';

  @override
  String get professionalCollectionClosedOnLabel => 'Waxaa La Xiray';

  @override
  String get professionalCollectionDeclarationAcceptedLabel =>
      'Baaqa Waa La Aqbalay';

  @override
  String get professionalCollectionDeclarationAcceptedByLabel =>
      'Baaqa Waxaa Aqbalay';

  @override
  String get professionalCollectionReasonsForTransferHeading =>
      'Sababaha Wareejinta';

  @override
  String get professionalCollectionNoReasonsRecorded =>
      'Sabab lama diiwaan gelin codsigan.';

  @override
  String get professionalCollectionRequestedServicesHeading =>
      'Adeegyada La Codsaday';

  @override
  String get professionalCollectionNoRequestedServicesRecorded =>
      'Adeeg la codsaday lama diiwaan gelin codsigan.';

  @override
  String get professionalCollectionNoNotesRecorded =>
      'Faallo lagama darin codsigan.';

  @override
  String get professionalCollectionViewCaseButton => 'Fiiri Kiiska Ururinta';

  @override
  String get professionalCollectionViewTimelineButton =>
      'Fiiri Taariikhda Falalka';

  @override
  String get professionalCollectionViewMessagesButton => 'Fiiri Fariimaha';

  @override
  String get professionalCollectionTimelineTitle => 'Taariikhda Falalka';

  @override
  String get professionalCollectionTimelineLoadError =>
      'Taariikhda falalka lama soo geli karin.';

  @override
  String get professionalCollectionTimelineEmptyState =>
      'Wali dhacdo taariikhda falalka ah ma jirto';

  @override
  String professionalCollectionTimelineOutcomeLabel(String outcome) {
    return 'Natiijada: $outcome';
  }

  @override
  String get professionalCollectionDocumentsEmptyState =>
      'Wali dukumenti lama xidhiidhin codsigan';

  @override
  String get professionalCollectionAttachmentsLoadError =>
      'Lifaaqyada lama soo geli karin.';

  @override
  String get professionalCollectionAttachmentsEmptyState =>
      'Wali lifaaq ma jiro';

  @override
  String get professionalCollectionUploadAttachmentButton => 'Ku Lifaaq Faylka';

  @override
  String get professionalCollectionUploadUnavailableMessage =>
      'Ku lifaaqidda faylka lagama heli karo marxaladdan codsiga.';

  @override
  String get attachmentDeleteTitle => 'Tirtir Lifaaqa';

  @override
  String get attachmentDeleteDialogContent =>
      'Lifaaqan si joogto ah ayaa loo tirtiri doonaa. Tan dib looma celin karo.';

  @override
  String get attachmentDeleteConfirmButton => 'Tirtir';

  @override
  String get attachmentDeletedSuccessfully =>
      'Lifaaqa si guul leh ayaa loo tirtiray';

  @override
  String get professionalCollectionMessagesTitle => 'Fariimaha';

  @override
  String get professionalCollectionMessagesLoadError =>
      'Fariimaha lama soo geli karin.';

  @override
  String get professionalCollectionMessagesEmptyState => 'Wali fariin ma jirto';

  @override
  String get professionalCollectionMessagesClosedNotice =>
      'Codsigan Ururinta Xirfadeed waa xiran yahay — fariimo cusub lama aqbalo.';

  @override
  String get professionalCollectionMessageInputHint => 'Qor fariin';

  @override
  String get professionalCollectionMessageSenderYou => 'Adiga';

  @override
  String get professionalCollectionMessageSenderTeam => 'Kooxda Deendoon';

  @override
  String get professionalCollectionSubmitSheetTitle =>
      'U Gudbi Ururinta Xirfadeed';

  @override
  String get professionalCollectionSubmitSheetDescription =>
      'Tani waxay kiiska u wareejinaysaa kooxda soo-celinta Deendoon si loo dib-u-eego. Qorshahaaga hadda socda wuu sii socon doonaa — tani waa codsi, ma aha ansixin.';

  @override
  String get professionalCollectionReasonForTransferHeading =>
      'Sababta Wareejinta';

  @override
  String get professionalCollectionNoActiveReasonsConfigured =>
      'Wali sababo wareejin oo firfircoon looma dejin ganacsigan.';

  @override
  String get professionalCollectionReasonsLoadError =>
      'Sababaha Wareejinta lama soo geli karin.';

  @override
  String get professionalCollectionNoActiveServicesConfigured =>
      'Wali adeegyo la codsan karo oo firfircoon looma dejin ganacsigan.';

  @override
  String get professionalCollectionServicesLoadError =>
      'Adeegyada La Codsaday lama soo geli karin.';

  @override
  String get professionalCollectionDeclarationConfirmLabel =>
      'Waxaan xaqiijinayaa Baaqa Macmiilka ee wareejintan.';

  @override
  String get professionalCollectionSubmitReasonsRequiredValidator =>
      'Dooro ugu yaraan hal Sabab Wareejin ah.';

  @override
  String get professionalCollectionSubmitServicesRequiredValidator =>
      'Dooro ugu yaraan hal Adeeg La Codsaday ah.';

  @override
  String get professionalCollectionSubmitDeclarationRequiredValidator =>
      'Waa inaad aqbashaa Baaqa Macmiilka si aad u gudbiso.';

  @override
  String get professionalCollectionSubmitButton => 'Gudbi Codsiga';

  @override
  String get recentCasesTitle => 'Kiisaska Dhawaan';

  @override
  String get recentCasesLoadError => 'Kiisaska dhawaan lama soo geli karin.';

  @override
  String get recentCasesEmptyState => 'Wax dhaqdhaqaaq ah lama arag';

  @override
  String get todaysOverviewLoadError => 'Guudmarka maanta lama soo geli karin.';

  @override
  String get todaysOverviewRemindersDueToday => 'Xasuusinta Maanta la Sugayo';

  @override
  String get todaysOverviewPaymentsDue => 'Lacag-bixinta la Sugayo';

  @override
  String get todaysOverviewClientVisits => 'Booqashada Macaamiisha';

  @override
  String get todaysOverviewFollowUps => 'Raadraaca';

  @override
  String get commonCancel => 'Jooji';

  @override
  String get commonOk => 'Hagaag';

  @override
  String get commonSave => 'Kaydi';

  @override
  String get customerAddTitle => 'Ku Dar Macmiil';

  @override
  String get customerEditTitle => 'Wax ka Beddel Macmiilka';

  @override
  String get customerDetailsTitle => 'Faahfaahinta Macmiilka';

  @override
  String get customerReadOnlyTooltip => 'Macmiilkan waa akhris-oo-kaliya';

  @override
  String get customerDetailLoadError => 'Macmiilkan lama soo geli karin.';

  @override
  String get creditLimitLabel => 'Xadka Deynta';

  @override
  String get creditLimitHint => '0.00';

  @override
  String get creditLimitRequiredValidator => 'Geli xadka deynta';

  @override
  String get creditLimitInvalidValidator => 'Geli xad deyn oo sax ah';

  @override
  String get customerListTitle => 'Macaamiisha';

  @override
  String get customerListSelectTitle => 'Dooro Macmiil';

  @override
  String get customerListShowArchivedFilter => 'Tus Kuwa La Xafiday';

  @override
  String get customerListLoadError => 'Macaamiisha lama soo geli karin.';

  @override
  String get customerListEmptyState => 'Wali macmiil ma jiro';

  @override
  String customerListEmptySearchState(String search) {
    return 'Lama helin macaamiil u dhigma \"$search\"';
  }

  @override
  String get customerRestoredSuccessfully =>
      'Macmiilka si guul leh ayaa loo soo celiyay';

  @override
  String get customerArchiveTitle => 'Xafid Macmiilka';

  @override
  String get customerArchiveDialogContent =>
      'Macmiilkan mar dambe kama muuqan doono liiska caadiga ah. Tan waxaa dib loogu celin karaa mar dambe.';

  @override
  String get customerArchiveConfirmButton => 'Xafid';

  @override
  String get customerArchivedSuccessfully =>
      'Macmiilka si guul leh ayaa loo xafiday';

  @override
  String get customerStatementGeneratedSuccessfully =>
      'Warbixinta Xisaabta si guul leh ayaa loo abuuray';

  @override
  String get customerDetailRecentPaymentsHeading => 'Lacag-bixinnada Dhawaan';

  @override
  String get customerDetailViewDebtsButton => 'Fiiri Daymaha';

  @override
  String get customerDetailAttachmentsButton => 'Lifaaqyada';

  @override
  String get customerDetailGenerateStatementButton =>
      'Samee Warbixinta Xisaabta';

  @override
  String get customerReadOnlyBannerTitle => 'Macmiil Akhris-oo-Kaliya ah';

  @override
  String get customerReadOnlyBannerMessage =>
      'Ganacsigaagu wuxuu ka sarreeyaa xadka macaamiisha ee qorshahaaga, sidaa darteed macmiilkan lama beddeli karo, lama xafidi karo, dukumentiyadana looma samayn karo. Wali si buuxda ayaa loo arki karaa. Kor u qaad qorshahaaga si aad u hesho gelitaan buuxa.';

  @override
  String get customerReadOnlyBannerUpgradeButton => 'Kor u Qaad Qorshaha';

  @override
  String get addEditCustomerNameLabel => 'Magaca';

  @override
  String get addEditCustomerNameRequired => 'Geli magaca macmiilka';

  @override
  String get addEditCustomerPhoneLabel => 'Taleefanka';

  @override
  String get addEditCustomerPhoneRequired => 'Geli lambar taleefan';

  @override
  String get addEditCustomerAddressLabel => 'Cinwaanka (Ikhtiyaari)';

  @override
  String get addEditCustomerContinueButton => 'Sii Wad';

  @override
  String get addEditCustomerDuplicateTitle => 'Nuqul Suurtagal ah';

  @override
  String get addEditCustomerViewExistingButton => 'Fiiri Macmiilka Jira';

  @override
  String get addEditCustomerPhoneNumbersLabel => 'Lambarrada Taleefanka';

  @override
  String get addEditCustomerPhonePrimaryBadge => 'Aasaasiga ah';

  @override
  String get addEditCustomerSetPrimaryButton => 'Ka Dhig Aasaasiga ah';

  @override
  String get addEditCustomerRemovePhoneButton => 'Ka Saar';

  @override
  String get addEditCustomerAddPhoneButton => 'Ku Dar Taleefan';

  @override
  String get addEditCustomerMaxPhoneNumbersMessage =>
      'Waxaad ku dari kartaa ilaa 3 lambar oo taleefan ah.';

  @override
  String get phoneNumberPickerTitle => 'Dooro Lambarka Taleefanka';

  @override
  String get phoneNumberPickerContinueButton => 'Sii Wad';

  @override
  String get customerDocumentsLoadError => 'Dukumentiyada lama soo geli karin.';

  @override
  String get customerDocumentsEmptyState => 'Wali dukumenti ma jiro';

  @override
  String get documentTypeReceipt => 'Rasiidka';

  @override
  String get documentTypeDemandLetter => 'Warqadda Dalabka';

  @override
  String get documentTypeStatement => 'Warbixinta Xisaabta';

  @override
  String get documentTypeInvoice => 'Qaansheegta';

  @override
  String get documentTabAll => 'Dhammaan';

  @override
  String get documentListTitleAll => 'Dhammaan Dukumentiyada';

  @override
  String get documentTabInvoices => 'Qaansheegyada';

  @override
  String get documentTabReceipts => 'Rasiidhada';

  @override
  String get documentTabLetters => 'Warqadaha';

  @override
  String get documentTabOther => 'Kale';

  @override
  String get documentSearchHint => 'Ka raadi dukumentiyada...';

  @override
  String get documentRecentDocumentsHeading => 'Dukumentiyada Dhawaan';

  @override
  String get documentEmptyInvoices => 'Wali qaansheeg ma jirto';

  @override
  String get documentEmptyReceipts => 'Wali rasiid ma jiro';

  @override
  String get documentEmptyLetters => 'Wali warqad ma jirto';

  @override
  String get documentEmptyStatements => 'Wali warbixin xisaabeed ma jirto';

  @override
  String get documentEmptyStatementsCaption =>
      'Warbixinaha xisaabta ee macmiilka ayaa halkan ka muuqan doona marka la sameeyo.';

  @override
  String get documentHistoryTitle => 'Taariikhda Dukumentiga';

  @override
  String get documentHistoryLoadError =>
      'Taariikhda dukumentigan lama soo geli karin.';

  @override
  String get documentHistoryEmptyState => 'Wali taariikh ma jirto';

  @override
  String get documentHistorySystemLabel => 'Nidaamka';

  @override
  String get documentEventGenerated => 'La Abuuray';

  @override
  String get documentEventDownloaded => 'La Soo Dejiyay';

  @override
  String get documentEventRegenerated => 'Dib Loo Abuuray';

  @override
  String get documentPreviewFallbackTitle => 'Dukumenti';

  @override
  String get documentDownloadTooltip => 'Soo Deji';

  @override
  String get documentShareTooltip => 'Wadaag';

  @override
  String get documentHistoryTooltip => 'Taariikhda';

  @override
  String get documentPreviewLoadError => 'Dukumentigan lama soo geli karin.';

  @override
  String get documentPreviewRenderError => 'Dukumentigan lama muujin karin.';

  @override
  String get documentShareTitle => 'Wadaag Dukumentiga';

  @override
  String get documentSharedSuccessMessage =>
      'Dukumentiga si guul leh ayaa loo wadaagay';

  @override
  String get documentStorageUsageTitle => 'Isticmaalka Kaydinta';

  @override
  String get documentStorageUsageLoadError =>
      'Isticmaalka kaydinta lama soo geli karin.';

  @override
  String documentStorageUsageLabel(String used, String total) {
    return '$used ee $total ayaa la isticmaalay';
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
  String get customerCasesLoadError => 'Kiisaska lama soo geli karin.';

  @override
  String get customerCasesEmptyState => 'Wali kiis ururin ah ma jiro';

  @override
  String get customerCardRestoreButton => 'Soo Celi';

  @override
  String get customerCardArchivedBadge => 'La Xafiday';

  @override
  String get customerInfoChangeStatusTooltip => 'Beddel Xaaladda Macmiilka';

  @override
  String get customerInfoEditCreditLimitTooltip => 'Wax ka Beddel Xadka Deynta';

  @override
  String get customerInfoOutstandingBalanceLabel => 'Hadhaaga Lacagta';

  @override
  String get customerInfoRemainingCreditLabel => 'Deynta Soo Hadhay';

  @override
  String get customerInfoCreditScoreLabel => 'Dhibcaha Deynta';

  @override
  String get customerSearchHint => 'Ku raadi magaca ama taleefanka';

  @override
  String get customerPaymentsLoadError =>
      'Lacag-bixinnada dhawaan lama soo geli karin.';

  @override
  String get customerPaymentsEmptyState => 'Lacag-bixin dhawaan lama arag';

  @override
  String get customerPaymentsMethodNotRecorded => 'Habka lama diiwaan gelin';

  @override
  String get creditLimitSheetTitle => 'Xadka Deynta';

  @override
  String get customerStatusSheetTitle => 'Xaaladda Macmiilka';

  @override
  String get debtListTitle => 'Daymaha';

  @override
  String get debtListSelectTitle => 'Dooro Dayn';

  @override
  String get debtListFilterAll => 'Dhammaan';

  @override
  String get debtListLoadError => 'Daymaha lama soo geli karin.';

  @override
  String get debtListEmptyState => 'Wali dayn ma jiro';

  @override
  String get debtListEmptyFilteredState => 'Xaaladdan dayn kuma jiro';

  @override
  String get debtListShowArchivedFilter => 'Tus Kuwa La Xafiday';

  @override
  String get debtRestoredSuccessfully =>
      'Daynta si guul leh ayaa loo soo celiyay';

  @override
  String get debtCardRestoreButton => 'Soo Celi';

  @override
  String get debtCardArchivedBadge => 'La Xafiday';

  @override
  String get addEditDebtAddTitle => 'Ku Dar Dayn';

  @override
  String get addEditDebtEditTitle => 'Wax ka Beddel Daynta';

  @override
  String get debtDetailTitle => 'Faahfaahinta Daynta';

  @override
  String get debtDetailLoadError => 'Daynta lama soo geli karin.';

  @override
  String get debtArchiveTitle => 'Xafid Daynta';

  @override
  String get debtArchiveDialogContent =>
      'Daynta mar dambe kama muuqan doonto liiska caadiga ah. Tan waxaa dib loogu celin karaa mar dambe.';

  @override
  String get debtArchiveConfirmButton => 'Xafid';

  @override
  String get debtArchivedSuccessfully => 'Daynta si guul leh ayaa loo xafiday';

  @override
  String debtDetailGenerateSuccessMessage(String label) {
    return '$label si guul leh ayaa loo abuuray';
  }

  @override
  String debtDetailGenerateErrorMessage(String label) {
    return '$label lama abuuri karin';
  }

  @override
  String get debtDetailInvoiceAttachedSuccess =>
      'Qaansheegta si guul leh ayaa loo lifaaqay';

  @override
  String get debtDetailCustomerInfoHeading => 'Macluumaadka Macmiilka';

  @override
  String get debtDetailCustomerLoadError =>
      'Macmiilka daynta lama soo geli karin.';

  @override
  String get debtDetailSummaryHeading => 'Soo-koobka Daynta';

  @override
  String get promiseToPayTitle => 'Ballanqaad Bixin';

  @override
  String get debtDetailCaseOpenedSuccess => 'Kiiska si guul leh ayaa loo furay';

  @override
  String get debtDetailOpenCaseButton => 'Fur Kiiska';

  @override
  String get debtDetailLogReminderHeading => 'Diiwaan Geli Xasuusin';

  @override
  String get debtDetailLogWhatsAppButton => 'Diiwaan Geli WhatsApp';

  @override
  String get debtDetailLogSmsButton => 'Diiwaan Geli SMS';

  @override
  String get debtDetailLogCallButton => 'Diiwaan Geli Wicitaan';

  @override
  String debtDetailReminderPresetLabel(String referenceNumber) {
    return 'Dayn $referenceNumber';
  }

  @override
  String get debtDetailPaymentHistoryHeading => 'Taariikhda Lacag-bixinta';

  @override
  String get debtDetailFollowUpTimelineHeading => 'Taariikhda Raadraaca';

  @override
  String get debtDetailPromiseToPayHistoryHeading =>
      'Taariikhda Ballanqaadka Bixinta';

  @override
  String get debtDetailGenerateDocumentsHeading => 'Samee Dukumentiyada';

  @override
  String get debtDetailRelatedDocumentsHeading => 'Dukumentiyada La Xiriira';

  @override
  String get debtScanInvoiceButton => 'Iskaan Qaansheegta';

  @override
  String get debtUploadInvoiceButton => 'Ku Lifaaq Qaansheegta';

  @override
  String get debtDetailRelatedCaseHeading => 'Kiiska La Xiriira';

  @override
  String get addEditDebtDueDateRequiredError => 'Dooro taariikhda dhammaadka.';

  @override
  String addEditDebtInvoiceUploadFailedMessage(String message) {
    return 'Daynta waa la keydiyay, laakiin qaansheegtu way fashilantay: $message';
  }

  @override
  String get addEditDebtCreditLimitExceededTitle =>
      'Xadka Deynta waa la Dhaafay';

  @override
  String get addEditDebtAmountLabel => 'Qadarka';

  @override
  String get addEditDebtAmountRequiredValidator => 'Geli qadar';

  @override
  String get addEditDebtAmountInvalidValidator => 'Geli qadar sax ah';

  @override
  String get addEditDebtDueDateHeading => 'Taariikhda Dhammaadka';

  @override
  String get addEditDebtSelectDueDateButton => 'Dooro Taariikhda Dhammaadka';

  @override
  String get addEditDebtInvoiceHeading => 'Qaansheegta (Ikhtiyaari)';

  @override
  String get addEditDebtRemoveInvoiceTooltip =>
      'Ka saar qaansheegta la doortay';

  @override
  String get addEditDebtNotesHeading => 'Faallooyin';

  @override
  String get addEditDebtNotesHint => 'Faallooyin ikhtiyaari ah';

  @override
  String get debtOriginalAmountLabel => 'Qadarka Asalka ah';

  @override
  String get debtRemainingBalanceLabel => 'Lacagta Soo Hadhay';

  @override
  String debtCardDueDateLabel(String dueDate) {
    return 'Wuxuu dhacayaa $dueDate';
  }

  @override
  String debtCardOverdueDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days maalmood ayaa dib u dhacday',
      one: '$days maalin ayaa dib u dhacday',
    );
    return '$_temp0';
  }

  @override
  String get debtSummaryDaysOverdueLabel => 'Maalmaha Dib u Dhaca';

  @override
  String get debtPaymentHistoryLoadError =>
      'Taariikhda lacag-bixinta lama soo geli karin.';

  @override
  String get debtPaymentHistoryEmptyState =>
      'Weli lacag-bixin lama diiwaan gelin';

  @override
  String get debtDocumentsLoadError =>
      'Dukumentiyada la xiriira lama soo geli karin.';

  @override
  String get debtTimelineLoadError =>
      'Taariikhda raadraaca lama soo geli karin.';

  @override
  String get debtTimelineStageDebtCreated => 'Dayn La Abuuray';

  @override
  String get debtTimelineStageWhatsappReminder => 'Xasuusin WhatsApp';

  @override
  String get debtTimelineStageSmsReminder => 'Xasuusin SMS';

  @override
  String get debtTimelineStagePhoneCall => 'Wicitaan Taleefan';

  @override
  String get debtTimelineStagePayment => 'Lacag-bixin';

  @override
  String get debtRelatedCaseLoadError =>
      'Kiiska la xiriira lama soo geli karin.';

  @override
  String get debtRelatedCaseEmptyState =>
      'Wali kiis ururin ah looma furin daynta';

  @override
  String get promiseToPaySheetDateLabel => 'Taariikhda Ballanqaadka';

  @override
  String get promiseToPaySheetSaveButton => 'Kaydi Ballanqaadka';

  @override
  String get promiseToPayHistoryLoadError =>
      'Taariikhda Ballanqaadka Bixinta lama soo geli karin.';

  @override
  String get promiseToPayHistoryEmptyState =>
      'Wali ballanqaad bixin lama diiwaan gelin';

  @override
  String promiseToPayHistoryPromisedLabel(String date) {
    return 'Waxaa la ballan qaaday $date';
  }

  @override
  String promiseToPayHistoryRecordedLabel(String date) {
    return 'La diiwaan geliyay $date';
  }

  @override
  String get logReminderCallLabel => 'Wicitaan';

  @override
  String logReminderSheetTitle(String label) {
    return 'Diiwaan Geli $label';
  }

  @override
  String get logReminderDetailsLabel => 'Faahfaahin (Ikhtiyaari)';

  @override
  String get recordPaymentDateLabel => 'Taariikhda Lacag-bixinta';

  @override
  String get recordPaymentMethodLabel => 'Habka Lacag-bixinta (Ikhtiyaari)';

  @override
  String get recordPaymentNotesLabel => 'Faallooyin (Ikhtiyaari)';

  @override
  String get recordPaymentSaveButton => 'Kaydi Lacag-bixinta';

  @override
  String get caseListTabHighRisk => 'Khatar Sare';

  @override
  String get caseListTabFollowUp => 'Raadraaca';

  @override
  String get caseListTabPromiseDue => 'Ballanqaad la Sugayo';

  @override
  String get caseListBrowseCustomersTooltip => 'Fiiri Macaamiisha';

  @override
  String get caseListProfessionalRequestsTooltip =>
      'Codsiyada Ururinta Xirfadeed';

  @override
  String get caseListEmptyFilteredState =>
      'Kiisas u dhigma shaandhadan lama helin';

  @override
  String get caseDetailTitle => 'Faahfaahinta Kiiska';

  @override
  String get caseDetailLoadError => 'Kiiskan lama soo geli karin.';

  @override
  String get caseDetailNoCustomerMessage =>
      'Kiiskan macmiil lala xiriiriyay ma jiro oo la tusi karo.';

  @override
  String get caseDetailCustomerLoadError =>
      'Macmiilka kiiskan lama soo geli karin.';

  @override
  String get caseDetailCustomerSummaryHeading => 'Soo-koobka Macmiilka';

  @override
  String get caseDetailDebtLoadError => 'Daynta kiiskan lama soo geli karin.';

  @override
  String get caseDetailCaseSummaryHeading => 'Soo-koobka Kiiska';

  @override
  String get caseDetailAddFollowUpButton => 'Ku Dar Raadraac';

  @override
  String get caseDetailMarkContactedButton => 'Calaamadee La Xiriiray';

  @override
  String get caseDetailRecordVisitButton => 'Diiwaan Geli Booqasho';

  @override
  String get caseDetailSubmitProfessionalCollectionButton =>
      'U Gudbi Ururinta Xirfadeed';

  @override
  String get caseDetailClosedMessage =>
      'Kiiskan waa xiran yahay — dhaqdhaqaaq dheeraad ah, raadraac, ama ficillo xiritaan ma khusayaan.';

  @override
  String get caseDetailTimelineHeading => 'Taariikhda Falalka';

  @override
  String get caseNotesEditTitle => 'Wax ka Beddel Faallooyinka';

  @override
  String get caseDetailNoNotesMessage => 'Wali faallo lama gelin.';

  @override
  String caseDetailReminderPresetLabel(String referenceNumber) {
    return 'Kiiska $referenceNumber';
  }

  @override
  String get caseDetailRelatedPaymentsHeading => 'Lacag-bixinnada La Xiriira';

  @override
  String get professionalCollectionRequestSubmittedSuccess =>
      'Codsiga Ururinta Xirfadeed si guul leh ayaa loo gudbiyay';

  @override
  String get closeCaseTitle => 'Xir Kiiska';

  @override
  String get closeCaseSheetReasonLabel => 'Natiijada Xirista';

  @override
  String get closeCaseSheetReasonRequiredValidator => 'Geli natiijada xirista';

  @override
  String get editCaseNotesSaveButton => 'Kaydi Faallooyinka';

  @override
  String get caseCardUnknownCustomer => 'Macmiil aan la garanayn';

  @override
  String get caseCardOutstandingLabel => 'Hadhaysa';

  @override
  String get caseUnassignedLabel => 'Aan La Xilsaarin';

  @override
  String get caseSummaryOutstandingAmountLabel => 'Qadarka Hadhaysa';

  @override
  String get caseSummaryAssignedOfficerLabel => 'Sarkalka La U Xilsaaray';

  @override
  String caseSummaryOfficerLabel(String officerId) {
    return 'Sarkalka $officerId';
  }

  @override
  String get caseSummaryLastActivityLabel => 'Dhaqdhaqaaqii Ugu Dambeeyay';

  @override
  String get caseTimelineLoadError => 'Taariikhda kiiska lama soo geli karin.';

  @override
  String get caseTimelineEmptyState => 'Wali dhaqdhaqaaq lama diiwaan gelin';

  @override
  String get collectionStageLabel => 'Marxaladda Ururinta';

  @override
  String collectionStageValueLabel(int stage) {
    return 'Marxaladda $stage ee 6';
  }

  @override
  String get reminderListCalendarTooltip => 'Kalandarka';

  @override
  String get reminderScheduleTitle => 'Jadwali Xasuusin';

  @override
  String get reminderFilterPayments => 'Lacag-bixinnada';

  @override
  String get reminderListLoadError => 'Xasuusinta lama soo geli karin.';

  @override
  String get reminderListEmptyFilteredState =>
      'Wax sugaya kuma jiraan shaandhadan';

  @override
  String get reminderListEmptyState => 'Wax sugaya ma jiraan';

  @override
  String get reminderCardCompleteButton => 'Dhammee';

  @override
  String get reminderSummaryLoadError => 'Soo-koobka lama soo geli karin.';

  @override
  String get reminderSummaryDueTodayLabel => 'Waa Maanta';

  @override
  String get reminderTypeBadgeVisit => 'BOOQASHO';

  @override
  String get reminderTypeBadgeFollowUp => 'RAADRAAC';

  @override
  String get reminderTypeBadgePayment => 'LACAG-BIXIN';

  @override
  String get reminderTypeBadgeRenewal => 'DIB-CUSBOONEYSIIN';

  @override
  String get reminderTypeBadgePromise => 'BALLANQAAD';

  @override
  String get customerPickerSheetEmptyState => 'Macmiil lama helin';

  @override
  String get reminderDetailDeleteDialogTitle => 'Tirtir Xasuusinta';

  @override
  String get reminderDetailDeleteDialogContent =>
      'Xasuusintan mar dambe kuma soo muuqan doonto goobna. Tallaabadan lama beddeli karo.';

  @override
  String get reminderDetailDeleteButton => 'Tirtir';

  @override
  String get reminderDetailNoAddressMessage =>
      'Ma jiro magac ama cinwaan macmiil oo lagu jihayn karo.';

  @override
  String get reminderDetailMapsOpenError => 'Khariidadaha lama furi karin.';

  @override
  String get reminderDetailTitle => 'Faahfaahinta Xasuusinta';

  @override
  String get reminderDetailLoadError => 'Xasuusintan lama soo geli karin.';

  @override
  String get reminderDetailTypeLabel => 'Nooca';

  @override
  String get reminderDetailAmountDueLabel => 'Lacagta la Sugayo';

  @override
  String get reminderDetailRelatedCaseLabel => 'Kiiska La Xiriira';

  @override
  String get reminderDetailViewCaseLabel => 'Fiiri Kiiska';

  @override
  String get reminderDetailCreatedByLabel => 'Waxaa Abuuray';

  @override
  String reminderDetailCreatedByValue(String userId) {
    return 'Isticmaale $userId';
  }

  @override
  String get reminderDetailCreatedOnLabel => 'Waxaa La Abuuray';

  @override
  String get reminderDetailNoNotesMessage => 'Wax faallo ah lagama darin';

  @override
  String get reminderDetailNavigateButton => 'U Jihee';

  @override
  String get reminderDetailCheckedInLabel => 'La Kormeeray';

  @override
  String get reminderDetailCheckInButton => 'Kormeer';

  @override
  String get reminderDetailLogVisitOutcomeLabel =>
      'Diiwaan Geli Natiijada Booqashada';

  @override
  String get reminderDetailSnoozeButton => 'Dib u Dhig Wax Yar';

  @override
  String get reminderDetailMarkCompletedButton =>
      'Calaamadee Sida La Dhammeeyay';

  @override
  String get reminderDetailWhatsAppButton => 'WhatsApp';

  @override
  String get reminderDetailSmsButton => 'SMS';

  @override
  String get reminderDetailRescheduleButton => 'Dib u Jadwali';

  @override
  String get reminderDetailLogVisitOutcomeHint => 'Maxaa dhacay booqashadan?';

  @override
  String get reminderDetailVisitOutcomeSavedMessage =>
      'Natiijada booqashada waa la kaydiyay.';

  @override
  String get reminderSnoozeSheetTitle => 'Dib u Dhig Xasuusinta';

  @override
  String get reminderSnoozeOneHour => '1 Saac';

  @override
  String get reminderSnoozeTomorrow => 'Berri';

  @override
  String get reminderSnoozeNextWeek => 'Toddobaadka Soo Socda';

  @override
  String get reminderSnoozePickDateTime => 'Dooro Taariikhda iyo Waqtiga';

  @override
  String reminderSnoozedUntilMessage(String date) {
    return 'Waxaa dib loo dhigay ilaa $date.';
  }

  @override
  String get reminderNoPhoneNumberMessage =>
      'Ma jiro lambar taleefan oo macmiilkan u diyaar ah.';

  @override
  String get reminderCouldNotOpenDialerMessage =>
      'Wicitaanka taleefanka lama furi karin.';

  @override
  String get reminderTypeClientVisit => 'Booqasho Macmiil';

  @override
  String get reminderTypeFollowUpCall => 'Wicitaan Raadraac';

  @override
  String get reminderTypePaymentDue => 'Lacag Sugaysa';

  @override
  String get reminderTypeContractRenewal => 'Dib u Cusboonaysiinta Heshiiska';

  @override
  String get reminderTimingOneDayBefore => '1 maalin ka hor';

  @override
  String get reminderTimingSameDay => 'Maalintii oo kale';

  @override
  String get reminderTimingOneHourBefore => '1 saac ka hor';

  @override
  String get reminderTimingCustomTime => 'Waqti Gaar ah';

  @override
  String get reminderDeliveryInApp => 'Ogeysiiska Abka Gudihiisa';

  @override
  String get reminderDeliveryPush => 'Ogeysiiska Push';

  @override
  String get reminderDeliveryWhatsApp => 'Fariinta WhatsApp';

  @override
  String get reminderDeliverySms => 'Fariinta SMS';

  @override
  String get reminderScheduleTypeRequiredValidator => 'Dooro nooca xasuusinta.';

  @override
  String get reminderScheduleCustomerRequiredValidator => 'Dooro macmiil.';

  @override
  String get reminderScheduleCustomFireRequiredValidator =>
      'Dooro taariikh/waqti gaar ah oo xasuusinta la diro.';

  @override
  String get reminderScheduleCustomFireBeforeDueValidator =>
      'Waqtiga gaarka ah waa inuu ka hor yimaadaa ama la mid noqdaa taariikhda dhammaadka.';

  @override
  String get reminderScheduleDeliveryMethodRequiredValidator =>
      'Dooro ugu yaraan hal habka gaarsiinta.';

  @override
  String get reminderScheduleRescheduleLoadingTitle => 'Dib u Jadwali';

  @override
  String get reminderScheduleRescheduleTitle => 'Dib u Jadwali Xasuusinta';

  @override
  String get reminderScheduleTypeHeading => 'Nooca Xasuusinta';

  @override
  String get reminderScheduleRelatedToHeading => 'La Xiriira';

  @override
  String get reminderScheduleTimingHeading =>
      'Goorma ayaa xasuusintan la diri doonaa?';

  @override
  String get reminderScheduleSelectCustomFireTimeButton =>
      'Dooro Waqtiga Gaarka ah';

  @override
  String get reminderScheduleDeliveryMethodsHeading => 'Habka Gaarsiinta';

  @override
  String get messagePreviewTitle => 'Dir Xasuusinta';

  @override
  String get messagePreviewWhatsAppOpenError => 'WhatsApp lama furi karin.';

  @override
  String get messagePreviewMessagingAppOpenError =>
      'Abka fariimaha lama furi karin.';

  @override
  String get messagePreviewUnknownRecipient => 'Qofka aan la garanayn';

  @override
  String get messagePreviewTemplatesLoadError =>
      'Qaababka fariimaha lama soo geli karin.';

  @override
  String get messagePreviewEmptyTemplatesState =>
      'Wali qaab fariin ah kuma jiro kanaalkan';

  @override
  String get messagePreviewUseTemplateHeading => 'Isticmaal Qaabka';

  @override
  String get messagePreviewSendViaWhatsAppButton => 'U Dir WhatsApp';

  @override
  String get messagePreviewSendViaSmsButton => 'U Dir SMS';

  @override
  String get notificationMarkAllReadButton => 'Calaamadee Dhammaan La Akhriyay';

  @override
  String get notificationFilterAll => 'Dhammaan';

  @override
  String get notificationListLoadError => 'Ogeysiisyada lama soo geli karin.';

  @override
  String get notificationListEmptyState => 'Wali ogeysiis ma jiro';

  @override
  String notificationListEmptyFilteredState(String type) {
    return 'Ogeysiisyo $type ah lama helin';
  }

  @override
  String get notificationTypeFallback => 'Ogeysiis';

  @override
  String get notificationDetailRelatedToLabel => 'La Xiriira';

  @override
  String get notificationDetailReferenceIdLabel => 'Aqoonsiga Tixraaca';

  @override
  String get notificationDetailReceivedLabel => 'La Helay';

  @override
  String get notificationDetailStatusLabel => 'Xaaladda';

  @override
  String get notificationDetailStatusRead => 'La Akhriyay';

  @override
  String get notificationDetailStatusUnread => 'Lama Akhrin';

  @override
  String get notificationDetailOpenButton => 'Fur';

  @override
  String get notificationTypeCreditLimitReached =>
      'Xadka Deynta Waa La Gaadhay';

  @override
  String get notificationTypePaymentReceived => 'Lacag-bixin Waa La Helay';

  @override
  String get notificationTypeDocumentAvailable => 'Dukumenti Diyaar ah';

  @override
  String get notificationTypeCollectionAssignment => 'U Xilsaarista Ururinta';

  @override
  String get notificationTypeReminderSent => 'Xasuusin Waa La Diray';

  @override
  String get notificationTypePromiseToPayDue =>
      'Ballanqaadka Bixinta ee Dhacay';

  @override
  String get notificationTypeCollectionRequestUpdate =>
      'Cusboonaysiinta Codsiga Ururinta';

  @override
  String get notificationTypeSubscriptionUpdate =>
      'Cusboonaysiinta Subscription-ka';

  @override
  String get notificationTypeStorageAddonUpdate =>
      'Cusboonaysiinta Add-on-ka Kaydinta';

  @override
  String get notificationTypeSupportTicketCreated =>
      'Tikidhka Taageerada Waa La Abuuray';

  @override
  String get notificationTypeSupportTicketReplied =>
      'Jawaab Tikidhka Taageerada';

  @override
  String get notificationTypeSupportTicketStatusChanged =>
      'Cusboonaysiinta Xaaladda Tikidhka';

  @override
  String get notificationTypeSupportTicketClosed =>
      'Tikidhka Taageerada Waa La Xiray';

  @override
  String get notificationTypeSupportTicketReopened =>
      'Tikidhka Taageerada Waa Dib Loo Furay';

  @override
  String get notificationTypeAdminAnnouncement => 'Ogeysiin';

  @override
  String get notificationDeleteAction => 'Tirtir';

  @override
  String get globalSearchTitle => 'Raadinta Guud';

  @override
  String get globalSearchHint =>
      'Ka raadi macaamiisha, daymaha, lacag-bixinnada, dukumentiyada, kiisaska';

  @override
  String get globalSearchCategoryAll => 'Dhammaan';

  @override
  String get globalSearchCategoryCustomers => 'Macaamiisha';

  @override
  String get globalSearchCategoryDebts => 'Daymaha';

  @override
  String get globalSearchCategoryPayments => 'Lacag-bixinnada';

  @override
  String get globalSearchCategoryDocuments => 'Dukumentiyada';

  @override
  String get globalSearchCategoryCases => 'Kiisaska';

  @override
  String get globalSearchErrorMessage => 'Raadinta lama dhammayn karin.';

  @override
  String get globalSearchNoResultsTitle => 'Wax natiijo ah lama helin';

  @override
  String globalSearchNoResultsMessage(String query) {
    return 'Waxba kuma beegnayn \"$query\". Isku day erey raadin oo kale ah.';
  }

  @override
  String get globalSearchDeendoonTitle => 'Raadi Deendoon';

  @override
  String get globalSearchDeendoonMessage =>
      'Hel macaamiisha, daymaha, lacag-bixinnada, dukumentiyada, iyo kiisaska.';

  @override
  String get globalSearchRecentSearchesHeading => 'Raadinta Dhawaan';

  @override
  String get globalSearchClearButton => 'Nadiifi';

  @override
  String get calendarTitle => 'Kalandarka';

  @override
  String get calendarPreviousMonthTooltip => 'Bisha hore';

  @override
  String get calendarNextMonthTooltip => 'Bisha xigta';

  @override
  String get monthJan => 'Jannaayo';

  @override
  String get monthFeb => 'Febraayo';

  @override
  String get monthMar => 'Maarso';

  @override
  String get monthApr => 'Abriil';

  @override
  String get monthMay => 'Maajo';

  @override
  String get monthJun => 'Juun';

  @override
  String get monthJul => 'Luuliyo';

  @override
  String get monthAug => 'Ogosto';

  @override
  String get monthSep => 'Sebtembar';

  @override
  String get monthOct => 'Oktoobar';

  @override
  String get monthNov => 'Noofembar';

  @override
  String get monthDec => 'Diseembar';

  @override
  String get weekdayMon => 'Isn';

  @override
  String get weekdayTue => 'Tal';

  @override
  String get weekdayWed => 'Arb';

  @override
  String get weekdayThu => 'Kha';

  @override
  String get weekdayFri => 'Jim';

  @override
  String get weekdaySat => 'Sab';

  @override
  String get weekdaySun => 'Axd';

  @override
  String get calendarWeekdayMonday => 'Isniin';

  @override
  String get calendarWeekdayTuesday => 'Talaado';

  @override
  String get calendarWeekdayWednesday => 'Arbaco';

  @override
  String get calendarWeekdayThursday => 'Khamiis';

  @override
  String get calendarWeekdayFriday => 'Jimce';

  @override
  String get calendarWeekdaySaturday => 'Sabti';

  @override
  String get calendarWeekdaySunday => 'Axad';

  @override
  String get calendarLoadError => 'Xogta kalandarka lama soo geli karin.';

  @override
  String get calendarEmptyStateTitle => 'Wax dhacdo ah ma jiraan';

  @override
  String get calendarEmptyStateMessage =>
      'Waxba lama sugayo, lama ballanqaaday, lamana qorsheynin maalintan.';

  @override
  String get calendarFollowUpWhatsApp => 'Raadraac WhatsApp';

  @override
  String get calendarFollowUpSms => 'Raadraac SMS';

  @override
  String get calendarFollowUpCallLogged => 'Wicitaan La Diiwaan Geliyay';

  @override
  String get calendarEntryTitleDebtDue => 'Dayn Dhacaysa';

  @override
  String calendarEntryTitleDue(String label) {
    return 'Wuxuu Dhacayaa: $label';
  }

  @override
  String get calendarEntryTitleFollowUpFallback => 'Raadraac';

  @override
  String get calendarEntryTitleReminderFallback => 'Xasuusin';

  @override
  String get analyticsTitle => 'Falanqaynta';

  @override
  String get analyticsTabOverview => 'Guudmar';

  @override
  String get analyticsTabReports => 'Warbixinno';

  @override
  String get analyticsTabTrends => 'Isbeddellada';

  @override
  String get analyticsNotIncludedTitle => 'Falanqaynta Kuma Jirto Qorshahaaga';

  @override
  String get analyticsNotIncludedMessage =>
      'Falanqaynta iyo Warbixinnadu kuma jiraan qorshahaaga hadda socda. Kor u qaad qorshahaaga si aad u furto Tirakoobyada (KPI), Falanqaynta Da\'da Daymaha, Qaybinta Khatarta, Isbeddelka Ururinta, iyo dhammaan noocyada Warbixinta.';

  @override
  String get analyticsUpgradePlanButton => 'Kordhi Qorshaha';

  @override
  String get overviewSectionCollectionAnalytics => 'Falanqaynta Ururinta';

  @override
  String get overviewSectionCollectionsTrend => 'Isbeddelka Ururinta';

  @override
  String get overviewSectionAgingAnalysis => 'Falanqaynta Da\'da Daymaha';

  @override
  String get overviewSectionRiskDistribution => 'Qaybinta Khatarta';

  @override
  String get overviewCollectionAnalyticsLoadError =>
      'Falanqaynta Ururinta lama soo geli karin.';

  @override
  String get overviewCollectionsTrendLoadError =>
      'Isbeddelka Ururinta lama soo geli karin.';

  @override
  String get overviewAgingAnalysisLoadError =>
      'Falanqaynta Da\'da Daymaha lama soo geli karin.';

  @override
  String get overviewRiskDistributionLoadError =>
      'Qaybinta Khatarta lama soo geli karin.';

  @override
  String get overviewKpiCollectionRate => 'Heerka Ururinta';

  @override
  String get overviewKpiTotalCollected => 'Wadarta La Ururiyay';

  @override
  String get overviewKpiAverageDays => 'Celceliska Maalmaha';

  @override
  String get overviewDonutTotalOutstanding => 'Wadarta Hadhaysa';

  @override
  String get overviewDonutClassifiedCustomers => 'Macaamiisha La Kala Saaray';

  @override
  String get overviewRiskLabelHigh => 'Khatar Sare';

  @override
  String get overviewRiskLabelMedium => 'Khatar Dhexdhexaad ah';

  @override
  String get overviewRiskLabelLow => 'Khatar Hoose';

  @override
  String get paymentReportMethodNotRecorded => 'Habka lama diiwaan gelin';

  @override
  String paymentReportDebtIdLabel(String debtId) {
    return 'Dayn #$debtId';
  }

  @override
  String get dateRangeMonthJan => 'Jan';

  @override
  String get dateRangeMonthFeb => 'Feb';

  @override
  String get dateRangeMonthMar => 'Mar';

  @override
  String get dateRangeMonthApr => 'Abr';

  @override
  String get dateRangeMonthMay => 'Maa';

  @override
  String get dateRangeMonthJun => 'Jun';

  @override
  String get dateRangeMonthJul => 'Luu';

  @override
  String get dateRangeMonthAug => 'Ogo';

  @override
  String get dateRangeMonthSep => 'Seb';

  @override
  String get dateRangeMonthOct => 'Okt';

  @override
  String get dateRangeMonthNov => 'Noo';

  @override
  String get dateRangeMonthDec => 'Dis';

  @override
  String get reportCategoryCustomers => 'Macaamiisha';

  @override
  String get reportCategoryDebts => 'Daymaha';

  @override
  String get reportCategoryCollectionCases => 'Kiisaska Ururinta Daynta';

  @override
  String get reportCategoryPayments => 'Lacag-bixinnada';

  @override
  String get reportCategoryCreditRisk => 'Khatarta Deynta';

  @override
  String get reportExportTooltip => 'Dhoofi';

  @override
  String get reportDebtsTitle => 'Warbixinta Daymaha';

  @override
  String get reportDebtsEmptyState => 'Daymo u dhigma shaandhadan lama helin';

  @override
  String get reportCustomersTitle => 'Warbixinta Macaamiisha';

  @override
  String get reportCustomersEmptyState =>
      'Macaamiil u dhigma shaandhadan lama helin';

  @override
  String get reportRiskFilterAll => 'Khatarta Oo Dhan';

  @override
  String get reportCreditRiskTitle => 'Warbixinta Khatarta Deynta';

  @override
  String get reportCreditRiskLoadError =>
      'Warbixinta khatarta deynta lama soo geli karin.';

  @override
  String get reportCollectionCasesTitle =>
      'Warbixinta Kiisaska Ururinta Daynta';

  @override
  String get reportCollectionCasesLoadError =>
      'Kiisaska ururinta daynta lama soo geli karin.';

  @override
  String get reportPaymentsTitle => 'Warbixinta Lacag-bixinnada';

  @override
  String get reportPaymentsClearDateFilterTooltip =>
      'Nadiifi Shaandhada Taariikhda';

  @override
  String get reportPaymentsLoadError => 'Lacag-bixinnada lama soo geli karin.';

  @override
  String get reportPaymentsEmptyState =>
      'Wax lacag-bixin ah kuma jiraan xilligan';

  @override
  String get averageDaysDetailDescription =>
      'Celceliska maalmaha u dhexeeya taariikhda dhammaadka daynta iyo taariikhda ay si buuxda u bixisay, daymaha xilligan la bixiyay.';

  @override
  String get averageDaysDetailDebtsHeading => 'Daymaha Xilligan La Bixiyay';

  @override
  String get averageDaysDetailEmptyState =>
      'Wax dayn ah lagama bixin xilligan.';

  @override
  String get collectionRateDetailFormulaCaption =>
      'Waxa La Ururiyay ÷ Qadarka Dhacay ee Xilliga';

  @override
  String get collectionRateDetailDebtsHeading => 'Daymaha Xilligan Dhacay';

  @override
  String get collectionRateDetailEmptyState =>
      'Wax dayn ah kuma dhicin xilligan.';

  @override
  String get agingBucketDebtsEmptyState => 'Wax dayn ah kuma jiraan qaybtan';

  @override
  String agingBucketDebtsShowingCountLabel(int shown, int total) {
    return 'Waxaa la tusinayaa $shown oo ka mid ah $total dayn oo ku jira qaybtan.';
  }

  @override
  String get exportActionSheetTitle => 'Dhoofi Sida';

  @override
  String get exportFormatPdf => 'PDF';

  @override
  String get exportFormatExcel => 'Excel';

  @override
  String get exportFormatCsv => 'CSV';

  @override
  String exportSavedToPathMessage(String path) {
    return 'Waxaa lagu kaydiyay $path';
  }

  @override
  String get subscriptionTitle => 'Rukumaynta';

  @override
  String get subscriptionLoadError => 'Rukumayntaada lama soo geli karin.';

  @override
  String get subscriptionManageStorageButton => 'Maamul Kaydinta';

  @override
  String get subscriptionAvailablePlansHeading => 'Qorshayaasha Diyaarka ah';

  @override
  String get subscriptionRequestHistoryHeading => 'Taariikhda Codsiyada';

  @override
  String subscriptionPlanChangeRequestSubmittedMessage(String planName) {
    return 'Codsiga isbeddelka qorshaha ee $planName waa la gudbiyay — xaaladda: Sugaya.';
  }

  @override
  String subscriptionRequestPlanChangeButton(String planName) {
    return 'U Codso Isbeddelka Qorshaha ee $planName';
  }

  @override
  String get subscriptionMonthlyPriceLabel => 'Qiimaha Bishii';

  @override
  String get subscriptionTrialEndsLabel => 'Tijaabadu Way Dhammaanaysaa';

  @override
  String get subscriptionStartDateLabel => 'Taariikhda Bilowga';

  @override
  String get subscriptionExpiryDateLabel => 'Taariikhda Dhammaadka';

  @override
  String get subscriptionCustomersLabel => 'Macaamiisha';

  @override
  String get storageUsedLabel => 'Kaydinta La Isticmaalay';

  @override
  String get subscriptionStorageLimitLabel => 'Xadka Kaydinta';

  @override
  String get subscriptionUnlimitedLabel => 'Xad la\'aan';

  @override
  String get subscriptionAnalyticsLabel => 'Falanqaynta';

  @override
  String get subscriptionIncludedLabel => 'Ku Jira';

  @override
  String get subscriptionNotIncludedLabel => 'Kuma Jiro';

  @override
  String get subscriptionAccountStatusLabel => 'Xaaladda Akoonka';

  @override
  String get subscriptionReadOnlyValueLabel => 'Akhris-oo-Kaliya';

  @override
  String get subscriptionNormalValueLabel => 'Caadi';

  @override
  String get subscriptionCustomerLimitReachedTitle =>
      'Xadka Macaamiisha Waa La Gaadhay';

  @override
  String get subscriptionCustomerLimitReachedMessage =>
      'Waxaad gaadhay xadka macaamiisha ee qorshahaaga hadda socda, sidaa darteed ku darista macaamiil cusub waa la xannibay. Xogtaada hadda jirta si buuxda ayaa loo heli karaa. Kor u qaad qorshahaaga si aad macaamiil dheeraad ah u darto.';

  @override
  String get subscriptionPlansLoadError =>
      'Qorshayaasha rukumaynta lama soo geli karin.';

  @override
  String get subscriptionNoPlansAvailable => 'Wax qorshayaal ah lama helin.';

  @override
  String get subscriptionCurrentPlanBadge => 'Qorshaha Hadda';

  @override
  String get subscriptionPlanCustomerLimitLabel => 'Xadka Macaamiisha';

  @override
  String get subscriptionChangeRequestHistoryLoadError =>
      'Taariikhda codsiyada isbeddelka rukumaynta lama soo geli karin.';

  @override
  String get subscriptionNoChangeRequestsMessage =>
      'Wali codsi isbeddel rukumayn ah ma jiro.';

  @override
  String get subscriptionLoadMoreButton => 'Soo Rar In Ka Badan';

  @override
  String get subscriptionChangeRequestCancelledMessage =>
      'Codsiga Isbeddelka Rukumaynta waa la joojiyay.';

  @override
  String get subscriptionFromLabel => 'Qorshihii Hore';

  @override
  String get subscriptionPaymentReferenceLabel => 'Tixraaca Lacag-bixinta';

  @override
  String get subscriptionRequestedOnLabel => 'Waxaa La Codsaday';

  @override
  String get subscriptionReviewedOnLabel => 'Waxaa Dib Loo Eegay';

  @override
  String get subscriptionRejectionReasonLabel => 'Sababta Diidmada';

  @override
  String get subscriptionCancelRequestButton => 'Jooji Codsiga';

  @override
  String get subscriptionRequestPlanChangeSheetTitle =>
      'Codso Isbeddelka Qorshaha';

  @override
  String subscriptionRequestPlanChangeDescription(
    String planName,
    String monthlyPrice,
  ) {
    return 'Waxaad codsanaysaa in loo beddelo $planName ($monthlyPrice / bishii). Tani waxay abuuraysaa codsi sugaya — qorshahaaga hadda socda wuu sii socon doonaa ilaa uu Maamulaha Nidaamka ansixiyo.';
  }

  @override
  String get subscriptionPaymentReferenceRequiredValidator =>
      'Tixraaca lacag-bixinta waa lagama maarmaan';

  @override
  String get subscriptionPaymentReferenceMaxLengthValidator =>
      'Tixraaca lacag-bixinta waa inuu ka koobnaadaa 100 xaraf ama ka yar';

  @override
  String get storageTitle => 'Kaydinta';

  @override
  String storageAddonRequestSubmittedMessage(String label) {
    return 'Codsiga Add-on-ka Kaydinta ee $label waa la gudbiyay — wuxuu sugayaa ansixinta Maamulaha Nidaamka.';
  }

  @override
  String get storageAddonRequestCancelledMessage =>
      'Codsiga Add-on-ka Kaydinta waa la joojiyay.';

  @override
  String get storageLoadError => 'Isticmaalka kaydintaada lama soo geli karin.';

  @override
  String get storageActiveAddonsHeading => 'Add-on-yada Kaydinta ee Firfircoon';

  @override
  String get storageAvailablePackagesHeading =>
      'Xirmooyinka Kaydinta ee Diyaarka ah';

  @override
  String storageRequestAddonButton(String label) {
    return 'Codso Add-on Kaydin ($label)';
  }

  @override
  String get storageOverviewHeading => 'Guudmarka Kaydinta';

  @override
  String get storageBaseAllowanceLabel => 'Qadarka Kaydinta ee Aasaasiga ah';

  @override
  String get storageEffectiveAllowanceLabel => 'Qadarka Kaydinta ee Dhabta ah';

  @override
  String get storageRemainingAllowanceLabel => 'Kaydinta Soo Hadhay';

  @override
  String get storageNoActiveAddonsMessage =>
      'Wali Add-on kaydin oo firfircoon ah ma jiro.';

  @override
  String get storageSizeLabel => 'Cabbirka';

  @override
  String get storageStartedOnLabel => 'Waxaa La Bilaabay';

  @override
  String get storageExpiresOnLabel => 'Wuxuu Dhici Doonaa';

  @override
  String get storageRequestAddonSheetTitle => 'Codso Add-on Kaydin';

  @override
  String storageRequestAddonDescription(String packageLabel) {
    return 'Waxaad codsanaysaa Add-on-ka kaydinta ee $packageLabel. Tani waxay abuuraysaa codsi sugaya — kama korodhsanayso qadarka kaydintaada ilaa uu Maamulaha Nidaamka ansixiyo. Qiimaha saxda ah ee bishii waxaa la xaqiijin doonaa marka la gudbiyo.';
  }

  @override
  String get bulkImportTitle => 'Soo Dejin Guud';

  @override
  String get bulkImportSampleTemplateHeading => 'Tusaalaha Foomka';

  @override
  String get bulkImportUploadFileHeading => 'Ku Rar Faylka';

  @override
  String get bulkImportAcceptedFormats => 'Noocyada la aqbalo: .xlsx, .xls';

  @override
  String get bulkImportSelectFilePrompt => 'Dooro fayl Excel ah';

  @override
  String get bulkImportButton => 'Soo Geli';

  @override
  String get bulkImportNoRowsFoundMessage =>
      'Wax saf ah lagama helin faylka la soo rartay.';

  @override
  String get bulkImportSummaryHeading => 'Soo-koobka Soo Gelinta';

  @override
  String get bulkImportImportedSuccessfullyLabel =>
      'Si Guul Leh Loo Soo Geliyay';

  @override
  String get bulkImportSkippedDuplicateLabel => 'La Booday (Nuqul)';

  @override
  String get bulkImportFailedLabel => 'Fashilmay';

  @override
  String get bulkImportFailedRowsHeading => 'Safafka Fashilmay';

  @override
  String bulkImportRowLabel(int rowNumber) {
    return 'Safka $rowNumber';
  }

  @override
  String get bulkImportDownloadTemplateButton => 'Soo Deji Tusaalaha Foomka';

  @override
  String get agingBucketCurrentLabel => 'Hadda';

  @override
  String get agingBucket1To30Label => '1–30 Maalmood';

  @override
  String get agingBucket31To60Label => '31–60 Maalmood';

  @override
  String get agingBucket61To90Label => '61–90 Maalmood';

  @override
  String get agingBucketOver90Label => 'In ka Badan 90 Maalmood';

  @override
  String get accountTitle => 'Akoonka';

  @override
  String get accountSectionLabel => 'AKOONKA';

  @override
  String get accountLogout => 'Ka Bax';

  @override
  String get accountCloseAccount => 'Xir Akoonka';

  @override
  String get closeAccountTitle => 'Xir Akoonka';

  @override
  String get closeAccountWarningHeading =>
      'Waxa dhaca marka aad xirto akoonkaaga';

  @override
  String get closeAccountWarningBody =>
      'Akoonkaaga waa la kaydin doonaa (archive) ganacsigaagana isla markiiba waa la joojin doonaa. Waa lagaa saari doonaa akoonka mana geli kartid mar dambe. Macaamiishaada, deymaha, lacag-bixinnada, dukumeentiyada, iyo taariikhda waa la haynayaa — waxba lama tirtiro. Si aad akoonkaaga dib u furto, la xiriir Taageerada Deendoon.';

  @override
  String get closeAccountPasswordLabel => 'Geli furahaaga si aad u xaqiijiso';

  @override
  String get closeAccountPasswordRequired => 'Furaha waa lagama maarmaan';

  @override
  String get closeAccountButton => 'Xir Akoonkayga';

  @override
  String get closeAccountConfirmDialogTitle => 'Ma xirtaa akoonkaaga?';

  @override
  String get closeAccountConfirmDialogContent =>
      'Tan waxay isla markiiba kaa saari doontaa akoonka waxayna joojin doontaa gelitaanka ganacsigaaga. Adiga kuma laaban kartid — kaliya Taageerada Deendoon ayaa dib u furi kara.';

  @override
  String get closeAccountConfirmButton => 'Haa, Xir Akoonka';

  @override
  String get profileTitle => 'Astaanta Shaqsiga';

  @override
  String get businessProfileTitle => 'Xogta Ganacsiga';

  @override
  String get businessProfileLoadError =>
      'Xogta ganacsigaaga lama soo geli karin.';

  @override
  String get businessProfileLogoInvalidTypeError =>
      'Logo-gu waa inuu noqdaa sawir JPEG ama PNG ah.';

  @override
  String get businessProfileLogoTooLargeError =>
      'Logo-gu waa inuu ahaadaa 2MB ama ka yar.';

  @override
  String get businessProfileUpdatedSuccess =>
      'Xogta Ganacsiga si guul leh ayaa loo cusboonaysiiyay';

  @override
  String get businessProfileCompanyNameLabel => 'Magaca Shirkadda';

  @override
  String get businessProfileCompanyNameRequired =>
      'Magaca shirkadda waa lagama maarmaan';

  @override
  String get businessProfileContactEmailLabel => 'Iimaylka Xiriirka';

  @override
  String get businessProfileContactEmailInvalid =>
      'Geli cinwaan iimayl oo sax ah';

  @override
  String get businessProfileContactPhoneLabel => 'Taleefanka Xiriirka';

  @override
  String get businessProfileAddressLabel => 'Cinwaanka Ganacsiga';

  @override
  String get businessProfileLogoNewSelected => 'Logo cusub ayaa la doortay';

  @override
  String get businessProfileLogoOnFile =>
      'Logo ayaa diiwaan ku jira — taabo si aad u bedesho';

  @override
  String get businessProfileLogoTapToAdd => 'Taabo si aad logo u darto';

  @override
  String get changePasswordCurrentLabel => 'Furaha Sirta ah ee Hadda';

  @override
  String get changePasswordCurrentRequired =>
      'Furaha sirta ah ee hadda waa lagama maarmaan';

  @override
  String get changePasswordNewRequired =>
      'Furaha sirta ah ee cusub waa lagama maarmaan';

  @override
  String get aboutTitle => 'Ku Saabsan';

  @override
  String get aboutDeendoonAboutSectionLabel => 'KU SAABSAN';

  @override
  String get aboutDeendoonOthersSectionLabel => 'KUWA KALE';

  @override
  String get aboutDeendoonNotPublishedMessage =>
      'Deendoon wali kuma jiro App Store-ka.';

  @override
  String get aboutDeendoonPlayStoreOpenError =>
      'Play Store-ka lama furi karin.';

  @override
  String get aboutDeendoonPrivacyPolicyLabel => 'Siyaasadda Sirta';

  @override
  String get aboutDeendoonTermsConditionsLabel => 'Shuruudaha iyo Xaaladaha';

  @override
  String get aboutDeendoonContactSupportLabel => 'La Xiriir Taageerada';

  @override
  String get aboutDeendoonRateAppLabel => 'Qiimee Barnaamijka';

  @override
  String get aboutDeendoonVersionLabel => 'Nooca';

  @override
  String get aboutDeendoonBuildNumberLabel => 'Lambarka Build-ka';

  @override
  String get aboutDeendoonCopyrightLabel => 'Xuquuqda Daabacaadda';

  @override
  String aboutDeendoonCopyrightValue(int year) {
    return '© $year Deendoon. Dhammaan xuquuqda way dhowran yihiin.';
  }

  @override
  String get aboutDeendoonTagline =>
      'Kaaliyaha Casriga ah ee\nSoo Celinta Deymaha';

  @override
  String get aboutDeendoonIntroHeading => 'Hordhac DEENDOON';

  @override
  String get aboutDeendoonIntroParagraph1 =>
      'DEENDOON waa app kaa caawinaya inaad si fudud u maamusho deymaha macaamiishaada oo aad u soo ceshato lacagta aad ku leedahay.';

  @override
  String get aboutDeendoonIntroParagraph2 =>
      'Waxaad ku diiwaangelin kartaa deymaha kaa maqan, la socon kartaa lacagaha la bixiyay iyo kuwa harsan, jadwal u samayn kartaa wicitaannada, fariimaha WhatsApp, SMS-ka iyo xasuusinnada muhiimka ah. App-ku wuxuu kuu sheegayaa cidda la xiriirkeedu gaaray iyo tallaabada xigta ee aad qaadi lahayd si aan deyn loo illoobin.';

  @override
  String get aboutDeendoonIntroParagraph3 =>
      'Haddii dadaalladaadu aysan ku filnaan soo celinta deynta, waxaad si toos ah uga codsan kartaa gudaha app-ka kooxda xirfadlayaasha Deendoon inay si sharci ah oo xirfad leh kuu metelaan, ula xiriiraan deyn-bixiyaha, ugana shaqeeyaan soo celinta lacagtaada.';

  @override
  String get aboutDeendoonBenefitsHeading =>
      'DEENDOON wuxuu kaa caawinayaa inaad:';

  @override
  String get aboutDeendoonBenefit1 =>
      'Diiwaangeliso oo aad maamusho dhammaan deymaha hal meel.';

  @override
  String get aboutDeendoonBenefit2 =>
      'Xasuusinno u dirto macaamiisha waqtigooda.';

  @override
  String get aboutDeendoonBenefit3 =>
      'La socoto wicitaannada, WhatsApp-ka, SMS-ka iyo ballamaha.';

  @override
  String get aboutDeendoonBenefit4 =>
      'Diiwaangeliso lacagaha la bixiyay iyo kuwa harsan.';

  @override
  String get aboutDeendoonBenefit5 =>
      'Hesho warbixinno cad oo ku saabsan deymahaaga.';

  @override
  String get aboutDeendoonBenefit6 =>
      'Kordhiso soo celinta lacagaha lagugu leeyahay iyo socodka lacagta (Cash Flow) ee ganacsigaaga.';

  @override
  String get aboutDeendoonConclusionHeading => 'Gunaanad';

  @override
  String get aboutDeendoonConclusionParagraph =>
      'DEENDOON waa kaaliye casri ah oo kuu fududeynaya maamulka deymaha, xoojiyana la socodka macaamiisha, si ganacsigaagu u helo lacagtiisa waqtigeeda.';

  @override
  String get aboutDeendoonInfoHeading => 'Macluumaad';

  @override
  String get subscriptionNoPlanLabel => 'Qorshe Ma Jiro';

  @override
  String storageAddonTitleLabel(String package) {
    return 'Kordhinta Kaydinta ee $package';
  }

  @override
  String get addCaseEntrySheetExistingCustomer =>
      'Macmiil Horey u Diiwaan Gashan';

  @override
  String get addCaseEntrySheetNewCustomer => 'Macmiil Cusub';

  @override
  String get addCaseReviewTitle => 'Dib u eeg';

  @override
  String get addCaseReviewCustomerHeading => 'Macmiil';

  @override
  String addCaseReviewCreditLimitLabel(String limit) {
    return 'Xadka Deynta: $limit';
  }

  @override
  String get addCaseReviewDebtHeading => 'Dayn';

  @override
  String addCaseReviewAmountLabel(String amount) {
    return 'Qadarka: $amount';
  }

  @override
  String addCaseReviewDueDateLabel(String date) {
    return 'Taariikhda Dhammaadka: $date';
  }

  @override
  String addCaseReviewNotesLabel(String notes) {
    return 'Faallooyin: $notes';
  }

  @override
  String addCaseReviewInvoiceLabel(String filename) {
    return 'Qaansheeg: $filename';
  }

  @override
  String get addCaseReviewCreateCustomerDebtButton => 'Samee Macmiil & Dayn';

  @override
  String get addCaseReviewCreateDebtButton => 'Samee Dayn';

  @override
  String get addCaseReviewTryAgainButton => 'Isku Day Mar Kale';

  @override
  String addCaseReviewCustomerCreatedDebtFailedMessage(
    String name,
    String message,
  ) {
    return 'Macmiilka \"$name\" si guul leh ayaa loo abuuray. Abuurista deynta way fashilantay: $message';
  }

  @override
  String get addCaseReviewOpenCustomerButton => 'Fur Macmiilka';

  @override
  String addCaseReviewDebtCreatedCaseFailedMessage(
    String referenceNumber,
    String message,
  ) {
    return 'Deynta $referenceNumber si guul leh ayaa loo abuuray. Abuurista Kiiska Ururinta way fashilantay: $message';
  }

  @override
  String get addCaseReviewCaseLaterHint =>
      'Waxaad Kiiska Ururinta Daynta u furi kartaa deyntan hadhow, bogga Faahfaahinta Deynta.';

  @override
  String get addCaseReviewOpenDebtButton => 'Fur Deynta';

  @override
  String overviewAgingLegendValue(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dayn · $amount',
      one: '$count Dayn · $amount',
    );
    return '$_temp0';
  }

  @override
  String overviewRiskLegendValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Macmiil',
      one: '$count Macmiil',
    );
    return '$_temp0';
  }

  @override
  String get bulkImportUnsupportedFileTypeError =>
      'Nooca faylka lama aqbalo. Kaliya faylasha .xlsx iyo .xls ayaa la aqbalaa.';

  @override
  String get supportTicketListTitle => 'Tikidhyadayda';

  @override
  String get supportTicketListLoadError => 'Lama soo rari karo tikidhyadaada.';

  @override
  String get supportTicketListEmptyState => 'Wali tikidh ma jiro.';

  @override
  String get supportTicketListEmptyFilteredState =>
      'Ma jiro tikidh la mid ah xaaladan.';

  @override
  String get supportTicketCreateTitle => 'Abuur Tikidh';

  @override
  String get supportTicketCreateValidationError =>
      'Fadlan buuxi mawduuca iyo faahfaahinta.';

  @override
  String get supportTicketSubjectLabel => 'Mawduuca';

  @override
  String get supportTicketSubjectHint => 'Si kooban u sharax dhibaatada';

  @override
  String get supportTicketDescriptionLabel => 'Faahfaahinta';

  @override
  String get supportTicketDescriptionHint =>
      'Bixi faahfaahin intii suurtogal ah';

  @override
  String get supportTicketPriorityLabel => 'Mudnaanta';

  @override
  String get supportTicketCategoryLabel => 'Qaybta';

  @override
  String get supportTicketSubmitButton => 'Dir Tikidhka';

  @override
  String get supportTicketDetailTitle => 'Tikidhka';

  @override
  String get supportTicketDetailLoadError => 'Lama soo rari karo tikidhkan.';

  @override
  String get supportTicketClosedNotice =>
      'Tikidhkan waa xiran yahay — jawaabo cusub lama aqbali doono.';

  @override
  String supportTicketClosedAtLabel(String date) {
    return 'Waxaa la xiray $date';
  }

  @override
  String supportTicketReopenedAtLabel(String date) {
    return 'Dib ayaa loo furay $date';
  }

  @override
  String get supportTicketAttachmentsTitle => 'Lifaaqyada';

  @override
  String get supportTicketAttachmentsLoadError =>
      'Lifaaqyada lama soo rari karo.';

  @override
  String get supportTicketNoAttachments => 'Wax lifaaq ah lama soo shubin.';

  @override
  String get supportTicketUploadButton => 'Lifaaq Fayl';

  @override
  String get supportTicketConversationTitle => 'Wada Xaajoodka';

  @override
  String get supportTicketConversationLoadError =>
      'Wada xaajoodka lama soo rari karo.';

  @override
  String get supportTicketNoRepliesYet => 'Wali jawaab ma jirto.';

  @override
  String get supportTicketReplyHint => 'Qor jawaab';

  @override
  String get supportTicketMessageSenderYou => 'Adiga';

  @override
  String get supportTicketMessageSenderDeendoon => 'Taageerada Deendoon';

  @override
  String get supportTicketPriorityLow => 'Hooseeya';

  @override
  String get supportTicketPriorityMedium => 'Dhexdhexaad';

  @override
  String get supportTicketPriorityHigh => 'Sarreeya';

  @override
  String get supportTicketPriorityUrgent => 'Degdeg ah';

  @override
  String get supportTicketCategoryTechnicalIssue => 'Dhibaato Farsamo';

  @override
  String get supportTicketCategoryPaymentBilling => 'Lacag-bixin / Biil';

  @override
  String get supportTicketCategoryAccount => 'Akoonka';

  @override
  String get supportTicketCategorySubscription => 'Subscription-ka';

  @override
  String get supportTicketCategoryDebtRecovery => 'Deyn & Ururin';

  @override
  String get supportTicketCategoryProfessionalCollection =>
      'Ururinta Xirfadleyda';

  @override
  String get supportTicketCategoryFeatureRequest => 'Codsi Sifayn';

  @override
  String get supportTicketCategoryOther => 'Kale';

  @override
  String get supportTicketContactCardTitle => 'La Xiriir Taageerada Deendoon';

  @override
  String get supportTicketContactPhoneButton => 'Taleefan';

  @override
  String get supportTicketContactWhatsAppButton => 'WhatsApp';

  @override
  String get supportTicketContactEmailButton => 'Iimayl';

  @override
  String get supportTicketContactLaunchError =>
      'Lama furi karo. Fadlan isku day mar kale.';
}
