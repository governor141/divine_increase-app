import 'package:cloud_firestore/cloud_firestore.dart';

/// A regular business listing, from the `businesses` Firestore collection.
/// Only documents with status == "approved" should ever be shown to users
/// — anything else is pending review or was rejected.
class Business {
  final String id;
  final String businessName;
  final String businessCategory;
  final String description;
  final String location;
  final String phone;
  final String email;
  final String logo;
  final String cover;
  final List<String> photos;
  final String status;

  const Business({
    required this.id,
    required this.businessName,
    required this.businessCategory,
    required this.description,
    required this.location,
    required this.phone,
    required this.email,
    required this.logo,
    required this.cover,
    required this.photos,
    required this.status,
  });

  factory Business.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Business(
      id: doc.id,
      businessName: (data['businessName'] ?? '') as String,
      businessCategory: (data['businessCategory'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      location: (data['location'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      logo: (data['logo'] ?? '') as String,
      cover: (data['cover'] ?? '') as String,
      photos: List<String>.from((data['photos'] as List?) ?? const []),
      status: (data['status'] ?? '') as String,
    );
  }

  /// The best available image to show for this business — falls back
  /// from logo, to cover, to the first gallery photo, to nothing.
  String get displayImage {
    if (logo.isNotEmpty) return logo;
    if (cover.isNotEmpty) return cover;
    if (photos.isNotEmpty) return photos.first;
    return '';
  }
}

/// A sponsored/featured listing, from the `featuredBusinesses` collection.
/// This is a separate system from regular businesses — these are
/// time-limited adverts (they carry an expiresAt) rather than permanent
/// directory profiles.
class FeaturedBusiness {
  final String id;
  final String name;
  final String category;
  final String description;
  final String location;
  final String phone;
  final String imageUrl;
  final bool isAdvert;
  final DateTime? expiresAt;

  const FeaturedBusiness({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    required this.phone,
    required this.imageUrl,
    required this.isAdvert,
    this.expiresAt,
  });

  factory FeaturedBusiness.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return FeaturedBusiness(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      location: (data['location'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? '') as String,
      isAdvert: (data['isAdvert'] ?? false) as bool,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }
}
