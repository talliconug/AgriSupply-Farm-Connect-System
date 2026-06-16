// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AgriSupply';

  @override
  String get appTagline => 'Farm Fresh to Your Doorstep';

  @override
  String get welcomeMessage => 'Welcome to AgriSupply';

  @override
  String get welcomeSubtitle => 'Connecting Ugandan Farmers with Buyers';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterPhone => 'Enter your phone number';

  @override
  String get verifyPhone => 'Verify Phone';

  @override
  String get enterOtp => 'Enter OTP Code';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String otpSent(String phone) {
    return 'OTP sent to $phone';
  }

  @override
  String get selectRole => 'Select your role';

  @override
  String get buyerRole => 'Buyer';

  @override
  String get buyerRoleDesc => 'I want to buy fresh farm products';

  @override
  String get farmerRole => 'Farmer';

  @override
  String get farmerRoleDesc => 'I want to sell my farm products';

  @override
  String get home => 'Home';

  @override
  String get products => 'Products';

  @override
  String get cart => 'Cart';

  @override
  String get orders => 'Orders';

  @override
  String get profile => 'Profile';

  @override
  String get favorites => 'Favorites';

  @override
  String get notifications => 'Notifications';

  @override
  String get categories => 'Categories';

  @override
  String get allCategories => 'All Categories';

  @override
  String get vegetables => 'Vegetables';

  @override
  String get fruits => 'Fruits';

  @override
  String get grains => 'Grains';

  @override
  String get dairy => 'Dairy';

  @override
  String get meat => 'Meat';

  @override
  String get poultry => 'Poultry';

  @override
  String get fishSeafood => 'Fish & Seafood';

  @override
  String get herbsSpices => 'Herbs & Spices';

  @override
  String get rootTubers => 'Root & Tubers';

  @override
  String get otherProducts => 'Other';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get filterProducts => 'Filter Products';

  @override
  String get sortBy => 'Sort By';

  @override
  String get sortByPriceLow => 'Price: Low to High';

  @override
  String get sortByPriceHigh => 'Price: High to Low';

  @override
  String get sortByNewest => 'Newest First';

  @override
  String get sortByRating => 'Highest Rated';

  @override
  String get priceRange => 'Price Range';

  @override
  String get minPrice => 'Min Price';

  @override
  String get maxPrice => 'Max Price';

  @override
  String get applyFilter => 'Apply Filter';

  @override
  String get clearFilter => 'Clear All';

  @override
  String get organic => 'Organic';

  @override
  String get organicCertified => 'Organic Certified';

  @override
  String get freshPicked => 'Fresh Picked';

  @override
  String get inStock => 'In Stock';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get lowStock => 'Low Stock';

  @override
  String itemsLeft(int count) {
    return '$count items left';
  }

  @override
  String get productDetails => 'Product Details';

  @override
  String get description => 'Description';

  @override
  String get specifications => 'Specifications';

  @override
  String get reviews => 'Reviews';

  @override
  String get noReviews => 'No reviews yet';

  @override
  String get writeReview => 'Write a Review';

  @override
  String get rating => 'Rating';

  @override
  String ratingCount(int count) {
    return '$count ratings';
  }

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get addedToCart => 'Added to cart';

  @override
  String get removeFromCart => 'Remove from Cart';

  @override
  String get buyNow => 'Buy Now';

  @override
  String get quantity => 'Quantity';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get total => 'Total';

  @override
  String get perKg => '/kg';

  @override
  String get perBunch => '/bunch';

  @override
  String get perPiece => '/piece';

  @override
  String get perLitre => '/litre';

  @override
  String get perDozen => '/dozen';

  @override
  String get perCrate => '/crate';

  @override
  String get perBag => '/bag';

  @override
  String get shoppingCart => 'Shopping Cart';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartEmptyMessage => 'Add some fresh products to your cart';

  @override
  String get continueShopping => 'Continue Shopping';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get deliveryFee => 'Delivery Fee';

  @override
  String get grandTotal => 'Grand Total';

  @override
  String get proceedToCheckout => 'Proceed to Checkout';

  @override
  String get checkout => 'Checkout';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get selectAddress => 'Select Address';

  @override
  String get addNewAddress => 'Add New Address';

  @override
  String get editAddress => 'Edit Address';

  @override
  String get deleteAddress => 'Delete Address';

  @override
  String get setAsDefault => 'Set as Default';

  @override
  String get addressLabel => 'Address Label';

  @override
  String get streetAddress => 'Street Address';

  @override
  String get city => 'City';

  @override
  String get district => 'District';

  @override
  String get region => 'Region';

  @override
  String get landmark => 'Landmark';

  @override
  String get deliveryInstructions => 'Delivery Instructions';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get selectPayment => 'Select Payment Method';

  @override
  String get mtnMobileMoney => 'MTN Mobile Money';

  @override
  String get airtelMoney => 'Airtel Money';

  @override
  String get cardPayment => 'Card Payment';

  @override
  String get cashOnDelivery => 'Cash on Delivery';

  @override
  String get mtnNumber => 'MTN Number';

  @override
  String get airtelNumber => 'Airtel Number';

  @override
  String get enterMobileNumber => 'Enter mobile money number';

  @override
  String get cardNumber => 'Card Number';

  @override
  String get expiryDate => 'Expiry Date';

  @override
  String get cvv => 'CVV';

  @override
  String get cardHolder => 'Card Holder Name';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get placeOrder => 'Place Order';

  @override
  String get confirmOrder => 'Confirm Order';

  @override
  String get orderPlaced => 'Order Placed Successfully!';

  @override
  String orderNumber(String number) {
    return 'Order #$number';
  }

  @override
  String get trackOrder => 'Track Order';

  @override
  String get viewOrderDetails => 'View Order Details';

  @override
  String get orderStatus => 'Order Status';

  @override
  String get pending => 'Pending';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get processing => 'Processing';

  @override
  String get shipped => 'Shipped';

  @override
  String get outForDelivery => 'Out for Delivery';

  @override
  String get delivered => 'Delivered';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get refunded => 'Refunded';

  @override
  String get myOrders => 'My Orders';

  @override
  String get orderHistory => 'Order History';

  @override
  String get noOrders => 'No orders yet';

  @override
  String get noOrdersMessage => 'Your orders will appear here';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get cancelOrderConfirm =>
      'Are you sure you want to cancel this order?';

  @override
  String get orderCancelled => 'Order cancelled successfully';

  @override
  String get payment => 'Payment';

  @override
  String get paymentStatus => 'Payment Status';

  @override
  String get paymentPending => 'Payment Pending';

  @override
  String get paymentProcessing => 'Processing Payment...';

  @override
  String get paymentSuccessful => 'Payment Successful';

  @override
  String get paymentFailed => 'Payment Failed';

  @override
  String get retryPayment => 'Retry Payment';

  @override
  String get farmerDashboard => 'Farmer Dashboard';

  @override
  String get myProducts => 'My Products';

  @override
  String get addProduct => 'Add Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String get productName => 'Product Name';

  @override
  String get productPrice => 'Product Price';

  @override
  String get productDescription => 'Product Description';

  @override
  String get productCategory => 'Category';

  @override
  String get productImages => 'Product Images';

  @override
  String get uploadImages => 'Upload Images';

  @override
  String get stockQuantity => 'Stock Quantity';

  @override
  String get unitType => 'Unit Type';

  @override
  String get publishProduct => 'Publish Product';

  @override
  String get saveDraft => 'Save as Draft';

  @override
  String get earnings => 'Earnings';

  @override
  String get totalEarnings => 'Total Earnings';

  @override
  String get thisMonth => 'This Month';

  @override
  String get thisWeek => 'This Week';

  @override
  String get today => 'Today';

  @override
  String get pendingPayout => 'Pending Payout';

  @override
  String get withdrawEarnings => 'Withdraw Earnings';

  @override
  String get followers => 'Followers';

  @override
  String get following => 'Following';

  @override
  String get follow => 'Follow';

  @override
  String get unfollow => 'Unfollow';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get farmingAssistant => 'Farming Assistant';

  @override
  String get askQuestion => 'Ask a question...';

  @override
  String get typeMessage => 'Type your message...';

  @override
  String get sendMessage => 'Send';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get takePicture => 'Take Picture';

  @override
  String get uploadPicture => 'Upload Picture';

  @override
  String get analyzeCrop => 'Analyze Crop';

  @override
  String get identifyPest => 'Identify Pest';

  @override
  String get diagnoseProblem => 'Diagnose Problem';

  @override
  String get weather => 'Weather';

  @override
  String get currentWeather => 'Current Weather';

  @override
  String get forecast => 'Forecast';

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get rainfall => 'Rainfall';

  @override
  String get weatherAlerts => 'Weather Alerts';

  @override
  String get settings => 'Settings';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get languageSettings => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get luganda => 'Luganda';

  @override
  String get runyankole => 'Runyankole';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemTheme => 'System Theme';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get aboutUs => 'About Us';

  @override
  String appVersion(String version) {
    return 'App Version $version';
  }

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountWarning =>
      'This action cannot be undone. All your data will be permanently deleted.';

  @override
  String get confirmDelete => 'Yes, Delete My Account';

  @override
  String get loading => 'Loading...';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get share => 'Share';

  @override
  String get copy => 'Copy';

  @override
  String get search => 'Search';

  @override
  String get clear => 'Clear';

  @override
  String get seeAll => 'See All';

  @override
  String get viewMore => 'View More';

  @override
  String get showLess => 'Show Less';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Info';

  @override
  String get networkError => 'Network error. Please check your connection.';

  @override
  String get serverError => 'Server error. Please try again later.';

  @override
  String get unknownError => 'An unknown error occurred.';

  @override
  String get sessionExpired => 'Session expired. Please login again.';

  @override
  String get invalidCredentials => 'Invalid email or password.';

  @override
  String get emailAlreadyExists => 'This email is already registered.';

  @override
  String get weakPassword => 'Password is too weak.';

  @override
  String get invalidEmail => 'Please enter a valid email.';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get invalidPhone => 'Please enter a valid phone number.';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get offlineMode => 'You\'re offline. Some features may be limited.';

  @override
  String get dataWillSync => 'Data will sync when you\'re back online.';

  @override
  String get ugandaShilling => 'UGX';

  @override
  String currency(String amount) {
    return 'UGX $amount';
  }

  @override
  String get kampala => 'Kampala';

  @override
  String get wakiso => 'Wakiso';

  @override
  String get mukono => 'Mukono';

  @override
  String get jinja => 'Jinja';

  @override
  String get entebbe => 'Entebbe';

  @override
  String get mbarara => 'Mbarara';

  @override
  String get gulu => 'Gulu';

  @override
  String get lira => 'Lira';

  @override
  String get mbale => 'Mbale';

  @override
  String get fortPortal => 'Fort Portal';
}
