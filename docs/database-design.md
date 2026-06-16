# AgriSupply Database Design Document

## Overview

This document describes the database architecture for AgriSupply, a digital agriculture marketplace connecting farmers and buyers in Uganda.

## Database Technology

- **Database**: PostgreSQL 15+
- **Hosting**: Supabase (managed PostgreSQL)
- **Extensions Used**:
  - `uuid-ossp` - UUID generation
  - `pgcrypto` - Cryptographic functions
  - `pg_trgm` - Trigram matching for search

## Entity Relationship Diagram

```
┌──────────────────┐       ┌──────────────────┐
│      users       │       │    products      │
├──────────────────┤       ├──────────────────┤
│ id (PK)          │       │ id (PK)          │
│ email            │       │ farmer_id (FK)   │──┐
│ full_name        │       │ name             │  │
│ phone            │       │ description      │  │
│ role             │       │ price            │  │
│ avatar           │       │ unit             │  │
│ region           │       │ category         │  │
│ district         │       │ stock            │  │
│ is_verified      │       │ images           │  │
│ created_at       │       │ rating           │  │
│ updated_at       │       │ created_at       │  │
└────────┬─────────┘       └──────────────────┘  │
         │                          │            │
         │                          │            │
         │ 1:N                      │ 1:N        │ 1:N
         │                          │            │
         ▼                          ▼            │
┌──────────────────┐       ┌──────────────────┐  │
│     orders       │       │ product_reviews  │  │
├──────────────────┤       ├──────────────────┤  │
│ id (PK)          │       │ id (PK)          │  │
│ user_id (FK)     │──┐    │ product_id (FK)  │  │
│ order_number     │  │    │ user_id (FK)     │──┤
│ status           │  │    │ rating           │  │
│ payment_status   │  │    │ comment          │  │
│ payment_method   │  │    │ images           │  │
│ subtotal         │  │    │ created_at       │  │
│ delivery_fee     │  │    └──────────────────┘  │
│ total            │  │                          │
│ delivery_address │  │    ┌──────────────────┐  │
│ created_at       │  │    │ farmer_followers │  │
└────────┬─────────┘  │    ├──────────────────┤  │
         │            │    │ id (PK)          │  │
         │ 1:N        │    │ farmer_id (FK)   │──┘
         ▼            │    │ follower_id (FK) │──┤
┌──────────────────┐  │    │ created_at       │  │
│   order_items    │  │    └──────────────────┘  │
├──────────────────┤  │                          │
│ id (PK)          │  │    ┌──────────────────┐  │
│ order_id (FK)    │  │    │product_favorites │  │
│ product_id (FK)  │  │    ├──────────────────┤  │
│ quantity         │  │    │ id (PK)          │  │
│ price            │  │    │ product_id (FK)  │──┘
│ created_at       │  │    │ user_id (FK)     │──┤
└──────────────────┘  │    │ created_at       │  │
                      │    └──────────────────┘  │
                      │                          │
                      │    ┌──────────────────┐  │
                      │    │   cart_items     │  │
                      │    ├──────────────────┤  │
                      └───▶│ id (PK)          │  │
                           │ user_id (FK)     │──┘
                           │ product_id (FK)  │
                           │ quantity         │
                           │ created_at       │
                           └──────────────────┘
```

## Table Specifications

### 1. users

Primary table for all user accounts (buyers, farmers, admins).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK, DEFAULT uuid_generate_v4() | Unique identifier |
| email | VARCHAR(255) | UNIQUE, NOT NULL | Email address |
| full_name | VARCHAR(255) | NOT NULL | User's full name |
| phone | VARCHAR(20) | UNIQUE, NOT NULL | Phone number (+256...) |
| role | VARCHAR(20) | NOT NULL, CHECK | buyer, farmer, admin |
| avatar | TEXT | | Profile image URL |
| region | VARCHAR(50) | | Ugandan region |
| district | VARCHAR(100) | | Ugandan district |
| address | TEXT | | Full address |
| is_verified | BOOLEAN | DEFAULT false | Phone/email verified |
| rating | DECIMAL(3,2) | DEFAULT 0.00 | Average rating (farmers) |
| follower_count | INTEGER | DEFAULT 0 | Number of followers |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Registration date |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update |

**Indexes:**
- `idx_users_email` ON email
- `idx_users_phone` ON phone
- `idx_users_role` ON role
- `idx_users_region` ON region

### 2. products

Products listed by farmers.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK | Unique identifier |
| farmer_id | UUID | FK → users.id, NOT NULL | Product owner |
| name | VARCHAR(255) | NOT NULL | Product name |
| description | TEXT | | Detailed description |
| price | DECIMAL(12,2) | NOT NULL, CHECK > 0 | Price in UGX |
| unit | VARCHAR(50) | NOT NULL | kg, bunch, piece, etc. |
| category | VARCHAR(50) | NOT NULL | Product category |
| stock | INTEGER | NOT NULL, DEFAULT 0 | Available quantity |
| images | TEXT[] | | Array of image URLs |
| is_organic | BOOLEAN | DEFAULT false | Organic certification |
| harvest_date | DATE | | When harvested |
| expiry_date | DATE | | Expiration date |
| min_order_qty | INTEGER | DEFAULT 1 | Minimum order quantity |
| max_order_qty | INTEGER | | Maximum per order |
| rating | DECIMAL(3,2) | DEFAULT 0.00 | Average rating |
| review_count | INTEGER | DEFAULT 0 | Number of reviews |
| region | VARCHAR(50) | | Location region |
| district | VARCHAR(100) | | Location district |
| latitude | DECIMAL(10,8) | | GPS latitude |
| longitude | DECIMAL(11,8) | | GPS longitude |
| is_active | BOOLEAN | DEFAULT true | Visible in marketplace |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Listed date |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update |

**Indexes:**
- `idx_products_farmer` ON farmer_id
- `idx_products_category` ON category
- `idx_products_region` ON region
- `idx_products_price` ON price
- `idx_products_search` ON name USING gin (name gin_trgm_ops)
- `idx_products_active` ON is_active WHERE is_active = true

### 3. orders

Customer orders.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK | Unique identifier |
| user_id | UUID | FK → users.id, NOT NULL | Buyer |
| order_number | VARCHAR(50) | UNIQUE, NOT NULL | AGR-YYYY-XXXXXX |
| status | VARCHAR(20) | NOT NULL | Order status |
| payment_status | VARCHAR(20) | DEFAULT 'pending' | Payment status |
| payment_method | VARCHAR(50) | NOT NULL | Payment method |
| subtotal | DECIMAL(12,2) | NOT NULL | Items total |
| delivery_fee | DECIMAL(12,2) | DEFAULT 0 | Delivery cost |
| discount | DECIMAL(12,2) | DEFAULT 0 | Discount applied |
| total | DECIMAL(12,2) | NOT NULL | Final amount |
| delivery_address | TEXT | NOT NULL | Delivery location |
| delivery_notes | TEXT | | Special instructions |
| estimated_delivery | TIMESTAMPTZ | | Expected delivery |
| delivered_at | TIMESTAMPTZ | | Actual delivery time |
| cancelled_at | TIMESTAMPTZ | | Cancellation time |
| cancellation_reason | TEXT | | Why cancelled |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Order placed |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update |

**Status Values:** pending, confirmed, processing, shipped, delivered, cancelled

**Indexes:**
- `idx_orders_user` ON user_id
- `idx_orders_status` ON status
- `idx_orders_number` ON order_number
- `idx_orders_created` ON created_at DESC

### 4. order_items

Individual items within orders.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK | Unique identifier |
| order_id | UUID | FK → orders.id, NOT NULL | Parent order |
| product_id | UUID | FK → products.id, NOT NULL | Product ordered |
| farmer_id | UUID | FK → users.id, NOT NULL | Product seller |
| quantity | INTEGER | NOT NULL, CHECK > 0 | Quantity ordered |
| price | DECIMAL(12,2) | NOT NULL | Price at order time |
| total | DECIMAL(12,2) | NOT NULL | quantity × price |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Created time |

**Indexes:**
- `idx_order_items_order` ON order_id
- `idx_order_items_product` ON product_id
- `idx_order_items_farmer` ON farmer_id

### 5. payments

Payment transaction records.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK | Unique identifier |
| order_id | UUID | FK → orders.id, NOT NULL | Related order |
| user_id | UUID | FK → users.id, NOT NULL | Payer |
| amount | DECIMAL(12,2) | NOT NULL | Payment amount |
| currency | VARCHAR(3) | DEFAULT 'UGX' | Currency code |
| payment_method | VARCHAR(50) | NOT NULL | Payment type |
| status | VARCHAR(20) | NOT NULL | Payment status |
| transaction_ref | VARCHAR(255) | | Provider reference |
| provider_response | JSONB | | Full API response |
| phone_number | VARCHAR(20) | | For mobile money |
| paid_at | TIMESTAMPTZ | | When paid |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Created time |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update |

**Status Values:** pending, processing, completed, failed, refunded

### 6. product_reviews

Customer reviews on products.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK | Unique identifier |
| product_id | UUID | FK → products.id, NOT NULL | Reviewed product |
| user_id | UUID | FK → users.id, NOT NULL | Reviewer |
| order_id | UUID | FK → orders.id | Related order |
| rating | INTEGER | NOT NULL, CHECK 1-5 | Star rating |
| comment | TEXT | | Review text |
| images | TEXT[] | | Review images |
| is_verified | BOOLEAN | DEFAULT false | Verified purchase |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Review date |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last edit |

**Indexes:**
- `idx_reviews_product` ON product_id
- `idx_reviews_user` ON user_id
- `idx_reviews_rating` ON rating

### 7. notifications

User notifications.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK | Unique identifier |
| user_id | UUID | FK → users.id, NOT NULL | Recipient |
| type | VARCHAR(50) | NOT NULL | Notification type |
| title | VARCHAR(255) | NOT NULL | Notification title |
| body | TEXT | NOT NULL | Notification content |
| data | JSONB | | Additional data |
| is_read | BOOLEAN | DEFAULT false | Read status |
| read_at | TIMESTAMPTZ | | When read |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Created time |

**Types:** order_update, payment, promotion, review, message, system

### 8. ai_chat_sessions

AI assistant chat history.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK | Session identifier |
| user_id | UUID | FK → users.id, NOT NULL | Chat owner |
| title | VARCHAR(255) | | Session title |
| messages | JSONB | DEFAULT '[]' | Chat messages |
| token_count | INTEGER | DEFAULT 0 | Tokens used |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Started |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last message |

## Triggers

### 1. Update Timestamp Trigger

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER trigger_update_users_timestamp
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### 2. Product Rating Trigger

```sql
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE products
  SET rating = (
    SELECT COALESCE(AVG(rating), 0)
    FROM product_reviews
    WHERE product_id = NEW.product_id
  ),
  review_count = (
    SELECT COUNT(*)
    FROM product_reviews
    WHERE product_id = NEW.product_id
  )
  WHERE id = NEW.product_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 3. Stock Reduction Trigger

```sql
CREATE OR REPLACE FUNCTION reduce_product_stock()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE products
  SET stock = stock - NEW.quantity
  WHERE id = NEW.product_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## Row Level Security (RLS)

### Users Table

```sql
-- Users can read their own data
CREATE POLICY "Users can view own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

-- Users can update own profile
CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- Public can view farmer profiles
CREATE POLICY "Public can view farmers"
  ON users FOR SELECT
  USING (role = 'farmer');
```

### Products Table

```sql
-- Anyone can view active products
CREATE POLICY "Public can view products"
  ON products FOR SELECT
  USING (is_active = true);

-- Farmers can manage own products
CREATE POLICY "Farmers manage own products"
  ON products FOR ALL
  USING (auth.uid() = farmer_id);
```

### Orders Table

```sql
-- Users can view own orders
CREATE POLICY "Users view own orders"
  ON orders FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create orders
CREATE POLICY "Users create orders"
  ON orders FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

## Performance Optimization

### Query Optimization

1. **Product Search**
   - Use GIN index with pg_trgm for fuzzy search
   - Partial indexes for active products

2. **Order History**
   - Index on user_id + created_at for pagination
   - Materialized view for order counts

3. **Analytics**
   - Pre-aggregated daily stats table
   - Partition orders by month

### Caching Strategy

```
┌────────────────┐
│  Application   │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│     Redis      │ ← Hot data cache
│  Cache Layer   │   - User sessions
└───────┬────────┘   - Product catalog
        │            - Cart data
        ▼
┌────────────────┐
│   PostgreSQL   │ ← Source of truth
│   (Supabase)   │
└────────────────┘
```

## Backup & Recovery

- **Continuous Backup**: Supabase Point-in-Time Recovery
- **Retention**: 7 days (Pro plan)
- **RPO**: < 1 minute
- **RTO**: < 1 hour

## Migration Strategy

1. Schema changes via migration files
2. Version control all migrations
3. Test on staging before production
4. Use transactions for data migrations
5. Monitor query performance after changes

---

Document Version: 1.0
Last Updated: January 2024
