import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/delivery_model.dart';
import '../models/payment_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USERS ====================
  
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> streamUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Stream<List<UserModel>> streamAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toFirestore());
  }

  // ==================== PRODUCTS ====================
  
  Future<String> createProduct(ProductModel product) async {
    final doc = await _firestore.collection('products').add(product.toFirestore());
    return doc.id;
  }

  Future<void> updateProduct(ProductModel product) async {
    await _firestore
        .collection('products')
        .doc(product.id)
        .update(product.toFirestore());
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    if (!doc.exists) return null;
    return ProductModel.fromFirestore(doc);
  }

  Stream<List<ProductModel>> streamAllProducts() {
    return _firestore
        .collection('products')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList());
  }

  Stream<List<ProductModel>> streamAvailableProducts() {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'AVAILABLE')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList());
  }

  Stream<List<ProductModel>> streamFarmerProducts(String farmerId) {
    return _firestore
        .collection('products')
        .where('farmer_id', isEqualTo: farmerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList());
  }

  // ==================== ORDERS ====================
  
  Future<String> createOrder(OrderModel order) async {
    final doc = await _firestore.collection('orders').add(order.toFirestore());
    return doc.id;
  }

  Future<void> updateOrder(OrderModel order) async {
    await _firestore.collection('orders').doc(order.id).update(order.toFirestore());
  }

  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromFirestore(doc);
  }

  Stream<List<OrderModel>> streamBuyerOrders(String buyerId) {
    return _firestore
        .collection('orders')
        .where('buyer_id', isEqualTo: buyerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  Stream<List<OrderModel>> streamFarmerOrders(String farmerId) {
    return _firestore
        .collection('orders')
        .where('farmer_id', isEqualTo: farmerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  Stream<List<OrderModel>> streamAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // ==================== DELIVERIES ====================
  
  Future<String> createDelivery(DeliveryModel delivery) async {
    final doc = await _firestore.collection('deliveries').add(delivery.toFirestore());
    return doc.id;
  }

  Future<void> updateDelivery(DeliveryModel delivery) async {
    await _firestore
        .collection('deliveries')
        .doc(delivery.id)
        .update(delivery.toFirestore());
  }

  Future<DeliveryModel?> getDeliveryByOrderId(String orderId) async {
    final snapshot = await _firestore
        .collection('deliveries')
        .where('order_id', isEqualTo: orderId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return DeliveryModel.fromFirestore(snapshot.docs.first);
  }

  Stream<List<DeliveryModel>> streamTransporterDeliveries(String transporterId) {
    return _firestore
        .collection('deliveries')
        .where('transporter_id', isEqualTo: transporterId)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DeliveryModel.fromFirestore(doc)).toList());
  }

  Stream<List<DeliveryModel>> streamPendingDeliveries() {
    return _firestore
        .collection('deliveries')
        .where('delivery_status', isEqualTo: 'PENDING')
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DeliveryModel.fromFirestore(doc)).toList());
  }

  // ==================== PAYMENTS ====================
  
  Future<String> createPayment(PaymentModel payment) async {
    final doc = await _firestore.collection('payments').add(payment.toFirestore());
    return doc.id;
  }

  Future<void> updatePayment(PaymentModel payment) async {
    await _firestore
        .collection('payments')
        .doc(payment.id)
        .update(payment.toFirestore());
  }

  Future<PaymentModel?> getPaymentByOrderId(String orderId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('order_id', isEqualTo: orderId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return PaymentModel.fromFirestore(snapshot.docs.first);
  }
}
