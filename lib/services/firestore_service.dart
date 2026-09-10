import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/delivery_model.dart';
import '../models/payment_model.dart';
import '../models/support_ticket_model.dart';

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

  /// Stream farmers assigned to a specific agent.
  Stream<List<UserModel>> streamAgentFarmers(String agentId) {
    return _firestore
        .collection('users')
        .where('agent_id', isEqualTo: agentId)
        .where('role', isEqualTo: 'FARMER')
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

  /// Reduce product stock by ordered quantity. If remaining = 0, mark as SOLD.
  Future<void> reduceProductStock(String productId, double orderedQty) async {
    final product = await getProduct(productId);
    if (product == null) return;

    final newQty = product.quantityKg - orderedQty;
    final clampedQty = newQty < 0 ? 0.0 : newQty;

    final updatedProduct = product.copyWith(
      quantityKg: clampedQty,
      status: clampedQty <= 0 ? ProductStatus.SOLD : ProductStatus.AVAILABLE,
    );
    await updateProduct(updatedProduct);
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

  /// Stream orders scoped to a specific agent.
  Stream<List<OrderModel>> streamAgentOrders(String agentId) {
    return _firestore
        .collection('orders')
        .where('agent_id', isEqualTo: agentId)
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

  /// Live stream of the delivery for a specific order (for real-time tracking)
  Stream<DeliveryModel?> streamDeliveryByOrderId(String orderId) {
    return _firestore
        .collection('deliveries')
        .where('order_id', isEqualTo: orderId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return DeliveryModel.fromFirestore(snapshot.docs.first);
        });
  }

  /// Stream all deliveries for a farmer's products (direct query using farmer_id on delivery)
  Stream<List<DeliveryModel>> streamFarmerDeliveries(String farmerId) {
    return _firestore
        .collection('deliveries')
        .where('farmer_id', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DeliveryModel.fromFirestore(doc)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Stream deliveries assigned to this transporter (all statuses for history)
  Stream<List<DeliveryModel>> streamTransporterDeliveries(String transporterId) {
    return _firestore
        .collection('deliveries')
        .where('transporter_id', isEqualTo: transporterId)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DeliveryModel.fromFirestore(doc)).toList());
  }

  /// Stream ONLY active deliveries for a transporter (ASSIGNED, PICKED_UP, IN_TRANSIT)
  Stream<List<DeliveryModel>> streamActiveTransporterDeliveries(String transporterId) {
    return _firestore
        .collection('deliveries')
        .where('transporter_id', isEqualTo: transporterId)
        .where('delivery_status', whereIn: ['ASSIGNED', 'PICKED_UP', 'IN_TRANSIT'])
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DeliveryModel.fromFirestore(doc)).toList());
  }

  /// Stream unassigned deliveries (PENDING + no transporter) — "Available Jobs"
  Stream<List<DeliveryModel>> streamAvailableDeliveries() {
    return _firestore
        .collection('deliveries')
        .where('delivery_status', isEqualTo: 'PENDING')
        .snapshots()
        .map((snapshot) {
          // Filter out deliveries that already have a transporter assigned
          final results = snapshot.docs
              .map((doc) => DeliveryModel.fromFirestore(doc))
              .where((d) => d.transporterId == null || d.transporterId!.isEmpty)
              .toList();
          // Sort client-side to avoid requiring composite index
          results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return results;
        });
  }

  /// Stream pending deliveries (all PENDING, for agents)
  Stream<List<DeliveryModel>> streamPendingDeliveries() {
    return _firestore
        .collection('deliveries')
        .where('delivery_status', isEqualTo: 'PENDING')
        .snapshots()
        .map((snapshot) {
          final results = snapshot.docs
              .map((doc) => DeliveryModel.fromFirestore(doc))
              .toList();
          results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return results;
        });
  }

  /// Stream deliveries for a specific buyer (direct query using buyer_id on delivery)
  Stream<List<DeliveryModel>> streamBuyerDeliveries(String buyerId) {
    return _firestore
        .collection('deliveries')
        .where('buyer_id', isEqualTo: buyerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DeliveryModel.fromFirestore(doc)).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Stream all deliveries (for admin oversight only)
  Stream<List<DeliveryModel>> streamAllDeliveries() {
    return _firestore
        .collection('deliveries')
        .snapshots()
        .map((snapshot) {
          final results = snapshot.docs
              .map((doc) => DeliveryModel.fromFirestore(doc))
              .toList();
          results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return results;
        });
  }

  /// Stream deliveries scoped to a specific agent (privacy-safe).
  Stream<List<DeliveryModel>> streamAgentDeliveries(String agentId) {
    return _firestore
        .collection('deliveries')
        .where('agent_id', isEqualTo: agentId)
        .snapshots()
        .map((snapshot) {
          final results = snapshot.docs
              .map((doc) => DeliveryModel.fromFirestore(doc))
              .toList();
          results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return results;
        });
  }

  /// Stream deliveries that are CONFIRMED by agent but payment still HELD (for admin escrow release).
  Stream<List<DeliveryModel>> streamConfirmedAwaitingRelease() {
    return _firestore
        .collection('deliveries')
        .where('confirmed_by_agent', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final results = snapshot.docs
              .map((doc) => DeliveryModel.fromFirestore(doc))
              .toList();
          results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return results;
        });
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

  /// Stream payments for a farmer (payee) — used for Farmer Wallet screen.
  Stream<List<PaymentModel>> streamFarmerPayments(String farmerId) {
    return _firestore
        .collection('payments')
        .where('payee_id', isEqualTo: farmerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList());
  }

  /// Stream all HELD payments (for admin escrow oversight).
  Stream<List<PaymentModel>> streamHeldPayments() {
    return _firestore
        .collection('payments')
        .where('escrow_status', isEqualTo: 'HELD')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList());
  }

  // ==================== ATOMIC PAYMENT PROCESSING ====================

  /// Process payment atomically — all 4 ops succeed together or all fail.
  /// Op 1: Create payment doc (escrow HELD, is_simulated: true)
  /// Op 2: Update order status to PAID
  /// Op 3: Decrement product stock, mark SOLD if qty <= 0
  /// Op 4: Create delivery doc (status: PENDING, transporter_id: null)
  Future<void> processPaymentAtomic({
    required OrderModel order,
    required String paymentMethod,
    required double commission,
    required double agentShare,
    required double farmerAmount,
    required String pickupLocation,
    required String dropoffLocation,
    String? agentId,
  }) async {
    final batch = _firestore.batch();

    // Op 1: Create payment doc
    final paymentRef = _firestore.collection('payments').doc();
    batch.set(paymentRef, {
      'order_id': order.id,
      'payer_id': order.buyerId,
      'payee_id': order.farmerId,
      'agent_id': agentId,
      'payment_method': paymentMethod,
      'amount': order.totalAmount,
      'commission': commission,
      'agent_share': agentShare,
      'farmer_amount': farmerAmount,
      'escrow_status': 'HELD',
      'is_simulated': true,
      'created_at': Timestamp.now(),
      'released_at': null,
      'released_by': null,
    });

    // Op 2: Update order status to PAID
    final orderRef = _firestore.collection('orders').doc(order.id);
    batch.update(orderRef, {'status': 'PAID'});

    // Op 3: Decrement product stock
    final product = await getProduct(order.productId);
    if (product != null) {
      final newQty = product.quantityKg - order.quantityKg;
      final clampedQty = newQty < 0 ? 0.0 : newQty;
      final productRef = _firestore.collection('products').doc(order.productId);
      batch.update(productRef, {
        'quantity_kg': clampedQty,
        'status': clampedQty <= 0 ? 'SOLD' : 'AVAILABLE',
      });
    }

    // Op 4: Create delivery doc
    final deliveryRef = _firestore.collection('deliveries').doc();
    batch.set(deliveryRef, {
      'order_id': order.id,
      'buyer_id': order.buyerId,
      'farmer_id': order.farmerId,
      'agent_id': agentId,
      'transporter_id': null,
      'pickup_location': pickupLocation,
      'pickup_region': null,
      'dropoff_location': dropoffLocation,
      'delivery_status': 'PENDING',
      'confirmed_by_agent': false,
      'delivery_fee': 0,
      'distance_km': 0,
      'delivered_at': null,
      'confirmed_at': null,
      'created_at': Timestamp.now(),
      'updated_at': Timestamp.now(),
    });

    // Atomic commit — all 4 operations succeed together or all fail
    await batch.commit();
    debugPrint('✅ Atomic payment processed: order=${order.id}, amount=${order.totalAmount}');
  }

  /// Release escrow atomically — admin one-tap release.
  /// Op 1: Update payment escrow_status HELD → RELEASED
  /// Op 2: Update order status to COMPLETED
  Future<void> releaseEscrowAtomic({
    required String paymentId,
    required String orderId,
    required String adminUid,
  }) async {
    final batch = _firestore.batch();

    // Op 1: Release payment
    final paymentRef = _firestore.collection('payments').doc(paymentId);
    batch.update(paymentRef, {
      'escrow_status': 'RELEASED',
      'released_at': Timestamp.now(),
      'released_by': adminUid,
    });

    // Op 2: Complete order
    final orderRef = _firestore.collection('orders').doc(orderId);
    batch.update(orderRef, {
      'status': 'COMPLETED',
    });

    await batch.commit();
    debugPrint('✅ Escrow released: payment=$paymentId, order=$orderId');
  }

  // ==================== SUPPORT TICKETS ====================

  Future<String> createSupportTicket(SupportTicketModel ticket) async {
    final doc = await _firestore.collection('support_tickets').add(ticket.toFirestore());
    return doc.id;
  }

  Future<void> updateSupportTicket(SupportTicketModel ticket) async {
    await _firestore
        .collection('support_tickets')
        .doc(ticket.id)
        .update(ticket.toFirestore());
  }

  Stream<List<SupportTicketModel>> streamAllSupportTickets() {
    return _firestore
        .collection('support_tickets')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SupportTicketModel.fromFirestore(doc)).toList());
  }

  /// Stream support tickets scoped to a specific agent.
  Stream<List<SupportTicketModel>> streamAgentSupportTickets(String agentId) {
    return _firestore
        .collection('support_tickets')
        .where('agent_id', isEqualTo: agentId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SupportTicketModel.fromFirestore(doc)).toList());
  }

  Stream<List<SupportTicketModel>> streamOpenSupportTickets() {
    return _firestore
        .collection('support_tickets')
        .where('status', isEqualTo: 'OPEN')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SupportTicketModel.fromFirestore(doc)).toList());
  }

  Stream<List<SupportTicketModel>> streamUserSupportTickets(String userId) {
    return _firestore
        .collection('support_tickets')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SupportTicketModel.fromFirestore(doc)).toList());
  }

  // ==================== AUTO-ACCEPT PROCESSING ====================

  /// Process expired PENDING orders that have passed their auto_accept_at time.
  /// Called on app startup and when order list screen opens.
  Future<int> processExpiredOrders() async {
    int processed = 0;
    try {
      final now = Timestamp.now();
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'PENDING')
          .where('auto_accept_at', isLessThanOrEqualTo: now)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({
          'status': 'ACCEPTED',
          'auto_accepted': true,
        });
        processed++;
      }

      if (processed > 0) {
        debugPrint('✅ Auto-accepted $processed expired orders');
      }
    } catch (e) {
      debugPrint('⚠️ Error processing expired orders: $e');
    }
    return processed;
  }
}
