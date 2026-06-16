class UserModel {

  UserModel({
    required this.id,
    required this.email,
    required this.fullName, required this.userType, required this.createdAt, required this.updatedAt, this.phone,
    this.profileImage,
    this.photoUrl,
    this.address,
    this.region,
    this.district,
    this.farmName,
    this.farmDescription,
    this.bio,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.totalProducts,
    this.totalOrders,
    this.isSuspended = false,
  });

  factory UserModel.fromJson(final Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String,
      userType: (json['role'] ?? json['user_type']) as String,
      profileImage: json['profile_image'] as String?,
      photoUrl: json['photo_url'] as String? ?? json['profile_image'] as String?,
      address: json['address_line'] as String? ?? json['address'] as String?,
      region: json['region'] as String?,
      district: json['district'] as String?,
      farmName: json['farm_name'] as String?,
      farmDescription: json['farm_description'] as String? ?? json['bio'] as String?,
      bio: json['bio'] as String? ?? json['farm_description'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      isVerified: json['is_verified'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      premiumExpiresAt: json['premium_expires_at'] != null
          ? DateTime.parse(json['premium_expires_at'] as String)
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      totalProducts: json['total_products'] as int?,
      totalOrders: json['total_orders'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isSuspended: json['is_suspended'] as bool? ?? false,
    );
  }
  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final String userType; // 'farmer', 'buyer', 'admin'
  final String? profileImage;
  final String? photoUrl;
  final String? address;
  final String? region;
  final String? district;
  final String? farmName;
  final String? farmDescription;
  final String? bio;
  final double? latitude;
  final double? longitude;
  final bool isVerified;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final double rating;
  final int totalRatings;
  final int? totalProducts;
  final int? totalOrders;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSuspended;

  /// Alias for userType - provides compatibility with code using 'role'
  String get role => userType;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'role': userType,
      'profile_image': profileImage,
      'photo_url': photoUrl,
      'address_line': address,
      'address': address,
      'region': region,
      'district': district,
      'farm_name': farmName,
      'farm_description': farmDescription,
      'bio': bio,
      'latitude': latitude,
      'longitude': longitude,
      'is_verified': isVerified,
      'is_premium': isPremium,
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'rating': rating,
      'total_ratings': totalRatings,
      'total_products': totalProducts,
      'total_orders': totalOrders,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_suspended': isSuspended,
    };
  }

  UserModel copyWith({
    final String? id,
    final String? email,
    final String? phone,
    final String? fullName,
    final String? userType,
    final String? profileImage,
    final String? photoUrl,
    final String? address,
    final String? region,
    final String? district,
    final String? farmName,
    final String? farmDescription,
    final String? bio,
    final double? latitude,
    final double? longitude,
    final bool? isVerified,
    final bool? isPremium,
    final DateTime? premiumExpiresAt,
    final double? rating,
    final int? totalRatings,
    final int? totalProducts,
    final int? totalOrders,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final bool? isSuspended,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      userType: userType ?? this.userType,
      profileImage: profileImage ?? this.profileImage,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      region: region ?? this.region,
      district: district ?? this.district,
      farmName: farmName ?? this.farmName,
      farmDescription: farmDescription ?? this.farmDescription,
      bio: bio ?? this.bio,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalProducts: totalProducts ?? this.totalProducts,
      totalOrders: totalOrders ?? this.totalOrders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSuspended: isSuspended ?? this.isSuspended,
    );
  }

  bool get isFarmer => userType == 'farmer';
  bool get isBuyer => userType == 'buyer';
  bool get isAdmin => userType == 'admin';
}

/// Enum for user types - can be used for type checking
enum UserType {
  farmer,
  buyer,
  admin,
}

/// UserRole class with static String constants for role values
class UserRole {

  UserRole._();
  static const String farmer = 'farmer';
  static const String buyer = 'buyer';
  static const String admin = 'admin'; // Private constructor to prevent instantiation
}
