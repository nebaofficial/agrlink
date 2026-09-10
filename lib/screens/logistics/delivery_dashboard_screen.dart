import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/delivery_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/user_role.dart';
import '../../models/user_model.dart';
import '../../widgets/status_badge.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  final UserModel? currentUser;
  const DeliveryDashboardScreen({super.key, this.currentUser});

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
    if (widget.currentUser != null) {
      return _buildDashboard(context, widget.currentUser!);
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    
    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildDashboard(context, snapshot.data!);
      },
    );
  }

  Widget _buildDashboard(BuildContext context, UserModel currentUser) {
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
          // Tab 1: Active Deliveries — jobs accepted by THIS transporter
          _ActiveDeliveriesTab(
            currentUser: currentUser,
            isAgent: isAgent,
          ),

          // Tab 2: Available Jobs — unassigned PENDING deliveries
          _AvailableJobsTab(
            currentUser: currentUser,
            isAgent: isAgent,
            isTransporter: isTransporter,
          ),
        ],
      ),
    );
  }
}

/// Tab 1: Shows deliveries assigned to and accepted by the current transporter
class _ActiveDeliveriesTab extends StatelessWidget {
  final UserModel currentUser;
  final bool isAgent;

  const _ActiveDeliveriesTab({
    required this.currentUser,
    required this.isAgent,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    // For transporters: show only their active deliveries (ASSIGNED, PICKED_UP, IN_TRANSIT)
    // For agents: show all non-pending deliveries
    final stream = isAgent
        ? firestoreService.streamPendingDeliveries() // Agents see pending ones here for overview
        : firestoreService.streamActiveTransporterDeliveries(currentUser.uid);

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
                Text(
                  'No active deliveries',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  isAgent
                      ? 'No deliveries in progress'
                      : 'Accept a job from "Available Jobs" to start',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final delivery = snapshot.data![index];
            return _DeliveryCard(
              delivery: delivery,
              firestoreService: firestoreService,
              isAgent: isAgent,
              currentUser: currentUser,
              showAcceptButton: false,
            );
          },
        );
      },
    );
  }
}

/// Tab 2: Shows unassigned jobs available for transporters to accept
class _AvailableJobsTab extends StatelessWidget {
  final UserModel currentUser;
  final bool isAgent;
  final bool isTransporter;

  const _AvailableJobsTab({
    required this.currentUser,
    required this.isAgent,
    required this.isTransporter,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    // Show all unassigned PENDING deliveries
    final stream = firestoreService.streamAvailableDeliveries();

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
                Icon(Icons.work_off_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No available jobs',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'New delivery jobs will appear here when buyers place orders',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final delivery = snapshot.data![index];
            return _DeliveryCard(
              delivery: delivery,
              firestoreService: firestoreService,
              isAgent: isAgent,
              currentUser: currentUser,
              showAcceptButton: isTransporter,
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
                    
                    // Delivery status flow indicator
                    _buildStatusFlow(delivery.status),
                    const SizedBox(height: 12),

                    _buildInfoRow(Icons.location_on, 'From: ${delivery.pickupLocation.isNotEmpty ? delivery.pickupLocation : product?.location ?? "Unknown"}'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.pin_drop, 'To: ${delivery.dropoffLocation}'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.scale, 'Quantity: ${order.quantityKg.toStringAsFixed(0)} kg'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.attach_money, 'Value: ETB ${order.totalAmount.toStringAsFixed(0)}'),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    if (showAcceptButton)
                      _buildAcceptButton(context),
                    
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

  Widget _buildStatusFlow(DeliveryStatus currentStatus) {
    final statuses = [
      ('PENDING', Icons.hourglass_empty),
      ('ASSIGNED', Icons.person_pin),
      ('IN TRANSIT', Icons.local_shipping),
      ('DELIVERED', Icons.check_circle),
    ];

    int currentIndex = 0;
    switch (currentStatus) {
      case DeliveryStatus.PENDING:
        currentIndex = 0;
        break;
      case DeliveryStatus.ASSIGNED:
        currentIndex = 1;
        break;
      case DeliveryStatus.PICKED_UP:
      case DeliveryStatus.IN_TRANSIT:
        currentIndex = 2;
        break;
      case DeliveryStatus.DELIVERED:
      case DeliveryStatus.CONFIRMED:
        currentIndex = 3;
        break;
    }

    return Row(
      children: List.generate(statuses.length, (index) {
        final isActive = index <= currentIndex;
        final isLast = index == statuses.length - 1;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF2D6A4F) : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statuses[index].$2,
                      size: 14,
                      color: isActive ? Colors.white : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statuses[index].$1,
                    style: TextStyle(
                      fontSize: 8,
                      color: isActive ? const Color(0xFF2D6A4F) : Colors.grey[400],
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    color: index < currentIndex ? const Color(0xFF2D6A4F) : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAcceptButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Accept Job'),
        onPressed: () async {
          try {
            // Guard: Check if already assigned by another transporter
            final latestDelivery = await firestoreService.getDeliveryByOrderId(delivery.orderId);
            if (latestDelivery != null &&
                latestDelivery.transporterId != null &&
                latestDelivery.transporterId!.isNotEmpty) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Order already picked by another transporter'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return;
            }

            final updatedDelivery = delivery.copyWith(
              transporterId: currentUser.uid,
              status: DeliveryStatus.ASSIGNED,
            );
            await firestoreService.updateDelivery(updatedDelivery);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Delivery job accepted!'),
                  backgroundColor: Color(0xFF2D6A4F),
                ),
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
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D6A4F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
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
        child: ElevatedButton.icon(
          icon: const Icon(Icons.inventory_2),
          label: const Text('Confirm Pickup'),
          onPressed: () => _updateStatus(context, DeliveryStatus.PICKED_UP),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
          ),
        ),
      );
    } else if (delivery.status == DeliveryStatus.PICKED_UP || 
               delivery.status == DeliveryStatus.IN_TRANSIT) {
      return Column(
        children: [
          if (delivery.status == DeliveryStatus.PICKED_UP)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.local_shipping),
                label: const Text('Mark In Transit'),
                onPressed: () => _updateStatus(context, DeliveryStatus.IN_TRANSIT),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirm Delivery'),
              onPressed: () => _updateStatus(context, DeliveryStatus.DELIVERED),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAgentActions(BuildContext context) {
    if (delivery.status == DeliveryStatus.DELIVERED && !delivery.confirmedByAgent) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
           icon: const Icon(Icons.verified),
           label: const Text('Verify & Confirm Delivery'),
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
           style: ElevatedButton.styleFrom(
             backgroundColor: const Color(0xFF7C3AED),
             foregroundColor: Colors.white,
           ),
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
