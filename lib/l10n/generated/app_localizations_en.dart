// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get profile => 'Profile';

  @override
  String get accountInfo => 'Account Information';

  @override
  String get registeredFarmer => 'Registered Farmer';

  @override
  String get cropsListed => 'Crops Listed';

  @override
  String get totalSold => 'Total Sold';

  @override
  String get earnings => 'Earnings';

  @override
  String get ordersPlaced => 'Orders Placed';

  @override
  String get totalVolume => 'Total Volume';

  @override
  String get avgRating => 'Avg. Rating';

  @override
  String get contactInfo => 'Contact Information';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get location => 'Location';

  @override
  String get addisAbaba => 'Addis Ababa, Ethiopia';

  @override
  String get memberSince => 'Member Since';

  @override
  String get verificationLevel => 'Verification Level';

  @override
  String get fullVerification => 'Full Verification (Fayda ID)';

  @override
  String get accountDetails => 'Account Details';

  @override
  String get identitySecurity => 'Identity & Security';

  @override
  String get verificationStatus => 'Verification Status';

  @override
  String get verifiedAccess => 'Verified — Full access enabled';

  @override
  String get signOut => 'Sign Out';

  @override
  String get myFarm => 'My Farm';

  @override
  String get market => 'Market';

  @override
  String get orders => 'Orders';

  @override
  String get logistics => 'Logistics';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get listNewCrop => 'List New Crop';

  @override
  String get viewOffers => 'View Offers';

  @override
  String get myCrops => 'My Crops';

  @override
  String get viewAll => 'View All';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get activeListings => 'Active Listings';

  @override
  String get activeBuyers => 'Active Buyers';

  @override
  String get noCropsYet => 'No crops listed yet';

  @override
  String get noActivityYet => 'No recent activities';

  @override
  String get noRecentActivities => 'No recent activities';

  @override
  String get manageCropsSales => 'Manage your crops and sales';

  @override
  String get faydaVerified => 'Your Fayda ID has been verified';

  @override
  String get thisSeason => 'This season';

  @override
  String get thisMonth => 'This month';

  @override
  String get connected => 'Connected';

  @override
  String orderReceivedFor(String cropName) {
    return 'Order received for $cropName';
  }

  @override
  String saleCompleted(String cropName) {
    return '$cropName sale completed';
  }

  @override
  String orderCancelled(String cropName) {
    return 'Order for $cropName was cancelled';
  }

  @override
  String get ton => 'T';

  @override
  String get kg => 'kg';

  @override
  String get marketplaceTitle => 'Marketplace';

  @override
  String get marketplaceSubtitle =>
      'Browse available crop listings from verified farmers';

  @override
  String get searchCrops => 'Search crops...';

  @override
  String get filterProducts => 'Filter Products';

  @override
  String get all => 'All';

  @override
  String get myOrders => 'My Orders';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get productDetails => 'Product Details';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String get deleteConfirm => 'Are you sure you want to delete this listing?';

  @override
  String get productDeleted => 'Product deleted';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get waitingForFarmerAcceptance => 'Waiting for farmer acceptance';

  @override
  String get waitingForYourAcceptance => 'Waiting for your acceptance';

  @override
  String get placeOrder => 'Place Order';

  @override
  String get confirmOrder => 'Confirm Order';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get platformFee => 'Platform Fee (5%)';

  @override
  String get totalPayable => 'Total Payable';

  @override
  String get orderPlacedSuccessfully => 'Order placed successfully!';

  @override
  String get selectExpectedDeliveryDate =>
      'Please select expected delivery date';

  @override
  String get quantityKgLabel => 'Quantity (kg)';

  @override
  String maxAvailable(double quantity) {
    return 'Max available: $quantity';
  }

  @override
  String get expectedDeliveryDate => 'Expected Delivery Date';

  @override
  String get selectDate => 'Select Date';

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusReserved => 'Reserved';

  @override
  String get statusSold => 'Sold';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusInTransit => 'In Transit';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get transactionDetails => 'Transaction Details';

  @override
  String get orderId => 'Order ID';

  @override
  String get quantity => 'Quantity';

  @override
  String get pricePerKg => 'Price per kg';

  @override
  String get netEarnings => 'Net Earnings';

  @override
  String get deliveryTracking => 'Delivery Tracking';

  @override
  String get trackingId => 'Tracking ID';

  @override
  String get transporter => 'Transporter';

  @override
  String get rejectOrder => 'Reject Order';

  @override
  String get acceptOrder => 'Accept Order';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get payNowEscrow => 'Pay Now (Secure Escrow)';

  @override
  String orderStatusUpdatedTo(String status) {
    return 'Order status updated to $status';
  }

  @override
  String get productInformation => 'Product Information';

  @override
  String get noLocation => 'No location';

  @override
  String get deliveryInformation => 'Delivery Information';

  @override
  String get expectedDate => 'Expected Date';

  @override
  String get deliveryArrangementPending =>
      'Delivery arrangement pending payment or confirmation.';

  @override
  String get secureCheckout => 'Secure Checkout';

  @override
  String get paymentSuccessful => 'Payment Successful';

  @override
  String get paymentEscrowSecured =>
      'Your payment has been secured in escrow. A transporter will be assigned shortly.';

  @override
  String get ok => 'OK';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get welcomeToAgriLink => 'Welcome to AgriLink';

  @override
  String get agrilinkSlogan => 'Connecting Farmers directly to Markets';

  @override
  String get empoweringAgriculture => 'Empowering\nAgriculture';

  @override
  String get introSubtitle =>
      'Connect directly with farmers, transporters, and buyers in a fair and transparent marketplace.';

  @override
  String get createAccount => 'Create Account';

  @override
  String get loginSubtitle => 'Connect farmers, buyers, and transporters';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get enterEmail => 'Please enter your email';

  @override
  String get enterValidEmail => 'Please enter a valid email';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterFullName => 'Please enter your full name';

  @override
  String get phoneOptional => 'Phone (Optional)';

  @override
  String get accountType => 'Account Type';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get enterPasswordRegister => 'Please enter a password';

  @override
  String get roleFarmer => 'Farmer';

  @override
  String get roleBuyer => 'Buyer';

  @override
  String get roleTransporter => 'Transporter';

  @override
  String get roleAgent => 'Agent';
}
