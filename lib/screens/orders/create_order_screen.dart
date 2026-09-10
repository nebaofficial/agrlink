import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/platform_config_provider.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';

import '../../widgets/product_image.dart';
import 'package:agrilink/l10n/generated/app_localizations.dart';

class CreateOrderScreen extends StatefulWidget {
  final ProductModel product;

  const CreateOrderScreen({super.key, required this.product});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  
  double _totalAmount = 0;
  double _commission = 0;
  double _commissionPerKg = 1.0; // Will be overridden from config
  bool _isLoading = false;
  DateTime? _expectedDelivery;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_calculateTotals);
    _loadBuyerProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read commission rate from platform config
    final config = Provider.of<PlatformConfigProvider>(context, listen: false);
    _commissionPerKg = config.commissionPerKg;
    _calculateTotals(); // Recalculate with real rate
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadBuyerProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userData = await authService.getCurrentUserData();
    if (userData != null && mounted) {
      setState(() {
        // Pre-fill address/city from profile if available
        if (userData.address != null && userData.address!.isNotEmpty) {
          _addressController.text = userData.address!;
        }
        if (userData.city != null && userData.city!.isNotEmpty) {
          _cityController.text = userData.city!;
        }
      });
    }
  }

  void _calculateTotals() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    if (quantity > 0) {
      setState(() {
        _totalAmount = quantity * widget.product.pricePerKg;
        _commission = quantity * _commissionPerKg; // 1 ETB/kg flat rate from config
      });
    } else {
      setState(() {
        _totalAmount = 0;
        _commission = 0;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null && picked != _expectedDelivery) {
      setState(() {
        _expectedDelivery = picked;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expectedDelivery == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selectExpectedDeliveryDate)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final config = Provider.of<PlatformConfigProvider>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) throw Exception('User not logged in');

      final quantity = double.parse(_quantityController.text);
      final totalAmount = quantity * widget.product.pricePerKg;
      final commissionPerKg = config.commissionPerKg;
      final commission = quantity * commissionPerKg;
      final agentSharePerKg = config.agentSharePerKg;
      final agentShare = quantity * agentSharePerKg;
      final netToFarmer = totalAmount - commission;

      // Look up farmer to get their agent_id and auto_accept preference
      final farmer = await firestoreService.getUser(widget.product.farmerId);
      final agentId = farmer?.agentId;
      final autoAcceptHours = config.orderAutoAcceptHours;
      final autoAcceptAt = DateTime.now().add(Duration(hours: autoAcceptHours));

      // If farmer has auto_accept_orders enabled, skip timer and accept instantly
      final farmerAutoAccepts = farmer?.autoAcceptOrders ?? false;

      final order = OrderModel(
        id: '', // Assigned by Firestore
        productId: widget.product.id,
        buyerId: user.uid,
        farmerId: widget.product.farmerId,
        agentId: agentId,
        quantityKg: quantity,
        agreedPrice: widget.product.pricePerKg,
        totalAmount: totalAmount,
        commissionPerKg: commissionPerKg,
        commission: commission,
        agentShare: agentShare,
        netToFarmer: netToFarmer,
        status: farmerAutoAccepts ? OrderStatus.ACCEPTED : OrderStatus.PENDING,
        expectedDelivery: _expectedDelivery,
        deliveryAddress: _addressController.text.trim(),
        deliveryCity: _cityController.text.trim(),
        createdAt: DateTime.now(),
        autoAcceptAt: farmerAutoAccepts ? null : autoAcceptAt,
        autoAccepted: farmerAutoAccepts,
      );

      await firestoreService.createOrder(order);

      // TODO: Send 3-channel notification to farmer
      // Channel 1: FCM push to farmer
      // Channel 2: FCM push to their agent
      // Channel 3: SMS to farmer phone (Africa's Talking API — Year 2)

      if (mounted) {
        final msg = farmerAutoAccepts
            ? 'Order placed & auto-accepted! You can now pay.'
            : AppLocalizations.of(context)!.orderPlacedSuccessfully;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        Navigator.pop(context); // Return to product detail
        Navigator.pop(context); // Return to marketplace
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.placeOrder)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ProductImage(
                          imageUrl: widget.product.imageUrl,
                          width: 60,
                          height: 60,
                          borderRadius: 8,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.cropName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${currencyFormat.format(widget.product.pricePerKg)} / kg',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Available: ${widget.product.quantityKg.toStringAsFixed(0)} kg',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quantity Input
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.quantityKgLabel,
                  hintText: AppLocalizations.of(context)!.maxAvailable(widget.product.quantityKg),
                  prefixIcon: const Icon(Icons.scale),
                  suffixText: 'kg',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final qty = double.tryParse(value);
                  if (qty == null) return 'Invalid number';
                  if (qty <= 0) return 'Must be greater than 0';
                  if (qty > widget.product.quantityKg) {
                    return 'Exceeds available quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Delivery Date
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.expectedDeliveryDate,
                    prefixIcon: const Icon(Icons.local_shipping),
                  ),
                  child: Text(
                    _expectedDelivery != null
                        ? dateFormat.format(_expectedDelivery!)
                        : AppLocalizations.of(context)!.selectDate,
                    style: TextStyle(
                      color: _expectedDelivery != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Delivery Location Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF2D6A4F), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Delivery Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Used for transport assignment and delivery planning',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Address',
                        prefixIcon: Icon(Icons.home_outlined),
                        hintText: 'Enter delivery address',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Delivery address is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City / Region',
                        prefixIcon: Icon(Icons.location_city_outlined),
                        hintText: 'e.g. Addis Ababa',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'City/Region is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Order Summary
              Card(
                color: const Color(0xFFF9FAFB),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.orderSummary,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SummaryRow(
                        label: AppLocalizations.of(context)!.subtotal,
                        value: currencyFormat.format(_totalAmount),
                      ),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: '${AppLocalizations.of(context)!.platformFee} (${_commissionPerKg.toStringAsFixed(0)} ETB/kg)',
                        value: currencyFormat.format(_commission),
                        isFee: true,
                      ),
                       const Divider(height: 24),
                      _SummaryRow(
                        label: AppLocalizations.of(context)!.totalPayable,
                        value: currencyFormat.format(_totalAmount),
                        isTotal: true,
                        color: const Color(0xFF2D6A4F),
                      ),
                    ],
                  ),
                ),
              ),

              // Auto-accept info
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Consumer<PlatformConfigProvider>(
                        builder: (context, config, _) => Text(
                          'If farmer doesn\'t respond within ${config.orderAutoAcceptHours} hours, order is auto-accepted.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(AppLocalizations.of(context)!.confirmOrder),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isFee;
  final bool isTotal;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isFee = false,
    this.isTotal = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isFee ? Colors.grey : Colors.black,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
