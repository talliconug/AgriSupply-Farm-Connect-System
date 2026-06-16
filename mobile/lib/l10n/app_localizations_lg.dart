// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ganda Luganda (`lg`).
class AppLocalizationsLg extends AppLocalizations {
  AppLocalizationsLg([String locale = 'lg']) : super(locale);

  @override
  String get appTitle => 'AgriSupply';

  @override
  String get appTagline => 'Okuva mu nnimiro Okutuuka ku Luggi Lwo';

  @override
  String get welcomeMessage => 'Tukusanidde mu AgriSupply';

  @override
  String get welcomeSubtitle => 'Tukugatta Abalimi ba Uganda n\'Abasubuzi';

  @override
  String get login => 'Yingira';

  @override
  String get register => 'Wandiika';

  @override
  String get logout => 'Fuluma';

  @override
  String get email => 'Email';

  @override
  String get password => 'Ekikuumi';

  @override
  String get confirmPassword => 'Kakasa Ekikuumi';

  @override
  String get forgotPassword => 'Wereze Ekikuumi?';

  @override
  String get resetPassword => 'Ddamu Ekikuumi';

  @override
  String get sendResetLink => 'Sindika Link y\'Okuddamu';

  @override
  String get fullName => 'Erinnya Lyo Lyonna';

  @override
  String get phoneNumber => 'Ennamba ya Simu';

  @override
  String get enterPhone => 'Wandika ennamba y\'essimu yo';

  @override
  String get verifyPhone => 'Kakasa Essimu';

  @override
  String get enterOtp => 'Wandika Ennamba OTP';

  @override
  String get resendOtp => 'Ddamu Sindika OTP';

  @override
  String otpSent(String phone) {
    return 'OTP esindikiddwa ku $phone';
  }

  @override
  String get selectRole => 'Londa omulimu gwo';

  @override
  String get buyerRole => 'Omuguzi';

  @override
  String get buyerRoleDesc => 'Njagala okugula eby\'okulya ebya bulijjo';

  @override
  String get farmerRole => 'Omulimi';

  @override
  String get farmerRoleDesc => 'Njagala okutunda ebivundu byange';

  @override
  String get home => 'Awaka';

  @override
  String get products => 'Ebintu';

  @override
  String get cart => 'Entamu';

  @override
  String get orders => 'Endagaano';

  @override
  String get profile => 'Ebinkukwatako';

  @override
  String get favorites => 'Ebisinga';

  @override
  String get notifications => 'Amawulire';

  @override
  String get categories => 'Ebika';

  @override
  String get allCategories => 'Ebika Byonna';

  @override
  String get vegetables => 'Enva';

  @override
  String get fruits => 'Ebibala';

  @override
  String get grains => 'Empeke';

  @override
  String get dairy => 'Ebiva mu Nte';

  @override
  String get meat => 'Ennyama';

  @override
  String get poultry => 'Enkoko';

  @override
  String get fishSeafood => 'Ebyennyanja';

  @override
  String get herbsSpices => 'Ebivundu n\'Obumba';

  @override
  String get rootTubers => 'Ebirimu Emirandira';

  @override
  String get otherProducts => 'Ebilala';

  @override
  String get searchProducts => 'Noonya ebintu...';

  @override
  String get filterProducts => 'Londera Ebintu';

  @override
  String get sortBy => 'Teeka Mu Nteekateeka';

  @override
  String get sortByPriceLow => 'Bbeeyi: Entono Okutuuka ku Nene';

  @override
  String get sortByPriceHigh => 'Bbeeyi: Nene Okutuuka ku Ntono';

  @override
  String get sortByNewest => 'Ebipya Byasooka';

  @override
  String get sortByRating => 'Ebisinze Okusiimibwa';

  @override
  String get priceRange => 'Omugaso';

  @override
  String get minPrice => 'Omugaso Omutono';

  @override
  String get maxPrice => 'Omugaso Omunene';

  @override
  String get applyFilter => 'Kozesa Ekilondera';

  @override
  String get clearFilter => 'Jjamu Byonna';

  @override
  String get organic => 'Eyabulijjo';

  @override
  String get organicCertified => 'Eyakakasibwa Eyabulijjo';

  @override
  String get freshPicked => 'Ekizibide Olwaleero';

  @override
  String get inStock => 'Kiriwo';

  @override
  String get outOfStock => 'Tewali';

  @override
  String get lowStock => 'Bisigadde Bitono';

  @override
  String itemsLeft(int count) {
    return 'Bisigadde $count';
  }

  @override
  String get productDetails => 'Ebikukwatako';

  @override
  String get description => 'Ennyonyola';

  @override
  String get specifications => 'Ebifaananyi';

  @override
  String get reviews => 'Endowooza';

  @override
  String get noReviews => 'Tewali ndowooza';

  @override
  String get writeReview => 'Wandika Endowooza';

  @override
  String get rating => 'Omuwendo';

  @override
  String ratingCount(int count) {
    return 'Omuwendo $count';
  }

  @override
  String get addToCart => 'Gattako ku Ntamu';

  @override
  String get addedToCart => 'Kigattidwako ku ntamu';

  @override
  String get removeFromCart => 'Kiggyeko ku Ntamu';

  @override
  String get buyNow => 'Gula Kati';

  @override
  String get quantity => 'Obungi';

  @override
  String get unitPrice => 'Bbeeyi y\'Ekimu';

  @override
  String get total => 'Omuwendo Gwonna';

  @override
  String get perKg => '/kg';

  @override
  String get perBunch => '/ekibbo';

  @override
  String get perPiece => '/ekitundu';

  @override
  String get perLitre => '/lita';

  @override
  String get perDozen => '/kumi na bibiri';

  @override
  String get perCrate => '/entamu';

  @override
  String get perBag => '/ensawo';

  @override
  String get shoppingCart => 'Entamu y\'Ebigula';

  @override
  String get cartEmpty => 'Entamu yo njereere';

  @override
  String get cartEmptyMessage => 'Gattako ebintu ebipya ku ntamu yo';

  @override
  String get continueShopping => 'Komeza Okugula';

  @override
  String get subtotal => 'Omutongole';

  @override
  String get deliveryFee => 'Ssente z\'Okuleeta';

  @override
  String get grandTotal => 'Omuwendo Gwonna';

  @override
  String get proceedToCheckout => 'Genda mu Kusasula';

  @override
  String get checkout => 'Sasula';

  @override
  String get deliveryAddress => 'Endabirira y\'Okuleeta';

  @override
  String get selectAddress => 'Londa Endabirira';

  @override
  String get addNewAddress => 'Gattako Endabirira Empya';

  @override
  String get editAddress => 'Kyusa Endabirira';

  @override
  String get deleteAddress => 'Sang\'a Endabirira';

  @override
  String get setAsDefault => 'Tekamu Engeri';

  @override
  String get addressLabel => 'Erinnya ly\'Endabirira';

  @override
  String get streetAddress => 'Endabirira y\'Oluguudo';

  @override
  String get city => 'Ekibuga';

  @override
  String get district => 'Disitulikiti';

  @override
  String get region => 'Ekitundu';

  @override
  String get landmark => 'Ekifo ekizaawa';

  @override
  String get deliveryInstructions => 'Ebiragiro by\'Okuleeta';

  @override
  String get paymentMethod => 'Enkola y\'Okusasula';

  @override
  String get selectPayment => 'Londa Enkola y\'Okusasula';

  @override
  String get mtnMobileMoney => 'MTN Mobile Money';

  @override
  String get airtelMoney => 'Airtel Money';

  @override
  String get cardPayment => 'Kaadi';

  @override
  String get cashOnDelivery => 'Ssente Bw\'oleeta';

  @override
  String get mtnNumber => 'Ennamba ya MTN';

  @override
  String get airtelNumber => 'Ennamba ya Airtel';

  @override
  String get enterMobileNumber => 'Wandika ennamba ya mobile money';

  @override
  String get cardNumber => 'Ennamba ya Kaadi';

  @override
  String get expiryDate => 'Olunaku lw\'Okuggwa';

  @override
  String get cvv => 'CVV';

  @override
  String get cardHolder => 'Erinnya lya Nannyini Kaadi';

  @override
  String get orderSummary => 'Enkola y\'Endagaano';

  @override
  String get placeOrder => 'Teekawo Endagaano';

  @override
  String get confirmOrder => 'Kakasa Endagaano';

  @override
  String get orderPlaced => 'Endagaano Etaddewo Obulungi!';

  @override
  String orderNumber(String number) {
    return 'Endagaano #$number';
  }

  @override
  String get trackOrder => 'Goberera Endagaano';

  @override
  String get viewOrderDetails => 'Laba Ebikukwatako by\'Endagaano';

  @override
  String get orderStatus => 'Embeera y\'Endagaano';

  @override
  String get pending => 'Erina';

  @override
  String get confirmed => 'Ekakasiddwa';

  @override
  String get processing => 'Etekawo';

  @override
  String get shipped => 'Etumiddwa';

  @override
  String get outForDelivery => 'Eri mu Kkubo';

  @override
  String get delivered => 'Evudde';

  @override
  String get cancelled => 'Ejijibbwa';

  @override
  String get refunded => 'Ssente Ziddiziddwa';

  @override
  String get myOrders => 'Endagaano Zange';

  @override
  String get orderHistory => 'Ebyafaayo by\'Endagaano';

  @override
  String get noOrders => 'Tewali ndagaano';

  @override
  String get noOrdersMessage => 'Endagaano zo zirijja wano';

  @override
  String get cancelOrder => 'Jjijja Endagaano';

  @override
  String get cancelOrderConfirm => 'Oli mukakafu okujjijja endagaano eno?';

  @override
  String get orderCancelled => 'Endagaano ejjijjiddwa obulungi';

  @override
  String get payment => 'Okusasula';

  @override
  String get paymentStatus => 'Embeera y\'Okusasula';

  @override
  String get paymentPending => 'Okusasula Kwerina';

  @override
  String get paymentProcessing => 'Okusasula Kukoleddwa...';

  @override
  String get paymentSuccessful => 'Okusasula Kukomekeddwa Obulungi';

  @override
  String get paymentFailed => 'Okusasula Kuvudde';

  @override
  String get retryPayment => 'Ddamu Okusasula';

  @override
  String get farmerDashboard => 'Essaabbo ly\'Omulimi';

  @override
  String get myProducts => 'Ebintu Byange';

  @override
  String get addProduct => 'Gattako Ekitundu';

  @override
  String get editProduct => 'Kyusa Ekitundu';

  @override
  String get deleteProduct => 'Sangula Ekitundu';

  @override
  String get productName => 'Erinnya ly\'Ekitundu';

  @override
  String get productPrice => 'Bbeeyi y\'Ekitundu';

  @override
  String get productDescription => 'Ennyonyola y\'Ekitundu';

  @override
  String get productCategory => 'Ekika';

  @override
  String get productImages => 'Ebifaananyi by\'Ekitundu';

  @override
  String get uploadImages => 'Teeka Ebifaananyi';

  @override
  String get stockQuantity => 'Obungi bw\'Ekitundu';

  @override
  String get unitType => 'Engeri y\'Ekitundu';

  @override
  String get publishProduct => 'Fulumya Ekitundu';

  @override
  String get saveDraft => 'Tereka nga Draft';

  @override
  String get earnings => 'Emiganyulo';

  @override
  String get totalEarnings => 'Emiganyulo Gyonna';

  @override
  String get thisMonth => 'Omwezi Guno';

  @override
  String get thisWeek => 'Wiiki Eno';

  @override
  String get today => 'Olwaleero';

  @override
  String get pendingPayout => 'Emiganyulo Erina';

  @override
  String get withdrawEarnings => 'Ggya Emiganyulo';

  @override
  String get followers => 'Abagoberera';

  @override
  String get following => 'Ogoberera';

  @override
  String get follow => 'Goberera';

  @override
  String get unfollow => 'Leka Okugoberera';

  @override
  String get viewProfile => 'Laba Ebikukwatako';

  @override
  String get aiAssistant => 'Omuyambi wa AI';

  @override
  String get farmingAssistant => 'Omuyambi w\'Okulima';

  @override
  String get askQuestion => 'Buuza ekibuuzo...';

  @override
  String get typeMessage => 'Wandika obubaka bwo...';

  @override
  String get sendMessage => 'Sindika';

  @override
  String get analyzing => 'Kwekeneenya...';

  @override
  String get takePicture => 'Kwata Ekifaananyi';

  @override
  String get uploadPicture => 'Teeka Ekifaananyi';

  @override
  String get analyzeCrop => 'Keneenya Ekimera';

  @override
  String get identifyPest => 'Manya Ekiwuka';

  @override
  String get diagnoseProblem => 'Manya Obuzibu';

  @override
  String get weather => 'Obudde';

  @override
  String get currentWeather => 'Obudde bwa Kati';

  @override
  String get forecast => 'Obulagula bw\'Obudde';

  @override
  String get temperature => 'Ebbugumu';

  @override
  String get humidity => 'Okunywa';

  @override
  String get rainfall => 'Enkuba';

  @override
  String get weatherAlerts => 'Amawulire g\'Obudde';

  @override
  String get settings => 'Entegeka';

  @override
  String get accountSettings => 'Entegeka z\'Akawunti';

  @override
  String get notificationSettings => 'Entegeka z\'Amawulire';

  @override
  String get languageSettings => 'Olulimi';

  @override
  String get selectLanguage => 'Londa Olulimi';

  @override
  String get english => 'Olungereza';

  @override
  String get luganda => 'Oluganda';

  @override
  String get runyankole => 'Runyankole';

  @override
  String get darkMode => 'Ekizikiza';

  @override
  String get lightMode => 'Obutangaavu';

  @override
  String get systemTheme => 'Engeri ya System';

  @override
  String get privacyPolicy => 'Enkola y\'Ebyama';

  @override
  String get termsOfService => 'Enkolagana';

  @override
  String get helpCenter => 'Obuyambi';

  @override
  String get contactSupport => 'Tugatteko';

  @override
  String get aboutUs => 'Ebife';

  @override
  String appVersion(String version) {
    return 'Vaasiyo $version';
  }

  @override
  String get deleteAccount => 'Sangula Akawunti';

  @override
  String get deleteAccountWarning =>
      'Kino tekisobola kuddizibwa. Ebikukwatako byonna bijja kusangulwa.';

  @override
  String get confirmDelete => 'Yee, Sangula Akawunti Yange';

  @override
  String get loading => 'Kiteekwa...';

  @override
  String get pleaseWait => 'Lindako...';

  @override
  String get refresh => 'Ddamu';

  @override
  String get retry => 'Gezaako Nate';

  @override
  String get save => 'Tereka';

  @override
  String get cancel => 'Sazaamu';

  @override
  String get confirm => 'Kakasa';

  @override
  String get done => 'Biwedde';

  @override
  String get next => 'Ekiddako';

  @override
  String get back => 'Emabega';

  @override
  String get skip => 'Buuka';

  @override
  String get close => 'Ggalawo';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yee';

  @override
  String get no => 'Nedda';

  @override
  String get edit => 'Kyusa';

  @override
  String get delete => 'Sangula';

  @override
  String get share => 'Gabana';

  @override
  String get copy => 'Koppa';

  @override
  String get search => 'Noonya';

  @override
  String get clear => 'Jjamu';

  @override
  String get seeAll => 'Laba Byonna';

  @override
  String get viewMore => 'Laba Ebisingako';

  @override
  String get showLess => 'Laba Bitono';

  @override
  String get error => 'Ensobi';

  @override
  String get success => 'Kiwedde Bulungi';

  @override
  String get warning => 'Okulabula';

  @override
  String get info => 'Amawulire';

  @override
  String get networkError => 'Ensobi y\'omukutu. Kebera okunyunyuza kwo.';

  @override
  String get serverError => 'Ensobi ya sevva. Gezaako nate oluvannyuma.';

  @override
  String get unknownError => 'Ensobi etamanyiddwa ebaddewo.';

  @override
  String get sessionExpired => 'Ssesiyo ewedde. Yingira nate.';

  @override
  String get invalidCredentials => 'Email oba password si ya butuufu.';

  @override
  String get emailAlreadyExists => 'Email eno ewandikiddwa dda.';

  @override
  String get weakPassword => 'Password ya nafu.';

  @override
  String get invalidEmail => 'Wandika email ya mazima.';

  @override
  String get requiredField => 'Kino kyetaagisa.';

  @override
  String get invalidPhone => 'Wandika ennamba y\'essimu ya mazima.';

  @override
  String get noInternetConnection => 'Tewali mukutu';

  @override
  String get offlineMode => 'Oli offline. Ebintu ebimu bisobola obutakola.';

  @override
  String get dataWillSync => 'Ebintu bijja okukwatagana bw\'oddayo online.';

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
