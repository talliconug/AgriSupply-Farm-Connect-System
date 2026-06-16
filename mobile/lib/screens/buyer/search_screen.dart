import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  String? _selectedCategory;
  String? _selectedRegion;
  double _minPrice = 0;
  double _maxPrice = 100000;
  bool _organicOnly = false;
  String _sortBy = 'relevance';
  bool _showFilters = false;

  List<ProductModel> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  final List<String> _regions = ['All Regions', 'Central', 'Eastern', 'Northern', 'Western'];
  final List<String> _sortOptions = ['relevance', 'price_low', 'price_high', 'rating', 'newest'];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedCategory == null) return;

    if (query.isNotEmpty && query.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 2 characters to search.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      // Apply filters without list refresh; search request below should be a single network call.
      productProvider.setCategory(_selectedCategory, refresh: false);
      productProvider.setRegion(
        _selectedRegion != null && _selectedRegion != 'All Regions'
            ? _selectedRegion
            : null,
        refresh: false,
      );
      productProvider.setPriceRange(
        _minPrice > 0 ? _minPrice : null,
        _maxPrice < 100000 ? _maxPrice : null,
        refresh: false,
      );
      productProvider.setOrganicOnly(_organicOnly ? true : null, refresh: false);
      productProvider.setSortBy(_sortBy, refresh: false);
      
      // Perform search
      await productProvider.searchProducts(query);
      
      setState(() => _searchResults = productProvider.searchResults);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedRegion = null;
      _minPrice = 0;
      _maxPrice = 100000;
      _organicOnly = false;
      _sortBy = 'relevance';
    });
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.grey900),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: const InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            hintStyle: TextStyle(color: AppColors.grey500),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.grey900),
            onPressed: _search,
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _selectedCategory != null || _organicOnly,
              child: Icon(
                Icons.tune,
                color: _showFilters ? AppColors.primaryGreen : AppColors.grey900,
              ),
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Panel
          if (_showFilters) _buildFiltersPanel(),

          // Results
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories
          Text('Category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('All', _selectedCategory == null, () {
                setState(() => _selectedCategory = null);
              }),
              ...ProductCategory.all.take(6).map((final category) {
                return _buildFilterChip(
                  category,
                  _selectedCategory == category,
                  () => setState(() => _selectedCategory = category),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Region
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Region', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedRegion ?? 'All Regions',
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: _regions.map((final region) {
                          return DropdownMenuItem(value: region, child: Text(region));
                        }).toList(),
                        onChanged: (final value) {
                          setState(() => _selectedRegion = value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sort By', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: _sortOptions.map((final option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(_getSortLabel(option)),
                          );
                        }).toList(),
                        onChanged: (final value) {
                          setState(() => _sortBy = value!);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price Range
          Text('Price Range (UGX)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            max: 100000,
            divisions: 20,
            labels: RangeLabels(
              _minPrice.toStringAsFixed(0),
              _maxPrice.toStringAsFixed(0),
            ),
            activeColor: AppColors.primaryGreen,
            onChanged: (final values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('UGX ${_minPrice.toStringAsFixed(0)}'),
              Text('UGX ${_maxPrice.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 16),

          // Organic Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Organic Only', style: Theme.of(context).textTheme.titleMedium),
              Switch(
                value: _organicOnly,
                onChanged: (final value) => setState(() => _organicOnly = value),
                activeThumbColor: AppColors.primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _search();
                    setState(() => _showFilters = false);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(final String label, final bool isSelected, final VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.grey700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return _buildRecentSearches();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${_searchResults.length} results found',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (final context, final index) {
              return ProductCard(
                product: _searchResults[index],
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.productDetail,
                  arguments: _searchResults[index].id,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Categories',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ProductCategory.all.take(8).map((final category) {
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = category);
                  _search();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ProductCategory.getIcon(category),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(final String sortBy) {
    switch (sortBy) {
      case 'relevance':
        return 'Relevance';
      case 'price_low':
        return 'Price: Low to High';
      case 'price_high':
        return 'Price: High to Low';
      case 'rating':
        return 'Top Rated';
      case 'newest':
        return 'Newest';
      default:
        return sortBy;
    }
  }
}
