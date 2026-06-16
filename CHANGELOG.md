# Changelog

All notable changes to AgriSupply will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Luganda language support
- Runyankole language support
- Voice assistant for illiterate farmers
- Offline order synchronization
- Group buying feature
- Farmer cooperatives support

---

## [1.0.0] - 2024-01-15

### Added

#### Core Features
- Complete user authentication system
  - Email/password registration and login
  - Phone OTP verification
  - Password reset functionality
  - JWT token-based sessions
  
- User roles and permissions
  - Buyer accounts
  - Farmer accounts
  - Admin accounts
  - Role-based access control

- Product Management
  - Product listing by farmers
  - Multiple image uploads
  - Product categories (10 categories)
  - Organic product certification flag
  - Stock management
  - Price per unit (kg, bunch, piece, etc.)
  
- Product Discovery
  - Browse all products
  - Filter by category
  - Filter by region/district
  - Filter by price range
  - Search by name
  - Sort by price, rating, date

- Shopping Cart
  - Add/remove products
  - Update quantities
  - Cart persistence
  - Stock validation

- Order System
  - Multi-item orders
  - Order confirmation
  - Order status tracking
  - Order history
  - Order cancellation (before shipping)

- Payment Integration
  - MTN Mobile Money (Uganda)
  - Airtel Money (Uganda)
  - Card payments via Flutterwave
  - Cash on Delivery option
  - Payment status tracking
  - Refund capability

- AI Features
  - Farming assistant chatbot
  - Crop image analysis
  - Pest identification
  - Disease diagnosis
  - Market price predictions
  - Weather-based recommendations

- Notifications
  - Push notifications (FCM)
  - In-app notifications
  - Order updates
  - Payment confirmations
  - Marketing messages

- Reviews & Ratings
  - Product reviews
  - Star ratings (1-5)
  - Review images
  - Verified purchase badges

- Farmer Features
  - Farmer dashboard
  - Product management
  - Order management
  - Earnings tracking
  - Follower system

- Admin Features
  - Admin dashboard
  - User management
  - Product moderation
  - Order oversight
  - Analytics & reports

#### Technical
- Flutter mobile app (iOS & Android)
- Node.js/Express backend API
- PostgreSQL database (Supabase)
- Supabase authentication
- Supabase file storage
- OpenAI GPT-4 integration
- Redis caching
- Docker containerization
- GitHub Actions CI/CD
- Nginx reverse proxy

#### Documentation
- API documentation
- Mobile app documentation
- Database design document
- Deployment guide
- Contributing guide
- Security policy

### Security
- JWT authentication
- bcrypt password hashing
- Rate limiting
- Input validation
- SQL injection prevention
- XSS protection
- CORS configuration
- HTTPS enforcement

---

## [0.9.0] - 2024-01-01 (Beta)

### Added
- Beta testing release
- Core functionality complete
- Limited to Central Uganda region

### Known Issues
- Some UI inconsistencies on older Android devices
- Occasional payment callback delays
- AI responses sometimes in English only

---

## [0.5.0] - 2023-12-01 (Alpha)

### Added
- Initial alpha release
- Basic product listing
- Simple order flow
- MTN Mobile Money only

### Limitations
- No AI features
- No notifications
- Limited to Kampala area

---

## Version History Summary

| Version | Date | Highlights |
|---------|------|------------|
| 1.0.0 | Jan 2024 | Production release |
| 0.9.0 | Jan 2024 | Beta testing |
| 0.5.0 | Dec 2023 | Alpha release |

---

## Upgrade Notes

### Upgrading to 1.0.0

#### Database Migrations
Run the following migrations in order:
1. `001_initial_schema.sql`
2. `002_add_ai_tables.sql`
3. `003_add_notifications.sql`

#### Environment Variables
New required environment variables:
- `OPENAI_API_KEY` - For AI features
- `FCM_PROJECT_ID` - For push notifications
- `AIRTEL_API_KEY` - For Airtel Money

#### Breaking Changes
- User table schema changed
- Order status values standardized
- API response format unified

---

## Roadmap

### Version 1.1.0 (Q2 2024)
- [ ] Multi-language support
- [ ] Voice commands
- [ ] Improved offline mode
- [ ] Delivery tracking map

### Version 1.2.0 (Q3 2024)
- [ ] Farmer cooperatives
- [ ] Group buying
- [ ] Subscription boxes
- [ ] Quality certifications

### Version 2.0.0 (Q4 2024)
- [ ] Web admin panel
- [ ] Farmer web portal
- [ ] Logistics integration
- [ ] Export features

---

## Contributors

Thanks to all contributors who have helped shape AgriSupply:

- Development Team
- Design Team
- QA Team
- Beta Testers
- Community Contributors

---

[Unreleased]: https://github.com/agrisupply/agrisupply/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/agrisupply/agrisupply/releases/tag/v1.0.0
[0.9.0]: https://github.com/agrisupply/agrisupply/releases/tag/v0.9.0
[0.5.0]: https://github.com/agrisupply/agrisupply/releases/tag/v0.5.0
