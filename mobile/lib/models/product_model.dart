class ProductModel {

  ProductModel({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.name, required this.description, required this.category, required this.price, required this.unit, required this.quantity, required this.availableQuantity, required this.images, required this.harvestDate, required this.createdAt, required this.updatedAt, this.farmerImage,
    this.farmerRating = 0.0,
    this.farmerVerified = false,
    this.region,
    this.district,
    this.isOrganic = false,
    this.isFeatured = false,
    this.isActive = true,
    this.expiryDate,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.totalSold = 0,
    this.status = 'active',
    this.views = 0,
  });

  factory ProductModel.fromJson(final Map<String, dynamic> json) {
    final quantityValue = json['quantity'] ?? json['quantity_available'] ?? json['available_quantity'] ?? 0;
    final availableQuantityValue = json['quantity_available'] ?? json['available_quantity'] ?? json['quantity'] ?? 0;
    final farmerData = json['farmer'] as Map<String, dynamic>?;
    final harvestDateRaw = json['harvest_date'] as String?;
    final createdAtRaw = json['created_at'] as String?;
    final fallbackDate = createdAtRaw ?? DateTime.now().toIso8601String();

    return ProductModel(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      farmerName: json['farmer_name'] as String? ?? farmerData?['full_name'] as String? ?? 'Unknown Farmer',
      farmerImage: json['farmer_image'] as String?,
      farmerRating: (json['farmer_rating'] as num?)?.toDouble() ?? 0.0,
      farmerVerified: json['farmer_verified'] as bool? ?? farmerData?['is_verified'] as bool? ?? false,
      name: json['name'] as String,
      description: json['description'] as String,
      category: ProductCategory.fromId(json['category'] as String), // Convert from backend ID
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
      quantity: (quantityValue as num).toDouble(),
      availableQuantity: (availableQuantityValue as num).toDouble(),
      images: (json['images'] as List?)?.cast<String>() ?? [],
      region: json['region'] as String? ?? farmerData?['region'] as String?,
      district: json['district'] as String? ?? farmerData?['district'] as String?,
      isOrganic: json['is_organic'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      harvestDate: DateTime.parse(harvestDateRaw ?? fallbackDate),
      expiryDate:
          json['expiry_date'] != null
              ? DateTime.parse(json['expiry_date'] as String)
              : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      totalSold: json['total_sold'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      status: json['status'] as String? ?? 'active',
      views: json['views_count'] as int? ?? json['views'] as int? ?? 0,
    );
  }

  /// Creates an empty ProductModel for use as a default value
  factory ProductModel.empty() {
    final now = DateTime.now();
    return ProductModel(
      id: '',
      farmerId: '',
      farmerName: '',
      name: '',
      description: '',
      category: '',
      price: 0,
      unit: 'kg',
      quantity: 0,
      availableQuantity: 0,
      images: [],
      harvestDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }
  final String id;
  final String farmerId;
  final String farmerName;
  final String? farmerImage;
  final double farmerRating;
  final bool farmerVerified;
  final String name;
  final String description;
  final String category;
  final double price;
  final String unit; // kg, bunch, piece, etc.
  final double quantity;
  final double availableQuantity;
  final List<String> images;
  final String? region;
  final String? district;
  final bool isOrganic;
  final bool isFeatured;
  final bool isActive;
  final DateTime harvestDate;
  final DateTime? expiryDate;
  final double rating;
  final int totalRatings;
  final int totalSold;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final int views;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'farmer_name': farmerName,
      'farmer_image': farmerImage,
      'farmer_rating': farmerRating,
      'farmer_verified': farmerVerified,
      'name': name,
      'description': description,
      'category': ProductCategory.toId(category), // Convert to backend ID
      'price': price,
      'unit': ProductUnit.toBackend(unit),
      'quantity': quantity,
      'quantity_available': availableQuantity,
      'images': images,
      'region': region,
      'district': district,
      'is_organic': isOrganic,
      'is_featured': isFeatured,
      'is_active': isActive,
      'harvest_date': harvestDate.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'rating': rating,
      'total_ratings': totalRatings,
      'total_sold': totalSold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status,
      'views_count': views,
    };
  }

  // Alias for farmerImage for backward compatibility
  String? get farmerPhoto => farmerImage;

  ProductModel copyWith({
    final String? id,
    final String? farmerId,
    final String? farmerName,
    final String? farmerImage,
    final double? farmerRating,
    final bool? farmerVerified,
    final String? name,
    final String? description,
    final String? category,
    final double? price,
    final String? unit,
    final double? quantity,
    final double? availableQuantity,
    final List<String>? images,
    final String? region,
    final String? district,
    final bool? isOrganic,
    final bool? isFeatured,
    final bool? isActive,
    final DateTime? harvestDate,
    final DateTime? expiryDate,
    final double? rating,
    final int? totalRatings,
    final int? totalSold,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final String? status,
    final int? views,
  }) {
    return ProductModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      farmerImage: farmerImage ?? this.farmerImage,
      farmerRating: farmerRating ?? this.farmerRating,
      farmerVerified: farmerVerified ?? this.farmerVerified,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      images: images ?? this.images,
      region: region ?? this.region,
      district: district ?? this.district,
      isOrganic: isOrganic ?? this.isOrganic,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      harvestDate: harvestDate ?? this.harvestDate,
      expiryDate: expiryDate ?? this.expiryDate,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalSold: totalSold ?? this.totalSold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      views: views ?? this.views,
    );
  }

  String get displayPrice => 'UGX ${price.toStringAsFixed(0)}/$unit';
  bool get isAvailable => availableQuantity > 0 && isActive;
  String get primaryImage => images.isNotEmpty ? images.first : '';
}

class ProductCategory {
  static const String vegetables = 'Vegetables';
  static const String fruits = 'Fruits';
  static const String grains = 'Grains & Cereals';
  static const String legumes = 'Legumes';
  static const String tubers = 'Tubers & Roots';
  static const String dairy = 'Dairy Products';
  static const String poultry = 'Poultry & Eggs';
  static const String meat = 'Meat';
  static const String fish = 'Fish & Seafood';
  static const String herbs = 'Herbs & Spices';
  static const String nuts = 'Nuts & Seeds';
  static const String honey = 'Honey & Bee Products';
  static const String beverages = 'Beverages';
  static const String other = 'Other';

  static List<String> get all => [
    vegetables,
    fruits,
    grains,
    legumes,
    tubers,
    dairy,
    poultry,
    meat,
    fish,
    herbs,
    nuts,
    honey,
    beverages,
    other,
  ];

  // Convert display name to backend ID
  static String toId(final String displayName) {
    switch (displayName) {
      case vegetables:
        return 'vegetables';
      case fruits:
        return 'fruits';
      case grains:
        return 'grains';
      case legumes:
        return 'legumes';
      case tubers:
        return 'tubers';
      case dairy:
        return 'dairy';
      case poultry:
        return 'meat'; // Backend combines meat & poultry
      case meat:
        return 'meat';
      case fish:
        return 'fish';
      case herbs:
        return 'spices'; // Backend uses 'spices' for herbs & spices
      case nuts:
        return 'other'; // Backend doesn't have nuts category
      case honey:
        return 'other'; // Backend doesn't have honey category
      case beverages:
        return 'coffee'; // Backend uses 'coffee' for beverages
      case other:
        return 'other';
      default:
        return 'other';
    }
  }

  // Convert backend ID to display name
  static String fromId(final String id) {
    switch (id) {
      case 'vegetables':
        return vegetables;
      case 'fruits':
        return fruits;
      case 'grains':
        return grains;
      case 'legumes':
        return legumes;
      case 'tubers':
        return tubers;
      case 'dairy':
        return dairy;
      case 'meat':
        return meat;
      case 'fish':
        return fish;
      case 'spices':
        return herbs;
      case 'coffee':
        return beverages;
      case 'other':
        return other;
      default:
        return other;
    }
  }

  static String getIcon(final String category) {
    switch (category) {
      case vegetables:
        return '🥬';
      case fruits:
        return '🍎';
      case grains:
        return '🌾';
      case legumes:
        return '🫘';
      case tubers:
        return '🥔';
      case dairy:
        return '🥛';
      case poultry:
        return '🥚';
      case meat:
        return '🥩';
      case fish:
        return '🐟';
      case herbs:
        return '🌿';
      case nuts:
        return '🥜';
      case honey:
        return '🍯';
      case beverages:
        return '🧃';
      default:
        return '📦';
    }
  }
}

class ProductUnit {
  static const String kg = 'kg';
  static const String gram = 'g';
  static const String piece = 'piece';
  static const String bunch = 'bunch';
  static const String basket = 'basket';
  static const String bag = 'bag';
  static const String crate = 'crate';
  static const String liter = 'liter';
  static const String dozen = 'dozen';
  static const String tray = 'tray';

  static List<String> get all => [
    kg,
    gram,
    piece,
    bunch,
    basket,
    bag,
    crate,
    liter,
    dozen,
    tray,
  ];

  static String toBackend(final String unit) {
    switch (unit) {
      case basket:
        return crate;
      case tray:
        return dozen;
      default:
        return unit;
    }
  }
}

class ProductStatus {
  static const String active = 'active';
  static const String inactive = 'inactive';
  static const String outOfStock = 'out_of_stock';
  static const String pending = 'pending';
  static const String rejected = 'rejected';

  static List<String> get all => [
    active,
    inactive,
    outOfStock,
    pending,
    rejected,
  ];
}
