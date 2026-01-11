import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/coffee_profile.dart';
import '../models/brew_log.dart';
import '../models/order.dart';
import '../models/product.dart';

class FirestoreService {
  FirestoreService(this._firestore);

  final firestore.FirebaseFirestore _firestore;

  firestore.CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  firestore.CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');
  firestore.CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');
  firestore.CollectionReference<Map<String, dynamic>> get _brewLogs =>
      _firestore.collection('brew_logs');

  Future<void> ensureUserDocument(User user) async {
    final doc = _users.doc(user.uid);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      await doc.set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  Future<CoffeeProfile?> fetchCoffeeProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    if (data == null || data['coffeeProfile'] == null) {
      return null;
    }
    return CoffeeProfile.fromMap(
      Map<String, dynamic>.from(data['coffeeProfile'] as Map),
    );
  }

  Future<void> saveCoffeeProfile(String uid, CoffeeProfile profile) async {
    await _users.doc(uid).set(
      {
        'coffeeProfile': profile.toMap(),
      },
      firestore.SetOptions(merge: true),
    );
  }

  Stream<List<Product>> watchActiveProducts() {
    return _products
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map<Product>((doc) => Product.fromDoc(doc)).toList(),
        );
  }

  Stream<List<Product>> watchAllProducts() {
    return _products
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map<Product>((doc) => Product.fromDoc(doc)).toList(),
        );
  }

  Stream<List<Order>> watchUserOrders(String uid) {
    return _orders
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map<Order>((doc) => Order.fromDoc(doc)).toList(),
        );
  }

  Stream<List<Order>> watchAllOrders() {
    return _orders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map<Order>((doc) => Order.fromDoc(doc)).toList(),
        );
  }

  Stream<List<BrewLog>> watchUserBrewLogs(String uid) {
    return _brewLogs
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map<BrewLog>((doc) => BrewLog.fromDoc(doc))
              .toList(),
        );
  }

  Future<DateTime?> fetchLastOrderDate(String uid) async {
    final snapshot = await _orders
        .where('userId', isEqualTo: uid)
        .orderBy('lastOrderDate', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    final data = snapshot.docs.first.data();
    return (data['lastOrderDate'] as firestore.Timestamp?)?.toDate();
  }

  Future<void> createOrder({
    required String userId,
    required List<OrderItem> items,
    required num totalPrice,
    required String paymentMethod,
  }) async {
    await _orders.add({
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': 'PENDING_PAYMENT',
      'paymentMethod': paymentMethod,
      'lastOrderDate': firestore.FieldValue.serverTimestamp(),
      'proofImageUrl': null,
      'createdAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  Future<void> addBrewLog({
    required String userId,
    required String productId,
    required String brewMethod,
    required int rating,
    required String note,
  }) async {
    await _brewLogs.add({
      'userId': userId,
      'productId': productId,
      'brewMethod': brewMethod,
      'rating': rating,
      'note': note,
      'createdAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  Future<void> upsertProduct(Product product) async {
    await _products.doc(product.id).set(product.toMap());
  }

  Future<void> createProduct({
    required String productId,
    required String name,
    required num price,
    required num weightGram,
    required List<String> tastingNotes,
    required String story,
    required bool active,
    required List<String> imageUrls,
  }) async {
    await _products.doc(productId).set({
      'name': name,
      'price': price,
      'weightGram': weightGram,
      'tastingNotes': tastingNotes,
      'story': story,
      'active': active,
      'imageUrl': imageUrls,
      'createdAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  String newProductId() {
    return _products.doc().id;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _orders.doc(orderId).set(
      {'status': status},
      firestore.SetOptions(merge: true),
    );
  }
}
