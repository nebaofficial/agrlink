import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

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
    Locale('am'),
    Locale('en')
  ];

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInfo;

  /// No description provided for @registeredFarmer.
  ///
  /// In en, this message translates to:
  /// **'Registered Farmer'**
  String get registeredFarmer;

  /// No description provided for @cropsListed.
  ///
  /// In en, this message translates to:
  /// **'Crops Listed'**
  String get cropsListed;

  /// No description provided for @totalSold.
  ///
  /// In en, this message translates to:
  /// **'Total Sold'**
  String get totalSold;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @ordersPlaced.
  ///
  /// In en, this message translates to:
  /// **'Orders Placed'**
  String get ordersPlaced;

  /// No description provided for @totalVolume.
  ///
  /// In en, this message translates to:
  /// **'Total Volume'**
  String get totalVolume;

  /// No description provided for @avgRating.
  ///
  /// In en, this message translates to:
  /// **'Avg. Rating'**
  String get avgRating;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfo;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @addisAbaba.
  ///
  /// In en, this message translates to:
  /// **'Addis Ababa, Ethiopia'**
  String get addisAbaba;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @verificationLevel.
  ///
  /// In en, this message translates to:
  /// **'Verification Level'**
  String get verificationLevel;

  /// No description provided for @fullVerification.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get fullVerification;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @identitySecurity.
  ///
  /// In en, this message translates to:
  /// **'Identity & Security'**
  String get identitySecurity;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get verificationStatus;

  /// No description provided for @verifiedAccess.
  ///
  /// In en, this message translates to:
  /// **'Verified — Full access enabled'**
  String get verifiedAccess;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @myFarm.
  ///
  /// In en, this message translates to:
  /// **'My Farm'**
  String get myFarm;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @logistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get logistics;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @listNewCrop.
  ///
  /// In en, this message translates to:
  /// **'List New Crop'**
  String get listNewCrop;

  /// No description provided for @viewOffers.
  ///
  /// In en, this message translates to:
  /// **'View Offers'**
  String get viewOffers;

  /// No description provided for @myCrops.
  ///
  /// In en, this message translates to:
  /// **'My Crops'**
  String get myCrops;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @activeListings.
  ///
  /// In en, this message translates to:
  /// **'Active Listings'**
  String get activeListings;

  /// No description provided for @activeBuyers.
  ///
  /// In en, this message translates to:
  /// **'Active Buyers'**
  String get activeBuyers;

  /// No description provided for @noCropsYet.
  ///
  /// In en, this message translates to:
  /// **'No crops listed yet'**
  String get noCropsYet;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No recent activities'**
  String get noActivityYet;

  /// No description provided for @noRecentActivities.
  ///
  /// In en, this message translates to:
  /// **'No recent activities'**
  String get noRecentActivities;

  /// No description provided for @manageCropsSales.
  ///
  /// In en, this message translates to:
  /// **'Manage your crops and sales'**
  String get manageCropsSales;

  /// No description provided for @faydaVerified.
  ///
  /// In en, this message translates to:
  /// **'Your account has been verified'**
  String get faydaVerified;

  /// No description provided for @thisSeason.
  ///
  /// In en, this message translates to:
  /// **'This season'**
  String get thisSeason;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @orderReceivedFor.
  ///
  /// In en, this message translates to:
  /// **'Order received for {cropName}'**
  String orderReceivedFor(String cropName);

  /// No description provided for @saleCompleted.
  ///
  /// In en, this message translates to:
  /// **'{cropName} sale completed'**
  String saleCompleted(String cropName);

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order for {cropName} was cancelled'**
  String orderCancelled(String cropName);

  /// No description provided for @ton.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get ton;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @marketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplaceTitle;

  /// No description provided for @marketplaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse available crop listings from verified farmers'**
  String get marketplaceSubtitle;

  /// No description provided for @searchCrops.
  ///
  /// In en, this message translates to:
  /// **'Search crops...'**
  String get searchCrops;

  /// No description provided for @filterProducts.
  ///
  /// In en, this message translates to:
  /// **'Filter Products'**
  String get filterProducts;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this listing?'**
  String get deleteConfirm;

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get productDeleted;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @waitingForFarmerAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Waiting for farmer acceptance'**
  String get waitingForFarmerAcceptance;

  /// No description provided for @waitingForYourAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your acceptance'**
  String get waitingForYourAcceptance;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @platformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform Fee'**
  String get platformFee;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total Payable'**
  String get totalPayable;

  /// No description provided for @orderPlacedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully!'**
  String get orderPlacedSuccessfully;

  /// No description provided for @selectExpectedDeliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Please select expected delivery date'**
  String get selectExpectedDeliveryDate;

  /// No description provided for @quantityKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity (kg)'**
  String get quantityKgLabel;

  /// No description provided for @maxAvailable.
  ///
  /// In en, this message translates to:
  /// **'Max available: {quantity}'**
  String maxAvailable(double quantity);

  /// No description provided for @expectedDeliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Expected Delivery Date'**
  String get expectedDeliveryDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  /// No description provided for @statusReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get statusReserved;

  /// No description provided for @statusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get statusSold;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusInTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get statusInTransit;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @pricePerKg.
  ///
  /// In en, this message translates to:
  /// **'Price per kg'**
  String get pricePerKg;

  /// No description provided for @netEarnings.
  ///
  /// In en, this message translates to:
  /// **'Net Earnings'**
  String get netEarnings;

  /// No description provided for @deliveryTracking.
  ///
  /// In en, this message translates to:
  /// **'Delivery Tracking'**
  String get deliveryTracking;

  /// No description provided for @trackingId.
  ///
  /// In en, this message translates to:
  /// **'Tracking ID'**
  String get trackingId;

  /// No description provided for @transporter.
  ///
  /// In en, this message translates to:
  /// **'Transporter'**
  String get transporter;

  /// No description provided for @rejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrder;

  /// No description provided for @acceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get acceptOrder;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @payNowEscrow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now (Secure Escrow)'**
  String get payNowEscrow;

  /// No description provided for @orderStatusUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Order status updated to {status}'**
  String orderStatusUpdatedTo(String status);

  /// No description provided for @productInformation.
  ///
  /// In en, this message translates to:
  /// **'Product Information'**
  String get productInformation;

  /// No description provided for @noLocation.
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get noLocation;

  /// No description provided for @deliveryInformation.
  ///
  /// In en, this message translates to:
  /// **'Delivery Information'**
  String get deliveryInformation;

  /// No description provided for @expectedDate.
  ///
  /// In en, this message translates to:
  /// **'Expected Date'**
  String get expectedDate;

  /// No description provided for @deliveryArrangementPending.
  ///
  /// In en, this message translates to:
  /// **'Delivery arrangement pending payment or confirmation.'**
  String get deliveryArrangementPending;

  /// No description provided for @secureCheckout.
  ///
  /// In en, this message translates to:
  /// **'Secure Checkout'**
  String get secureCheckout;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get paymentSuccessful;

  /// No description provided for @paymentEscrowSecured.
  ///
  /// In en, this message translates to:
  /// **'Your payment has been secured in escrow. A transporter will be assigned shortly.'**
  String get paymentEscrowSecured;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @welcomeToAgriLink.
  ///
  /// In en, this message translates to:
  /// **'Welcome to AgriLink'**
  String get welcomeToAgriLink;

  /// No description provided for @agrilinkSlogan.
  ///
  /// In en, this message translates to:
  /// **'Connecting Farmers directly to Markets'**
  String get agrilinkSlogan;

  /// No description provided for @empoweringAgriculture.
  ///
  /// In en, this message translates to:
  /// **'Empowering\nAgriculture'**
  String get empoweringAgriculture;

  /// No description provided for @introSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect directly with farmers, transporters, and buyers in a fair and transparent marketplace.'**
  String get introSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect farmers, buyers, and transporters'**
  String get loginSubtitle;

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

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get enterFullName;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (Optional)'**
  String get phoneOptional;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @enterPasswordRegister.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get enterPasswordRegister;

  /// No description provided for @roleFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get roleFarmer;

  /// No description provided for @roleBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get roleBuyer;

  /// No description provided for @roleTransporter.
  ///
  /// In en, this message translates to:
  /// **'Transporter'**
  String get roleTransporter;

  /// No description provided for @roleAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get roleAgent;

  /// No description provided for @publicDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Connecting\nFarms to Markets'**
  String get publicDashboardTitle;

  /// No description provided for @publicDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ethiopia\'s trusted agricultural marketplace — browse live crop listings and real-time prices from verified farmers nationwide.'**
  String get publicDashboardSubtitle;

  /// No description provided for @publicLiveMarketData.
  ///
  /// In en, this message translates to:
  /// **'Live market data'**
  String get publicLiveMarketData;

  /// No description provided for @publicStatsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Network of Farms'**
  String get publicStatsSectionTitle;

  /// No description provided for @publicStatFarmers.
  ///
  /// In en, this message translates to:
  /// **'Active Farmers'**
  String get publicStatFarmers;

  /// No description provided for @publicStatListings.
  ///
  /// In en, this message translates to:
  /// **'Active Listings'**
  String get publicStatListings;

  /// No description provided for @publicStatVolume.
  ///
  /// In en, this message translates to:
  /// **'Daily Volume'**
  String get publicStatVolume;

  /// No description provided for @publicMarketPrices.
  ///
  /// In en, this message translates to:
  /// **'Market Prices'**
  String get publicMarketPrices;

  /// No description provided for @publicLiveListings.
  ///
  /// In en, this message translates to:
  /// **'Live Marketplace Listings'**
  String get publicLiveListings;

  /// No description provided for @publicCtaTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to start trading?'**
  String get publicCtaTitle;

  /// No description provided for @publicCtaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to purchase, contact sellers, set favorite orders, and access exclusive marketplace features.'**
  String get publicCtaSubtitle;

  /// No description provided for @publicLoginToTrade.
  ///
  /// In en, this message translates to:
  /// **'Login to Trade'**
  String get publicLoginToTrade;

  /// No description provided for @publicLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading listings...'**
  String get publicLoading;

  /// No description provided for @publicNoListings.
  ///
  /// In en, this message translates to:
  /// **'No listings available right now'**
  String get publicNoListings;

  /// No description provided for @publicBecomeAFarmer.
  ///
  /// In en, this message translates to:
  /// **'Become a Farmer'**
  String get publicBecomeAFarmer;

  /// No description provided for @publicBecomeAFarmerDesc.
  ///
  /// In en, this message translates to:
  /// **'Process setup on AgriLink in a matter of 10 min — easy, mobile-friendly registration and start selling to thousands of buyers.'**
  String get publicBecomeAFarmerDesc;

  /// No description provided for @publicJoinMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Join the Marketplace'**
  String get publicJoinMarketplace;
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
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
