class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://ugrraxmjvbujpdzfsvzt.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVncnJheG1qdmJ1anBkemZzdnp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczNDYyNjEsImV4cCI6MjA4MjkyMjI2MX0.julW_csYQxpYGBdWG-jP1i5ARX4Ym-F0egeL_nkNOlo';

  // Backend API Configuration
  // For local development: http://localhost:3000/api/v1
  // Production (Render): https://agrisupply-farm-connect-system.onrender.com/api/v1
  static const String apiBaseUrl = 'https://agrisupply-farm-connect-system.onrender.com/api/v1';

  // App Information
  static const String appName = 'AgriSupply Farm Connect';
  static const String appVersion = '1.0.0';

  // Mobile Money Configuration
  static const String mobileMoneyApiUrl = 'YOUR_MOBILE_MONEY_API_URL';
  static const String mobileMoneyApiKey = 'YOUR_MOBILE_MONEY_API_KEY';

  // Note: AI Chat uses the main API endpoint (apiBaseUrl/ai/chat) - no separate config needed

  // Default pagination
  static const int defaultPageSize = 20;

  // Image upload limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxImagesPerProduct = 5;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
