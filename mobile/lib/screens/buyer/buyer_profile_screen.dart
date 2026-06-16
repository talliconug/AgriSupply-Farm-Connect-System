import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedRegion = 'Central';
  String _selectedDistrict = 'Kampala';
  bool _isLoading = false;
  bool _isEditing = false;

  final Map<String, List<String>> _districts = {
    'Central': [
      'Buikwe', 'Bukomansimbi', 'Butambala', 'Buvuma', 'Gomba', 'Kalangala', 
      'Kalungi', 'Kampala', 'Kayunga', 'Kiboga', 'Kyankwanzi', 'Luwero', 
      'Lwengo', 'Lyantonde', 'Masaka', 'Mityana', 'Mpigi', 'Mubende', 
      'Mukono', 'Nakaseke', 'Nakasongola', 'Rakai', 'Sembabule', 'Wakiso'
    ],
    'Eastern': [
      'Amuria', 'Budaka', 'Bududa', 'Bugiri', 'Bugweri', 'Bukwa', 'Bulambuli', 
      'Busia', 'Butaleja', 'Butebo', 'Buyende', 'Iganga', 'Jinja', 'Kaberamaido', 
      'Kalaki', 'Kaliro', 'Kamuli', 'Kapchorwa', 'Kapelebyong', 'Katakwi', 
      'Kibuku', 'Kumi', 'Kween', 'Luuka', 'Manafwa', 'Mayuge', 'Mbale', 
      'Namayingo', 'Namisindwa', 'Namutumba', 'Ngora', 'Pallisa', 'Serere', 
      'Sironko', 'Soroti', 'Tororo'
    ],
    'Northern': [
      'Abim', 'Adjumani', 'Agago', 'Alebtong', 'Amudat', 'Amuru', 'Apac', 
      'Arua', 'Dokolo', 'Gulu', 'Kaabong', 'Kitgum', 'Koboko', 'Kole', 
      'Kotido', 'Lamwo', 'Lira', 'Maracha', 'Moroto', 'Moyo', 'Nabilatuk', 
      'Napak', 'Nebbi', 'Ngora', 'Nwoya', 'Obongi', 'Omoro', 'Otuke', 
      'Oyam', 'Pader', 'Pakwach', 'Yumbe', 'Zombo'
    ],
    'Western': [
      'Buhweju', 'Buliisa', 'Bundibugyo', 'Bunyangabu', 'Bushenyi', 'Butobo', 
      'Hoima', 'Ibanda', 'Isingiro', 'Kabale', 'Kabarole', 'Kagadi', 'Kakumiro', 
      'Kamwenge', 'Kanungu', 'Kasese', 'Kibaale', 'Kikuube', 'Kiruhura', 
      'Kiryandongo', 'Kisoro', 'Kitagwenda', 'Kyegegwa', 'Kyenjojo', 'Masindi', 
      'Mbarara', 'Mitooma', 'Ntoroko', 'Ntungamo', 'Rubanda', 'Rubirizi', 
      'Rukiga', 'Rukungiri', 'Rwampara', 'Sheema'
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadOrders();
  }

  void _loadOrders() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    if (authProvider.currentUser != null && orderProvider.buyerOrders.isEmpty) {
      orderProvider.fetchBuyerOrders(authProvider.currentUser!.id);
    }
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
      if (user.district != null) {
        _selectedDistrict = user.district!;
        // Auto-detect region from district
        _selectedRegion = _getRegionFromDistrict(_selectedDistrict);
      } else if (user.region != null) {
        _selectedRegion = user.region!;
      }
    }
  }

  // Get region from selected district
  String _getRegionFromDistrict(final String district) {
    for (final entry in _districts.entries) {
      if (entry.value.contains(district)) {
        return entry.key;
      }
    }
    return 'Central'; // Default fallback
  }

  // Get all districts across all regions for flat list
  List<String> _getAllDistricts() {
    final allDistricts = <String>[];
    for (final districts in _districts.values) {
      allDistricts.addAll(districts);
    }
    allDistricts.sort();
    return allDistricts;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.updateProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        region: _selectedRegion,
        district: _selectedDistrict,
      );

      if (!mounted) return;

      if (result) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showError('Failed to update profile. Please try again.');
      }
    } catch (e) {
      _showError('An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      // Upload to Supabase Storage
      final storageService = StorageService();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        _showError('User not found');
        return;
      }

      final imageUrl = await storageService.uploadProfilePicture(
        imageFile: File(image.path),
        userId: userId,
      );

      // Update user profile with new image URL
      final result = await authProvider.updateProfile(
        photoUrl: imageUrl,
      );
      
      if (mounted) {
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          _showError('Failed to update profile image in database');
        }
      }
    } catch (e) {
      _showError('Failed to upload image: $e');
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

  @override
  Widget build(final BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.grey900,
          elevation: 0,
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _isEditing = true),
              )
            else
              TextButton(
                onPressed: () {
                  setState(() => _isEditing = false);
                  _loadUserData();
                },
                child: const Text('Cancel'),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Image
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primaryGreen,
                        backgroundImage: user?.profileImage != null
                            ? NetworkImage(user!.profileImage!)
                            : null,
                        child: user?.profileImage == null
                            ? Text(
                                user?.fullName.substring(0, 1).toUpperCase() ??
                                    'U',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // User Type Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_bag,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Buyer Account',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields
                CustomTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: Icons.person_outlined,
                  enabled: _isEditing,
                  validator: (final value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Your email address',
                  prefixIcon: Icons.email_outlined,
                  enabled: false,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '+256 700 123 456',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _addressController,
                  label: 'Address',
                  hint: 'Enter your address',
                  prefixIcon: Icons.location_on_outlined,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 16),

                if (_isEditing) ...[
                  // District selection (auto-detects region)
                  _buildDropdown(
                    label: 'District',
                    value: _selectedDistrict,
                    items: _getAllDistricts(),
                    onChanged: (final value) {
                      setState(() {
                        _selectedDistrict = value!;
                        // Auto-detect and update region
                        _selectedRegion = _getRegionFromDistrict(value);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Region (auto-filled, read-only)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.map_outlined, color: AppColors.grey600, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Region (Auto-detected)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedRegion,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Auto',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  CustomButton(
                    text: 'Save Changes',
                    onPressed: _updateProfile,
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.grey600),
                        const SizedBox(width: 12),
                        Text(
                          '$_selectedDistrict, $_selectedRegion',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Account Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Member since', 'January 2026'),
                      const Divider(height: 24),
                      Consumer<OrderProvider>(
                        builder: (final context, final orderProvider, final child) {
                          final count = orderProvider.buyerOrders.length.toString();
                          return _buildInfoRow('Total orders', count);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required final String label,
    required final String value,
    required final List<String> items,
    required final void Function(String?) onChanged,
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
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            menuMaxHeight: 400, // Prevent overflow by limiting dropdown height
            items: items.map((final item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(final String label, final String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey600,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
