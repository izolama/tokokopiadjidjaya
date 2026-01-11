import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.weightGram,
    required this.tastingNotes,
    required this.story,
    required this.active,
    required this.imageUrls,
    required this.createdAt,
  });

  final String id;
  final String name;
  final num price;
  final num weightGram;
  final List<String> tastingNotes;
  final String story;
  final bool active;
  final List<String> imageUrls;
  final DateTime createdAt;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Product(
      id: doc.id,
      name: data['name'] as String? ?? '',
      price: data['price'] as num? ?? 0,
      weightGram: data['weightGram'] as num? ?? 0,
      tastingNotes: List<String>.from(data['tastingNotes'] as List? ?? []),
      story: data['story'] as String? ?? '',
      active: data['active'] as bool? ?? true,
      imageUrls: _parseImageUrls(data['imageUrl']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'weightGram': weightGram,
      'tastingNotes': tastingNotes,
      'story': story,
      'active': active,
      'imageUrl': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static List<String> _parseImageUrls(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return [];
  }
}
