import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/product_model.dart';

class CreateProductScreen extends StatefulWidget {
  final ProductModel? productToEdit;

  const CreateProductScreen({super.key, this.productToEdit});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minOrderController = TextEditingController(text: '1.0');
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _harvestDate;
  File? _imageFile;
  bool _isLoading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      _initEditMode();
    }
  }

  void _initEditMode() {
    final p = widget.productToEdit!;
    _cropNameController.text = p.cropName;
    _quantityController.text = p.quantityKg.toString();
    _minOrderController.text = p.minOrderKg.toString();
    _priceController.text = p.pricePerKg.toString();
    _locationController.text = p.location ?? '';
    _descriptionController.text = p.description;
    _harvestDate = p.harvestDate;
    // Image handling for edit mode would require downloading or showing network image
  }

  @override
  void dispose() {
    _cropNameController.dispose();
    _quantityController.dispose();
    _minOrderController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Select Photo Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF2D6A4F)),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFF2D6A4F)),
                title: const Text('Take a Photo (Camera)'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _harvestDate) {
      setState(() {
        _harvestDate = picked;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_harvestDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a harvest date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) throw Exception('User not logged in');

      // Upload image to Firebase Storage and get URL
      String? imageUrl = widget.productToEdit?.imageUrl;
      if (_imageFile != null) {
        final storageService = Provider.of<StorageService>(context, listen: false);
        imageUrl = await storageService.uploadProductImage(_imageFile!);
      }

      final product = ProductModel(
        id: widget.productToEdit?.id ?? '', // ID assigned by firestore on create
        farmerId: user.uid,
        cropName: _cropNameController.text.trim(),
        description: _descriptionController.text.trim(),
        quantityKg: double.parse(_quantityController.text),
        minOrderKg: double.parse(_minOrderController.text),
        pricePerKg: double.parse(_priceController.text),
        harvestDate: _harvestDate,
        status: ProductStatus.AVAILABLE,
        location: _locationController.text.trim(),
        imageUrl: imageUrl,
        createdAt: widget.productToEdit?.createdAt ?? DateTime.now(),
      );

      if (widget.productToEdit != null) {
        await firestoreService.updateProduct(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
        }
      } else {
        await firestoreService.createProduct(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product created successfully')),
          );
        }
      }

      if (mounted) Navigator.pop(context);
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
    final isEditing = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'List New Crop'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : (widget.productToEdit?.imageUrl != null
                            ? DecorationImage(
                                image: widget.productToEdit!.imageUrl!.startsWith('http')
                                    ? NetworkImage(widget.productToEdit!.imageUrl!) as ImageProvider
                                    : AssetImage(widget.productToEdit!.imageUrl!) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null),
                  ),
                  child: _imageFile == null && widget.productToEdit?.imageUrl == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to add photo', style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Crop Name
              TextFormField(
                controller: _cropNameController,
                decoration: const InputDecoration(
                  labelText: 'Crop Name',
                  hintText: 'e.g. Red Onions',
                  prefixIcon: Icon(Icons.grass),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter crop name' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your product, harvesting method, etc.',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter description' : null,
              ),
              const SizedBox(height: 16),

              // Quantity & Price Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity (kg)',
                        hintText: 'e.g. 500',
                        prefixIcon: Icon(Icons.scale),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minOrderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min Order (kg)',
                        hintText: 'e.g. 10',
                        prefixIcon: Icon(Icons.shopping_basket),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Price per kg
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price per kg (ETB)',
                  hintText: 'e.g. 50',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location / Farm Name',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter location' : null,
              ),
              const SizedBox(height: 16),

              // Harvest Date
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Harvest Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _harvestDate != null
                        ? DateFormat('MMM dd, yyyy').format(_harvestDate!)
                        : 'Select Date',
                    style: TextStyle(
                      color: _harvestDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(isEditing ? 'Update Listing' : 'List Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
