import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_lg.dart';

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
    Locale('lg'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'AgriSupply'**
  String get appTitle;

  /// The app's main tagline
  ///
  /// In en, this message translates to:
  /// **'Farm Fresh to Your Doorstep'**
  String get appTagline;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to AgriSupply'**
  String get welcomeMessage;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connecting Ugandan Farmers with Buyers'**
  String get welcomeSubtitle;

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

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

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

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhone;

  /// No description provided for @verifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get verifyPhone;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP Code'**
  String get enterOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to {phone}'**
  String otpSent(String phone);

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select your role'**
  String get selectRole;

  /// No description provided for @buyerRole.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyerRole;

  /// No description provided for @buyerRoleDesc.
  ///
  /// In en, this message translates to:
  /// **'I want to buy fresh farm products'**
  String get buyerRoleDesc;

  /// No description provided for @farmerRole.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmerRole;

  /// No description provided for @farmerRoleDesc.
  ///
  /// In en, this message translates to:
  /// **'I want to sell my farm products'**
  String get farmerRoleDesc;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @vegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get vegetables;

  /// No description provided for @fruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get fruits;

  /// No description provided for @grains.
  ///
  /// In en, this message translates to:
  /// **'Grains'**
  String get grains;

  /// No description provided for @dairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get dairy;

  /// No description provided for @meat.
  ///
  /// In en, this message translates to:
  /// **'Meat'**
  String get meat;

  /// No description provided for @poultry.
  ///
  /// In en, this message translates to:
  /// **'Poultry'**
  String get poultry;

  /// No description provided for @fishSeafood.
  ///
  /// In en, this message translates to:
  /// **'Fish & Seafood'**
  String get fishSeafood;

  /// No description provided for @herbsSpices.
  ///
  /// In en, this message translates to:
  /// **'Herbs & Spices'**
  String get herbsSpices;

  /// No description provided for @rootTubers.
  ///
  /// In en, this message translates to:
  /// **'Root & Tubers'**
  String get rootTubers;

  /// No description provided for @otherProducts.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherProducts;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @filterProducts.
  ///
  /// In en, this message translates to:
  /// **'Filter Products'**
  String get filterProducts;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @sortByPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get sortByPriceLow;

  /// No description provided for @sortByPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get sortByPriceHigh;

  /// No description provided for @sortByNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get sortByNewest;

  /// No description provided for @sortByRating.
  ///
  /// In en, this message translates to:
  /// **'Highest Rated'**
  String get sortByRating;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @applyFilter.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get applyFilter;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearFilter;

  /// No description provided for @organic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get organic;

  /// No description provided for @organicCertified.
  ///
  /// In en, this message translates to:
  /// **'Organic Certified'**
  String get organicCertified;

  /// No description provided for @freshPicked.
  ///
  /// In en, this message translates to:
  /// **'Fresh Picked'**
  String get freshPicked;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @itemsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} items left'**
  String itemsLeft(int count);

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @specifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get specifications;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @noReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviews;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get writeReview;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @ratingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ratings'**
  String ratingCount(int count);

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get addedToCart;

  /// No description provided for @removeFromCart.
  ///
  /// In en, this message translates to:
  /// **'Remove from Cart'**
  String get removeFromCart;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @perKg.
  ///
  /// In en, this message translates to:
  /// **'/kg'**
  String get perKg;

  /// No description provided for @perBunch.
  ///
  /// In en, this message translates to:
  /// **'/bunch'**
  String get perBunch;

  /// No description provided for @perPiece.
  ///
  /// In en, this message translates to:
  /// **'/piece'**
  String get perPiece;

  /// No description provided for @perLitre.
  ///
  /// In en, this message translates to:
  /// **'/litre'**
  String get perLitre;

  /// No description provided for @perDozen.
  ///
  /// In en, this message translates to:
  /// **'/dozen'**
  String get perDozen;

  /// No description provided for @perCrate.
  ///
  /// In en, this message translates to:
  /// **'/crate'**
  String get perCrate;

  /// No description provided for @perBag.
  ///
  /// In en, this message translates to:
  /// **'/bag'**
  String get perBag;

  /// No description provided for @shoppingCart.
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get shoppingCart;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add some fresh products to your cart'**
  String get cartEmptyMessage;

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get continueShopping;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @proceedToCheckout.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Checkout'**
  String get proceedToCheckout;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @selectAddress.
  ///
  /// In en, this message translates to:
  /// **'Select Address'**
  String get selectAddress;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addNewAddress;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddress;

  /// No description provided for @deleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Delete Address'**
  String get deleteAddress;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get setAsDefault;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address Label'**
  String get addressLabel;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get streetAddress;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @landmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get landmark;

  /// No description provided for @deliveryInstructions.
  ///
  /// In en, this message translates to:
  /// **'Delivery Instructions'**
  String get deliveryInstructions;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @selectPayment.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPayment;

  /// No description provided for @mtnMobileMoney.
  ///
  /// In en, this message translates to:
  /// **'MTN Mobile Money'**
  String get mtnMobileMoney;

  /// No description provided for @airtelMoney.
  ///
  /// In en, this message translates to:
  /// **'Airtel Money'**
  String get airtelMoney;

  /// No description provided for @cardPayment.
  ///
  /// In en, this message translates to:
  /// **'Card Payment'**
  String get cardPayment;

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get cashOnDelivery;

  /// No description provided for @mtnNumber.
  ///
  /// In en, this message translates to:
  /// **'MTN Number'**
  String get mtnNumber;

  /// No description provided for @airtelNumber.
  ///
  /// In en, this message translates to:
  /// **'Airtel Number'**
  String get airtelNumber;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter mobile money number'**
  String get enterMobileNumber;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @cardHolder.
  ///
  /// In en, this message translates to:
  /// **'Card Holder Name'**
  String get cardHolder;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

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

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed Successfully!'**
  String get orderPlaced;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String orderNumber(String number);

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackOrder;

  /// No description provided for @viewOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'View Order Details'**
  String get viewOrderDetails;

  /// No description provided for @orderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order Status'**
  String get orderStatus;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @shipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get shipped;

  /// No description provided for @outForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get outForDelivery;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrders;

  /// No description provided for @noOrdersMessage.
  ///
  /// In en, this message translates to:
  /// **'Your orders will appear here'**
  String get noOrdersMessage;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @cancelOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order?'**
  String get cancelOrderConfirm;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled successfully'**
  String get orderCancelled;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment Pending'**
  String get paymentPending;

  /// No description provided for @paymentProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing Payment...'**
  String get paymentProcessing;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailed;

  /// No description provided for @retryPayment.
  ///
  /// In en, this message translates to:
  /// **'Retry Payment'**
  String get retryPayment;

  /// No description provided for @farmerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Farmer Dashboard'**
  String get farmerDashboard;

  /// No description provided for @myProducts.
  ///
  /// In en, this message translates to:
  /// **'My Products'**
  String get myProducts;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @productPrice.
  ///
  /// In en, this message translates to:
  /// **'Product Price'**
  String get productPrice;

  /// No description provided for @productDescription.
  ///
  /// In en, this message translates to:
  /// **'Product Description'**
  String get productDescription;

  /// No description provided for @productCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get productCategory;

  /// No description provided for @productImages.
  ///
  /// In en, this message translates to:
  /// **'Product Images'**
  String get productImages;

  /// No description provided for @uploadImages.
  ///
  /// In en, this message translates to:
  /// **'Upload Images'**
  String get uploadImages;

  /// No description provided for @stockQuantity.
  ///
  /// In en, this message translates to:
  /// **'Stock Quantity'**
  String get stockQuantity;

  /// No description provided for @unitType.
  ///
  /// In en, this message translates to:
  /// **'Unit Type'**
  String get unitType;

  /// No description provided for @publishProduct.
  ///
  /// In en, this message translates to:
  /// **'Publish Product'**
  String get publishProduct;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as Draft'**
  String get saveDraft;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @pendingPayout.
  ///
  /// In en, this message translates to:
  /// **'Pending Payout'**
  String get pendingPayout;

  /// No description provided for @withdrawEarnings.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Earnings'**
  String get withdrawEarnings;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @farmingAssistant.
  ///
  /// In en, this message translates to:
  /// **'Farming Assistant'**
  String get farmingAssistant;

  /// No description provided for @askQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a question...'**
  String get askQuestion;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeMessage;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendMessage;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @takePicture.
  ///
  /// In en, this message translates to:
  /// **'Take Picture'**
  String get takePicture;

  /// No description provided for @uploadPicture.
  ///
  /// In en, this message translates to:
  /// **'Upload Picture'**
  String get uploadPicture;

  /// No description provided for @analyzeCrop.
  ///
  /// In en, this message translates to:
  /// **'Analyze Crop'**
  String get analyzeCrop;

  /// No description provided for @identifyPest.
  ///
  /// In en, this message translates to:
  /// **'Identify Pest'**
  String get identifyPest;

  /// No description provided for @diagnoseProblem.
  ///
  /// In en, this message translates to:
  /// **'Diagnose Problem'**
  String get diagnoseProblem;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @currentWeather.
  ///
  /// In en, this message translates to:
  /// **'Current Weather'**
  String get currentWeather;

  /// No description provided for @forecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecast;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @rainfall.
  ///
  /// In en, this message translates to:
  /// **'Rainfall'**
  String get rainfall;

  /// No description provided for @weatherAlerts.
  ///
  /// In en, this message translates to:
  /// **'Weather Alerts'**
  String get weatherAlerts;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @luganda.
  ///
  /// In en, this message translates to:
  /// **'Luganda'**
  String get luganda;

  /// No description provided for @runyankole.
  ///
  /// In en, this message translates to:
  /// **'Runyankole'**
  String get runyankole;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

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

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version {version}'**
  String appVersion(String version);

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data will be permanently deleted.'**
  String get deleteAccountWarning;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete My Account'**
  String get confirmDelete;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

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

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

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

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @viewMore.
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get unknownError;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again.'**
  String get sessionExpired;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get invalidCredentials;

  /// No description provided for @emailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get emailAlreadyExists;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get weakPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email.'**
  String get invalidEmail;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get invalidPhone;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Some features may be limited.'**
  String get offlineMode;

  /// No description provided for @dataWillSync.
  ///
  /// In en, this message translates to:
  /// **'Data will sync when you\'re back online.'**
  String get dataWillSync;

  /// No description provided for @ugandaShilling.
  ///
  /// In en, this message translates to:
  /// **'UGX'**
  String get ugandaShilling;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'UGX {amount}'**
  String currency(String amount);

  /// No description provided for @kampala.
  ///
  /// In en, this message translates to:
  /// **'Kampala'**
  String get kampala;

  /// No description provided for @wakiso.
  ///
  /// In en, this message translates to:
  /// **'Wakiso'**
  String get wakiso;

  /// No description provided for @mukono.
  ///
  /// In en, this message translates to:
  /// **'Mukono'**
  String get mukono;

  /// No description provided for @jinja.
  ///
  /// In en, this message translates to:
  /// **'Jinja'**
  String get jinja;

  /// No description provided for @entebbe.
  ///
  /// In en, this message translates to:
  /// **'Entebbe'**
  String get entebbe;

  /// No description provided for @mbarara.
  ///
  /// In en, this message translates to:
  /// **'Mbarara'**
  String get mbarara;

  /// No description provided for @gulu.
  ///
  /// In en, this message translates to:
  /// **'Gulu'**
  String get gulu;

  /// No description provided for @lira.
  ///
  /// In en, this message translates to:
  /// **'Lira'**
  String get lira;

  /// No description provided for @mbale.
  ///
  /// In en, this message translates to:
  /// **'Mbale'**
  String get mbale;

  /// No description provided for @fortPortal.
  ///
  /// In en, this message translates to:
  /// **'Fort Portal'**
  String get fortPortal;
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
      <String>['en', 'lg'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'lg':
      return AppLocalizationsLg();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
