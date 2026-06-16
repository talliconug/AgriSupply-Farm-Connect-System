import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

class AddProductScreen extends StatefulWidget {

  const AddProductScreen({super.key, this.productId});
  final String? productId;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  String _selectedCategory = ProductCategory.vegetables;
  String _selectedUnit = ProductUnit.kg;
  bool _isOrganic = false;
  DateTime _harvestDate = DateTime.now();
  DateTime? _expiryDate;
  final List<File> _selectedImages = [];
  List<String> _existingImages = [];

  bool _isLoading = false;
  bool get _isEditing => widget.productId != null;
  ProductModel? _existingProduct;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);

    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final product = await productProvider.getProductById(widget.productId!);

      if (product != null) {
        setState(() {
          _existingProduct = product;
          _nameController.text = product.name;
          _descriptionController.text = product.description;
          _priceController.text = product.price.toString();
          _quantityController.text = product.availableQuantity.toString();
          _selectedCategory = product.category;
          _selectedUnit = product.unit;
          _isOrganic = product.isOrganic;
          _harvestDate = product.harvestDate;
          _expiryDate = product.expiryDate;
          _existingImages = product.images;
        });
      }
    } catch (e) {
      _showError('Failed to load product');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((final e) => File(e.path)));
      });
    }
  }

  Future<void> _selectDate(final bool isHarvestDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isHarvestDate ? _harvestDate : (_expiryDate ?? _harvestDate),
      firstDate: isHarvestDate
          ? DateTime.now().subtract(const Duration(days: 30))
          : _harvestDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isHarvestDate) {
          _harvestDate = date;
          if (_expiryDate != null && _expiryDate!.isBefore(_harvestDate)) {
            _expiryDate = null;
          }
        } else {
          _expiryDate = date;
        }
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty && _existingImages.isEmpty) {
      _showError('Please add at least one product image');
      return;
    }

    if (_expiryDate != null && _expiryDate!.isBefore(_harvestDate)) {
      _showError('Expiry date must be on or after the harvest date');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);

      final now = DateTime.now();
      final product = ProductModel(
        id: _isEditing ? widget.productId! : '',
        farmerId: authProvider.currentUser!.id,
        farmerName: authProvider.currentUser!.fullName,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceController.text.trim()),
        unit: _selectedUnit,
        quantity: double.parse(_quantityController.text.trim()),
        availableQuantity: double.parse(_quantityController.text.trim()),
        images: _existingImages,
        isOrganic: _isOrganic,
        harvestDate: _harvestDate,
        expiryDate: _expiryDate,
        createdAt: _existingProduct?.createdAt ?? now,
        updatedAt: now,
      );

      dynamic result;
      if (_isEditing) {
        result = await productProvider.updateProduct(product);
      } else {
        result = await productProvider.createProduct(product, _selectedImages);
      }

      if (!mounted) return;

      final success = result != null && result != false;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Product updated successfully'
                : 'Product added successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        _showError(productProvider.errorMessage ?? 'Failed to save product');
      }
    } catch (e) {
      _showError('Error creating product: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(final String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeExistingImage(final int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  void _removeSelectedImage(final int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(final BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.grey900,
          elevation: 0,
          actions: [
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: _showDeleteDialog,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Images Section
              Text(
                'Product Images',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildImagePicker(),
              const SizedBox(height: 24),

              // Basic Information
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _nameController,
                label: 'Product Name',
                hint: 'e.g., Fresh Tomatoes',
                prefixIcon: Icons.eco,
                validator: (final value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe your product...',
                prefixIcon: Icons.description,
                maxLines: 4,
                validator: (final value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              _buildDropdown(
                label: 'Category',
                value: _selectedCategory,
                items: ProductCategory.all,
                icon: ProductCategory.getIcon(_selectedCategory),
                onChanged: (final value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              const SizedBox(height: 24),

              // Pricing & Quantity
              Text(
                'Pricing & Quantity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _priceController,
                      label: 'Price (UGX)',
                      hint: '5000',
                      prefixIcon: Icons.money,
                      keyboardType: TextInputType.number,
                      validator: (final value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Unit',
                      value: _selectedUnit,
                      items: ProductUnit.all,
                      onChanged: (final value) {
                        setState(() => _selectedUnit = value!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _quantityController,
                label: 'Available Quantity',
                hint: '100',
                prefixIcon: Icons.inventory,
                keyboardType: TextInputType.number,
                validator: (final value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Dates
              Text(
                'Dates',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Harvest Date',
                      date: _harvestDate,
                      onTap: () => _selectDate(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Expiry Date (Optional)',
                      date: _expiryDate,
                      onTap: () => _selectDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Organic Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isOrganic
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isOrganic ? AppColors.success : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.eco,
                      color: _isOrganic ? AppColors.success : AppColors.grey500,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Organic Product',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _isOrganic
                                  ? AppColors.success
                                  : AppColors.grey700,
                            ),
                          ),
                          Text(
                            'Mark if this product is organically grown',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isOrganic,
                      onChanged: (final value) => setState(() => _isOrganic = value),
                      activeThumbColor: AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: _isEditing ? 'Update Product' : 'Add Product',
                onPressed: _saveProduct,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final totalImages = _existingImages.length + _selectedImages.length;

    return Column(
      children: [
        // Image Grid
        if (totalImages > 0)
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Existing images
                ..._existingImages.asMap().entries.map((final entry) {
                  return _buildImageTile(
                    imageUrl: entry.value,
                    onRemove: () => _removeExistingImage(entry.key),
                  );
                }),
                // New images
                ..._selectedImages.asMap().entries.map((final entry) {
                  return _buildImageTile(
                    imageFile: entry.value,
                    onRemove: () => _removeSelectedImage(entry.key),
                  );
                }),
                // Add button
                if (totalImages < 5)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.grey300,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              color: AppColors.grey500),
                          SizedBox(height: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: AppColors.grey500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey300),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate,
                      size: 48, color: AppColors.grey500),
                  SizedBox(height: 8),
                  Text(
                    'Add Product Images',
                    style: TextStyle(color: AppColors.grey600),
                  ),
                  Text(
                    'Up to 5 images',
                    style: TextStyle(color: AppColors.grey500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageTile({
    required final VoidCallback onRemove, final String? imageUrl,
    final File? imageFile,
  }) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    imageFile!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required final String label,
    required final String value,
    required final List<String> items,
    required final void Function(String?) onChanged,
    final String? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: items.map((final item) {
              return DropdownMenuItem(
                value: item,
                child: Row(
                  children: [
                    if (icon != null && item == value)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(icon),
                      ),
                    Text(item),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required final String label,
    required final DateTime? date,
    required final VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: AppColors.grey600),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Select',
                  style: TextStyle(
                    color: date != null ? AppColors.grey900 : AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog() {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text(
            'Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              final productProvider =
                  Provider.of<ProductProvider>(context, listen: false);
              final success =
                  await productProvider.deleteProduct(widget.productId!);

              if (mounted) {
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  setState(() => _isLoading = false);
                  _showError('Failed to delete product');
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
