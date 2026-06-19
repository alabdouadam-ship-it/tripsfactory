import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
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
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TripShip'**
  String get appTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @pleaseSelectAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please select all required fields'**
  String get pleaseSelectAllFields;

  /// No description provided for @pleaseSelectDateFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select trip date first'**
  String get pleaseSelectDateFirst;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinRevolution.
  ///
  /// In en, this message translates to:
  /// **'Join the logistics revolution'**
  String get joinRevolution;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @enterEmailToReset.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset link.'**
  String get enterEmailToReset;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @linkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent'**
  String get linkSent;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidCredentials;

  /// No description provided for @emailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email before logging in'**
  String get emailNotConfirmed;

  /// No description provided for @userAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please sign in.'**
  String get userAlreadyRegistered;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterName;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error occurred'**
  String get unexpectedError;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeDesert.
  ///
  /// In en, this message translates to:
  /// **'Desert'**
  String get themeDesert;

  /// No description provided for @themeMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get themeMidnight;

  /// No description provided for @themeOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get themeOcean;

  /// No description provided for @themeSteel.
  ///
  /// In en, this message translates to:
  /// **'Steel'**
  String get themeSteel;

  /// No description provided for @themeOasis.
  ///
  /// In en, this message translates to:
  /// **'Oasis'**
  String get themeOasis;

  /// No description provided for @themeSkyline.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get themeSkyline;

  /// No description provided for @themeLimestone.
  ///
  /// In en, this message translates to:
  /// **'Stone'**
  String get themeLimestone;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio / Description'**
  String get bio;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @individual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get individual;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get verificationStatus;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @unverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get unverified;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @postTrip.
  ///
  /// In en, this message translates to:
  /// **'Post a Trip'**
  String get postTrip;

  /// No description provided for @origin.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get origin;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get destination;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @availableWeight.
  ///
  /// In en, this message translates to:
  /// **'Available Weight'**
  String get availableWeight;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @pricePerKg.
  ///
  /// In en, this message translates to:
  /// **'Price per kg'**
  String get pricePerKg;

  /// No description provided for @flatPrice.
  ///
  /// In en, this message translates to:
  /// **'Flat Price'**
  String get flatPrice;

  /// No description provided for @createTrip.
  ///
  /// In en, this message translates to:
  /// **'Create Trip'**
  String get createTrip;

  /// No description provided for @copyTrip.
  ///
  /// In en, this message translates to:
  /// **'Copy Trip'**
  String get copyTrip;

  /// No description provided for @shareTrip.
  ///
  /// In en, this message translates to:
  /// **'Share Trip'**
  String get shareTrip;

  /// No description provided for @tripPosted.
  ///
  /// In en, this message translates to:
  /// **'Trip posted successfully'**
  String get tripPosted;

  /// No description provided for @pleaseSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get pleaseSelectDate;

  /// No description provided for @pleaseSelectTime.
  ///
  /// In en, this message translates to:
  /// **'Please select a time'**
  String get pleaseSelectTime;

  /// No description provided for @enterCity.
  ///
  /// In en, this message translates to:
  /// **'Enter city name'**
  String get enterCity;

  /// No description provided for @invalidWeight.
  ///
  /// In en, this message translates to:
  /// **'Invalid weight'**
  String get invalidWeight;

  /// No description provided for @postShipment.
  ///
  /// In en, this message translates to:
  /// **'Send a Package'**
  String get postShipment;

  /// No description provided for @editShipment.
  ///
  /// In en, this message translates to:
  /// **'Edit Shipment'**
  String get editShipment;

  /// No description provided for @shipmentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Shipment updated successfully!'**
  String get shipmentUpdated;

  /// No description provided for @iAmTraveler.
  ///
  /// In en, this message translates to:
  /// **'Driver OR Traveler'**
  String get iAmTraveler;

  /// No description provided for @iAmSender.
  ///
  /// In en, this message translates to:
  /// **'I am a Sender'**
  String get iAmSender;

  /// No description provided for @packageDetails.
  ///
  /// In en, this message translates to:
  /// **'Package Details'**
  String get packageDetails;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description (What are you sending?)'**
  String get description;

  /// No description provided for @createRequest.
  ///
  /// In en, this message translates to:
  /// **'Create Shipment Request'**
  String get createRequest;

  /// No description provided for @shipmentPosted.
  ///
  /// In en, this message translates to:
  /// **'Shipment request created successfully'**
  String get shipmentPosted;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickup;

  /// No description provided for @dropoff.
  ///
  /// In en, this message translates to:
  /// **'Dropoff Location'**
  String get dropoff;

  /// No description provided for @companyOnlyFeature.
  ///
  /// In en, this message translates to:
  /// **'Corporate Feature'**
  String get companyOnlyFeature;

  /// No description provided for @mustBeCompany.
  ///
  /// In en, this message translates to:
  /// **'Only verified companies can post shipment requests. Please switch your account type to \'Company\' in your profile.'**
  String get mustBeCompany;

  /// No description provided for @goToProfile.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile'**
  String get goToProfile;

  /// No description provided for @internalTrips.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get internalTrips;

  /// No description provided for @externalTrips.
  ///
  /// In en, this message translates to:
  /// **'External'**
  String get externalTrips;

  /// No description provided for @requestedShipments.
  ///
  /// In en, this message translates to:
  /// **'Last Requested Shipments'**
  String get requestedShipments;

  /// No description provided for @noTripsFound.
  ///
  /// In en, this message translates to:
  /// **'No available trips found.'**
  String get noTripsFound;

  /// No description provided for @noShipmentsFound.
  ///
  /// In en, this message translates to:
  /// **'No shipment requests found.'**
  String get noShipmentsFound;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @town.
  ///
  /// In en, this message translates to:
  /// **'Town'**
  String get town;

  /// No description provided for @confirmSwitchMode.
  ///
  /// In en, this message translates to:
  /// **'Switch Mode?'**
  String get confirmSwitchMode;

  /// No description provided for @switchToTraveler.
  ///
  /// In en, this message translates to:
  /// **'Switch to Traveler Mode?'**
  String get switchToTraveler;

  /// No description provided for @switchToClient.
  ///
  /// In en, this message translates to:
  /// **'Switch to Sender/Client Mode?'**
  String get switchToClient;

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

  /// No description provided for @travelerRegistration.
  ///
  /// In en, this message translates to:
  /// **'Traveler Registration'**
  String get travelerRegistration;

  /// No description provided for @vehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get vehicleInfo;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @uploadLicense.
  ///
  /// In en, this message translates to:
  /// **'Upload Driver License'**
  String get uploadLicense;

  /// No description provided for @uploadID.
  ///
  /// In en, this message translates to:
  /// **'Upload National ID'**
  String get uploadID;

  /// No description provided for @uploadVehiclePhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Vehicle Photo'**
  String get uploadVehiclePhoto;

  /// No description provided for @uploadRegistration.
  ///
  /// In en, this message translates to:
  /// **'Upload Registration'**
  String get uploadRegistration;

  /// No description provided for @uploadRentalContract.
  ///
  /// In en, this message translates to:
  /// **'Upload Rental Contract'**
  String get uploadRentalContract;

  /// No description provided for @uploadIdentityProof.
  ///
  /// In en, this message translates to:
  /// **'Upload Identity Proof'**
  String get uploadIdentityProof;

  /// No description provided for @identityProof.
  ///
  /// In en, this message translates to:
  /// **'Identity Proof'**
  String get identityProof;

  /// No description provided for @passport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passport;

  /// No description provided for @iqama.
  ///
  /// In en, this message translates to:
  /// **'Iqama / Residence Permit'**
  String get iqama;

  /// No description provided for @travelerType.
  ///
  /// In en, this message translates to:
  /// **'Traveler Type'**
  String get travelerType;

  /// No description provided for @travelerWithVehicle.
  ///
  /// In en, this message translates to:
  /// **'Traveler with Vehicle'**
  String get travelerWithVehicle;

  /// No description provided for @normalTraveler.
  ///
  /// In en, this message translates to:
  /// **'Normal Traveler'**
  String get normalTraveler;

  /// No description provided for @travelerAsPerson.
  ///
  /// In en, this message translates to:
  /// **'Traveling as person'**
  String get travelerAsPerson;

  /// No description provided for @driverLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverLabel;

  /// No description provided for @shipmentDriversOnly.
  ///
  /// In en, this message translates to:
  /// **'Shipment offers are for drivers only (travelers with a vehicle)'**
  String get shipmentDriversOnly;

  /// No description provided for @requestedShipmentsOnlyForVehicleOwners.
  ///
  /// In en, this message translates to:
  /// **'Requested shipments only available for vehicle owners'**
  String get requestedShipmentsOnlyForVehicleOwners;

  /// No description provided for @pendingRating.
  ///
  /// In en, this message translates to:
  /// **'Pending Rating'**
  String get pendingRating;

  /// No description provided for @rateUser.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rateUser;

  /// No description provided for @isVehicleRented.
  ///
  /// In en, this message translates to:
  /// **'Is the vehicle rented?'**
  String get isVehicleRented;

  /// No description provided for @make.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Make (e.g. Toyota)'**
  String get make;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Model (e.g. Camry)'**
  String get model;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @plateNumber.
  ///
  /// In en, this message translates to:
  /// **'Plate Number'**
  String get plateNumber;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplication;

  /// No description provided for @applicationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Application Submitted! Admin will review it.'**
  String get applicationSubmitted;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get registerNow;

  /// No description provided for @driverAccessRestricted.
  ///
  /// In en, this message translates to:
  /// **'Driver Access Restricted'**
  String get driverAccessRestricted;

  /// No description provided for @mustBeVerifiedTraveler.
  ///
  /// In en, this message translates to:
  /// **'You must be a verified traveler to access this mode.'**
  String get mustBeVerifiedTraveler;

  /// No description provided for @applicationPending.
  ///
  /// In en, this message translates to:
  /// **'Application Pending'**
  String get applicationPending;

  /// No description provided for @waitAdminApproval.
  ///
  /// In en, this message translates to:
  /// **'Your application is currently being reviewed by an admin.'**
  String get waitAdminApproval;

  /// No description provided for @applicationRejected.
  ///
  /// In en, this message translates to:
  /// **'Application Rejected'**
  String get applicationRejected;

  /// No description provided for @cannotReapply.
  ///
  /// In en, this message translates to:
  /// **'Your application was rejected. You cannot reapply at this time.'**
  String get cannotReapply;

  /// No description provided for @alreadyApproved.
  ///
  /// In en, this message translates to:
  /// **'Already Approved'**
  String get alreadyApproved;

  /// No description provided for @alreadyCompanyAccount.
  ///
  /// In en, this message translates to:
  /// **'You already have an approved company account.'**
  String get alreadyCompanyAccount;

  /// No description provided for @alreadyDriverAccount.
  ///
  /// In en, this message translates to:
  /// **'You already have an approved driver account.'**
  String get alreadyDriverAccount;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @companyRegistration.
  ///
  /// In en, this message translates to:
  /// **'Company Registration'**
  String get companyRegistration;

  /// No description provided for @companyInfo.
  ///
  /// In en, this message translates to:
  /// **'Company Information'**
  String get companyInfo;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// No description provided for @companyAddress.
  ///
  /// In en, this message translates to:
  /// **'Company Address'**
  String get companyAddress;

  /// No description provided for @crNumber.
  ///
  /// In en, this message translates to:
  /// **'CR Number'**
  String get crNumber;

  /// No description provided for @crNumberDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'The CR number must contain digits only'**
  String get crNumberDigitsOnly;

  /// No description provided for @uploadCR.
  ///
  /// In en, this message translates to:
  /// **'Upload CR Document'**
  String get uploadCR;

  /// No description provided for @upgradeToBusiness.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Business Account'**
  String get upgradeToBusiness;

  /// No description provided for @upgradeToDriver.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Driver (with vehicle)'**
  String get upgradeToDriver;

  /// No description provided for @companyAccessRestricted.
  ///
  /// In en, this message translates to:
  /// **'Company Feature'**
  String get companyAccessRestricted;

  /// No description provided for @mustBeVerifiedCompany.
  ///
  /// In en, this message translates to:
  /// **'Only verified companies can access this feature.'**
  String get mustBeVerifiedCompany;

  /// No description provided for @verifiedCompanyAccount.
  ///
  /// In en, this message translates to:
  /// **'Verified Company Account'**
  String get verifiedCompanyAccount;

  /// No description provided for @driverRating.
  ///
  /// In en, this message translates to:
  /// **'Traveler Rating'**
  String get driverRating;

  /// No description provided for @clientRating.
  ///
  /// In en, this message translates to:
  /// **'Sender Rating'**
  String get clientRating;

  /// No description provided for @noRatings.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get noRatings;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get reviews;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @findTrip.
  ///
  /// In en, this message translates to:
  /// **'Find Trip'**
  String get findTrip;

  /// No description provided for @findDriver.
  ///
  /// In en, this message translates to:
  /// **'Find Driver'**
  String get findDriver;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @myTrips.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get myTrips;

  /// No description provided for @myOffers.
  ///
  /// In en, this message translates to:
  /// **'My Offers'**
  String get myOffers;

  /// No description provided for @myShipments.
  ///
  /// In en, this message translates to:
  /// **'My Shipments'**
  String get myShipments;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @noOffersYet.
  ///
  /// In en, this message translates to:
  /// **'No offers received yet'**
  String get noOffersYet;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Field required'**
  String get fieldRequired;

  /// No description provided for @makeOffer.
  ///
  /// In en, this message translates to:
  /// **'Make an Offer'**
  String get makeOffer;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @shipmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Shipment Details'**
  String get shipmentDetails;

  /// No description provided for @offersReceived.
  ///
  /// In en, this message translates to:
  /// **'Offers Received'**
  String get offersReceived;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @invalidCredentialsMessage.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidCredentialsMessage;

  /// No description provided for @emailNotConfirmedMessage.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email before logging in'**
  String get emailNotConfirmedMessage;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(Object error);

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @cancelTrip.
  ///
  /// In en, this message translates to:
  /// **'Cancel Trip'**
  String get cancelTrip;

  /// No description provided for @confirmCancelTrip.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this trip?'**
  String get confirmCancelTrip;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @closeRequest.
  ///
  /// In en, this message translates to:
  /// **'Close Request'**
  String get closeRequest;

  /// No description provided for @confirmCloseRequest.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to close this request? This action cannot be undone.'**
  String get confirmCloseRequest;

  /// No description provided for @requestClosed.
  ///
  /// In en, this message translates to:
  /// **'Request Closed'**
  String get requestClosed;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get statusUpdated;

  /// No description provided for @offerAccepted.
  ///
  /// In en, this message translates to:
  /// **'Offer Accepted! Shipment marked as Booked.'**
  String get offerAccepted;

  /// No description provided for @startTrip.
  ///
  /// In en, this message translates to:
  /// **'Start Trip'**
  String get startTrip;

  /// No description provided for @deliver.
  ///
  /// In en, this message translates to:
  /// **'Deliver'**
  String get deliver;

  /// No description provided for @markDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark Delivered'**
  String get markDelivered;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @selectShipment.
  ///
  /// In en, this message translates to:
  /// **'Select Shipment'**
  String get selectShipment;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip Details'**
  String get tripDetails;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @traveler.
  ///
  /// In en, this message translates to:
  /// **'Traveler'**
  String get traveler;

  /// No description provided for @unknownTraveler.
  ///
  /// In en, this message translates to:
  /// **'Unknown Traveler'**
  String get unknownTraveler;

  /// No description provided for @createShipmentFirst.
  ///
  /// In en, this message translates to:
  /// **'Please create a shipment request first'**
  String get createShipmentFirst;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent to traveler!'**
  String get requestSent;

  /// No description provided for @ratings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get ratings;

  /// No description provided for @travelerRating.
  ///
  /// In en, this message translates to:
  /// **'Traveler Rating'**
  String get travelerRating;

  /// No description provided for @noReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviews;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @travelerNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Traveler information not available'**
  String get travelerNotAvailable;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @main.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get main;

  /// No description provided for @myActivity.
  ///
  /// In en, this message translates to:
  /// **'My Activity'**
  String get myActivity;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get comingSoon;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your trusted shipping partner'**
  String get appTagline;

  /// No description provided for @loginToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Login to your account'**
  String get loginToYourAccount;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @weak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weak;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strong;

  /// No description provided for @accountCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Created Successfully'**
  String get accountCreatedTitle;

  /// No description provided for @accountCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification email to your inbox. Please check your email (and spam folder) and click the link to activate your account.'**
  String get accountCreatedMessage;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please login.'**
  String get emailAlreadyRegistered;

  /// No description provided for @checkBackLater.
  ///
  /// In en, this message translates to:
  /// **'Please check back later for new items.'**
  String get checkBackLater;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter New Password'**
  String get enterNewPassword;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @updatePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePasswordButton;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully! Please login with your new password.'**
  String get passwordUpdatedSuccess;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @internalShipping.
  ///
  /// In en, this message translates to:
  /// **'Internal Shipping'**
  String get internalShipping;

  /// No description provided for @externalShipping.
  ///
  /// In en, this message translates to:
  /// **'External Shipping'**
  String get externalShipping;

  /// No description provided for @noDriversFound.
  ///
  /// In en, this message translates to:
  /// **'No Drivers Available'**
  String get noDriversFound;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please check back later for private transport drivers.'**
  String get tryAgainLater;

  /// No description provided for @availableTravelers.
  ///
  /// In en, this message translates to:
  /// **'Latest Available Travelers'**
  String get availableTravelers;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @selectVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle Type'**
  String get selectVehicleType;

  /// No description provided for @originCity.
  ///
  /// In en, this message translates to:
  /// **'Origin City'**
  String get originCity;

  /// No description provided for @destinationCity.
  ///
  /// In en, this message translates to:
  /// **'Destination City'**
  String get destinationCity;

  /// No description provided for @car.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get car;

  /// No description provided for @sedan.
  ///
  /// In en, this message translates to:
  /// **'Sedan'**
  String get sedan;

  /// No description provided for @van.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get van;

  /// No description provided for @truck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get truck;

  /// No description provided for @bus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get bus;

  /// No description provided for @tractorTrailer.
  ///
  /// In en, this message translates to:
  /// **'Tractor and Trailer'**
  String get tractorTrailer;

  /// No description provided for @largeCar.
  ///
  /// In en, this message translates to:
  /// **'Large Car'**
  String get largeCar;

  /// No description provided for @mediumCar.
  ///
  /// In en, this message translates to:
  /// **'Medium Car'**
  String get mediumCar;

  /// No description provided for @smallCar.
  ///
  /// In en, this message translates to:
  /// **'Small Car'**
  String get smallCar;

  /// No description provided for @refrigerated.
  ///
  /// In en, this message translates to:
  /// **'Refrigerated'**
  String get refrigerated;

  /// No description provided for @noVehicle.
  ///
  /// In en, this message translates to:
  /// **'I don\'t have a vehicle'**
  String get noVehicle;

  /// No description provided for @shippingType.
  ///
  /// In en, this message translates to:
  /// **'Shipping Type'**
  String get shippingType;

  /// No description provided for @noTravelersFound.
  ///
  /// In en, this message translates to:
  /// **'No Travelers Available'**
  String get noTravelersFound;

  /// No description provided for @verifiedTraveler.
  ///
  /// In en, this message translates to:
  /// **'Verified Traveler'**
  String get verifiedTraveler;

  /// No description provided for @identityVerified.
  ///
  /// In en, this message translates to:
  /// **'Identity Verified'**
  String get identityVerified;

  /// No description provided for @platformProtected.
  ///
  /// In en, this message translates to:
  /// **'Platform Protected'**
  String get platformProtected;

  /// No description provided for @licenseVerified.
  ///
  /// In en, this message translates to:
  /// **'License Verified'**
  String get licenseVerified;

  /// No description provided for @pendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Pending Verification'**
  String get pendingVerification;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @nationalIdUrl.
  ///
  /// In en, this message translates to:
  /// **'National ID URL'**
  String get nationalIdUrl;

  /// No description provided for @sender.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get sender;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @moreFilters.
  ///
  /// In en, this message translates to:
  /// **'More Filters'**
  String get moreFilters;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @allVehicles.
  ///
  /// In en, this message translates to:
  /// **'All Transport Means'**
  String get allVehicles;

  /// No description provided for @allLocations.
  ///
  /// In en, this message translates to:
  /// **'All Locations'**
  String get allLocations;

  /// No description provided for @anyOrigin.
  ///
  /// In en, this message translates to:
  /// **'Any Origin'**
  String get anyOrigin;

  /// No description provided for @anyDestination.
  ///
  /// In en, this message translates to:
  /// **'Any Destination'**
  String get anyDestination;

  /// No description provided for @selectWeight.
  ///
  /// In en, this message translates to:
  /// **'Select Weight (Kg)'**
  String get selectWeight;

  /// No description provided for @travelerPerson.
  ///
  /// In en, this message translates to:
  /// **'Traveler (Person)'**
  String get travelerPerson;

  /// No description provided for @errorInternalOnlyHomeCountry.
  ///
  /// In en, this message translates to:
  /// **'Internal routes must be within {country}.'**
  String errorInternalOnlyHomeCountry(String country);

  /// No description provided for @errorExternalMustBeOutside.
  ///
  /// In en, this message translates to:
  /// **'This route is internal as both locations are in {country}. Please select External mode for outside routes.'**
  String errorExternalMustBeOutside(String country);

  /// No description provided for @errorExternalMustInvolveHomeCountry.
  ///
  /// In en, this message translates to:
  /// **'For external routes, {country} must be either the origin or the destination.'**
  String errorExternalMustInvolveHomeCountry(String country);

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Send Booking Request'**
  String get bookNow;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @internalRequests.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get internalRequests;

  /// No description provided for @externalRequests.
  ///
  /// In en, this message translates to:
  /// **'External'**
  String get externalRequests;

  /// No description provided for @noGpsProvided.
  ///
  /// In en, this message translates to:
  /// **'No precise GPS location provided'**
  String get noGpsProvided;

  /// No description provided for @gpsAvailable.
  ///
  /// In en, this message translates to:
  /// **'GPS Coordinates Available'**
  String get gpsAvailable;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @shipment.
  ///
  /// In en, this message translates to:
  /// **'Shipment'**
  String get shipment;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @waitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Sender Confirmation'**
  String get waitingConfirmation;

  /// No description provided for @markAsPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Mark as Picked Up'**
  String get markAsPickedUp;

  /// No description provided for @markAsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark as Delivered'**
  String get markAsDelivered;

  /// No description provided for @confirmReceiptPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Receipt & Payment'**
  String get confirmReceiptPayment;

  /// No description provided for @bookingsRequests.
  ///
  /// In en, this message translates to:
  /// **'Bookings & Requests'**
  String get bookingsRequests;

  /// No description provided for @noBookingsYet.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet.'**
  String get noBookingsYet;

  /// No description provided for @pickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get pickedUp;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @scheduledBadge.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduledBadge;

  /// No description provided for @inTransitBadge.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get inTransitBadge;

  /// No description provided for @completedBadge.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedBadge;

  /// No description provided for @cancelledBadge.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledBadge;

  /// No description provided for @offerSent.
  ///
  /// In en, this message translates to:
  /// **'Offer sent!'**
  String get offerSent;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @offerSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer Sent'**
  String get offerSentTitle;

  /// No description provided for @pickupLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickupLabel;

  /// No description provided for @dropoffLabel.
  ///
  /// In en, this message translates to:
  /// **'Dropoff'**
  String get dropoffLabel;

  /// No description provided for @optionalMessage.
  ///
  /// In en, this message translates to:
  /// **'Optional Message'**
  String get optionalMessage;

  /// No description provided for @currencySAR.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get currencySAR;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get statusPickedUp;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get statusBooked;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusPending;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @rateYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate Your Experience'**
  String get rateYourExperience;

  /// No description provided for @howWasTheExperience.
  ///
  /// In en, this message translates to:
  /// **'How was your experience with this transaction?'**
  String get howWasTheExperience;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get submitRating;

  /// No description provided for @ratingSaved.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your rating has been saved.'**
  String get ratingSaved;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)...'**
  String get commentHint;

  /// No description provided for @enterComment.
  ///
  /// In en, this message translates to:
  /// **'Enter your comment'**
  String get enterComment;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @ticketStatus.
  ///
  /// In en, this message translates to:
  /// **'Ticket Status'**
  String get ticketStatus;

  /// No description provided for @ticketIsClosed.
  ///
  /// In en, this message translates to:
  /// **'This ticket is closed.'**
  String get ticketIsClosed;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at'**
  String get updatedAt;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Start the conversation!'**
  String get noMessagesYet;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingData;

  /// No description provided for @directBooking.
  ///
  /// In en, this message translates to:
  /// **'Direct Booking'**
  String get directBooking;

  /// No description provided for @statusInCommunication.
  ///
  /// In en, this message translates to:
  /// **'In Communication'**
  String get statusInCommunication;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @accountSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Suspended'**
  String get accountSuspendedTitle;

  /// No description provided for @accountSuspendedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended by the administrators. Please contact support for more information.'**
  String get accountSuspendedMessage;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @whatsappSupport.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Support'**
  String get whatsappSupport;

  /// No description provided for @travelerStatus.
  ///
  /// In en, this message translates to:
  /// **'Traveler Status'**
  String get travelerStatus;

  /// No description provided for @statusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get statusSuspended;

  /// No description provided for @statusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get statusBlocked;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get uploading;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get uploadFailed;

  /// No description provided for @driverLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver License'**
  String get driverLicense;

  /// No description provided for @rentalContract.
  ///
  /// In en, this message translates to:
  /// **'Rental Contract'**
  String get rentalContract;

  /// No description provided for @crDocument.
  ///
  /// In en, this message translates to:
  /// **'CR Document'**
  String get crDocument;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @avatarUpdateRestricted.
  ///
  /// In en, this message translates to:
  /// **'You can update your profile photo in'**
  String get avatarUpdateRestricted;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @subscriptionExpiry.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expires'**
  String get subscriptionExpiry;

  /// No description provided for @licenseExpiry.
  ///
  /// In en, this message translates to:
  /// **'License Expires'**
  String get licenseExpiry;

  /// No description provided for @markTripAsFull.
  ///
  /// In en, this message translates to:
  /// **'Trip is Full'**
  String get markTripAsFull;

  /// No description provided for @completeTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip Completed'**
  String get completeTrip;

  /// No description provided for @confirmCompleteTrip.
  ///
  /// In en, this message translates to:
  /// **'Are you sure this trip is completed? Status will be updated to Completed.'**
  String get confirmCompleteTrip;

  /// No description provided for @unreadMessages.
  ///
  /// In en, this message translates to:
  /// **'Unread Messages'**
  String get unreadMessages;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @handshakeHandedGoods.
  ///
  /// In en, this message translates to:
  /// **'I Handed Over Goods'**
  String get handshakeHandedGoods;

  /// No description provided for @handshakePaymentSent.
  ///
  /// In en, this message translates to:
  /// **'I Sent Payment'**
  String get handshakePaymentSent;

  /// No description provided for @handshakeWaitingDriver.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Driver Confirmation'**
  String get handshakeWaitingDriver;

  /// No description provided for @handshakeGoodsReceived.
  ///
  /// In en, this message translates to:
  /// **'I Received Goods'**
  String get handshakeGoodsReceived;

  /// No description provided for @handshakeConfirmPickup.
  ///
  /// In en, this message translates to:
  /// **'Confirm Pickup'**
  String get handshakeConfirmPickup;

  /// No description provided for @handshakeConfirmReceipt.
  ///
  /// In en, this message translates to:
  /// **'Confirm Receipt'**
  String get handshakeConfirmReceipt;

  /// No description provided for @handshakeConfirmPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment Received'**
  String get handshakeConfirmPaymentReceived;

  /// No description provided for @handshakeMarkPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Mark Payment Received'**
  String get handshakeMarkPaymentReceived;

  /// No description provided for @handshakeWaitingClient.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Client Confirmation'**
  String get handshakeWaitingClient;

  /// No description provided for @cancelBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBookingTitle;

  /// No description provided for @cancelBookingConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking? This action cannot be undone.'**
  String get cancelBookingConfirmMessage;

  /// No description provided for @cancelBookingReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancellation...'**
  String get cancelBookingReasonHint;

  /// No description provided for @actionRequiredPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment Received'**
  String get actionRequiredPayment;

  /// No description provided for @actionRequiredPaymentSender.
  ///
  /// In en, this message translates to:
  /// **'Mark Payment Sent'**
  String get actionRequiredPaymentSender;

  /// No description provided for @paymentConfirmedIndicator.
  ///
  /// In en, this message translates to:
  /// **'Payment Confirmed'**
  String get paymentConfirmedIndicator;

  /// No description provided for @goodsReceivedByTravelerIndicator.
  ///
  /// In en, this message translates to:
  /// **'Traveler Confirmed Pickup'**
  String get goodsReceivedByTravelerIndicator;

  /// No description provided for @rated.
  ///
  /// In en, this message translates to:
  /// **'Rated'**
  String get rated;

  /// No description provided for @thankYouForRating.
  ///
  /// In en, this message translates to:
  /// **'Thank you for rating!'**
  String get thankYouForRating;

  /// No description provided for @waitingForSenderToHandOver.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sender to hand over the goods'**
  String get waitingForSenderToHandOver;

  /// No description provided for @waitingForSenderToPay.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sender to mark payment'**
  String get waitingForSenderToPay;

  /// No description provided for @anotherOfferAccepted.
  ///
  /// In en, this message translates to:
  /// **'Another offer has already been accepted for this shipment.'**
  String get anotherOfferAccepted;

  /// No description provided for @otherOfferAcceptedBadge.
  ///
  /// In en, this message translates to:
  /// **'OTHER ACCEPTED'**
  String get otherOfferAcceptedBadge;

  /// No description provided for @requestedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested on'**
  String get requestedOnLabel;

  /// No description provided for @offerStartTripHint.
  ///
  /// In en, this message translates to:
  /// **'Action: Start trip to update status'**
  String get offerStartTripHint;

  /// No description provided for @offerMarkDeliveredHint.
  ///
  /// In en, this message translates to:
  /// **'Action: Mark delivered when done'**
  String get offerMarkDeliveredHint;

  /// No description provided for @offerStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get offerStartButton;

  /// No description provided for @offerDeliverButton.
  ///
  /// In en, this message translates to:
  /// **'Deliver'**
  String get offerDeliverButton;

  /// No description provided for @offerTripStarted.
  ///
  /// In en, this message translates to:
  /// **'Trip started'**
  String get offerTripStarted;

  /// No description provided for @offerMarkedDelivered.
  ///
  /// In en, this message translates to:
  /// **'Marked as delivered'**
  String get offerMarkedDelivered;

  /// No description provided for @chatClientLabel.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get chatClientLabel;

  /// No description provided for @operationHistory.
  ///
  /// In en, this message translates to:
  /// **'Operation History'**
  String get operationHistory;

  /// No description provided for @eventOfferCreated.
  ///
  /// In en, this message translates to:
  /// **'Offer Created'**
  String get eventOfferCreated;

  /// No description provided for @eventRequestCreated.
  ///
  /// In en, this message translates to:
  /// **'Request Created'**
  String get eventRequestCreated;

  /// No description provided for @eventBookingCreated.
  ///
  /// In en, this message translates to:
  /// **'Booking Created'**
  String get eventBookingCreated;

  /// No description provided for @eventBookingAccepted.
  ///
  /// In en, this message translates to:
  /// **'Booking Accepted'**
  String get eventBookingAccepted;

  /// No description provided for @eventBookingRejected.
  ///
  /// In en, this message translates to:
  /// **'Booking Rejected'**
  String get eventBookingRejected;

  /// No description provided for @eventCommunicationStarted.
  ///
  /// In en, this message translates to:
  /// **'Communication Started'**
  String get eventCommunicationStarted;

  /// No description provided for @eventOfferAccepted.
  ///
  /// In en, this message translates to:
  /// **'Offer Accepted'**
  String get eventOfferAccepted;

  /// No description provided for @eventOfferRejected.
  ///
  /// In en, this message translates to:
  /// **'Offer Rejected'**
  String get eventOfferRejected;

  /// No description provided for @eventDeliveredVerifiedOtp.
  ///
  /// In en, this message translates to:
  /// **'Delivered (Verified OTP)'**
  String get eventDeliveredVerifiedOtp;

  /// No description provided for @eventGoodsHanded.
  ///
  /// In en, this message translates to:
  /// **'Goods Handed Over'**
  String get eventGoodsHanded;

  /// No description provided for @eventGoodsReceived.
  ///
  /// In en, this message translates to:
  /// **'Goods Received'**
  String get eventGoodsReceived;

  /// No description provided for @eventPaymentSent.
  ///
  /// In en, this message translates to:
  /// **'Payment Sent'**
  String get eventPaymentSent;

  /// No description provided for @eventPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get eventPaymentReceived;

  /// No description provided for @eventDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get eventDelivered;

  /// No description provided for @eventCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get eventCompleted;

  /// No description provided for @eventCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get eventCancelled;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No operation history yet.'**
  String get noHistoryYet;

  /// No description provided for @eventTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get eventTime;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noRatingsYet.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get noRatingsYet;

  /// No description provided for @showingCachedData.
  ///
  /// In en, this message translates to:
  /// **'Showing cached data'**
  String get showingCachedData;

  /// No description provided for @tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip Completed'**
  String get tripCompleted;

  /// No description provided for @tripCompletedConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure this trip is completed? This signifies you have reached your destination and all deliveries are finalized. This action cannot be undone.'**
  String get tripCompletedConfirmMessage;

  /// No description provided for @confirmCompletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Completion'**
  String get confirmCompletion;

  /// No description provided for @cancelTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Trip'**
  String get cancelTripTitle;

  /// No description provided for @cancelTripConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this trip? All pending and accepted bookings will be cancelled. This action cannot be undone.'**
  String get cancelTripConfirmMessage;

  /// No description provided for @confirmCancellation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancellation'**
  String get confirmCancellation;

  /// No description provided for @bookingRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Booking request sent to driver successfully!'**
  String get bookingRequestSent;

  /// No description provided for @tripIsFull.
  ///
  /// In en, this message translates to:
  /// **'Trip is Full'**
  String get tripIsFull;

  /// No description provided for @markTripFullConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Mark this trip as full? Other users will no longer be able to request bookings.'**
  String get markTripFullConfirmMessage;

  /// No description provided for @confirmFull.
  ///
  /// In en, this message translates to:
  /// **'Confirm Full'**
  String get confirmFull;

  /// No description provided for @tripMarkedFull.
  ///
  /// In en, this message translates to:
  /// **'Trip marked as full'**
  String get tripMarkedFull;

  /// No description provided for @errorLoadBookings.
  ///
  /// In en, this message translates to:
  /// **'Could not load bookings'**
  String get errorLoadBookings;

  /// No description provided for @accountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended.'**
  String get accountSuspended;

  /// No description provided for @credentialsExpired.
  ///
  /// In en, this message translates to:
  /// **'Your subscription or license has expired. Please renew.'**
  String get credentialsExpired;

  /// No description provided for @cannotCancelTripActiveBookings.
  ///
  /// In en, this message translates to:
  /// **'Cannot cancel trip: Contains active bookings that are in transit, delivered, or paid.'**
  String get cannotCancelTripActiveBookings;

  /// No description provided for @errorFetchingTrips.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch trips. Please try again.'**
  String get errorFetchingTrips;

  /// No description provided for @requestAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'Request already sent to this driver for this shipment.'**
  String get requestAlreadySent;

  /// No description provided for @bookingRequestExists.
  ///
  /// In en, this message translates to:
  /// **'You already have a booking request for this trip.'**
  String get bookingRequestExists;

  /// No description provided for @shipmentAlreadyBooked.
  ///
  /// In en, this message translates to:
  /// **'This shipment has already been booked with another driver.'**
  String get shipmentAlreadyBooked;

  /// No description provided for @cannotCancelGoodsHandedOver.
  ///
  /// In en, this message translates to:
  /// **'Cannot cancel: goods have already been handed over to the driver.'**
  String get cannotCancelGoodsHandedOver;

  /// No description provided for @cannotCancelPaymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Cannot cancel: payment has already been confirmed.'**
  String get cannotCancelPaymentConfirmed;

  /// No description provided for @failedCreateShipment.
  ///
  /// In en, this message translates to:
  /// **'Failed to create shipment. Please try again.'**
  String get failedCreateShipment;

  /// No description provided for @failedLoadShipments.
  ///
  /// In en, this message translates to:
  /// **'Failed to load shipments. Please try again.'**
  String get failedLoadShipments;

  /// No description provided for @failedSearchShipments.
  ///
  /// In en, this message translates to:
  /// **'Failed to search shipments. Please try again.'**
  String get failedSearchShipments;

  /// No description provided for @failedUpdateShipmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update shipment status.'**
  String get failedUpdateShipmentStatus;

  /// No description provided for @failedLoadShipmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load shipment details.'**
  String get failedLoadShipmentDetails;

  /// No description provided for @couldNotResolveLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve location address. Please select a specific town if available.'**
  String get couldNotResolveLocation;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get reportUser;

  /// No description provided for @reportUserDescription.
  ///
  /// In en, this message translates to:
  /// **'Please describe why you are reporting this user:'**
  String get reportUserDescription;

  /// No description provided for @reportReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (e.g., harassment, spam)...'**
  String get reportReasonHint;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted.'**
  String get reportSubmitted;

  /// No description provided for @reportSubmittedBlocked.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. User has been blocked.'**
  String get reportSubmittedBlocked;

  /// No description provided for @reportSubmittedCannotBlock.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. User cannot be blocked due to an active engagement.'**
  String get reportSubmittedCannotBlock;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @warningCheckGoodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Important Traveler Notice'**
  String get warningCheckGoodsTitle;

  /// No description provided for @warningCheckGoodsBody.
  ///
  /// In en, this message translates to:
  /// **'We advise you to inspect the goods and ensure their legality. The platform only connects parties and bears no legal or ethical responsibility.'**
  String get warningCheckGoodsBody;

  /// No description provided for @warningCheckTravelerTitle.
  ///
  /// In en, this message translates to:
  /// **'Important Sender Notice'**
  String get warningCheckTravelerTitle;

  /// No description provided for @warningCheckTravelerBody.
  ///
  /// In en, this message translates to:
  /// **'Please verify the traveler\'s identity. The platform is not responsible for any loss or damage to the shipment, legally or ethically.'**
  String get warningCheckTravelerBody;

  /// No description provided for @policyWarningDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get policyWarningDialogTitle;

  /// No description provided for @policyWarningDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to accept this offer?\n\nWe advise you to verify the traveler. The platform explicitly disclaims all liability for any loss or damage to the shipment, legally or ethically. Our role is solely to connect the parties.'**
  String get policyWarningDialogBody;

  /// No description provided for @acceptAndProceed.
  ///
  /// In en, this message translates to:
  /// **'Agree & Accept Offer'**
  String get acceptAndProceed;

  /// No description provided for @acceptBookingAndProceed.
  ///
  /// In en, this message translates to:
  /// **'Agree & Accept Booking'**
  String get acceptBookingAndProceed;

  /// No description provided for @chatDisabledRejected.
  ///
  /// In en, this message translates to:
  /// **'Chat disabled because booking is rejected.'**
  String get chatDisabledRejected;

  /// No description provided for @chatDisabledOtherAccepted.
  ///
  /// In en, this message translates to:
  /// **'Chat disabled because another offer was accepted.'**
  String get chatDisabledOtherAccepted;

  /// No description provided for @chatDisabledCompleted.
  ///
  /// In en, this message translates to:
  /// **'Chat disabled as the trip is completed.'**
  String get chatDisabledCompleted;

  /// No description provided for @chatDisabledCancelled.
  ///
  /// In en, this message translates to:
  /// **'Chat disabled because booking is cancelled.'**
  String get chatDisabledCancelled;

  /// No description provided for @chatDisabledGeneric.
  ///
  /// In en, this message translates to:
  /// **'Chat is currently unavailable.'**
  String get chatDisabledGeneric;

  /// No description provided for @privacyAndSafety.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Safety'**
  String get privacyAndSafety;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users found'**
  String get noBlockedUsers;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @blockUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block this user? You will no longer see their messages or offers.'**
  String get blockUserConfirm;

  /// No description provided for @userBlockedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User blocked successfully.'**
  String get userBlockedSuccess;

  /// No description provided for @userUnblockedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User unblocked successfully.'**
  String get userUnblockedSuccess;

  /// No description provided for @unblockUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unblock this user? You will be able to communicate with them again.'**
  String get unblockUserConfirm;

  /// No description provided for @cannotBlockActiveEngagement.
  ///
  /// In en, this message translates to:
  /// **'You cannot block this user because you have an active trip or shipment with them.'**
  String get cannotBlockActiveEngagement;

  /// No description provided for @cannotBookBlockedUser.
  ///
  /// In en, this message translates to:
  /// **'Cannot book trip with a blocked user.'**
  String get cannotBookBlockedUser;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @errorSavingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error saving profile'**
  String get errorSavingProfile;

  /// No description provided for @pleaseSelectPickupDropoff.
  ///
  /// In en, this message translates to:
  /// **'Please select Pickup and Dropoff locations'**
  String get pleaseSelectPickupDropoff;

  /// No description provided for @errorCreatingShipment.
  ///
  /// In en, this message translates to:
  /// **'Error creating shipment'**
  String get errorCreatingShipment;

  /// No description provided for @couldNotGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get location'**
  String get couldNotGetLocation;

  /// No description provided for @errorLoadingReviews.
  ///
  /// In en, this message translates to:
  /// **'Error loading reviews'**
  String get errorLoadingReviews;

  /// No description provided for @prohibitedItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prohibited Items'**
  String get prohibitedItemsTitle;

  /// No description provided for @prohibitedItemsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Please ensure your shipment does not contain any of the following items:'**
  String get prohibitedItemsDisclaimer;

  /// No description provided for @prohibitedDrugs.
  ///
  /// In en, this message translates to:
  /// **'Drugs & Narcotics'**
  String get prohibitedDrugs;

  /// No description provided for @prohibitedAlcohol.
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get prohibitedAlcohol;

  /// No description provided for @prohibitedWeapons.
  ///
  /// In en, this message translates to:
  /// **'Weapons & Explosives'**
  String get prohibitedWeapons;

  /// No description provided for @prohibitedFlammables.
  ///
  /// In en, this message translates to:
  /// **'Flammable Materials'**
  String get prohibitedFlammables;

  /// No description provided for @prohibitedCurrency.
  ///
  /// In en, this message translates to:
  /// **'Large Cash Amounts'**
  String get prohibitedCurrency;

  /// No description provided for @prohibitedAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get prohibitedAnimals;

  /// No description provided for @viewProhibitedItems.
  ///
  /// In en, this message translates to:
  /// **'View Prohibited Items'**
  String get viewProhibitedItems;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deliveryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Code (OTP)'**
  String get deliveryCodeLabel;

  /// No description provided for @deliveryCodeInstruction.
  ///
  /// In en, this message translates to:
  /// **'Share this code with the traveler only when you receive your shipment.'**
  String get deliveryCodeInstruction;

  /// No description provided for @enterDeliveryCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Delivery Code'**
  String get enterDeliveryCode;

  /// No description provided for @deliveryCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter 4-digit code if available to confirm instantly.'**
  String get deliveryCodeOptional;

  /// No description provided for @confirmWithCode.
  ///
  /// In en, this message translates to:
  /// **'Confirm with Code'**
  String get confirmWithCode;

  /// No description provided for @markDeliveredWithoutCode.
  ///
  /// In en, this message translates to:
  /// **'Mark Delivered without Code'**
  String get markDeliveredWithoutCode;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid Code'**
  String get invalidCode;

  /// No description provided for @notifDeliveredVerified.
  ///
  /// In en, this message translates to:
  /// **'Delivery Verified!'**
  String get notifDeliveredVerified;

  /// No description provided for @notifDeliveredVerifiedBody.
  ///
  /// In en, this message translates to:
  /// **'The shipment has been delivered and verified with OTP.'**
  String get notifDeliveredVerifiedBody;

  /// No description provided for @notifClientConfirmedReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt Confirmed'**
  String get notifClientConfirmedReceipt;

  /// No description provided for @notifClientConfirmedReceiptBody.
  ///
  /// In en, this message translates to:
  /// **'Client has confirmed receipt of the shipment.'**
  String get notifClientConfirmedReceiptBody;

  /// No description provided for @pleaseUploadCRDocument.
  ///
  /// In en, this message translates to:
  /// **'Please upload the CR Document.'**
  String get pleaseUploadCRDocument;

  /// No description provided for @pleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Please login to subscribe to alerts'**
  String get pleaseLogin;

  /// No description provided for @searchRadius.
  ///
  /// In en, this message translates to:
  /// **'Search Radius'**
  String get searchRadius;

  /// No description provided for @fileSelected.
  ///
  /// In en, this message translates to:
  /// **'File selected'**
  String get fileSelected;

  /// No description provided for @fileSelectedFor.
  ///
  /// In en, this message translates to:
  /// **'File selected for {type}'**
  String fileSelectedFor(Object type);

  /// No description provided for @pleaseUploadIdentityProof.
  ///
  /// In en, this message translates to:
  /// **'Please upload identity proof.'**
  String get pleaseUploadIdentityProof;

  /// No description provided for @pleaseUploadVehicleDocuments.
  ///
  /// In en, this message translates to:
  /// **'Please upload all vehicle-related documents.'**
  String get pleaseUploadVehicleDocuments;

  /// No description provided for @pleaseUploadRentalContract.
  ///
  /// In en, this message translates to:
  /// **'Please upload the rental contract.'**
  String get pleaseUploadRentalContract;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Please check your internet and try again.'**
  String get networkError;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSize;

  /// No description provided for @textSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get textSizeSmall;

  /// No description provided for @textSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textSizeNormal;

  /// No description provided for @textSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// No description provided for @textSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra Large'**
  String get textSizeExtraLarge;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @supportMessage.
  ///
  /// In en, this message translates to:
  /// **'Your message (optional)'**
  String get supportMessage;

  /// No description provided for @supportMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent. We will respond as soon as possible.'**
  String get supportMessageSent;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @aboutTripShip.
  ///
  /// In en, this message translates to:
  /// **'About TripShip'**
  String get aboutTripShip;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @aboutTripShipDescription.
  ///
  /// In en, this message translates to:
  /// **'TripShip is a comprehensive logistics platform connecting travelers and senders. We make shipping easier, faster, and more reliable.'**
  String get aboutTripShipDescription;

  /// No description provided for @notifBookingApproved.
  ///
  /// In en, this message translates to:
  /// **'Booking Request Approved'**
  String get notifBookingApproved;

  /// No description provided for @notifBookingApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'Your booking request has been approved'**
  String get notifBookingApprovedBody;

  /// No description provided for @notifOfferAcceptedBody.
  ///
  /// In en, this message translates to:
  /// **'Your offer has been accepted! Get ready to deliver'**
  String get notifOfferAcceptedBody;

  /// No description provided for @notifSenderHandedGoods.
  ///
  /// In en, this message translates to:
  /// **'Sender Handed Over Goods'**
  String get notifSenderHandedGoods;

  /// No description provided for @notifConfirmReceipt.
  ///
  /// In en, this message translates to:
  /// **'Please confirm receipt'**
  String get notifConfirmReceipt;

  /// No description provided for @notifPaymentMarked.
  ///
  /// In en, this message translates to:
  /// **'Payment Marked'**
  String get notifPaymentMarked;

  /// No description provided for @notifConfirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Please confirm payment received'**
  String get notifConfirmPayment;

  /// No description provided for @notifTravelerDelivered.
  ///
  /// In en, this message translates to:
  /// **'Traveler Delivered Shipment'**
  String get notifTravelerDelivered;

  /// No description provided for @notifGoodsReceived.
  ///
  /// In en, this message translates to:
  /// **'Goods Received'**
  String get notifGoodsReceived;

  /// No description provided for @notifGoodsInTransit.
  ///
  /// In en, this message translates to:
  /// **'Traveler confirmed receipt - shipment in transit'**
  String get notifGoodsInTransit;

  /// No description provided for @notifPaymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment Confirmed'**
  String get notifPaymentConfirmed;

  /// No description provided for @notifPaymentConfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'Traveler confirmed payment received'**
  String get notifPaymentConfirmedBody;

  /// No description provided for @notifDeliveryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sender confirmed receipt - request closed'**
  String get notifDeliveryCompleted;

  /// No description provided for @notifNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get notifNewMessage;

  /// No description provided for @notifNewOffer.
  ///
  /// In en, this message translates to:
  /// **'New Offer!'**
  String get notifNewOffer;

  /// No description provided for @notifNewOfferBody.
  ///
  /// In en, this message translates to:
  /// **'You have received a new offer for your shipment'**
  String get notifNewOfferBody;

  /// No description provided for @notifNewRequest.
  ///
  /// In en, this message translates to:
  /// **'New Shipment Request'**
  String get notifNewRequest;

  /// No description provided for @notifNewRequestBody.
  ///
  /// In en, this message translates to:
  /// **'You have received a new shipment request'**
  String get notifNewRequestBody;

  /// No description provided for @notifNewBookingRequest.
  ///
  /// In en, this message translates to:
  /// **'New Booking Request!'**
  String get notifNewBookingRequest;

  /// No description provided for @notifNewBookingRequestBody.
  ///
  /// In en, this message translates to:
  /// **'Someone wants to book your trip'**
  String get notifNewBookingRequestBody;

  /// No description provided for @notifOfferDeclined.
  ///
  /// In en, this message translates to:
  /// **'Offer Declined'**
  String get notifOfferDeclined;

  /// No description provided for @notifOfferDeclinedBody.
  ///
  /// In en, this message translates to:
  /// **'Your offer was not accepted this time'**
  String get notifOfferDeclinedBody;

  /// No description provided for @notifBookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking Cancelled'**
  String get notifBookingCancelled;

  /// No description provided for @notifBookingCancelledBody.
  ///
  /// In en, this message translates to:
  /// **'A booking has been cancelled'**
  String get notifBookingCancelledBody;

  /// No description provided for @notifNewTripMatchingAlert.
  ///
  /// In en, this message translates to:
  /// **'New Trip Matching Your Alert'**
  String get notifNewTripMatchingAlert;

  /// No description provided for @notifNewTripMatchingAlertBody.
  ///
  /// In en, this message translates to:
  /// **'A new trip matches your route alert. Check it out!'**
  String get notifNewTripMatchingAlertBody;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @seeAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'See all notifications'**
  String get seeAllNotifications;

  /// No description provided for @readNotifications.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readNotifications;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to you'**
  String get enterVerificationCode;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to'**
  String get codeSentTo;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhone;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @allProvinces.
  ///
  /// In en, this message translates to:
  /// **'All Provinces'**
  String get allProvinces;

  /// No description provided for @allCities.
  ///
  /// In en, this message translates to:
  /// **'All Cities'**
  String get allCities;

  /// No description provided for @allOfProvince.
  ///
  /// In en, this message translates to:
  /// **'{province} Province'**
  String allOfProvince(String province);

  /// No description provided for @allOrigins.
  ///
  /// In en, this message translates to:
  /// **'All Origins'**
  String get allOrigins;

  /// No description provided for @allDestinations.
  ///
  /// In en, this message translates to:
  /// **'All Destinations'**
  String get allDestinations;

  /// No description provided for @selectProvince.
  ///
  /// In en, this message translates to:
  /// **'Select Province'**
  String get selectProvince;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get selectCity;

  /// No description provided for @repeatTrip.
  ///
  /// In en, this message translates to:
  /// **'Repeat Trip'**
  String get repeatTrip;

  /// No description provided for @selectRepeatDays.
  ///
  /// In en, this message translates to:
  /// **'Select Repeat Days'**
  String get selectRepeatDays;

  /// No description provided for @createAlert.
  ///
  /// In en, this message translates to:
  /// **'Create Alert'**
  String get createAlert;

  /// No description provided for @alertCreated.
  ///
  /// In en, this message translates to:
  /// **'Alert created successfully'**
  String get alertCreated;

  /// No description provided for @alertMeWhenAvailable.
  ///
  /// In en, this message translates to:
  /// **'Notify me when a matching trip is available'**
  String get alertMeWhenAvailable;

  /// No description provided for @alertMe.
  ///
  /// In en, this message translates to:
  /// **'Notify Me'**
  String get alertMe;

  /// No description provided for @alertRequiresOriginAndDest.
  ///
  /// In en, this message translates to:
  /// **'Please specify origin and destination to create an alert'**
  String get alertRequiresOriginAndDest;

  /// No description provided for @pleaseSelectOriginAndDest.
  ///
  /// In en, this message translates to:
  /// **'Please select both origin and destination cities'**
  String get pleaseSelectOriginAndDest;

  /// No description provided for @myAlerts.
  ///
  /// In en, this message translates to:
  /// **'My Alerts'**
  String get myAlerts;

  /// No description provided for @shipmentAlerts.
  ///
  /// In en, this message translates to:
  /// **'Shipment Alerts'**
  String get shipmentAlerts;

  /// No description provided for @addAlert.
  ///
  /// In en, this message translates to:
  /// **'Add Alert'**
  String get addAlert;

  /// No description provided for @noAlertsYet.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet. Create one from the trips search.'**
  String get noAlertsYet;

  /// No description provided for @deleteAlert.
  ///
  /// In en, this message translates to:
  /// **'Delete Alert'**
  String get deleteAlert;

  /// No description provided for @confirmDeleteAlert.
  ///
  /// In en, this message translates to:
  /// **'Delete this alert?'**
  String get confirmDeleteAlert;

  /// No description provided for @alertDeleted.
  ///
  /// In en, this message translates to:
  /// **'Alert deleted'**
  String get alertDeleted;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @arrivalTime.
  ///
  /// In en, this message translates to:
  /// **'Arrival Time'**
  String get arrivalTime;

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time'**
  String get estimatedTime;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date and Time'**
  String get dateTime;

  /// No description provided for @alertsLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You have reached the limit of {limit} alerts. Please delete an alert to add a new one.'**
  String alertsLimitReached(int limit);

  /// No description provided for @maxAlertsReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Limit Reached'**
  String get maxAlertsReachedTitle;

  /// No description provided for @alertType.
  ///
  /// In en, this message translates to:
  /// **'Alert Type'**
  String get alertType;

  /// No description provided for @myShipmentAlerts.
  ///
  /// In en, this message translates to:
  /// **'My Shipment Alerts'**
  String get myShipmentAlerts;

  /// No description provided for @manageAlerts.
  ///
  /// In en, this message translates to:
  /// **'Manage Alerts'**
  String get manageAlerts;

  /// No description provided for @alertLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Alert Limit Exceeded'**
  String get alertLimitExceeded;

  /// No description provided for @deleteAlertToAddNew.
  ///
  /// In en, this message translates to:
  /// **'Please delete an existing alert to add a new one.'**
  String get deleteAlertToAddNew;

  /// No description provided for @shipmentAlertsLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You have reached the limit of {limit} shipment alerts. Please delete one to add a new one.'**
  String shipmentAlertsLimitReached(int limit);

  /// No description provided for @profilePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhotoLabel;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile;

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missing;

  /// No description provided for @completeNow.
  ///
  /// In en, this message translates to:
  /// **'Complete Now'**
  String get completeNow;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @noDocumentsFound.
  ///
  /// In en, this message translates to:
  /// **'No documents found'**
  String get noDocumentsFound;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @vehicleColor.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Color'**
  String get vehicleColor;

  /// No description provided for @supportChat.
  ///
  /// In en, this message translates to:
  /// **'Support Chat'**
  String get supportChat;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get typeMessage;

  /// No description provided for @companyOnlyFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Feature'**
  String get companyOnlyFeatureTitle;

  /// No description provided for @companyOnlyFeatureBody.
  ///
  /// In en, this message translates to:
  /// **'This feature is only available for company accounts.'**
  String get companyOnlyFeatureBody;

  /// No description provided for @becomeACompany.
  ///
  /// In en, this message translates to:
  /// **'Become a Company'**
  String get becomeACompany;

  /// No description provided for @driverOnlyFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver Feature'**
  String get driverOnlyFeatureTitle;

  /// No description provided for @driverOnlyFeatureBody.
  ///
  /// In en, this message translates to:
  /// **'Accessing shipment requests is restricted to drivers with registered vehicles. Would you like to upgrade to a driver account now?'**
  String get driverOnlyFeatureBody;

  /// No description provided for @onboardingEarnMoney.
  ///
  /// In en, this message translates to:
  /// **'Earn money by delivering shipments during your travels'**
  String get onboardingEarnMoney;

  /// No description provided for @onboardingSendPackages.
  ///
  /// In en, this message translates to:
  /// **'Send packages anywhere at affordable prices'**
  String get onboardingSendPackages;

  /// No description provided for @onboardingSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get onboardingSecure;

  /// No description provided for @onboardingFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get onboardingFast;

  /// No description provided for @onboardingAffordable.
  ///
  /// In en, this message translates to:
  /// **'Affordable'**
  String get onboardingAffordable;

  /// No description provided for @notifNewShipmentMatchingAlert.
  ///
  /// In en, this message translates to:
  /// **'New Shipment Match'**
  String get notifNewShipmentMatchingAlert;

  /// No description provided for @notifNewShipmentMatchingAlertBody.
  ///
  /// In en, this message translates to:
  /// **'A new shipment matches your saved route alert!'**
  String get notifNewShipmentMatchingAlertBody;

  /// No description provided for @uploadingAvatar.
  ///
  /// In en, this message translates to:
  /// **'Uploading avatar...'**
  String get uploadingAvatar;

  /// No description provided for @shareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share Location'**
  String get shareLocation;

  /// No description provided for @locationShared.
  ///
  /// In en, this message translates to:
  /// **'Location Shared'**
  String get locationShared;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServiceDisabled;

  /// No description provided for @sharingLocation.
  ///
  /// In en, this message translates to:
  /// **'Sharing location...'**
  String get sharingLocation;

  /// No description provided for @shipmentDeliveryCode.
  ///
  /// In en, this message translates to:
  /// **'Delivery Code'**
  String get shipmentDeliveryCode;

  /// No description provided for @shipmentDeliveryCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get shipmentDeliveryCodeCopied;

  /// No description provided for @shipmentShareCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Share this code with the driver at delivery'**
  String get shipmentShareCodeHint;

  /// No description provided for @shipmentHandedToDriver.
  ///
  /// In en, this message translates to:
  /// **'Handed shipment to driver'**
  String get shipmentHandedToDriver;

  /// No description provided for @shipmentPaymentSentToDriver.
  ///
  /// In en, this message translates to:
  /// **'Payment Sent to Driver'**
  String get shipmentPaymentSentToDriver;

  /// No description provided for @shipmentDriverReceivedGoods.
  ///
  /// In en, this message translates to:
  /// **'Driver received shipment'**
  String get shipmentDriverReceivedGoods;

  /// No description provided for @shipmentDriverConfirmedPayment.
  ///
  /// In en, this message translates to:
  /// **'Driver confirmed payment'**
  String get shipmentDriverConfirmedPayment;

  /// No description provided for @shipmentConfirmReceived.
  ///
  /// In en, this message translates to:
  /// **'Confirm Shipment Received'**
  String get shipmentConfirmReceived;

  /// No description provided for @shipmentMarkDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark Shipment as Delivered'**
  String get shipmentMarkDelivered;

  /// No description provided for @shipmentConfirmPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment Received'**
  String get shipmentConfirmPaymentReceived;

  /// No description provided for @shipmentCancelShipment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Shipment'**
  String get shipmentCancelShipment;

  /// No description provided for @shipmentCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this shipment engagement?'**
  String get shipmentCancelConfirm;

  /// No description provided for @shipmentCancelConfirmYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get shipmentCancelConfirmYes;

  /// No description provided for @statusInTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get statusInTransit;

  /// No description provided for @supportTickets.
  ///
  /// In en, this message translates to:
  /// **'Support Tickets'**
  String get supportTickets;

  /// No description provided for @noTicketsFound.
  ///
  /// In en, this message translates to:
  /// **'No support tickets found'**
  String get noTicketsFound;

  /// No description provided for @newTicket.
  ///
  /// In en, this message translates to:
  /// **'New Ticket'**
  String get newTicket;

  /// No description provided for @createTicket.
  ///
  /// In en, this message translates to:
  /// **'Create Ticket'**
  String get createTicket;

  /// No description provided for @ticketCreated.
  ///
  /// In en, this message translates to:
  /// **'Ticket created successfully'**
  String get ticketCreated;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @promotedBadge.
  ///
  /// In en, this message translates to:
  /// **'Promoted'**
  String get promotedBadge;

  /// No description provided for @howCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get howCanWeHelp;

  /// No description provided for @openSupportTicket.
  ///
  /// In en, this message translates to:
  /// **'Open a Support Ticket'**
  String get openSupportTicket;

  /// No description provided for @chatOnWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Chat on WhatsApp'**
  String get chatOnWhatsApp;

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get updateRequired;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @cancelOffer.
  ///
  /// In en, this message translates to:
  /// **'Cancel Offer'**
  String get cancelOffer;

  /// No description provided for @domestic.
  ///
  /// In en, this message translates to:
  /// **'Domestic'**
  String get domestic;

  /// No description provided for @international.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get international;

  /// No description provided for @acceptAction.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptAction;

  /// No description provided for @rejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectAction;

  /// No description provided for @chatAction.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatAction;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Request shipments from different countries and cities at affordable prices'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Deliver shipments to different countries and cities and earn money'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'Fast, safe, and reliable delivery for all your shipments'**
  String get onboardingSubtitle3;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String weeksAgo(int count);

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String monthsAgo(int count);

  /// No description provided for @yearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} years ago'**
  String yearsAgo(int count);

  /// No description provided for @updateMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of TripShip is available. Please update to continue using the app.'**
  String get updateMessage;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @accountBlocked.
  ///
  /// In en, this message translates to:
  /// **'Account Blocked'**
  String get accountBlocked;

  /// No description provided for @accountBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been permanently blocked due to a violation of our terms of service.'**
  String get accountBlockedMessage;

  /// No description provided for @suspensionErrorNotice.
  ///
  /// In en, this message translates to:
  /// **'If you believe this is an error, please contact TripShip Support to resolve your account status.'**
  String get suspensionErrorNotice;

  /// No description provided for @secureTransactionLogged.
  ///
  /// In en, this message translates to:
  /// **'This transaction is secured and logged by TripShip.'**
  String get secureTransactionLogged;

  /// No description provided for @bookingSecuredLogged.
  ///
  /// In en, this message translates to:
  /// **'Booking secured and logged via TripShip platform.'**
  String get bookingSecuredLogged;

  /// No description provided for @paymentDetailsSecure.
  ///
  /// In en, this message translates to:
  /// **'Payment details are processed securely and recorded.'**
  String get paymentDetailsSecure;

  /// No description provided for @conversationSecuredModerated.
  ///
  /// In en, this message translates to:
  /// **'Conversation secured and moderated by TripShip.'**
  String get conversationSecuredModerated;

  /// No description provided for @sendImage.
  ///
  /// In en, this message translates to:
  /// **'Send Image'**
  String get sendImage;

  /// No description provided for @voiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice Message'**
  String get voiceMessage;

  /// No description provided for @failedToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get failedToSendMessage;

  /// No description provided for @failedToRefreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh status'**
  String get failedToRefreshStatus;
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
      <String>['ar', 'en', 'es', 'fr', 'tr'].contains(locale.languageCode);

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
    case 'fr':
      return AppLocalizationsFr();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
