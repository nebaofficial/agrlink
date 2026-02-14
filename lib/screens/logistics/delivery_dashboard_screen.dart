import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/delivery_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/user_role.dart';
import '../../models/user_model.dart';
import '../../widgets/status_badge.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUser = snapshot.data!;
        final isTransporter = currentUser.role == UserRole.TRANSPORTER;
        final isAgent = currentUser.role == UserRole.AGENT;

        if (!isTransporter && !isAgent) {
          return const Scaffold(
            body: Center(
              child: Text('Access Denied. Transporter or Agent account required.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(isAgent ? 'Logistics Dashboard' : 'My Deliveries'),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                const Tab(text: 'Active Deliveries'),
                Tab(text: isAgent ? 'Pending Assignment' : 'Available Jobs'),
              ],
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Active Deliveries
              _DeliveryList(
                stream: isTransporter
                    ? firestoreService.streamTransporterDeliveries(currentUser.uid)
                    : firestoreService.streamPendingDeliveries(), // Simple placeholder for agent active view
                emptyMessage: 'No active deliveries',
                isAgent: isAgent,
                currentUser: currentUser,
              ),

              // Tab 2: Pending/Available
              _DeliveryList(
                stream: firestoreService.streamPendingDeliveries(),
                emptyMessage: 'No pending deliveries',
                isAgent: isAgent,
                currentUser: currentUser,
                showAcceptButton: isTransporter,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeliveryList extends StatelessWidget {
  final Stream<List<DeliveryModel>> stream;
  final String emptyMessage;
  final bool isAgent;
  final UserModel currentUser;
  final bool showAcceptButton;

  const _DeliveryList({
    required this.stream,
    required this.emptyMessage,
    required this.isAgent,
    required this.currentUser,
    this.showAcceptButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<List<DeliveryModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(emptyMessage, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        final deliveries = snapshot.data!;
        
        // Filter: Transporters should only see available jobs (no transporter assigned) in tab 2
        // In tab 1 they see their own (handled by stream)
        final displayList = showAcceptButton 
            ? deliveries.where((d) => d.transporterId == null).toList() 
            : deliveries;

        if (displayList.isEmpty) {
           return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(emptyMessage, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: displayList.length,
          itemBuilder: (context, index) {
            final delivery = displayList[index];
            return _DeliveryCard(
              delivery: delivery,
              firestoreService: firestoreService,
              isAgent: isAgent,
              currentUser: currentUser,
              showAcceptButton: showAcceptButton,
            );
          },
        );
      },
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final DeliveryModel delivery;
  final FirestoreService firestoreService;
  final bool isAgent;
  final UserModel currentUser;
  final bool showAcceptButton;

  const _DeliveryCard({
    required this.delivery,
    required this.firestoreService,
    required this.isAgent,
    required this.currentUser,
    required this.showAcceptButton,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, HH:mm');

    return FutureBuilder<OrderModel?>(
      future: firestoreService.getOrder(delivery.orderId),
      builder: (context, orderSnapshot) {
        final order = orderSnapshot.data;
        if (order == null) return const SizedBox.shrink();

        return FutureBuilder<ProductModel?>(
          future: firestoreService.getProduct(order.productId),
          builder: (context, productSnapshot) {
            final product = productSnapshot.data;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product?.cropName ?? 'Loading...',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        StatusBadge(
                          status: delivery.status.value,
                          type: StatusType.delivery,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    _buildInfoRow(Icons.location_on, 'From: ${product?.location ?? "Unknown"}'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.pin_drop, 'To: ${delivery.dropoffLocation}'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.scale, 'Quantity: ${order.quantityKg} kg'),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    if (showAcceptButton)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                               final updatedDelivery = delivery.copyWith(
                                transporterId: currentUser.uid,
                                status: DeliveryStatus.ASSIGNED,
                              );
                              await firestoreService.updateDelivery(updatedDelivery);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Delivery job accepted!')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Accept Job'),
                        ),
                      ),
                    
                    if (!showAcceptButton && delivery.transporterId == currentUser.uid)
                       _buildTransporterActions(context),

                    if (isAgent)
                      _buildAgentActions(context),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  Widget _buildTransporterActions(BuildContext context) {
    if (delivery.status == DeliveryStatus.ASSIGNED) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus(context, DeliveryStatus.PICKED_UP),
          child: const Text('Confirm Pickup'),
        ),
      );
    } else if (delivery.status == DeliveryStatus.PICKED_UP || 
               delivery.status == DeliveryStatus.IN_TRANSIT) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus(context, DeliveryStatus.DELIVERED),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
          child: const Text('Confirm Delivery'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAgentActions(BuildContext context) {
    if (delivery.status == DeliveryStatus.DELIVERED && !delivery.confirmedByAgent) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
           onPressed: () async {
              try {
                final updatedDelivery = delivery.copyWith(
                  status: DeliveryStatus.CONFIRMED,
                  confirmedByAgent: true,
                  agentId: currentUser.uid,
                );
                await firestoreService.updateDelivery(updatedDelivery);
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delivery confirmed!')),
                  );
                 }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
           },
           child: const Text('Verify & Confirm Delivery'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _updateStatus(BuildContext context, DeliveryStatus status) async {
    try {
      final updatedDelivery = delivery.copyWith(status: status);
      await firestoreService.updateDelivery(updatedDelivery);
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${status.value}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
