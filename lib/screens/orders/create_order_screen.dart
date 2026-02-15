import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
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
  
  double _totalAmount = 0;
  double _commission = 0; // 5% platform fee
  double _netToFarmer = 0;
  bool _isLoading = false;
  DateTime? _expectedDelivery;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_calculateTotals);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    if (quantity > 0) {
      setState(() {
        _totalAmount = quantity * widget.product.pricePerKg;
        _commission = _totalAmount * 0.05; // 5% commission
        _netToFarmer = _totalAmount - _commission;
      });
    } else {
      setState(() {
        _totalAmount = 0;
        _commission = 0;
        _netToFarmer = 0;
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
      final user = authService.currentUser;

      if (user == null) throw Exception('User not logged in');

      final quantity = double.parse(_quantityController.text);

      final order = OrderModel(
        id: '', // Assigned by Firestore
        productId: widget.product.id,
        buyerId: user.uid,
        farmerId: widget.product.farmerId,
        quantityKg: quantity,
        agreedPrice: widget.product.pricePerKg,
        totalAmount: _totalAmount,
        commission: _commission,
        netToFarmer: _netToFarmer,
        status: OrderStatus.PENDING,
        expectedDelivery: _expectedDelivery,
        createdAt: DateTime.now(),
      );

      await firestoreService.createOrder(order);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.orderPlacedSuccessfully)),
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
                        child: widget.product.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.product.imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.agriculture, color: Colors.grey),
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
                        label: AppLocalizations.of(context)!.platformFee,
                        value: currencyFormat.format(_commission),
                        isFee: true,
                      ),
                       const Divider(height: 24),
                      _SummaryRow(
                        label: AppLocalizations.of(context)!.totalPayable,
                        value: currencyFormat.format(_totalAmount), // Commission is usually deducted from seller, buyer pays total
                        isTotal: true,
                        color: const Color(0xFF2D6A4F),
                      ),
                    ],
                  ),
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
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isFee ? Colors.grey : Colors.black,
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
