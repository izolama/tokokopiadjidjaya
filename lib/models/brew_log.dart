import 'package:cloud_firestore/cloud_firestore.dart';

class BrewLog {
  const BrewLog({
    required this.id,
    required this.userId,
    required this.productId,
    required this.brewMethod,
    required this.rating,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String productId;
  final String brewMethod;
  final int rating;
  final String note;
  final DateTime createdAt;

  factory BrewLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BrewLog(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      productId: data['productId'] as String? ?? '',
      brewMethod: data['brewMethod'] as String? ?? '',
      rating: data['rating'] as int? ?? 0,
      note: data['note'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'brewMethod': brewMethod,
      'rating': rating,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
