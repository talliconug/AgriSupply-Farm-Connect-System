import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _farmDescriptionController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedRegion = '';
  String _selectedDistrict = '';
  File? _profileImage;
  bool _isLoading = false;
  bool _isEditing = false;

  UserModel? _user;

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
    if (authProvider.currentUser != null && orderProvider.farmerOrders.isEmpty) {
      orderProvider.fetchFarmerOrders(authProvider.currentUser!.id);
    }
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _user = authProvider.user;

    if (_user != null) {
      _nameController.text = _user!.fullName;
      _emailController.text = _user!.email;
      _phoneController.text = _user!.phone ?? '';
      _farmNameController.text = _user!.farmName ?? '';
      _farmDescriptionController.text = _user!.farmDescription ?? '';
      _addressController.text = _user!.address ?? '';
      
      // Auto-detect region from district
      if (_user!.district != null && _user!.district!.isNotEmpty) {
        _selectedDistrict = _user!.district!;
        _selectedRegion = _getRegionFromDistrict(_selectedDistrict);
      } else if (_user!.region != null && _user!.region!.isNotEmpty) {
        _selectedRegion = _user!.region!;
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _farmNameController.dispose();
    _farmDescriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        _showError('User not found');
        return;
      }

      // Upload to Supabase Storage
      final storageService = StorageService();
      final imageUrl = await storageService.uploadProfilePicture(
        imageFile: File(image.path),
        userId: userId,
      );

      // Update profile with new image URL
      final result = await authProvider.updateProfile(
        photoUrl: imageUrl,
      );

      if (mounted) {
        if (result) {
          setState(() => _profileImage = File(image.path));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          _showError('Failed to update profile image');
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
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        farmName: _farmNameController.text.trim(),
        bio: _farmDescriptionController.text.trim(),
        address: _addressController.text.trim(),
        region: _selectedRegion,
        district: _selectedDistrict,
      );

      if (!mounted) return;

      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.grey900,
          elevation: 0,
          actions: [
            if (!_isEditing)
              IconButton(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit),
              )
            else
              TextButton(
                onPressed: () {
                  _loadUserData();
                  setState(() => _isEditing = false);
                },
                child: const Text('Cancel'),
              ),
          ],
        ),
        body: Consumer<AuthProvider>(
          builder: (final context, final authProvider, final child) {
            final user = authProvider.user;

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Photo
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.grey200,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (user?.photoUrl != null
                                  ? NetworkImage(user!.photoUrl!)
                                  : null) as ImageProvider?,
                          child: _profileImage == null &&
                                  user?.photoUrl == null
                              ? Text(
                                  user?.fullName.isNotEmpty ?? false
                                      ? user!.fullName[0].toUpperCase()
                                      : 'F',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.grey600,
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
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
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
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      user?.fullName ?? 'Farmer',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Verified Farmer',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats
                  _buildStatsRow(),
                  const SizedBox(height: 24),

                  // Personal Information
                  _buildSectionHeader('Personal Information'),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    prefixIcon: Icons.person,
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
                    prefixIcon: Icons.email,
                    enabled: false, // Email cannot be changed
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone',
                    prefixIcon: Icons.phone,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  // Farm Information
                  _buildSectionHeader('Farm Information'),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _farmNameController,
                    label: 'Farm Name',
                    prefixIcon: Icons.agriculture,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _farmDescriptionController,
                    label: 'Farm Description',
                    prefixIcon: Icons.description,
                    enabled: _isEditing,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Location
                  _buildSectionHeader('Location'),
                  const SizedBox(height: 12),
                  
                  // District selection (auto-detects region)
                  _buildDropdown(
                    label: 'District',
                    value: _selectedDistrict.isEmpty ? null : _selectedDistrict,
                    items: _getAllDistricts(),
                    enabled: _isEditing,
                    onChanged: (final value) {
                      setState(() {
                        _selectedDistrict = value ?? '';
                        // Auto-detect and update region
                        if (value != null && value.isNotEmpty) {
                          _selectedRegion = _getRegionFromDistrict(value);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Region (auto-filled, read-only)
                  if (_selectedRegion.isNotEmpty)
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
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _addressController,
                    label: 'Address',
                    prefixIcon: Icons.location_on,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  if (_isEditing) ...[
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: _saveProfile,
                    ),
                    const SizedBox(height: 32),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Consumer<AuthProvider>(
      builder: (final context, final provider, final child) {
        final user = provider.user;
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        final ordersCount = orderProvider.farmerOrders.isNotEmpty
            ? orderProvider.farmerOrders.length.toString()
            : (user?.totalOrders?.toString() ?? '0');

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  'Products', user?.totalProducts?.toString() ?? '0'),
              Container(height: 40, width: 1, color: AppColors.grey300),
              _buildStatItem('Orders', ordersCount),
              Container(height: 40, width: 1, color: AppColors.grey300),
              _buildStatItem(
                'Rating',
                user?.rating.toStringAsFixed(1) ?? '0.0',
                suffix: '\u{2B50}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(final String label, final String value, {final String? suffix}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 4),
              Text(suffix, style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(final String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildDropdown({
    required final String label,
    required final String? value,
    required final List<String> items,
    required final bool enabled,
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
            color: enabled ? AppColors.grey100 : AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            hint: Text('Select $label'),
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            menuMaxHeight: 400, // Prevent overflow by limiting dropdown height
            items: items
                .map((final item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (final route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
