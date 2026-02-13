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
  /// **'Card'**
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
  /// **'No locks found'**
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

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordDigitRequired.
  ///
  /// In en, this message translates to:
  /// **'Must contain at least one digit'**
  String get passwordDigitRequired;

  /// No description provided for @passwordSymbolRequired.
  ///
  /// In en, this message translates to:
  /// **'Must contain at least one symbol'**
  String get passwordSymbolRequired;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @userAgreement.
  ///
  /// In en, this message translates to:
  /// **'User Agreement'**
  String get userAgreement;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @readAndApprove.
  ///
  /// In en, this message translates to:
  /// **'I have read and approved'**
  String get readAndApprove;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @acceptAndLogin.
  ///
  /// In en, this message translates to:
  /// **'Approve and Login'**
  String get acceptAndLogin;

  /// No description provided for @termsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsDialogTitle;

  /// No description provided for @termsDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please approve the agreements to continue using the application.'**
  String get termsDialogSubtitle;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get emailAlreadyInUse;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get weakPassword;

  /// No description provided for @checkVerificationAndComplete.
  ///
  /// In en, this message translates to:
  /// **'Check Verification and Complete'**
  String get checkVerificationAndComplete;

  /// No description provided for @changeEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Change email address'**
  String get changeEmailAddress;

  /// No description provided for @verificationEmailSentMsg.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent!'**
  String get verificationEmailSentMsg;

  /// No description provided for @verificationEmailInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please check your email and click the link. Then press the button below to continue.'**
  String get verificationEmailInstruction;

  /// No description provided for @ttlockWebPortalRegister.
  ///
  /// In en, this message translates to:
  /// **'Register via TTLock Web Portal'**
  String get ttlockWebPortalRegister;

  /// No description provided for @pleaseAgreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the user agreement and privacy policy.'**
  String get pleaseAgreeToTerms;

  /// No description provided for @infoFilledContinueLogin.
  ///
  /// In en, this message translates to:
  /// **'Information filled, you can now login.'**
  String get infoFilledContinueLogin;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordInstruction.
  ///
  /// In en, this message translates to:
  /// **'For your security, password reset operations are performed via the TTLock web portal or the official mobile application.'**
  String get resetPasswordInstruction;

  /// No description provided for @ttlockWebPortal.
  ///
  /// In en, this message translates to:
  /// **'TTLock Web Portal'**
  String get ttlockWebPortal;

  /// No description provided for @viewOnAppStore.
  ///
  /// In en, this message translates to:
  /// **'View on App Store'**
  String get viewOnAppStore;

  /// No description provided for @viewOnPlayStore.
  ///
  /// In en, this message translates to:
  /// **'View on Play Store'**
  String get viewOnPlayStore;

  /// No description provided for @noAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get noAccountRegister;

  /// No description provided for @addDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Device'**
  String get addDeviceTitle;

  /// No description provided for @categoryLocks.
  ///
  /// In en, this message translates to:
  /// **'Locks'**
  String get categoryLocks;

  /// No description provided for @categoryGateways.
  ///
  /// In en, this message translates to:
  /// **'Gateways'**
  String get categoryGateways;

  /// No description provided for @categoryCameras.
  ///
  /// In en, this message translates to:
  /// **'Cameras'**
  String get categoryCameras;

  /// No description provided for @deviceAllLocks.
  ///
  /// In en, this message translates to:
  /// **'All Locks'**
  String get deviceAllLocks;

  /// No description provided for @deviceDoorLock.
  ///
  /// In en, this message translates to:
  /// **'Door Lock'**
  String get deviceDoorLock;

  /// No description provided for @devicePadlock.
  ///
  /// In en, this message translates to:
  /// **'Padlock'**
  String get devicePadlock;

  /// No description provided for @deviceSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get deviceSafe;

  /// No description provided for @deviceGatewayWifi.
  ///
  /// In en, this message translates to:
  /// **'G2 Wi-Fi'**
  String get deviceGatewayWifi;

  /// No description provided for @deviceGatewayG3.
  ///
  /// In en, this message translates to:
  /// **'G3 Wi-Fi'**
  String get deviceGatewayG3;

  /// No description provided for @deviceCameraSurveillance.
  ///
  /// In en, this message translates to:
  /// **'Surveillance Camera'**
  String get deviceCameraSurveillance;

  /// No description provided for @scanBluetoothLock.
  ///
  /// In en, this message translates to:
  /// **'Scan for Bluetooth Locks'**
  String get scanBluetoothLock;

  /// No description provided for @bluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Please turn on Bluetooth.'**
  String get bluetoothOff;

  /// No description provided for @lockOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Lock is out of range or in sleep mode.'**
  String get lockOutOfRange;

  /// No description provided for @lockConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to lock. Move closer and try again.'**
  String get lockConnectionFailed;

  /// No description provided for @lockBluetoothError.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth error: {errorMessage}'**
  String lockBluetoothError(String errorMessage);

  /// No description provided for @adminManagement.
  ///
  /// In en, this message translates to:
  /// **'Admin Management'**
  String get adminManagement;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @lockUsers.
  ///
  /// In en, this message translates to:
  /// **'Lock Users'**
  String get lockUsers;

  /// No description provided for @lockUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage lock access and block users'**
  String get lockUsersSubtitle;

  /// No description provided for @transferLock.
  ///
  /// In en, this message translates to:
  /// **'Transfer Lock'**
  String get transferLock;

  /// No description provided for @transferLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer to another user'**
  String get transferLockSubtitle;

  /// No description provided for @transferGateway.
  ///
  /// In en, this message translates to:
  /// **'Transfer Gateway'**
  String get transferGateway;

  /// No description provided for @transferGatewaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer gateway ownership to another account'**
  String get transferGatewaySubtitle;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export or backup data'**
  String get exportDataSubtitle;

  /// No description provided for @newGroupComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Creating new group coming soon'**
  String get newGroupComingSoon;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @adminRights.
  ///
  /// In en, this message translates to:
  /// **'Admin Rights'**
  String get adminRights;

  /// No description provided for @createAdmin.
  ///
  /// In en, this message translates to:
  /// **'Create Admin'**
  String get createAdmin;

  /// No description provided for @createAdminComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Create admin feature coming soon'**
  String get createAdminComingSoon;

  /// No description provided for @transferLockComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Lock transfer feature coming soon'**
  String get transferLockComingSoon;

  /// No description provided for @exportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Export feature coming soon'**
  String get exportComingSoon;

  /// No description provided for @unnamedGroup.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Group'**
  String get unnamedGroup;

  /// No description provided for @lockCount.
  ///
  /// In en, this message translates to:
  /// **'Lock Count: {count}'**
  String lockCount(String count);

  /// No description provided for @editingGroup.
  ///
  /// In en, this message translates to:
  /// **'Editing group {groupName}'**
  String editingGroup(String groupName);

  /// No description provided for @preparingRecords.
  ///
  /// In en, this message translates to:
  /// **'Preparing records, please wait...'**
  String get preparingRecords;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Export error: {error}'**
  String exportError(String error);

  /// No description provided for @grantAdminDesc.
  ///
  /// In en, this message translates to:
  /// **'Admin privileges will be granted to the selected lock.'**
  String get grantAdminDesc;

  /// No description provided for @userEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'User (Phone/Email)'**
  String get userEmailOrPhone;

  /// No description provided for @grantAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant Access'**
  String get grantAccess;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @adminGranted.
  ///
  /// In en, this message translates to:
  /// **'Admin privileges granted!'**
  String get adminGranted;

  /// No description provided for @lockRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock Records ({start} - {end})'**
  String lockRecordsTitle(String start, String end);

  /// No description provided for @userAccessManagement.
  ///
  /// In en, this message translates to:
  /// **'User & Access Management'**
  String get userAccessManagement;

  /// No description provided for @appUsers.
  ///
  /// In en, this message translates to:
  /// **'App Users'**
  String get appUsers;

  /// No description provided for @accessKeysFreeze.
  ///
  /// In en, this message translates to:
  /// **'Access Keys (Freeze)'**
  String get accessKeysFreeze;

  /// No description provided for @registerNewUser.
  ///
  /// In en, this message translates to:
  /// **'Register New User'**
  String get registerNewUser;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @searchUser.
  ///
  /// In en, this message translates to:
  /// **'Search user...'**
  String get searchUser;

  /// No description provided for @noSharedKeys.
  ///
  /// In en, this message translates to:
  /// **'No shared keys.'**
  String get noSharedKeys;

  /// No description provided for @key.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get key;

  /// No description provided for @frozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get frozen;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @keyFrozen.
  ///
  /// In en, this message translates to:
  /// **'Key frozen (Access blocked)'**
  String get keyFrozen;

  /// No description provided for @keyUnfrozen.
  ///
  /// In en, this message translates to:
  /// **'Key unfrozen (Access restored)'**
  String get keyUnfrozen;

  /// No description provided for @errorWithMsg.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMsg(String error);

  /// No description provided for @lockRecordsWithName.
  ///
  /// In en, this message translates to:
  /// **'{lockName} Records'**
  String lockRecordsWithName(String lockName);

  /// No description provided for @lockRecords.
  ///
  /// In en, this message translates to:
  /// **'Lock Records'**
  String get lockRecords;

  /// No description provided for @readFromLock.
  ///
  /// In en, this message translates to:
  /// **'Read from Lock (Bluetooth)'**
  String get readFromLock;

  /// No description provided for @clearAllRecords.
  ///
  /// In en, this message translates to:
  /// **'Clear All Records'**
  String get clearAllRecords;

  /// No description provided for @syncRecords.
  ///
  /// In en, this message translates to:
  /// **'Sync Records'**
  String get syncRecords;

  /// No description provided for @connectingReadingLogs.
  ///
  /// In en, this message translates to:
  /// **'Connecting to lock and reading records...'**
  String get connectingReadingLogs;

  /// No description provided for @missingLockData.
  ///
  /// In en, this message translates to:
  /// **'Lock data missing, cannot connect via Bluetooth.'**
  String get missingLockData;

  /// No description provided for @connectFromHomeFirst.
  ///
  /// In en, this message translates to:
  /// **'Please connect to lock from home screen first.'**
  String get connectFromHomeFirst;

  /// No description provided for @recordsSynced.
  ///
  /// In en, this message translates to:
  /// **'Records synchronized successfully'**
  String get recordsSynced;

  /// No description provided for @uploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload error: {error}'**
  String uploadError(String error);

  /// No description provided for @readError.
  ///
  /// In en, this message translates to:
  /// **'Read error: {error}'**
  String readError(String error);

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String unexpectedError(String error);

  /// No description provided for @shareLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Share {lockName} Lock'**
  String shareLockTitle(Object lockName);

  /// No description provided for @emailOrPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'example@email.com or +905551234567'**
  String get emailOrPhoneHint;

  /// No description provided for @emailOrPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Email or phone number required'**
  String get emailOrPhoneRequired;

  /// No description provided for @validEmailOrPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email or phone number'**
  String get validEmailOrPhoneRequired;

  /// No description provided for @permissionLevel.
  ///
  /// In en, this message translates to:
  /// **'Permission Level'**
  String get permissionLevel;

  /// No description provided for @adminPermission.
  ///
  /// In en, this message translates to:
  /// **'Admin - Full access (open, close, settings)'**
  String get adminPermission;

  /// No description provided for @normalUserPermission.
  ///
  /// In en, this message translates to:
  /// **'Normal User - Unlock and lock'**
  String get normalUserPermission;

  /// No description provided for @limitedUserPermission.
  ///
  /// In en, this message translates to:
  /// **'Limited User - View only'**
  String get limitedUserPermission;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not Selected'**
  String get notSelected;

  /// No description provided for @remarksLabel.
  ///
  /// In en, this message translates to:
  /// **'Remarks (Optional)'**
  String get remarksLabel;

  /// No description provided for @remarksHint.
  ///
  /// In en, this message translates to:
  /// **'Notes about the share...'**
  String get remarksHint;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @selectStartEndDate.
  ///
  /// In en, this message translates to:
  /// **'Please select start and end dates'**
  String get selectStartEndDate;

  /// No description provided for @lockSharedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{lockName} lock shared successfully'**
  String lockSharedSuccess(Object lockName);

  /// No description provided for @sharingError.
  ///
  /// In en, this message translates to:
  /// **'Sharing error'**
  String get sharingError;

  /// No description provided for @tabTimed.
  ///
  /// In en, this message translates to:
  /// **'Timed'**
  String get tabTimed;

  /// No description provided for @tabOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get tabOneTime;

  /// No description provided for @tabPermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get tabPermanent;

  /// No description provided for @tabRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get tabRecurring;

  /// No description provided for @enterReceiver.
  ///
  /// In en, this message translates to:
  /// **'Please enter receiver'**
  String get enterReceiver;

  /// No description provided for @keySentToReceiver.
  ///
  /// In en, this message translates to:
  /// **'The key has been sent to the receiver.'**
  String get keySentToReceiver;

  /// No description provided for @sentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Sent Successfully'**
  String get sentSuccessfully;

  /// No description provided for @shareableLink.
  ///
  /// In en, this message translates to:
  /// **'Shareable Link'**
  String get shareableLink;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopied;

  /// No description provided for @sendViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Send via Email'**
  String get sendViaEmail;

  /// No description provided for @sendViaSMS.
  ///
  /// In en, this message translates to:
  /// **'Send via SMS'**
  String get sendViaSMS;

  /// No description provided for @sendAppDownloadLink.
  ///
  /// In en, this message translates to:
  /// **'Send App Download Link'**
  String get sendAppDownloadLink;

  /// No description provided for @receiver.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get receiver;

  /// No description provided for @receiverHint.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone'**
  String get receiverHint;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @enterHere.
  ///
  /// In en, this message translates to:
  /// **'Enter here'**
  String get enterHere;

  /// No description provided for @validityPeriod.
  ///
  /// In en, this message translates to:
  /// **'Validity Period'**
  String get validityPeriod;

  /// No description provided for @configured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get configured;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @allowRemoteUnlock.
  ///
  /// In en, this message translates to:
  /// **'Allow Remote Unlock'**
  String get allowRemoteUnlock;

  /// No description provided for @permanentKeyNote.
  ///
  /// In en, this message translates to:
  /// **'Permanent keys remain valid unless deleted.'**
  String get permanentKeyNote;

  /// No description provided for @timedKeyNote.
  ///
  /// In en, this message translates to:
  /// **'Timed keys are valid only during the specified period.'**
  String get timedKeyNote;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @cycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get cycle;

  /// No description provided for @remoteControls.
  ///
  /// In en, this message translates to:
  /// **'Remote Controls'**
  String get remoteControls;

  /// No description provided for @remoteControl.
  ///
  /// In en, this message translates to:
  /// **'Remote Control'**
  String get remoteControl;

  /// No description provided for @wirelessKeypads.
  ///
  /// In en, this message translates to:
  /// **'Wireless Keypads'**
  String get wirelessKeypads;

  /// No description provided for @wirelessKeypad.
  ///
  /// In en, this message translates to:
  /// **'Wireless Keypad'**
  String get wirelessKeypad;

  /// No description provided for @doorSensor.
  ///
  /// In en, this message translates to:
  /// **'Door Sensor'**
  String get doorSensor;

  /// No description provided for @sensorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Sensor not found'**
  String get sensorNotFound;

  /// No description provided for @qrCodes.
  ///
  /// In en, this message translates to:
  /// **'QR Codes'**
  String get qrCodes;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @qrContent.
  ///
  /// In en, this message translates to:
  /// **'QR Content'**
  String get qrContent;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @qrCodeCreated.
  ///
  /// In en, this message translates to:
  /// **'QR Code created'**
  String get qrCodeCreated;

  /// No description provided for @wifiLockDetails.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Lock Details'**
  String get wifiLockDetails;

  /// No description provided for @isOnline.
  ///
  /// In en, this message translates to:
  /// **'Is Online'**
  String get isOnline;

  /// No description provided for @networkName.
  ///
  /// In en, this message translates to:
  /// **'Network Name'**
  String get networkName;

  /// No description provided for @rssiGrade.
  ///
  /// In en, this message translates to:
  /// **'Signal Strength'**
  String get rssiGrade;

  /// No description provided for @detailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Detail not found'**
  String get detailNotFound;

  /// No description provided for @bluetoothAddInstructions.
  ///
  /// In en, this message translates to:
  /// **'Adding process should be started via Bluetooth.'**
  String get bluetoothAddInstructions;

  /// No description provided for @lockSettings.
  ///
  /// In en, this message translates to:
  /// **'Lock Settings'**
  String get lockSettings;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @lockNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock Name'**
  String get lockNameTitle;

  /// No description provided for @updateBatteryStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Battery Status'**
  String get updateBatteryStatus;

  /// No description provided for @syncWithServer.
  ///
  /// In en, this message translates to:
  /// **'Sync with server'**
  String get syncWithServer;

  /// No description provided for @groupSetting.
  ///
  /// In en, this message translates to:
  /// **'Group Setting'**
  String get groupSetting;

  /// No description provided for @manageGroup.
  ///
  /// In en, this message translates to:
  /// **'Manage Group'**
  String get manageGroup;

  /// No description provided for @wifiSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Settings'**
  String get wifiSettingsTitle;

  /// No description provided for @manageWifiConnection.
  ///
  /// In en, this message translates to:
  /// **'Manage Wi-Fi connection'**
  String get manageWifiConnection;

  /// No description provided for @lockingSettings.
  ///
  /// In en, this message translates to:
  /// **'Locking Settings'**
  String get lockingSettings;

  /// No description provided for @autoLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Lock'**
  String get autoLockTitle;

  /// No description provided for @setTime.
  ///
  /// In en, this message translates to:
  /// **'Set Time'**
  String get setTime;

  /// No description provided for @passageModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Passage Mode'**
  String get passageModeTitle;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @passiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Passive'**
  String get passiveLabel;

  /// No description provided for @workingHours.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get workingHours;

  /// No description provided for @configureWorkingFreezingModes.
  ///
  /// In en, this message translates to:
  /// **'Configure working/freezing modes'**
  String get configureWorkingFreezingModes;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changeAdminPasscodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Admin Passcode'**
  String get changeAdminPasscodeTitle;

  /// No description provided for @updateSuperPasscode.
  ///
  /// In en, this message translates to:
  /// **'Update Super Passcode'**
  String get updateSuperPasscode;

  /// No description provided for @transferLockToUser.
  ///
  /// In en, this message translates to:
  /// **'Transfer to another user'**
  String get transferLockToUser;

  /// No description provided for @deleteLockAction.
  ///
  /// In en, this message translates to:
  /// **'DELETE LOCK'**
  String get deleteLockAction;

  /// No description provided for @renameLock.
  ///
  /// In en, this message translates to:
  /// **'Rename Lock'**
  String get renameLock;

  /// No description provided for @newName.
  ///
  /// In en, this message translates to:
  /// **'New Name'**
  String get newName;

  /// No description provided for @selectGroup.
  ///
  /// In en, this message translates to:
  /// **'Select Group'**
  String get selectGroup;

  /// No description provided for @noGroupsFoundCreateOne.
  ///
  /// In en, this message translates to:
  /// **'No groups found. Create a group first.'**
  String get noGroupsFoundCreateOne;

  /// No description provided for @lockAssignedToGroup.
  ///
  /// In en, this message translates to:
  /// **'Lock assigned to {groupName} group'**
  String lockAssignedToGroup(Object groupName);

  /// No description provided for @removeGroupAssignment.
  ///
  /// In en, this message translates to:
  /// **'Remove Group'**
  String get removeGroupAssignment;

  /// No description provided for @groupAssignmentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Group assignment removed'**
  String get groupAssignmentRemoved;

  /// No description provided for @batterySynced.
  ///
  /// In en, this message translates to:
  /// **'Battery synchronized'**
  String get batterySynced;

  /// No description provided for @autoLockTime.
  ///
  /// In en, this message translates to:
  /// **'Auto Lock Time'**
  String get autoLockTime;

  /// No description provided for @enterTimeInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Enter time in seconds (0 to turn off)'**
  String get enterTimeInSeconds;

  /// No description provided for @secondsShortcut.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get secondsShortcut;

  /// No description provided for @workingMode.
  ///
  /// In en, this message translates to:
  /// **'Working Mode'**
  String get workingMode;

  /// No description provided for @continuouslyWorking.
  ///
  /// In en, this message translates to:
  /// **'Continuously Working (Default)'**
  String get continuouslyWorking;

  /// No description provided for @freezingMode.
  ///
  /// In en, this message translates to:
  /// **'Freezing Mode (Stays Locked)'**
  String get freezingMode;

  /// No description provided for @customHours.
  ///
  /// In en, this message translates to:
  /// **'Custom Hours'**
  String get customHours;

  /// No description provided for @modeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Mode updated'**
  String get modeUpdated;

  /// No description provided for @newPasscodeTitle.
  ///
  /// In en, this message translates to:
  /// **'New Passcode'**
  String get newPasscodeTitle;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @receiverUsernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Receiver Username'**
  String get receiverUsernameTitle;

  /// No description provided for @transferInitiated.
  ///
  /// In en, this message translates to:
  /// **'Transfer initiated'**
  String get transferInitiated;

  /// No description provided for @deleteLockConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Lock?'**
  String get deleteLockConfirmationTitle;

  /// No description provided for @deleteLockConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'CAUTION: This action permanently deletes the lock from the server. It is recommended to perform a hardware reset via the SDK first.'**
  String get deleteLockConfirmationMessage;

  /// No description provided for @checkConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Check Connectivity'**
  String get checkConnectivity;

  /// No description provided for @operationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Operation successful'**
  String get operationSuccessful;

  /// No description provided for @operationFailedWithMsg.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String operationFailedWithMsg(Object error);

  /// No description provided for @bluetoothOffInstructions.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Please turn on Bluetooth.'**
  String get bluetoothOffInstructions;

  /// No description provided for @lockOutOfRangeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Lock is out of range or in sleep mode.'**
  String get lockOutOfRangeInstructions;

  /// No description provided for @lockConnectionFailedInstructions.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to lock. Move closer and try again.'**
  String get lockConnectionFailedInstructions;

  /// No description provided for @remoteUnlockCommandSent.
  ///
  /// In en, this message translates to:
  /// **'🔓 Remote unlock command sent'**
  String get remoteUnlockCommandSent;

  /// No description provided for @remoteControlError.
  ///
  /// In en, this message translates to:
  /// **'Remote control error'**
  String get remoteControlError;

  /// No description provided for @gatewayConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Gateway or Wi-Fi connection could not be established. Please check your Gateway device.'**
  String get gatewayConnectionError;

  /// No description provided for @remoteUnlock.
  ///
  /// In en, this message translates to:
  /// **'Remote Unlock'**
  String get remoteUnlock;

  /// No description provided for @remoteAccess.
  ///
  /// In en, this message translates to:
  /// **'Remote Access'**
  String get remoteAccess;

  /// No description provided for @electronicKeysMenu.
  ///
  /// In en, this message translates to:
  /// **'Electronic\nKeys'**
  String get electronicKeysMenu;

  /// No description provided for @passcodesMenu.
  ///
  /// In en, this message translates to:
  /// **'Passcodes'**
  String get passcodesMenu;

  /// No description provided for @cardsMenu.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get cardsMenu;

  /// No description provided for @fingerprintMenu.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get fingerprintMenu;

  /// No description provided for @facesMenu.
  ///
  /// In en, this message translates to:
  /// **'Faces'**
  String get facesMenu;

  /// No description provided for @remoteControlMenu.
  ///
  /// In en, this message translates to:
  /// **'Remote\nControl'**
  String get remoteControlMenu;

  /// No description provided for @wirelessKeypadMenu.
  ///
  /// In en, this message translates to:
  /// **'Wireless\nKeypad'**
  String get wirelessKeypadMenu;

  /// No description provided for @doorSensorMenu.
  ///
  /// In en, this message translates to:
  /// **'Door\nSensor'**
  String get doorSensorMenu;

  /// No description provided for @qrCodeMenu.
  ///
  /// In en, this message translates to:
  /// **'QR\nCode'**
  String get qrCodeMenu;

  /// No description provided for @recordsMenu.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get recordsMenu;

  /// No description provided for @shareMenu.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareMenu;

  /// No description provided for @settingsMenu.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsMenu;

  /// No description provided for @loadingConfig.
  ///
  /// In en, this message translates to:
  /// **'Loading configuration...'**
  String get loadingConfig;

  /// No description provided for @configLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load configuration: {error}'**
  String configLoadError(Object error);

  /// No description provided for @timeConflict.
  ///
  /// In en, this message translates to:
  /// **'Time Conflict'**
  String get timeConflict;

  /// No description provided for @timeOverlapWarning.
  ///
  /// In en, this message translates to:
  /// **'This time period overlaps with existing ones:'**
  String get timeOverlapWarning;

  /// No description provided for @addStill.
  ///
  /// In en, this message translates to:
  /// **'Do you want to add it anyway?'**
  String get addStill;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesMsg.
  ///
  /// In en, this message translates to:
  /// **'Your changes are not saved. Are you sure you want to exit?'**
  String get unsavedChangesMsg;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @configSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved'**
  String get configSaved;

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// No description provided for @noPlanAdded.
  ///
  /// In en, this message translates to:
  /// **'No plan added yet'**
  String get noPlanAdded;

  /// No description provided for @addTimelineInstruction.
  ///
  /// In en, this message translates to:
  /// **'Tap the + icon above to add a time period'**
  String get addTimelineInstruction;

  /// No description provided for @passageModeInstruction.
  ///
  /// In en, this message translates to:
  /// **'You can set multiple time periods for passage mode. The lock will remain unlocked during these periods.'**
  String get passageModeInstruction;

  /// No description provided for @ttlockAccount.
  ///
  /// In en, this message translates to:
  /// **'TTLock Account'**
  String get ttlockAccount;

  /// No description provided for @ttlockWebSyncMsg.
  ///
  /// In en, this message translates to:
  /// **'This account was created with the TTLock official app. To sync passwords, please update your password using the TTLock Web Portal.'**
  String get ttlockWebSyncMsg;

  /// No description provided for @openPortal.
  ///
  /// In en, this message translates to:
  /// **'Open Portal'**
  String get openPortal;

  /// No description provided for @urlOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open URL: {url}'**
  String urlOpenError(Object url);

  /// No description provided for @timePeriod.
  ///
  /// In en, this message translates to:
  /// **'Time Period'**
  String get timePeriod;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @transferAction.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferAction;

  /// No description provided for @timeSet.
  ///
  /// In en, this message translates to:
  /// **'Time set'**
  String get timeSet;

  /// No description provided for @tokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Token not found'**
  String get tokenNotFound;

  /// No description provided for @adminOnlyLinkWarning.
  ///
  /// In en, this message translates to:
  /// **'Note: Only the Lock Admin can generate unlock links.'**
  String get adminOnlyLinkWarning;

  /// No description provided for @sendKeySuccessNoLink.
  ///
  /// In en, this message translates to:
  /// **'Key sent successfully, but a web link could not be generated due to permission restrictions.\nThe receiver can use the key by downloading the app.'**
  String get sendKeySuccessNoLink;

  /// No description provided for @shareMessageWithLink.
  ///
  /// In en, this message translates to:
  /// **'Hello, I sent you a smart lock access key. You can access it via the link below:\n\n{link}'**
  String shareMessageWithLink(Object link);

  /// No description provided for @shareMessageNoLink.
  ///
  /// In en, this message translates to:
  /// **'Hello, I sent you a smart lock access key. Please download the Yavuz Lock app and log in to use it.'**
  String get shareMessageNoLink;

  /// No description provided for @keyAccessSubject.
  ///
  /// In en, this message translates to:
  /// **'Lock Access Key'**
  String get keyAccessSubject;

  /// No description provided for @emailAppNotFound.
  ///
  /// In en, this message translates to:
  /// **'Email app not found'**
  String get emailAppNotFound;

  /// No description provided for @smsAppNotFound.
  ///
  /// In en, this message translates to:
  /// **'SMS app not found'**
  String get smsAppNotFound;

  /// No description provided for @deleteErrorWithMsg.
  ///
  /// In en, this message translates to:
  /// **'Deletion error: {error}'**
  String deleteErrorWithMsg(Object error);

  /// No description provided for @newQrWithName.
  ///
  /// In en, this message translates to:
  /// **'New QR ({name})'**
  String newQrWithName(Object name);

  /// No description provided for @oneTimeKeyNote.
  ///
  /// In en, this message translates to:
  /// **'One-time keys expire after first use or 1 hour.'**
  String get oneTimeKeyNote;

  /// No description provided for @sendMultipleKeys.
  ///
  /// In en, this message translates to:
  /// **'Send Multiple Keys'**
  String get sendMultipleKeys;

  /// No description provided for @sendMultipleKeysComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Send multiple keys feature coming soon'**
  String get sendMultipleKeysComingSoon;

  /// No description provided for @groupListLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load group list: {error}'**
  String groupListLoadError(Object error);

  /// No description provided for @addNewGroup.
  ///
  /// In en, this message translates to:
  /// **'Add New Group'**
  String get addNewGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @groupAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Group added successfully'**
  String get groupAddedSuccessfully;

  /// No description provided for @groupAddError.
  ///
  /// In en, this message translates to:
  /// **'Failed to add group: {error}'**
  String groupAddError(Object error);

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get editGroup;

  /// No description provided for @newGroupName.
  ///
  /// In en, this message translates to:
  /// **'New Group Name'**
  String get newGroupName;

  /// No description provided for @groupUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group updated'**
  String get groupUpdated;

  /// No description provided for @noGroupsCreatedYet.
  ///
  /// In en, this message translates to:
  /// **'No groups created yet'**
  String get noGroupsCreatedYet;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @deleteGroupConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the group {name}?'**
  String deleteGroupConfirmation(Object name);

  /// No description provided for @groupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Group deleted'**
  String get groupDeleted;

  /// No description provided for @authorizationStatus.
  ///
  /// In en, this message translates to:
  /// **'Authorization Status'**
  String get authorizationStatus;

  /// No description provided for @authorizedAdmin.
  ///
  /// In en, this message translates to:
  /// **'Authorized Administrator (Admin)'**
  String get authorizedAdmin;

  /// No description provided for @normalUser.
  ///
  /// In en, this message translates to:
  /// **'Normal User'**
  String get normalUser;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @unfreeze.
  ///
  /// In en, this message translates to:
  /// **'Unfreeze'**
  String get unfreeze;

  /// No description provided for @freeze.
  ///
  /// In en, this message translates to:
  /// **'Freeze'**
  String get freeze;

  /// No description provided for @revokeAuthority.
  ///
  /// In en, this message translates to:
  /// **'Revoke Authority'**
  String get revokeAuthority;

  /// No description provided for @authorize.
  ///
  /// In en, this message translates to:
  /// **'Authorize'**
  String get authorize;

  /// No description provided for @changePeriod.
  ///
  /// In en, this message translates to:
  /// **'Change Period'**
  String get changePeriod;

  /// No description provided for @unlockLink.
  ///
  /// In en, this message translates to:
  /// **'Unlock Link'**
  String get unlockLink;

  /// No description provided for @unfreezeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Freeze removed'**
  String get unfreezeSuccess;

  /// No description provided for @freezeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Key frozen'**
  String get freezeSuccess;

  /// No description provided for @revokeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Authority revoked'**
  String get revokeSuccess;

  /// No description provided for @authorizeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Authority granted'**
  String get authorizeSuccess;

  /// No description provided for @unlockLinkDescription.
  ///
  /// In en, this message translates to:
  /// **'You can share this link with the user to allow them to open the lock via a browser.'**
  String get unlockLinkDescription;

  /// No description provided for @authorityError.
  ///
  /// In en, this message translates to:
  /// **'Authority Error: Link creation can only be done by the Lock Owner.'**
  String get authorityError;

  /// No description provided for @linkRetrievalError.
  ///
  /// In en, this message translates to:
  /// **'Link retrieval error: {error}'**
  String linkRetrievalError(Object error);

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @dateError.
  ///
  /// In en, this message translates to:
  /// **'End date cannot be before start date'**
  String get dateError;

  /// No description provided for @updateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updateSuccess;

  /// No description provided for @deleteKeyConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this key? This action cannot be undone.'**
  String get deleteKeyConfirmation;

  /// No description provided for @deleteKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Key'**
  String get deleteKeyTitle;

  /// No description provided for @groupManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Management'**
  String get groupManagementTitle;

  /// No description provided for @groupLocksLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load group locks: {error}'**
  String groupLocksLoadError(Object error);

  /// No description provided for @groupLocksTitle.
  ///
  /// In en, this message translates to:
  /// **'{groupName} Locks'**
  String groupLocksTitle(Object groupName);

  /// No description provided for @lock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lock;

  /// No description provided for @lockListRetrievalError.
  ///
  /// In en, this message translates to:
  /// **'Failed to retrieve lock list: {error}'**
  String lockListRetrievalError(Object error);

  /// No description provided for @operationCompletedWithCounts.
  ///
  /// In en, this message translates to:
  /// **'Operation completed. {success} added, {fail} errors.'**
  String operationCompletedWithCounts(Object fail, Object success);

  /// No description provided for @shareGroup.
  ///
  /// In en, this message translates to:
  /// **'Share Group'**
  String get shareGroup;

  /// No description provided for @shareGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Group {groupName}'**
  String shareGroupTitle(Object groupName);

  /// No description provided for @receiverHintUserEmail.
  ///
  /// In en, this message translates to:
  /// **'Receiver Username / Email'**
  String get receiverHintUserEmail;

  /// No description provided for @groupShareNote.
  ///
  /// In en, this message translates to:
  /// **'This operation sends an e-key for all locks in the group.'**
  String get groupShareNote;

  /// No description provided for @locksSharedCounts.
  ///
  /// In en, this message translates to:
  /// **'{success} locks shared, {fail} failed.'**
  String locksSharedCounts(Object fail, Object success);

  /// No description provided for @noLocksInGroup.
  ///
  /// In en, this message translates to:
  /// **'No locks in this group.'**
  String get noLocksInGroup;

  /// No description provided for @groupDetail.
  ///
  /// In en, this message translates to:
  /// **'Group Detail'**
  String get groupDetail;

  /// No description provided for @totalLocksCount.
  ///
  /// In en, this message translates to:
  /// **'Total {count} Locks'**
  String totalLocksCount(Object count);

  /// No description provided for @editGroupLocks.
  ///
  /// In en, this message translates to:
  /// **'Edit Group Locks (Add/Remove)'**
  String get editGroupLocks;

  /// No description provided for @unnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get unnamed;

  /// No description provided for @defaultCountry.
  ///
  /// In en, this message translates to:
  /// **'Turkey'**
  String get defaultCountry;

  /// No description provided for @securityQuestion.
  ///
  /// In en, this message translates to:
  /// **'Security Question'**
  String get securityQuestion;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @securityQuestionSoon.
  ///
  /// In en, this message translates to:
  /// **'Security question setting will be added soon'**
  String get securityQuestionSoon;

  /// No description provided for @countryRegion.
  ///
  /// In en, this message translates to:
  /// **'Country/Region'**
  String get countryRegion;

  /// No description provided for @userTerms.
  ///
  /// In en, this message translates to:
  /// **'User Terms'**
  String get userTerms;

  /// No description provided for @editField.
  ///
  /// In en, this message translates to:
  /// **'Edit {field}'**
  String editField(Object field);

  /// No description provided for @enterNewField.
  ///
  /// In en, this message translates to:
  /// **'Enter new {field}'**
  String enterNewField(Object field);

  /// No description provided for @fieldUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{field} updated successfully'**
  String fieldUpdatedSuccess(Object field);

  /// No description provided for @passwordResetInstruction.
  ///
  /// In en, this message translates to:
  /// **'Use the \'Forgot Password\' feature on the login page to change your password.'**
  String get passwordResetInstruction;

  /// No description provided for @avatarSoon.
  ///
  /// In en, this message translates to:
  /// **'Avatar change feature will be added soon'**
  String get avatarSoon;

  /// No description provided for @customerService.
  ///
  /// In en, this message translates to:
  /// **'Customer Service'**
  String get customerService;

  /// No description provided for @support247.
  ///
  /// In en, this message translates to:
  /// **'24/7 Support'**
  String get support247;

  /// No description provided for @contactUsOnIssues.
  ///
  /// In en, this message translates to:
  /// **'Contact us whenever you experience any issues'**
  String get contactUsOnIssues;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @salesCooperation.
  ///
  /// In en, this message translates to:
  /// **'Sales and Cooperation'**
  String get salesCooperation;

  /// No description provided for @officialWebsite.
  ///
  /// In en, this message translates to:
  /// **'Official Website'**
  String get officialWebsite;

  /// No description provided for @webAdminSystem.
  ///
  /// In en, this message translates to:
  /// **'Web Management System'**
  String get webAdminSystem;

  /// No description provided for @hotelAdminSystem.
  ///
  /// In en, this message translates to:
  /// **'Hotel Management System'**
  String get hotelAdminSystem;

  /// No description provided for @apartmentSystem.
  ///
  /// In en, this message translates to:
  /// **'Apartment System'**
  String get apartmentSystem;

  /// No description provided for @userManual.
  ///
  /// In en, this message translates to:
  /// **'User Manual'**
  String get userManual;

  /// No description provided for @liveSupport.
  ///
  /// In en, this message translates to:
  /// **'Live Support'**
  String get liveSupport;

  /// No description provided for @copiedToClipboardMsg.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard: {text}'**
  String copiedToClipboardMsg(Object text);

  /// No description provided for @customerServiceDescription.
  ///
  /// In en, this message translates to:
  /// **'You can contact us for any technical issues, feature requests, or general questions. We will try to help you as quickly as possible.'**
  String get customerServiceDescription;

  /// No description provided for @liveChatSoon.
  ///
  /// In en, this message translates to:
  /// **'Live support chat will be active soon. For now, you can reach us via email.'**
  String get liveChatSoon;

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Email'**
  String get sendEmail;

  /// No description provided for @createPasscodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Passcode'**
  String get createPasscodeTitle;

  /// No description provided for @passcodeHint.
  ///
  /// In en, this message translates to:
  /// **'Passcode (4-9 digits)'**
  String get passcodeHint;

  /// No description provided for @enterPasscode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a passcode'**
  String get enterPasscode;

  /// No description provided for @passcodeLengthError.
  ///
  /// In en, this message translates to:
  /// **'Passcode must be between 4 and 9 digits'**
  String get passcodeLengthError;

  /// No description provided for @validityStart.
  ///
  /// In en, this message translates to:
  /// **'Validity Start'**
  String get validityStart;

  /// No description provided for @validityEnd.
  ///
  /// In en, this message translates to:
  /// **'Validity End'**
  String get validityEnd;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @passive.
  ///
  /// In en, this message translates to:
  /// **'Passive'**
  String get passive;

  /// No description provided for @gatewayRequired.
  ///
  /// In en, this message translates to:
  /// **'Gateway required'**
  String get gatewayRequired;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noEKeysFound.
  ///
  /// In en, this message translates to:
  /// **'No electronic keys found'**
  String get noEKeysFound;

  /// No description provided for @keyFor.
  ///
  /// In en, this message translates to:
  /// **'Key for {username}'**
  String keyFor(String username);

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @updateErrorWithMsg.
  ///
  /// In en, this message translates to:
  /// **'Update error: {error}'**
  String updateErrorWithMsg(Object error);

  /// No description provided for @scanGatewayTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Gateway'**
  String get scanGatewayTitle;

  /// No description provided for @scanLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Lock'**
  String get scanLockTitle;

  /// No description provided for @stopScan.
  ///
  /// In en, this message translates to:
  /// **'Stop Scan'**
  String get stopScan;

  /// No description provided for @reScan.
  ///
  /// In en, this message translates to:
  /// **'Re-Scan'**
  String get reScan;

  /// No description provided for @deviceAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Device successfully added'**
  String get deviceAddedSuccess;

  /// No description provided for @scanningGatewayStatus.
  ///
  /// In en, this message translates to:
  /// **'Connecting to gateway...'**
  String get scanningGatewayStatus;

  /// No description provided for @scanningLockStatus.
  ///
  /// In en, this message translates to:
  /// **'Please stay close to the lock...'**
  String get scanningLockStatus;

  /// No description provided for @scanningGateways.
  ///
  /// In en, this message translates to:
  /// **'Scanning for gateways...'**
  String get scanningGateways;

  /// No description provided for @scanningLocks.
  ///
  /// In en, this message translates to:
  /// **'Scanning for locks...'**
  String get scanningLocks;

  /// No description provided for @ensureBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Please ensure Bluetooth is on'**
  String get ensureBluetooth;

  /// No description provided for @gatewayNotFound.
  ///
  /// In en, this message translates to:
  /// **'Gateway not found'**
  String get gatewayNotFound;

  /// No description provided for @lockNotFound.
  ///
  /// In en, this message translates to:
  /// **'Lock not found'**
  String get lockNotFound;

  /// No description provided for @scanNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Scanned surrounding devices but nothing found.'**
  String get scanNotFoundMessage;

  /// No description provided for @gatewaySetupNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Gateway setup not added yet'**
  String get gatewaySetupNotAdded;

  /// No description provided for @foundDevices.
  ///
  /// In en, this message translates to:
  /// **'{count} devices found'**
  String foundDevices(int count);

  /// No description provided for @connectingTo.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {name}...'**
  String connectingTo(String name);

  /// No description provided for @unnamedLock.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Lock'**
  String get unnamedLock;

  /// No description provided for @unknownGateway.
  ///
  /// In en, this message translates to:
  /// **'Unknown Gateway'**
  String get unknownGateway;

  /// No description provided for @gatewayDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Gateway Detail'**
  String get gatewayDetailTitle;

  /// No description provided for @gatewayName.
  ///
  /// In en, this message translates to:
  /// **'Gateway Name'**
  String get gatewayName;

  /// No description provided for @gatewayMac.
  ///
  /// In en, this message translates to:
  /// **'Gateway MAC'**
  String get gatewayMac;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @lockCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Lock Count'**
  String get lockCountLabel;

  /// No description provided for @renameGateway.
  ///
  /// In en, this message translates to:
  /// **'Rename Gateway'**
  String get renameGateway;

  /// No description provided for @deleteGatewayAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Gateway'**
  String get deleteGatewayAction;

  /// No description provided for @transferGatewayAction.
  ///
  /// In en, this message translates to:
  /// **'Transfer Gateway'**
  String get transferGatewayAction;

  /// No description provided for @checkUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Check for Upgrade'**
  String get checkUpgrade;

  /// No description provided for @setUpgradeMode.
  ///
  /// In en, this message translates to:
  /// **'Set to Upgrade Mode'**
  String get setUpgradeMode;

  /// No description provided for @viewLocks.
  ///
  /// In en, this message translates to:
  /// **'View Locks'**
  String get viewLocks;

  /// No description provided for @enterNewGatewayName.
  ///
  /// In en, this message translates to:
  /// **'Enter new gateway name'**
  String get enterNewGatewayName;

  /// No description provided for @deleteGatewayConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this gateway?'**
  String get deleteGatewayConfirmation;

  /// No description provided for @enterReceiverUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter receiver\'s username'**
  String get enterReceiverUsername;

  /// No description provided for @gatewayRenamedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Gateway renamed successfully'**
  String get gatewayRenamedSuccess;

  /// No description provided for @gatewayDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Gateway deleted successfully'**
  String get gatewayDeletedSuccess;

  /// No description provided for @gatewayTransferredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Gateway transferred successfully'**
  String get gatewayTransferredSuccess;

  /// No description provided for @errorRenamingGateway.
  ///
  /// In en, this message translates to:
  /// **'Error renaming gateway: {error}'**
  String errorRenamingGateway(Object error);

  /// No description provided for @errorDeletingGateway.
  ///
  /// In en, this message translates to:
  /// **'Error deleting gateway: {error}'**
  String errorDeletingGateway(Object error);

  /// No description provided for @errorTransferringGateway.
  ///
  /// In en, this message translates to:
  /// **'Error transferring gateway: {error}'**
  String errorTransferringGateway(Object error);

  /// No description provided for @errorCheckingUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Error checking for upgrade: {error}'**
  String errorCheckingUpgrade(Object error);

  /// No description provided for @errorSettingUpgradeMode.
  ///
  /// In en, this message translates to:
  /// **'Error setting upgrade mode: {error}'**
  String errorSettingUpgradeMode(Object error);

  /// No description provided for @upgradeCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Check'**
  String get upgradeCheckTitle;

  /// No description provided for @needUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Need Upgrade'**
  String get needUpgrade;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @gatewaySetToUpgradeMode.
  ///
  /// In en, this message translates to:
  /// **'Gateway is set to upgrade mode'**
  String get gatewaySetToUpgradeMode;

  /// No description provided for @noGatewaysFound.
  ///
  /// In en, this message translates to:
  /// **'No gateways found.'**
  String get noGatewaysFound;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get roleNormal;

  /// No description provided for @roleObserver.
  ///
  /// In en, this message translates to:
  /// **'Observer'**
  String get roleObserver;

  /// No description provided for @accessTokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Access token not found'**
  String get accessTokenNotFound;

  /// No description provided for @lockIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Lock ID not found.'**
  String get lockIdNotFound;

  /// No description provided for @invalidLockIdFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid Lock ID format.'**
  String get invalidLockIdFormat;

  /// No description provided for @loginToSeePasscodes.
  ///
  /// In en, this message translates to:
  /// **'Please login to see passcodes.'**
  String get loginToSeePasscodes;

  /// No description provided for @noAccessPermission.
  ///
  /// In en, this message translates to:
  /// **'No access permission'**
  String get noAccessPermission;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String daysLeft(int days);

  /// No description provided for @hoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String hoursLeft(int hours);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @admins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get admins;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @validityType.
  ///
  /// In en, this message translates to:
  /// **'Validity Type'**
  String get validityType;

  /// No description provided for @scanCard.
  ///
  /// In en, this message translates to:
  /// **'Scan Card'**
  String get scanCard;

  /// No description provided for @connectAndScan.
  ///
  /// In en, this message translates to:
  /// **'Connect to lock and scan card'**
  String get connectAndScan;

  /// No description provided for @cardNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Card name is required'**
  String get cardNameRequired;

  /// No description provided for @bluetoothRequired.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth connection required'**
  String get bluetoothRequired;

  /// No description provided for @selectDays.
  ///
  /// In en, this message translates to:
  /// **'Select Days'**
  String get selectDays;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @weekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get weekend;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @workday.
  ///
  /// In en, this message translates to:
  /// **'Workday'**
  String get workday;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @scanLockDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan for Yavuz Lock locks via Bluetooth and add them to your app.'**
  String get scanLockDescription;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;
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
