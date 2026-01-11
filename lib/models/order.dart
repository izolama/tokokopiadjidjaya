import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.qty,
    required this.price,
  });

  final String productId;
  final String name;
  final int qty;
  final num price;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'qty': qty,
      'price': price,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['productId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      qty: data['qty'] as int? ?? 1,
      price: data['price'] as num? ?? 0,
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.paymentMethod,
    required this.lastOrderDate,
    required this.proofImageUrl,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final List<OrderItem> items;
  final num totalPrice;
  final String status;
  final String paymentMethod;
  final DateTime lastOrderDate;
  final String? proofImageUrl;
  final DateTime createdAt;

  factory Order.fromDoc(
    firestore.DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return Order(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      items: (data['items'] as List? ?? [])
          .map((item) => OrderItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      totalPrice: data['totalPrice'] as num? ?? 0,
      status: data['status'] as String? ?? 'PENDING_PAYMENT',
      paymentMethod: data['paymentMethod'] as String? ?? 'WHATSAPP',
      lastOrderDate: (data['lastOrderDate'] as firestore.Timestamp?)?.toDate() ??
          DateTime.now(),
      proofImageUrl: data['proofImageUrl'] as String?,
      createdAt:
          (data['createdAt'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
