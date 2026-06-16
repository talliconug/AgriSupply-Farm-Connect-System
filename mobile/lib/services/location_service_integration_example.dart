/// Compile-safe reference notes for integrating [LocationService] into profile screens.
///
/// This file intentionally keeps integration guidance as plain strings so it does
/// not introduce analyzer errors from incomplete snippet code.
class LocationServiceIntegrationExample {
  static const String summary =
      'Use LocationService in profile screen State classes to auto-detect region.';

  static const List<String> steps = <String>[
    "Import '../../services/location_service.dart' in your profile screen.",
    'Add state fields: LocationService instance and a loading flag.',
    'Add a location-detect button near address/region fields.',
    'Implement a method that reads GPS, resolves region, and updates form state.',
    'Handle denied permission by showing a dialog and opening location settings.',
    'Ensure Android and iOS location permissions are configured.',
  ];
}
