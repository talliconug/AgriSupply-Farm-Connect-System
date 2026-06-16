class ReviewModel {

  ReviewModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.farmerId,
    required this.buyerId,
    required this.buyerName,
    required this.rating, required this.createdAt, required this.updatedAt, this.buyerImage,
    this.comment,
    this.images,
    this.farmerReply,
    this.replyAt,
  });

  factory ReviewModel.fromJson(final Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      farmerId: json['farmer_id'] as String,
      buyerId: json['buyer_id'] as String,
      buyerName: json['buyer_name'] as String,
      buyerImage: json['buyer_image'] as String?,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      images: json['images'] != null ? (json['images'] as List).cast<String>() : null,
      farmerReply: json['farmer_reply'] as String?,
      replyAt: json['reply_at'] != null
          ? DateTime.parse(json['reply_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  final String id;
  final String orderId;
  final String productId;
  final String farmerId;
  final String buyerId;
  final String buyerName;
  final String? buyerImage;
  final double rating;
  final String? comment;
  final List<String>? images;
  final String? farmerReply;
  final DateTime? replyAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'farmer_id': farmerId,
      'buyer_id': buyerId,
      'buyer_name': buyerName,
      'buyer_image': buyerImage,
      'rating': rating,
      'comment': comment,
      'images': images,
      'farmer_reply': farmerReply,
      'reply_at': replyAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
