import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadPaymentProof({
    required String orderId,
    required File file,
  }) async {
    final ref = _storage.ref('payment_proofs/$orderId');
    final snapshot = await ref.putFile(file);
    return snapshot.ref.getDownloadURL();
  }

  Future<String> uploadProductImage({
    required String productId,
    required File file,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('product_images/$productId/$timestamp');
    final snapshot = await ref.putFile(file);
    return snapshot.ref.getDownloadURL();
  }
}
