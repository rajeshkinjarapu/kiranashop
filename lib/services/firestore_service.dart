import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/address.dart';
import '../models/app_user.dart';
import '../models/category.dart';
import '../models/katha_transaction.dart';
import '../models/offer.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import '../models/shop_settings.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ---------- Users ----------

  Future<AppUser?> findUserByPhone(String phone) async {
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return AppUser.fromDoc(snap.docs.first);
  }

  Future<AppUser> createUser({
    required String name,
    required String phone,
  }) async {
    final ref = await _db.collection(AppConstants.usersCollection).add({
      'name': name,
      'phone': phone,
      'role': AppConstants.roleMember,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return AppUser(
      id: ref.id,
      name: name,
      phone: phone,
      role: AppConstants.roleMember,
    );
  }

  Future<void> updateUserName(String userId, String name) => _db
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .update({'name': name});

  Stream<List<AppUser>> membersStream() => _db
      .collection(AppConstants.usersCollection)
      .where('role', isEqualTo: AppConstants.roleMember)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromDoc).toList());

  // ---------- Katha Book (Ledger) ----------

  Stream<List<KathaTransaction>> kathaStream(String userId) => _db
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .collection('katha_transactions')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(KathaTransaction.fromDoc).toList());

  Future<void> addKathaTransaction(
      String userId, KathaTransaction transaction) async {
    final userRef = _db.collection(AppConstants.usersCollection).doc(userId);
    final kathaRef = userRef.collection('katha_transactions').doc();

    await _db.runTransaction((tx) async {
      final userDoc = await tx.get(userRef);
      if (!userDoc.exists) throw Exception('User not found');

      final currentBalance =
          (userDoc.data()?['kathaBalance'] ?? 0.0).toDouble();
      
      // If transaction type is credit (store gives credit/advance), balance increases.
      // If payment (customer pays back), balance decreases.
      final amountChange = transaction.type == TransactionType.credit 
          ? transaction.amount 
          : -transaction.amount;
          
      final newBalance = currentBalance + amountChange;

      tx.update(userRef, {'kathaBalance': newBalance});
      
      final transactionMap = transaction.toMap();
      transactionMap['createdAt'] = FieldValue.serverTimestamp();
      tx.set(kathaRef, transactionMap);
    });
  }

  // ---------- Categories ----------

  Stream<List<Category>> categoriesStream() => _db
      .collection(AppConstants.categoriesCollection)
      .orderBy('sortOrder')
      .snapshots()
      .map((s) => s.docs.map(Category.fromDoc).toList());

  Future<void> saveCategory(Category category, {String? id}) {
    final col = _db.collection(AppConstants.categoriesCollection);
    if (id == null) return col.add(category.toMap()).then((_) {});
    return col.doc(id).set(category.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteCategory(String id) =>
      _db.collection(AppConstants.categoriesCollection).doc(id).delete();

  // ---------- Products ----------

  Stream<List<Product>> productsStream() => _db
      .collection(AppConstants.productsCollection)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Product.fromDoc).toList());

  Future<void> saveProduct(Product product, {String? id}) {
    final col = _db.collection(AppConstants.productsCollection);
    if (id == null) return col.add(product.toMap()).then((_) {});
    return col.doc(id).set(product.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteProduct(String id) =>
      _db.collection(AppConstants.productsCollection).doc(id).delete();

  Future<void> updateProductStock(String id, bool inStock) =>
      _db.collection(AppConstants.productsCollection).doc(id).update({'inStock': inStock});

  // ---------- Offers ----------

  Stream<List<Offer>> offersStream() => _db
      .collection(AppConstants.offersCollection)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(Offer.fromDoc).toList());

  // ---------- Orders ----------

  Future<String> placeOrder(OrderModel order) async {
    final ref = _db.collection(AppConstants.ordersCollection).doc();
    await ref.set(order.toMap());

    // Decrement stock for each item (best-effort).
    final batch = _db.batch();
    for (final item in order.items) {
      if (item.productId.isEmpty) continue;
      final pRef = _db.collection(AppConstants.productsCollection).doc(item.productId);
      batch.update(pRef, {'stockQty': FieldValue.increment(-item.qty)});
    }
    try {
      await batch.commit();
    } catch (_) {
      // Stock decrement is best-effort; order is already placed.
    }
    return ref.id;
  }

  Stream<List<OrderModel>> userOrdersStream(String userId) => _db
      .collection(AppConstants.ordersCollection)
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromDoc).toList());

  Stream<List<OrderModel>> allOrdersStream() => _db
      .collection(AppConstants.ordersCollection)
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromDoc).toList());

  Future<void> updateOrderStatus(String orderId, String status) => _db
      .collection(AppConstants.ordersCollection)
      .doc(orderId)
      .update({'status': status});

  // ---------- Addresses ----------

  Stream<List<Address>> addressesStream(String userId) => _db
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .collection(AppConstants.addressesCollection)
      .snapshots()
      .map((s) => s.docs.map(Address.fromDoc).toList());

  Future<void> saveAddress(String userId, Address address, {String? id}) {
    final col = _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.addressesCollection);
    if (id == null) return col.add(address.toMap()).then((_) {});
    return col.doc(id).set(address.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteAddress(String userId, String id) => _db
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .collection(AppConstants.addressesCollection)
      .doc(id)
      .delete();

  // ---------- Settings ----------

  Stream<ShopSettings> settingsStream() => _db
      .doc(AppConstants.settingsDoc)
      .snapshots()
      .map(ShopSettings.fromDoc);

  Future<ShopSettings> fetchSettings() =>
      _db.doc(AppConstants.settingsDoc).get().then(ShopSettings.fromDoc);

  Future<void> saveSettings(ShopSettings settings) => _db
      .doc(AppConstants.settingsDoc)
      .set(settings.toMap(), SetOptions(merge: true));
}
