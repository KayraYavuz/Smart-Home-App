import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('de'),
    Locale('en'),
    Locale('tr')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Yavuz Lock'**
  String get appTitle;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Option to change the app language
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// Button to unlock the door
  ///
  /// In en, this message translates to:
  /// **'Unlock Door'**
  String get unlockDoor;

  /// Button to lock the door
  ///
  /// In en, this message translates to:
  /// **'Lock Door'**
  String get lockDoor;

  /// Home navigation item
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Devices section
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// My locks section title
  ///
  /// In en, this message translates to:
  /// **'My Locks'**
  String get myLocks;

  /// Add device button
  ///
  /// In en, this message translates to:
  /// **'Add Device'**
  String get addDevice;

  /// Profile section
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// German language option
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// Turkish language option
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// Dialog title for language selection
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @soundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn app sounds on/off'**
  String get soundSubtitle;

  /// No description provided for @touchToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Touch to Unlock'**
  String get touchToUnlock;

  /// No description provided for @touchToUnlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable touch to unlock feature'**
  String get touchToUnlockSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications for lock events'**
  String get notificationsSubtitle;

  /// No description provided for @personalizedSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Personalized Suggestions'**
  String get personalizedSuggestions;

  /// No description provided for @personalizedSuggestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show suggestions based on your usage'**
  String get personalizedSuggestionsSubtitle;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @screenLock.
  ///
  /// In en, this message translates to:
  /// **'Screen Lock'**
  String get screenLock;

  /// No description provided for @hideInvalidAccess.
  ///
  /// In en, this message translates to:
  /// **'Hide Invalid Access'**
  String get hideInvalidAccess;

  /// No description provided for @deviceManagement.
  ///
  /// In en, this message translates to:
  /// **'Device Management'**
  String get deviceManagement;

  /// No description provided for @gatewayManagement.
  ///
  /// In en, this message translates to:
  /// **'Gateway Management'**
  String get gatewayManagement;

  /// No description provided for @gatewayManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage and connect your Yavuz Lock Gateways'**
  String get gatewayManagementSubtitle;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get deleteAccountConfirmation;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @loggedOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Logged out'**
  String get loggedOutMessage;

  /// No description provided for @accountDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeletedMessage;

  /// No description provided for @screenLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Screen Lock'**
  String get screenLockTitle;

  /// No description provided for @hideInvalidAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide Invalid Access'**
  String get hideInvalidAccessTitle;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @seconds30.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get seconds30;

  /// No description provided for @minute1.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get minute1;

  /// No description provided for @minutes5.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get minutes5;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Info'**
  String get accountInfo;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @allRecords.
  ///
  /// In en, this message translates to:
  /// **'All Records'**
  String get allRecords;

  /// No description provided for @voiceAssistant.
  ///
  /// In en, this message translates to:
  /// **'Voice Assistant'**
  String get voiceAssistant;

  /// No description provided for @systemManagement.
  ///
  /// In en, this message translates to:
  /// **'System Management'**
  String get systemManagement;

  /// No description provided for @groupManagement.
  ///
  /// In en, this message translates to:
  /// **'Group Management'**
  String get groupManagement;

  /// No description provided for @workTogether.
  ///
  /// In en, this message translates to:
  /// **'Work Together'**
  String get workTogether;

  /// No description provided for @voiceAssistantComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Voice assistant coming soon'**
  String get voiceAssistantComingSoon;

  /// No description provided for @workTogetherTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Together'**
  String get workTogetherTitle;

  /// No description provided for @queryLock.
  ///
  /// In en, this message translates to:
  /// **'Query Lock'**
  String get queryLock;

  /// No description provided for @queryLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Query the addition time of a lock'**
  String get queryLockDesc;

  /// No description provided for @utilityMeter.
  ///
  /// In en, this message translates to:
  /// **'Utility Meter'**
  String get utilityMeter;

  /// No description provided for @utilityMeterDesc.
  ///
  /// In en, this message translates to:
  /// **'Using utility meters makes apartment management easier.'**
  String get utilityMeterDesc;

  /// No description provided for @cardEncoder.
  ///
  /// In en, this message translates to:
  /// **'Card Encoder'**
  String get cardEncoder;

  /// No description provided for @cardEncoderDesc.
  ///
  /// In en, this message translates to:
  /// **'Issue cards with card encoder without gateway'**
  String get cardEncoderDesc;

  /// No description provided for @hotelPMS.
  ///
  /// In en, this message translates to:
  /// **'Hotel PMS'**
  String get hotelPMS;

  /// No description provided for @hotelPMSDesc.
  ///
  /// In en, this message translates to:
  /// **'Hotel management system'**
  String get hotelPMSDesc;

  /// No description provided for @thirdPartyDevice.
  ///
  /// In en, this message translates to:
  /// **'Third Party Device'**
  String get thirdPartyDevice;

  /// No description provided for @thirdPartyDeviceDesc.
  ///
  /// In en, this message translates to:
  /// **'Open door with third party devices'**
  String get thirdPartyDeviceDesc;

  /// No description provided for @ttRenting.
  ///
  /// In en, this message translates to:
  /// **'TTRenting'**
  String get ttRenting;

  /// No description provided for @ttRentingDesc.
  ///
  /// In en, this message translates to:
  /// **'Long-term Rental Management System'**
  String get ttRentingDesc;

  /// No description provided for @openPlatform.
  ///
  /// In en, this message translates to:
  /// **'Open Platform'**
  String get openPlatform;

  /// No description provided for @openPlatformDesc.
  ///
  /// In en, this message translates to:
  /// **'APP SDK, Cloud API, DLL'**
  String get openPlatformDesc;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Feature coming soon'**
  String get featureComingSoon;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editName;

  /// No description provided for @enterNewName.
  ///
  /// In en, this message translates to:
  /// **'Enter new name'**
  String get enterNewName;

  /// No description provided for @selectLock.
  ///
  /// In en, this message translates to:
  /// **'Select Lock'**
  String get selectLock;

  /// No description provided for @lockId.
  ///
  /// In en, this message translates to:
  /// **'Lock ID'**
  String get lockId;

  /// No description provided for @macAddress.
  ///
  /// In en, this message translates to:
  /// **'MAC Address'**
  String get macAddress;

  /// No description provided for @lockTime.
  ///
  /// In en, this message translates to:
  /// **'Lock Time'**
  String get lockTime;

  /// No description provided for @batteryLevel.
  ///
  /// In en, this message translates to:
  /// **'Battery Level'**
  String get batteryLevel;

  /// No description provided for @noMetersFound.
  ///
  /// In en, this message translates to:
  /// **'No meters found.'**
  String get noMetersFound;

  /// No description provided for @lastReading.
  ///
  /// In en, this message translates to:
  /// **'Last Reading'**
  String get lastReading;

  /// No description provided for @addMeter.
  ///
  /// In en, this message translates to:
  /// **'Add Meter'**
  String get addMeter;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @encoderConnected.
  ///
  /// In en, this message translates to:
  /// **'Card Encoder Connected'**
  String get encoderConnected;

  /// No description provided for @encoderNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Card Encoder Not Connected'**
  String get encoderNotConnected;

  /// No description provided for @connectEncoder.
  ///
  /// In en, this message translates to:
  /// **'Connect Encoder'**
  String get connectEncoder;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// No description provided for @issueCard.
  ///
  /// In en, this message translates to:
  /// **'Issue Card'**
  String get issueCard;

  /// No description provided for @readCard.
  ///
  /// In en, this message translates to:
  /// **'Read Card'**
  String get readCard;

  /// No description provided for @clearCard.
  ///
  /// In en, this message translates to:
  /// **'Clear Card'**
  String get clearCard;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @occupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get occupied;

  /// No description provided for @vacant.
  ///
  /// In en, this message translates to:
  /// **'Vacant'**
  String get vacant;

  /// No description provided for @cleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get cleaning;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get checkOut;

  /// No description provided for @checkInConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to check-in this room?'**
  String get checkInConfirm;

  /// No description provided for @checkOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to check-out this room?'**
  String get checkOutConfirm;

  /// No description provided for @roomCleaning.
  ///
  /// In en, this message translates to:
  /// **'Room Cleaning'**
  String get roomCleaning;

  /// No description provided for @finishCleaningConfirm.
  ///
  /// In en, this message translates to:
  /// **'Mark room as clean?'**
  String get finishCleaningConfirm;

  /// No description provided for @checkInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Check-in successful'**
  String get checkInSuccess;

  /// No description provided for @checkOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Check-out successful'**
  String get checkOutSuccess;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found.'**
  String get noDevicesFound;

  /// No description provided for @turnedOn.
  ///
  /// In en, this message translates to:
  /// **'turned on'**
  String get turnedOn;

  /// No description provided for @turnedOff.
  ///
  /// In en, this message translates to:
  /// **'turned off'**
  String get turnedOff;

  /// No description provided for @noPropertiesFound.
  ///
  /// In en, this message translates to:
  /// **'No properties found.'**
  String get noPropertiesFound;

  /// No description provided for @rented.
  ///
  /// In en, this message translates to:
  /// **'Rented'**
  String get rented;

  /// No description provided for @tenant.
  ///
  /// In en, this message translates to:
  /// **'Tenant'**
  String get tenant;

  /// No description provided for @rentDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get rentDueDate;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @sendKey.
  ///
  /// In en, this message translates to:
  /// **'Send Key'**
  String get sendKey;

  /// No description provided for @remind.
  ///
  /// In en, this message translates to:
  /// **'Remind'**
  String get remind;

  /// No description provided for @readyForRent.
  ///
  /// In en, this message translates to:
  /// **'Ready for rent'**
  String get readyForRent;

  /// No description provided for @keySent.
  ///
  /// In en, this message translates to:
  /// **'Digital key sent'**
  String get keySent;

  /// No description provided for @reminderSent.
  ///
  /// In en, this message translates to:
  /// **'Payment reminder sent'**
  String get reminderSent;

  /// No description provided for @addProperty.
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get addProperty;

  /// No description provided for @appSdkDesc.
  ///
  /// In en, this message translates to:
  /// **'Integrate lock management directly into your own mobile application.'**
  String get appSdkDesc;

  /// No description provided for @cloudApiDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect your server to Yavuz Lock cloud for centralized management.'**
  String get cloudApiDesc;

  /// No description provided for @desktopSdkDesc.
  ///
  /// In en, this message translates to:
  /// **'Desktop solutions and hardware integrations via DLL/SDK.'**
  String get desktopSdkDesc;

  /// No description provided for @developerPortalInfo.
  ///
  /// In en, this message translates to:
  /// **'For more technical information and credentials, visit the Developer Portal.'**
  String get developerPortalInfo;

  /// No description provided for @visitPortal.
  ///
  /// In en, this message translates to:
  /// **'Visit Developer Portal'**
  String get visitPortal;

  /// No description provided for @viewDocumentation.
  ///
  /// In en, this message translates to:
  /// **'View Documentation'**
  String get viewDocumentation;

  /// No description provided for @noLocksFound.
  ///
  /// In en, this message translates to:
  /// **'No locks found from API.'**
  String get noLocksFound;

  /// No description provided for @allLocks.
  ///
  /// In en, this message translates to:
  /// **'Yavuz Lock'**
  String get allLocks;

  /// No description provided for @refreshLocks.
  ///
  /// In en, this message translates to:
  /// **'Refresh Locks'**
  String get refreshLocks;

  /// No description provided for @gateways.
  ///
  /// In en, this message translates to:
  /// **'Gateways'**
  String get gateways;

  /// No description provided for @securityWarning.
  ///
  /// In en, this message translates to:
  /// **'Security Warning'**
  String get securityWarning;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @sharedLock.
  ///
  /// In en, this message translates to:
  /// **'Shared Lock'**
  String get sharedLock;

  /// No description provided for @sharedWithYou.
  ///
  /// In en, this message translates to:
  /// **'shared with you.'**
  String get sharedWithYou;

  /// No description provided for @whatDoYouWantToDo.
  ///
  /// In en, this message translates to:
  /// **'What do you want to do?'**
  String get whatDoYouWantToDo;

  /// No description provided for @cancelShare.
  ///
  /// In en, this message translates to:
  /// **'Cancel Share'**
  String get cancelShare;

  /// No description provided for @shareCancelled.
  ///
  /// In en, this message translates to:
  /// **'Share cancelled'**
  String get shareCancelled;

  /// No description provided for @deleteDevice.
  ///
  /// In en, this message translates to:
  /// **'Delete Device'**
  String get deleteDevice;

  /// No description provided for @deleteDeviceConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this device from the app?'**
  String get deleteDeviceConfirmation;

  /// No description provided for @deleteDeviceDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This action only removes it from this app, the device is not physically affected.'**
  String get deleteDeviceDisclaimer;

  /// No description provided for @deviceRemoved.
  ///
  /// In en, this message translates to:
  /// **'device removed'**
  String get deviceRemoved;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone'**
  String get emailOrPhone;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @codeSent.
  ///
  /// In en, this message translates to:
  /// **'Code Sent'**
  String get codeSent;

  /// No description provided for @verifyCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verifyCodeLabel;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @resetPasswordBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordBtn;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully!'**
  String get passwordResetSuccess;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username required'**
  String get usernameRequired;

  /// No description provided for @codeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get codeRequired;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @registerBtn.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerBtn;

  /// No description provided for @registrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful!'**
  String get registrationSuccess;

  /// No description provided for @registrationSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created successfully.'**
  String get registrationSuccessMsg;

  /// No description provided for @loginIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Login ID:'**
  String get loginIdLabel;

  /// No description provided for @loginIdNote.
  ///
  /// In en, this message translates to:
  /// **'Please note this ID. You must use this to login.'**
  String get loginIdNote;

  /// No description provided for @loginBtn.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginBtn;

  /// No description provided for @enterCodePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter Code'**
  String get enterCodePlaceholder;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @statusLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get statusLocked;

  /// No description provided for @statusUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get statusUnlocked;

  /// No description provided for @statusSecurityWarning.
  ///
  /// In en, this message translates to:
  /// **'Security Warning'**
  String get statusSecurityWarning;

  /// No description provided for @lockOpened.
  ///
  /// In en, this message translates to:
  /// **'{lockName} opened'**
  String lockOpened(String lockName);

  /// No description provided for @lockClosed.
  ///
  /// In en, this message translates to:
  /// **'{lockName} locked'**
  String lockClosed(String lockName);

  /// No description provided for @lockOpenedApp.
  ///
  /// In en, this message translates to:
  /// **'{lockName} opened from app'**
  String lockOpenedApp(String lockName);

  /// No description provided for @lockOpenedKeypad.
  ///
  /// In en, this message translates to:
  /// **'{lockName} opened with keypad'**
  String lockOpenedKeypad(String lockName);

  /// No description provided for @lockOpenedFingerprint.
  ///
  /// In en, this message translates to:
  /// **'{lockName} opened with fingerprint'**
  String lockOpenedFingerprint(String lockName);

  /// No description provided for @lockOpenedCard.
  ///
  /// In en, this message translates to:
  /// **'{lockName} opened with card'**
  String lockOpenedCard(String lockName);

  /// No description provided for @lowBatteryWarning.
  ///
  /// In en, this message translates to:
  /// **'{lockName} low battery'**
  String lowBatteryWarning(String lockName);

  /// No description provided for @lockTamperedWarning.
  ///
  /// In en, this message translates to:
  /// **'{lockName} security warning!'**
  String lockTamperedWarning(String lockName);

  /// No description provided for @lockStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'{lockName} status updated'**
  String lockStatusUpdated(String lockName);

  /// No description provided for @unknownLock.
  ///
  /// In en, this message translates to:
  /// **'Unknown Lock'**
  String get unknownLock;

  /// No description provided for @defaultLockName.
  ///
  /// In en, this message translates to:
  /// **'Yavuz Lock'**
  String get defaultLockName;

  /// No description provided for @defaultSharedLockName.
  ///
  /// In en, this message translates to:
  /// **'Shared Yavuz Lock'**
  String get defaultSharedLockName;

  /// No description provided for @seamLockDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Seam Lock'**
  String get seamLockDefaultName;

  /// No description provided for @seamDevicesAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} Seam devices added'**
  String seamDevicesAdded(int count);

  /// No description provided for @lockAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Yavuz Lock successfully added'**
  String get lockAddedSuccess;

  /// No description provided for @deviceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type: {type}'**
  String deviceTypeLabel(String type);

  /// No description provided for @shareCancelError.
  ///
  /// In en, this message translates to:
  /// **'Share cancellation error: {error}'**
  String shareCancelError(String error);

  /// No description provided for @errorDevicesLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading devices'**
  String get errorDevicesLoading;

  /// No description provided for @errorInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection'**
  String get errorInternetConnection;

  /// No description provided for @errorServerTimeout.
  ///
  /// In en, this message translates to:
  /// **'Server timeout, please try again'**
  String get errorServerTimeout;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get verificationEmailSent;

  /// No description provided for @checkInbox.
  ///
  /// In en, this message translates to:
  /// **'Please check your inbox'**
  String get checkInbox;

  /// No description provided for @checkVerification.
  ///
  /// In en, this message translates to:
  /// **'Check Verification'**
  String get checkVerification;

  /// No description provided for @verificationSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Verified'**
  String get verificationSuccessTitle;

  /// No description provided for @verificationSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get verificationSuccessMsg;

  /// No description provided for @emailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email not verified yet'**
  String get emailNotVerified;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmail;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login Successful'**
  String get loginSuccess;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get loginFailed;

  /// No description provided for @passwordSyncError.
  ///
  /// In en, this message translates to:
  /// **'Password synchronization error'**
  String get passwordSyncError;

  /// No description provided for @accountInfoPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get accountInfoPhone;

  /// No description provided for @accountInfoEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountInfoEmail;

  /// No description provided for @accountInfoUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get accountInfoUsername;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get saveSuccess;

  /// No description provided for @sentLink.
  ///
  /// In en, this message translates to:
  /// **'Link Sent'**
  String get sentLink;

  /// No description provided for @checkInboxForLink.
  ///
  /// In en, this message translates to:
  /// **'Please check your email and click the link.'**
  String get checkInboxForLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;
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
      <String>['de', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
