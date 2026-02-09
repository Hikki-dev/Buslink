import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

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
    Locale('en'),
    Locale('si'),
    Locale('ta')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BusLink'**
  String get appTitle;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @lateDepartures.
  ///
  /// In en, this message translates to:
  /// **'Late Departures'**
  String get lateDepartures;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @sinhala.
  ///
  /// In en, this message translates to:
  /// **'Sinhala'**
  String get sinhala;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get tamil;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @routes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routes;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @refunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get refunds;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @enterOriginDestination.
  ///
  /// In en, this message translates to:
  /// **'Please enter origin and destination'**
  String get enterOriginDestination;

  /// No description provided for @yourFavorites.
  ///
  /// In en, this message translates to:
  /// **'Your Favorites'**
  String get yourFavorites;

  /// No description provided for @tapToQuickBook.
  ///
  /// In en, this message translates to:
  /// **'Tap to quick book'**
  String get tapToQuickBook;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// No description provided for @manageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your routes, trips, and bookings.'**
  String get manageSubtitle;

  /// No description provided for @addTrip.
  ///
  /// In en, this message translates to:
  /// **'Add New Trip'**
  String get addTrip;

  /// No description provided for @addRoute.
  ///
  /// In en, this message translates to:
  /// **'Add Route'**
  String get addRoute;

  /// No description provided for @manageRoutes.
  ///
  /// In en, this message translates to:
  /// **'Manage Routes'**
  String get manageRoutes;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @refineDate.
  ///
  /// In en, this message translates to:
  /// **'Refine Date'**
  String get refineDate;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @quickSelect.
  ///
  /// In en, this message translates to:
  /// **'Quick Select'**
  String get quickSelect;

  /// No description provided for @netRevenueOverTime.
  ///
  /// In en, this message translates to:
  /// **'Net Revenue Over Time'**
  String get netRevenueOverTime;

  /// No description provided for @topRoutesRevenue.
  ///
  /// In en, this message translates to:
  /// **'Top Routes by Net Revenue'**
  String get topRoutesRevenue;

  /// No description provided for @netRevenue30d.
  ///
  /// In en, this message translates to:
  /// **'Net Revenue (30d)'**
  String get netRevenue30d;

  /// No description provided for @netRevenueToday.
  ///
  /// In en, this message translates to:
  /// **'Net Revenue (Today)'**
  String get netRevenueToday;

  /// No description provided for @noRevenueData.
  ///
  /// In en, this message translates to:
  /// **'No revenue data for this period'**
  String get noRevenueData;

  /// No description provided for @noRouteData.
  ///
  /// In en, this message translates to:
  /// **'No route data available'**
  String get noRouteData;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @searchRouteHint.
  ///
  /// In en, this message translates to:
  /// **'Search Route (e.g. Colombo)'**
  String get searchRouteHint;

  /// No description provided for @punctualityOverview.
  ///
  /// In en, this message translates to:
  /// **'Punctuality Overview'**
  String get punctualityOverview;

  /// No description provided for @highDelayTrips.
  ///
  /// In en, this message translates to:
  /// **'High Delay Trips'**
  String get highDelayTrips;

  /// No description provided for @totalTrips.
  ///
  /// In en, this message translates to:
  /// **'Total Trips'**
  String get totalTrips;

  /// No description provided for @lateRate.
  ///
  /// In en, this message translates to:
  /// **'Late Rate'**
  String get lateRate;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noData;

  /// No description provided for @onTime.
  ///
  /// In en, this message translates to:
  /// **'On Time'**
  String get onTime;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @noSignificantDelays.
  ///
  /// In en, this message translates to:
  /// **'No significant delays.'**
  String get noSignificantDelays;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @selectYear.
  ///
  /// In en, this message translates to:
  /// **'Select Year'**
  String get selectYear;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @loginErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Email and Password cannot be empty.'**
  String get loginErrorEmpty;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to BusLink to continue.'**
  String get loginSubtitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join us and start your journey today.'**
  String get signupSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @nameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name (Alphabets only)'**
  String get nameInvalid;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name too short'**
  String get nameTooShort;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Your email address'**
  String get enterEmail;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get enterPassword;

  /// No description provided for @passwordLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordLengthError;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @reenterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reenterPassword;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @marketingTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel with\nComfort & Style'**
  String get marketingTitle;

  /// No description provided for @marketingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join thousands of satisfied travelers who trust\nBusLink for their daily commutes.'**
  String get marketingSubtitle;

  /// No description provided for @myTrips.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get myTrips;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @adminPreview.
  ///
  /// In en, this message translates to:
  /// **'Admin Preview'**
  String get adminPreview;

  /// No description provided for @exitPreview.
  ///
  /// In en, this message translates to:
  /// **'Exit Preview'**
  String get exitPreview;

  /// No description provided for @newNotification.
  ///
  /// In en, this message translates to:
  /// **'New Notification'**
  String get newNotification;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'VIEW'**
  String get view;

  /// No description provided for @findTrips.
  ///
  /// In en, this message translates to:
  /// **'Find Trips'**
  String get findTrips;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @noRoutesFound.
  ///
  /// In en, this message translates to:
  /// **'No Routes Found'**
  String get noRoutesFound;

  /// No description provided for @adjustFilters.
  ///
  /// In en, this message translates to:
  /// **'Adjust filters to see results'**
  String get adjustFilters;

  /// No description provided for @previewApp.
  ///
  /// In en, this message translates to:
  /// **'Preview App'**
  String get previewApp;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMyTrips.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get navMyTrips;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get navSupport;

  /// No description provided for @navLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get navLogin;

  /// No description provided for @navLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get navLogout;

  /// No description provided for @heroSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Book your bus tickets instantly with BusLink. Reliable, fast, and secure.'**
  String get heroSubtitle1;

  /// No description provided for @heroSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Discover the most beautiful routes across the island in comfort.'**
  String get heroSubtitle2;

  /// No description provided for @heroSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'Seamless payments and real-time tracking for your journey.'**
  String get heroSubtitle3;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get greetingEvening;

  /// No description provided for @conductorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Conductor Dashboard'**
  String get conductorDashboard;

  /// No description provided for @scanTicket.
  ///
  /// In en, this message translates to:
  /// **'Scan Ticket'**
  String get scanTicket;

  /// No description provided for @scanTicketSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a passenger ticket to verify boarding'**
  String get scanTicketSubtitle;

  /// No description provided for @manualTicketId.
  ///
  /// In en, this message translates to:
  /// **'Manual Ticket ID'**
  String get manualTicketId;

  /// No description provided for @useCamera.
  ///
  /// In en, this message translates to:
  /// **'Use Camera'**
  String get useCamera;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @searchTrips.
  ///
  /// In en, this message translates to:
  /// **'Search Trips'**
  String get searchTrips;

  /// No description provided for @liveJourney.
  ///
  /// In en, this message translates to:
  /// **'Live Journey'**
  String get liveJourney;

  /// No description provided for @yourBusIsHere.
  ///
  /// In en, this message translates to:
  /// **'Your bus is here'**
  String get yourBusIsHere;

  /// No description provided for @trackNow.
  ///
  /// In en, this message translates to:
  /// **'TRACK NOW'**
  String get trackNow;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @careers.
  ///
  /// In en, this message translates to:
  /// **'Careers'**
  String get careers;

  /// No description provided for @blog.
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get blog;

  /// No description provided for @partners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get partners;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @faqs.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get faqs;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @rightsReserved.
  ///
  /// In en, this message translates to:
  /// **'© 2024 BusLink. All rights reserved.'**
  String get rightsReserved;

  /// No description provided for @madeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Made with love in Sri Lanka'**
  String get madeWithLove;

  /// No description provided for @upcomingTrip.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Trip'**
  String get upcomingTrip;

  /// No description provided for @arrivingIn.
  ///
  /// In en, this message translates to:
  /// **'Arriving in'**
  String get arrivingIn;

  /// No description provided for @busNo.
  ///
  /// In en, this message translates to:
  /// **'Bus No'**
  String get busNo;

  /// No description provided for @origin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get origin;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @seats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get seats;

  /// No description provided for @pricePaid.
  ///
  /// In en, this message translates to:
  /// **'Price Paid'**
  String get pricePaid;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusDelayed.
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get statusDelayed;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @tabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get tabUpcoming;

  /// No description provided for @tabCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get tabCompleted;

  /// No description provided for @tabCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get tabCancelled;

  /// No description provided for @tabDelayed.
  ///
  /// In en, this message translates to:
  /// **'DELAYED'**
  String get tabDelayed;

  /// No description provided for @viewTicket.
  ///
  /// In en, this message translates to:
  /// **'VIEW TICKET'**
  String get viewTicket;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;
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
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
