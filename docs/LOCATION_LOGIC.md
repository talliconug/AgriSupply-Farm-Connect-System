# Location Logic & Geolocation in AgriSupply

## Overview
The location system in AgriSupply is a critical component that enables regional product filtering, delivery fee calculation, market insights, and connects farmers with nearby buyers.

---

## Why Location is Needed

### 1. **Product Discovery & Filtering**
- Buyers can filter products by region to find fresh produce from nearby farmers
- Shows products available in specific districts
- Reduces delivery time and costs by prioritizing local suppliers

### 2. **Delivery Fee Calculation**
The system calculates delivery fees based on regional distances:
- **Same Region**: UGX 5,000
- **Adjacent Regions**: UGX 10,000 - 15,000
- **Distant Regions**: UGX 15,000 - 18,000

Example from `backend/src/utils/helpers.js`:
```javascript
const calculateDeliveryFee = (fromRegion, toRegion) => {
  if (fromRegion === toRegion) return 5000; // Same region
  
  const regionFees = {
    'Central-Eastern': 10000,
    'Central-Northern': 15000,
    'Central-Western': 12000,
    'Eastern-Northern': 12000,
    'Eastern-Western': 15000,
    'Northern-Western': 18000,
  };
  
  const key = [fromRegion, toRegion].sort().join('-');
  return regionFees[key] || 15000;
};
```

### 3. **Market Insights & AI Predictions**
- Region-specific crop price trends
- Localized farming advice based on climate and soil conditions
- Market demand forecasts by region

### 4. **Farmer-Buyer Matching**
- Connects farmers with buyers in their vicinity
- Promotes local trade and food security
- Reduces post-harvest losses through faster transactions

### 5. **Analytics & Reporting**
- Track regional sales performance
- Identify high-demand areas
- Government/NGO data for agricultural planning

---

## Uganda Regions & Districts

### Regions (4)
1. **Central** - 24 districts
2. **Eastern** - 36 districts  
3. **Northern** - 33 districts
4. **Western** - 35 districts

**Total: 128 districts**

### Complete Districts List

#### Central Region (24)
Buikwe, Bukomansimbi, Butambala, Buvuma, Gomba, Kalangala, Kalungi, Kampala, Kayunga, Kiboga, Kyankwanzi, Luwero, Lwengo, Lyantonde, Masaka, Mityana, Mpigi, Mubende, Mukono, Nakaseke, Nakasongola, Rakai, Sembabule, Wakiso

#### Eastern Region (36)
Amuria, Budaka, Bududa, Bugiri, Bugweri, Bukwa, Bulambuli, Busia, Butaleja, Butebo, Buyende, Iganga, Jinja, Kaberamaido, Kalaki, Kaliro, Kamuli, Kapchorwa, Kapelebyong, Katakwi, Kibuku, Kumi, Kween, Luuka, Manafwa, Mayuge, Mbale, Namayingo, Namisindwa, Namutumba, Ngora, Pallisa, Serere, Sironko, Soroti, Tororo

#### Northern Region (33)
Abim, Adjumani, Agago, Alebtong, Amudat, Amuru, Apac, Arua, Dokolo, Gulu, Kaabong, Kitgum, Koboko, Kole, Kotido, Lamwo, Lira, Maracha, Moroto, Moyo, Nabilatuk, Napak, Nebbi, Ngora, Nwoya, Obongi, Omoro, Otuke, Oyam, Pader, Pakwach, Yumbe, Zombo

#### Western Region (35)
Buhweju, Buliisa, Bundibugyo, Bunyangabu, Bushenyi, Butobo, Hoima, Ibanda, Isingiro, Kabale, Kabarole, Kagadi, Kakumiro, Kamwenge, Kanungu, Kasese, Kibaale, Kikuube, Kiruhura, Kiryandongo, Kisoro, Kitagwenda, Kyegegwa, Kyenjojo, Masindi, Mbarara, Mitooma, Ntoroko, Ntungamo, Rubanda, Rubirizi, Rukiga, Rukungiri, Rwampara, Sheema

---

## Geolocation Implementation

### Mobile App (`location_service.dart`)

The `LocationService` class handles all geolocation features:

#### Key Methods

1. **`getCurrentPosition()`**
   - Requests location permissions
   - Gets device GPS coordinates
   - Returns latitude/longitude

2. **`getRegionFromCoordinates(lat, lng)`**
   - Maps GPS coordinates to Uganda regions
   - Uses approximate regional boundaries

3. **`calculateDistance(lat1, lng1, lat2, lng2)`**
   - Calculates distance between two points in kilometers
   - Used for "products near you" feature

4. **Permission Handling**
   - Checks if location services are enabled
   - Requests user permission
   - Handles denied/permanently denied states

### Usage Example

```dart
import 'package:agrisupply/services/location_service.dart';

final locationService = LocationService();

// Get current location
final position = await locationService.getCurrentPosition();
print('Latitude: ${position?.latitude}');
print('Longitude: ${position?.longitude}');

// Detect region
final region = locationService.getRegionFromCoordinates(
  position!.latitude, 
  position.longitude
);
print('You are in: $region region');

// Calculate distance
final distance = locationService.calculateDistance(
  0.3476, 32.5825, // Kampala
  0.4536, 33.2039, // Jinja
);
print('Distance: ${distance.toStringAsFixed(2)} km');
```

---

## Backend Implementation

### Location Validation

All location data is validated against the official Uganda districts list:

```javascript
// backend/src/utils/validators.js
body('region')
  .optional()
  .isIn(constants.uganda.regions)
  .withMessage('Invalid region'),

body('district')
  .notEmpty()
  .withMessage('District is required'),
```

### Helper Functions

```javascript
// Check if district belongs to region
isValidDistrict(district, region)

// Get all districts in a region
getDistrictsByRegion(region)

// Calculate delivery fee
calculateDeliveryFee(fromRegion, toRegion)
```

---

## Database Schema

### Users Table
```sql
region VARCHAR(50)       -- Central, Eastern, Northern, Western
district VARCHAR(100)    -- User's district
address TEXT             -- Detailed address
```

### Products Table
```sql
region VARCHAR(50)       -- Product location region
district VARCHAR(100)    -- Product location district
latitude DECIMAL(10,8)   -- GPS latitude (optional)
longitude DECIMAL(11,8)  -- GPS longitude (optional)
```

### Indexes for Performance
- `idx_products_region` ON region
- `idx_users_region` ON region

---

## User Flows

### Farmer Registration
1. Farmer selects region from dropdown
2. Districts populate based on selected region
3. Can optionally enable GPS to auto-detect location
4. Products inherit farmer's default region/district

### Buyer Product Search
1. Buyer filters by region
2. System shows products from that region
3. Delivery fee auto-calculated based on farmer's region
4. "Near Me" feature sorts by GPS distance

### Order Placement
1. System detects buyer's region
2. Calculates delivery fee from farmer's region
3. Estimates delivery time based on distance
4. Routes order to nearest distribution center

---

## Future Enhancements

### 1. **Reverse Geocoding**
- Convert GPS coordinates to exact addresses
- Integrate Google Maps or OpenStreetMap API

### 2. **Interactive Maps**
- Show farmer locations on map
- Visual delivery radius
- Route optimization for deliveries

### 3. **Sub-County/Parish Data**
- More granular location tracking
- Village-level product sourcing

### 4. **Real-time Distance Tracking**
- Live delivery tracking
- ETA updates based on actual location

### 5. **Location-based Notifications**
- Alert buyers when farmers near them list new products
- Notify farmers of nearby buyer demand

---

## Security & Privacy

### Location Data Protection
- GPS coordinates optional, not required
- Location data encrypted in transit
- Users can disable geolocation anytime
- Only region/district visible to other users (not exact GPS)

### Permissions
- Clear explanation why location is needed
- Graceful fallback if permission denied
- Manual region/district selection always available

---

## Performance Considerations

### Caching
- District lists cached in app memory
- Region boundaries preloaded
- Reduces API calls for location lookups

### Database Queries
```sql
-- Efficient region filtering
SELECT * FROM products 
WHERE region = 'Central' 
AND is_active = true 
ORDER BY created_at DESC;

-- Distance-based search (using PostGIS extension)
SELECT *, ST_Distance(
  ST_MakePoint(longitude, latitude),
  ST_MakePoint(32.5825, 0.3476) -- Kampala
) AS distance
FROM products
WHERE distance < 50000 -- 50km radius
ORDER BY distance;
```

---

## Testing Locations

### Test Regions
- **Central**: Kampala, Wakiso
- **Eastern**: Jinja, Mbale
- **Northern**: Gulu, Lira
- **Western**: Mbarara, Fort Portal

### Delivery Fee Tests
```
Kampala → Wakiso = 5,000 UGX (same region)
Kampala → Jinja = 10,000 UGX (adjacent)
Kampala → Gulu = 15,000 UGX (distant)
```

---

## Support

For location-related issues:
- Email: support@agrisupply.ug
- Docs: https://docs.agrisupply.ug/location
- GitHub: https://github.com/agrisupply/issues

---

**Last Updated**: March 2026
**Version**: 1.0.0
