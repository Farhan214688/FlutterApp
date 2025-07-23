class Service {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isPopular;
  final bool isWeeklyOffer;
  final double discountPercentage;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isPopular = false,
    this.isWeeklyOffer = false,
    this.discountPercentage = 0.0,
  });

  // Create a copy of this service with some fields replaced
  Service copyWith({
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isPopular,
    bool? isWeeklyOffer,
    double? discountPercentage,
  }) {
    return Service(
      id: this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isPopular: isPopular ?? this.isPopular,
      isWeeklyOffer: isWeeklyOffer ?? this.isWeeklyOffer,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }

  // Calculate the discounted price if applicable
  double get finalPrice {
    if (isWeeklyOffer && discountPercentage > 0) {
      return price - (price * discountPercentage / 100);
    }
    return price;
  }
} 