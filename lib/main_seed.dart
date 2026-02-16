import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'models/user_role.dart';
import 'models/product_model.dart';
import 'models/order_model.dart';
import 'models/delivery_model.dart';
import 'models/payment_model.dart';

// Run this file with: flutter run -t lib/main_seed.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SeedApp());
}

class SeedApp extends StatelessWidget {
  const SeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('AgriLink Database Seeder')),
        body: const SeederView(),
      ),
    );
  }
}

class SeederView extends StatefulWidget {
  const SeederView({super.key});

  @override
  State<SeederView> createState() => _SeederViewState();
}

class _SeederViewState extends State<SeederView> {
  final List<String> _logs = [];
  bool _isSeeding = false;

  void _log(String message) {
    setState(() {
      _logs.add(message);
    });
    debugPrint(message);
  }

  Future<void> _seedDatabase() async {
    setState(() {
      _isSeeding = true;
      _logs.clear();
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Create Users
      _log('Creating Users...');
      
      final farmerId = 'seed_farmer_1';
      final buyerId = 'seed_buyer_1';
      final transporterId = 'seed_transporter_1';
      final agentId = 'seed_agent_1';

      await firestore.collection('users').doc(farmerId).set(
        UserModel(
          uid: farmerId,
          fullName: 'Abebe Kebede (Farmer)',
          email: 'farmer@test.com',
          role: UserRole.FARMER,
          phone: '+251911000001',
          isVerified: true,
          rating: 4.8,
          createdAt: DateTime.now(),
        ).toFirestore()
      );

      await firestore.collection('users').doc(buyerId).set(
        UserModel(
          uid: buyerId,
          fullName: 'Sara Mohamed (Buyer)',
          email: 'buyer@test.com',
          role: UserRole.BUYER,
          phone: '+251911000002',
          isVerified: true,
          rating: 4.5,
          createdAt: DateTime.now(),
        ).toFirestore()
      );

      await firestore.collection('users').doc(transporterId).set(
        UserModel(
          uid: transporterId,
          fullName: 'Dawit Thomas (Transporter)',
          email: 'driver@test.com',
          role: UserRole.TRANSPORTER,
          phone: '+251911000003',
          isVerified: true,
          rating: 4.9,
          createdAt: DateTime.now(),
        ).toFirestore()
      );
      
      await firestore.collection('users').doc(agentId).set(
        UserModel(
          uid: agentId,
          fullName: 'Lula Ali (Agent)',
          email: 'agent@test.com',
          role: UserRole.AGENT,
          phone: '+251911000004',
          isVerified: true,
          rating: 4.7,
          createdAt: DateTime.now(),
        ).toFirestore()
      );

      _log('✅ Users created');

      // 2. Create Products
      _log('Creating Products...');
      final productId1 = 'seed_product_1'; // Teff
      final productId2 = 'seed_product_2'; // Coffee

      await firestore.collection('products').doc(productId1).set(
        ProductModel(
          id: productId1,
          farmerId: farmerId,
          cropName: 'Teff (White)',
          description: 'High quality white Teff from Debre Zeit.',
          pricePerKg: 50.0,
          quantityKg: 1000.0,
          minOrderKg: 50.0,
          location: 'Debre Zeit, Oromia',
          harvestDate: DateTime.now().subtract(const Duration(days: 10)),
          status: ProductStatus.AVAILABLE,
          imageUrl: 'assets/images/products/teff.png',
          createdAt: DateTime.now(),
        ).toFirestore()
      );
      
      await firestore.collection('products').doc(productId2).set(
        ProductModel(
          id: productId2,
          farmerId: farmerId,
          cropName: 'Organic Coffee Beans',
          description: 'Premium export quality coffee beans.',
          pricePerKg: 350.0,
          quantityKg: 500.0,
          minOrderKg: 10.0,
          location: 'Jimma, Oromia',
          harvestDate: DateTime.now().subtract(const Duration(days: 5)),
          status: ProductStatus.AVAILABLE,
          imageUrl: 'assets/images/products/coffee.png',
          createdAt: DateTime.now(),
        ).toFirestore()
      );
      
      _log('✅ Products created');

      // 3. Create Orders
      _log('Creating Orders...');
      final orderId1 = 'seed_order_1';

      final order1 = OrderModel(
        id: orderId1,
        productId: productId1,
        buyerId: buyerId,
        farmerId: farmerId,
        quantityKg: 100.0,
        agreedPrice: 50.0,
        totalAmount: 5000.0,
        status: OrderStatus.PAID,
        expectedDelivery: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now(),
      );
      
      await firestore.collection('orders').doc(orderId1).set(order1.toFirestore());
      _log('✅ Orders created');

      // 4. Create Payments
      _log('Creating Payments...');
      final paymentId1 = 'seed_payment_1';
      
      await firestore.collection('payments').doc(paymentId1).set(
        PaymentModel(
          id: paymentId1,
          orderId: orderId1,
          payerId: buyerId,
          payeeId: farmerId,
          paymentMethod: 'Telebirr',
          amount: 5000.0,
          escrowStatus: EscrowStatus.HELD,
          createdAt: DateTime.now(),
        ).toFirestore()
      );
      _log('✅ Payments created');

      // 5. Create Deliveries
      _log('Creating Deliveries...');
      final deliveryId1 = 'seed_delivery_1';
      
      await firestore.collection('deliveries').doc(deliveryId1).set(
        DeliveryModel(
          id: deliveryId1,
          orderId: orderId1,
          transporterId: transporterId, // Assigned
          pickupLocation: 'Debre Zeit, Oromia',
          dropoffLocation: 'Addis Ababa, Bole',
          status: DeliveryStatus.ASSIGNED,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).toFirestore()
      );
      _log('✅ Deliveries created');

      _log('🎉 SEEDING COMPLETE!');
      
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSeeding ? null : _seedDatabase,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: _isSeeding 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('SEED DATABASE', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(_logs[index], style: const TextStyle(fontFamily: 'Monospace')),
              );
            },
          ),
        ),
      ],
    );
  }
}
