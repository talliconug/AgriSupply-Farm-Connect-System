import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';

class DeliveryAddress {
  DeliveryAddress({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.region,
    required this.district,
    this.phone,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String fullAddress;
  final String region;
  final String district;
  final String? phone;
  final bool isDefault;
}

class DeliveryAddressesScreen extends StatefulWidget {
  const DeliveryAddressesScreen({super.key});

  @override
  State<DeliveryAddressesScreen> createState() =>
      _DeliveryAddressesScreenState();
}

class _DeliveryAddressesScreenState extends State<DeliveryAddressesScreen> {
  final List<DeliveryAddress> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    // Load user's saved addresses
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUser();
    final user = authProvider.currentUser;

    _addresses.clear();

    if (user != null && user.address != null && user.address!.isNotEmpty) {
      // Add user's primary address
      _addresses.add(
        DeliveryAddress(
          id: '1',
          label: 'Home',
          fullAddress: user.address!,
          region: user.region ?? 'Central',
          district: user.district ?? 'Kampala',
          phone: user.phone,
          isDefault: true,
        ),
      );
    }

    // TODO: Load additional saved addresses from backend
    setState(() {});
  }

  Future<bool> _saveAddressToDatabase(final DeliveryAddress address) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ok = await authProvider.updateProfile(
      address: address.fullAddress,
      region: address.region,
      district: address.district,
      phone: address.phone,
    );

    if (ok) {
      await authProvider.refreshUser();
    }
    return ok;
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Addresses'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
      ),
      body: _addresses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (final context, final index) {
                final address = _addresses[index];
                return _buildAddressCard(address);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAddressDialog,
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 80,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Delivery Addresses',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a delivery address to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddAddressDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(final DeliveryAddress address) {
    final center = _districtCenter(address.district);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      address.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (final value) {
                    if (value == 'edit') {
                      _showEditAddressDialog(address);
                    } else if (value == 'delete') {
                      _deleteAddress(address);
                    } else if (value == 'default') {
                      _setAsDefault(address);
                    }
                  },
                  itemBuilder: (final context) => [
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Set as Default'),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.grey600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address.fullAddress,
                    style: const TextStyle(color: AppColors.grey700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 16,
                  color: AppColors.grey600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${address.district}, ${address.region}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
            if (address.phone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: AppColors.grey600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    address.phone!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FlutterMap(
                  options: MapOptions(initialCenter: center, initialZoom: 12),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.agrisupply.mobile',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: center,
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primaryGreen,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LatLng _districtCenter(final String district) {
    const districtCenters = <String, LatLng>{
      'Kampala': LatLng(0.3476, 32.5825),
      'Wakiso': LatLng(0.4044, 32.4599),
      'Mukono': LatLng(0.3533, 32.7553),
      'Mbarara': LatLng(-0.6072, 30.6545),
      'Gulu': LatLng(2.7746, 32.2989),
      'Mbale': LatLng(1.0821, 34.1750),
      'Jinja': LatLng(0.4479, 33.2026),
      'Arua': LatLng(3.0201, 30.9111),
      'Masaka': LatLng(-0.3338, 31.7341),
    };

    return districtCenters[district] ?? const LatLng(0.3476, 32.5825);
  }

  // Get region from selected district
  String _getRegionFromDistrict(final String district) {
    const districts = {
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

    for (final entry in districts.entries) {
      if (entry.value.contains(district)) {
        return entry.key;
      }
    }
    return 'Central'; // Default fallback
  }

  // Get all districts across all regions for flat list
  List<String> _getAllDistricts() {
    const districts = {
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
    final allDistricts = <String>[];
    for (final districtList in districts.values) {
      allDistricts.addAll(districtList);
    }
    allDistricts.sort();
    return allDistricts;
  }

  void _showAddAddressDialog() {
    final labelController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    var selectedRegion = 'Central';
    var selectedDistrict = 'Kampala';

    showDialog<void>(
      context: context,
      builder: (final context) => StatefulBuilder(
        builder: (final context, final setState) => AlertDialog(
          title: const Text('Add Delivery Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: labelController,
                  label: 'Label',
                  hint: 'e.g., Home, Office',
                  prefixIcon: Icons.label_outlined,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: addressController,
                  label: 'Full Address',
                  hint: 'Street, Building, Landmark',
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // District selection (auto-detects region)
                DropdownButtonFormField<String>(
                  initialValue: selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  items: _getAllDistricts().map((final district) {
                    return DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: (final value) {
                    if (value != null) {
                      setState(() {
                        selectedDistrict = value;
                        // Auto-detect and update region
                        selectedRegion = _getRegionFromDistrict(value);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
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
                            selectedRegion,
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
                  controller: phoneController,
                  label: 'Phone Number',
                  hint: '+256 XXX XXX XXX',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (labelController.text.isNotEmpty &&
                    addressController.text.isNotEmpty) {
                  final newAddress = DeliveryAddress(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    label: labelController.text,
                    fullAddress: addressController.text,
                    region: selectedRegion,
                    district: selectedDistrict,
                    phone: phoneController.text.isNotEmpty
                        ? phoneController.text
                        : null,
                    isDefault: true,
                  );

                  final saved = await _saveAddressToDatabase(newAddress);
                  if (!saved) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to save address to database'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                    return;
                  }

                  this.setState(() {
                    _addresses
                      ..clear()
                      ..add(newAddress);
                  });
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Address saved successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAddressDialog(final DeliveryAddress address) {
    final labelController = TextEditingController(text: address.label);
    final addressController = TextEditingController(text: address.fullAddress);
    final phoneController = TextEditingController(text: address.phone ?? '');
    var selectedRegion = address.region;
    var selectedDistrict = address.district;

    showDialog<void>(
      context: context,
      builder: (final context) => StatefulBuilder(
        builder: (final context, final setState) => AlertDialog(
          title: const Text('Edit Delivery Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: labelController,
                  label: 'Label',
                  hint: 'e.g., Home, Office',
                  prefixIcon: Icons.label_outlined,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: addressController,
                  label: 'Full Address',
                  hint: 'Street, Building, Landmark',
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // District selection (auto-detects region)
                DropdownButtonFormField<String>(
                  initialValue: selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  items: _getAllDistricts().map((final district) {
                    return DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: (final value) {
                    if (value != null) {
                      setState(() {
                        selectedDistrict = value;
                        selectedRegion = _getRegionFromDistrict(value);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
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
                      Expanded(
                        child: Column(
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
                              selectedRegion,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                  controller: phoneController,
                  label: 'Phone Number',
                  hint: '+256 XXX XXX XXX',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (labelController.text.isNotEmpty &&
                    addressController.text.isNotEmpty) {
                  final updatedAddress = DeliveryAddress(
                    id: address.id,
                    label: labelController.text,
                    fullAddress: addressController.text,
                    region: selectedRegion,
                    district: selectedDistrict,
                    phone: phoneController.text.isNotEmpty
                        ? phoneController.text
                        : null,
                    isDefault: address.isDefault,
                  );

                  final saved = await _saveAddressToDatabase(updatedAddress);
                  if (!saved) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to update address in database'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                    return;
                  }

                  this.setState(() {
                    final index = _addresses.indexWhere((final a) => a.id == address.id);
                    if (index != -1) {
                      _addresses[index] = updatedAddress;
                    }
                  });
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Address updated successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAddress(final DeliveryAddress address) {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final saved = await authProvider.updateProfile(
                address: '',
              );

              if (!saved) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete address from database'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                return;
              }

              await authProvider.refreshUser();
              setState(() => _addresses.remove(address));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Address deleted from database'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _setAsDefault(final DeliveryAddress address) async {
    final saved = await _saveAddressToDatabase(address);
    if (!saved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save default address to database'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() {
      for (var i = 0; i < _addresses.length; i++) {
        _addresses[i] = DeliveryAddress(
          id: _addresses[i].id,
          label: _addresses[i].label,
          fullAddress: _addresses[i].fullAddress,
          region: _addresses[i].region,
          district: _addresses[i].district,
          phone: _addresses[i].phone,
          isDefault: _addresses[i].id == address.id,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default address updated in database'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
