-- ============================================
-- AgriSupply Farm Connect System
-- Supabase Database Schema
-- Complete SQL Migration
-- ============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================
-- 1. USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20) UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'buyer' CHECK (role IN ('buyer', 'farmer', 'admin')),
    photo_url TEXT,
    bio TEXT,
    
    -- Address information
    region VARCHAR(100),
    district VARCHAR(100),
    village VARCHAR(255),
    address_line TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Farmer-specific fields
    farm_name VARCHAR(255),
    farm_size DECIMAL(10, 2),
    farm_size_unit VARCHAR(20) DEFAULT 'acres',
    farming_experience INTEGER,
    crops_grown TEXT[],
    
    -- Verification & Premium
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP WITH TIME ZONE,
    is_premium BOOLEAN DEFAULT FALSE,
    premium_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Account status
    is_suspended BOOLEAN DEFAULT FALSE,
    suspension_reason TEXT,
    suspended_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Statistics
    rating DECIMAL(3, 2) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    total_sales INTEGER DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    
    -- Auth
    auth_provider VARCHAR(50) DEFAULT 'email',
    google_id VARCHAR(255),
    phone_verified BOOLEAN DEFAULT FALSE,
    email_verified BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for users
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_region ON users(region);
CREATE INDEX IF NOT EXISTS idx_users_is_verified ON users(is_verified);
CREATE INDEX IF NOT EXISTS idx_users_is_premium ON users(is_premium);
CREATE INDEX IF NOT EXISTS idx_users_full_name_trgm ON users USING gin(full_name gin_trgm_ops);

-- ============================================
-- 2. PRODUCTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Basic info
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    sub_category VARCHAR(100),
    
    -- Pricing
    price DECIMAL(12, 2) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    min_order_quantity INTEGER DEFAULT 1,
    discount_percentage DECIMAL(5, 2) DEFAULT 0,
    
    -- Stock
    quantity_available INTEGER NOT NULL DEFAULT 0,
    quantity_sold INTEGER DEFAULT 0,
    is_in_stock BOOLEAN DEFAULT TRUE,
    
    -- Media
    images TEXT[],
    thumbnail_url TEXT,
    video_url TEXT,
    
    -- Details
    origin_location VARCHAR(255),
    harvest_date DATE,
    expiry_date DATE,
    is_organic BOOLEAN DEFAULT FALSE,
    is_certified BOOLEAN DEFAULT FALSE,
    certification_type VARCHAR(100),
    
    -- SEO & Discovery
    tags TEXT[],
    is_featured BOOLEAN DEFAULT FALSE,
    featured_until TIMESTAMP WITH TIME ZONE,
    views_count INTEGER DEFAULT 0,
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'sold_out', 'rejected', 'draft')),
    rejection_reason TEXT,
    
    -- Ratings
    rating DECIMAL(3, 2) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for products
CREATE INDEX IF NOT EXISTS idx_products_farmer_id ON products(farmer_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);
CREATE INDEX IF NOT EXISTS idx_products_is_featured ON products(is_featured);
CREATE INDEX IF NOT EXISTS idx_products_rating ON products(rating);
CREATE INDEX IF NOT EXISTS idx_products_name_trgm ON products USING gin(name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_description_trgm ON products USING gin(description gin_trgm_ops);

-- ============================================
-- 3. ORDERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    buyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Pricing
    subtotal DECIMAL(12, 2) NOT NULL,
    delivery_fee DECIMAL(10, 2) DEFAULT 0,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(12, 2) NOT NULL,
    
    -- Delivery
    delivery_address TEXT NOT NULL,
    delivery_region VARCHAR(100),
    delivery_district VARCHAR(100),
    delivery_latitude DECIMAL(10, 8),
    delivery_longitude DECIMAL(11, 8),
    delivery_instructions TEXT,
    estimated_delivery_date DATE,
    actual_delivery_date TIMESTAMP WITH TIME ZONE,
    
    -- Tracking
    tracking_number VARCHAR(50),
    
    -- Status
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN (
        'pending', 'confirmed', 'processing', 'shipped', 
        'out_for_delivery', 'delivered', 'cancelled', 'refunded'
    )),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN (
        'pending', 'paid', 'failed', 'refunded'
    )),
    
    -- Cancellation/Refund
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT,
    cancelled_by UUID REFERENCES users(id),
    refund_requested BOOLEAN DEFAULT FALSE,
    refund_reason TEXT,
    
    -- Admin
    admin_notes TEXT,
    
    -- Timestamps
    confirmed_at TIMESTAMP WITH TIME ZONE,
    shipped_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for orders
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_buyer_id ON orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_region ON orders(delivery_region);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);

-- ============================================
-- 4. ORDER ITEMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    farmer_id UUID NOT NULL REFERENCES users(id),
    
    -- Item details (snapshot at order time)
    product_name VARCHAR(255) NOT NULL,
    product_image TEXT,
    unit_price DECIMAL(12, 2) NOT NULL,
    quantity INTEGER NOT NULL,
    subtotal DECIMAL(12, 2) NOT NULL,
    
    -- Status for multi-seller orders
    status VARCHAR(30) DEFAULT 'pending',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for order items
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_farmer_id ON order_items(farmer_id);

-- ============================================
-- 5. ORDER STATUS HISTORY
-- ============================================
CREATE TABLE IF NOT EXISTS order_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status VARCHAR(30) NOT NULL,
    notes TEXT,
    changed_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);

-- ============================================
-- 6. PAYMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    
    -- Payment details
    amount DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'UGX',
    payment_method VARCHAR(50) NOT NULL,
    
    -- Provider reference
    provider_reference VARCHAR(255),
    provider_transaction_id VARCHAR(255),
    
    -- Mobile Money specifics
    phone_number VARCHAR(20),
    mobile_money_provider VARCHAR(50),
    
    -- Card specifics (for Flutterwave)
    card_last_four VARCHAR(4),
    card_type VARCHAR(50),
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'successful', 'failed', 'cancelled', 'refunded'
    )),
    failure_reason TEXT,
    
    -- Timestamps
    initiated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for payments
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_provider_reference ON payments(provider_reference);

-- ============================================
-- 7. REFUNDS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS refunds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id),
    user_id UUID NOT NULL REFERENCES users(id),
    
    amount DECIMAL(12, 2) NOT NULL,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'processed', 'failed'
    )),
    
    processed_by UUID REFERENCES users(id),
    processed_at TIMESTAMP WITH TIME ZONE,
    failure_reason TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_refunds_payment_id ON refunds(payment_id);
CREATE INDEX IF NOT EXISTS idx_refunds_order_id ON refunds(order_id);
CREATE INDEX IF NOT EXISTS idx_refunds_user_id ON refunds(user_id);

-- ============================================
-- 8. NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- ============================================
-- 9. NOTIFICATION PREFERENCES
-- ============================================
CREATE TABLE IF NOT EXISTS notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    push_enabled BOOLEAN DEFAULT TRUE,
    email_enabled BOOLEAN DEFAULT TRUE,
    sms_enabled BOOLEAN DEFAULT FALSE,
    
    order_updates BOOLEAN DEFAULT TRUE,
    promotional BOOLEAN DEFAULT TRUE,
    price_alerts BOOLEAN DEFAULT TRUE,
    new_products BOOLEAN DEFAULT TRUE,
    messages BOOLEAN DEFAULT TRUE,
    tips_and_advice BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id ON notification_preferences(user_id);

-- ============================================
-- 10. USER DEVICES (for Push Notifications)
-- ============================================
CREATE TABLE IF NOT EXISTS user_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    device_token TEXT NOT NULL,
    device_type VARCHAR(20) NOT NULL CHECK (device_type IN ('android', 'ios', 'web')),
    device_name VARCHAR(255),
    
    is_active BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_device_token ON user_devices(device_token);

-- ============================================
-- 11. PRODUCT REVIEWS
-- ============================================
CREATE TABLE IF NOT EXISTS product_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id),
    
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    images TEXT[],
    
    is_verified_purchase BOOLEAN DEFAULT FALSE,
    is_visible BOOLEAN DEFAULT TRUE,
    
    helpful_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(product_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_product_reviews_product_id ON product_reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_product_reviews_user_id ON product_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_product_reviews_rating ON product_reviews(rating);

-- ============================================
-- 12. PRODUCT FAVORITES
-- ============================================
CREATE TABLE IF NOT EXISTS product_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, product_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_product_favorites_user_id ON product_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_product_favorites_product_id ON product_favorites(product_id);

-- ============================================
-- 13. FARMER FOLLOWERS
-- ============================================
CREATE TABLE IF NOT EXISTS farmer_followers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(farmer_id, follower_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_farmer_followers_farmer_id ON farmer_followers(farmer_id);
CREATE INDEX IF NOT EXISTS idx_farmer_followers_follower_id ON farmer_followers(follower_id);

-- ============================================
-- 14. AI CHAT SESSIONS
-- ============================================
CREATE TABLE IF NOT EXISTS ai_chat_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    title VARCHAR(255),
    messages JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_ai_chat_sessions_user_id ON ai_chat_sessions(user_id);

-- ============================================
-- 15. AI USAGE TRACKING
-- ============================================
CREATE TABLE IF NOT EXISTS ai_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    feature VARCHAR(50) NOT NULL,
    tokens_used INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_ai_usage_user_id ON ai_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_usage_feature ON ai_usage(feature);
CREATE INDEX IF NOT EXISTS idx_ai_usage_created_at ON ai_usage(created_at);

-- ============================================
-- 16. CART ITEMS
-- ============================================
CREATE TABLE IF NOT EXISTS cart_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, product_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON cart_items(user_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_product_id ON cart_items(product_id);

-- ============================================
-- 17. SYSTEM SETTINGS
-- ============================================
CREATE TABLE IF NOT EXISTS system_settings (
    id INTEGER PRIMARY KEY DEFAULT 1,
    
    maintenance_mode BOOLEAN DEFAULT FALSE,
    registration_enabled BOOLEAN DEFAULT TRUE,
    
    min_withdrawal_amount DECIMAL(12, 2) DEFAULT 50000,
    commission_rate DECIMAL(5, 2) DEFAULT 5,
    delivery_fee_per_km DECIMAL(10, 2) DEFAULT 500,
    
    featured_product_fee DECIMAL(12, 2) DEFAULT 10000,
    premium_monthly_fee DECIMAL(12, 2) DEFAULT 50000,
    premium_yearly_fee DECIMAL(12, 2) DEFAULT 500000,
    
    support_email VARCHAR(255) DEFAULT 'support@agrisupply.ug',
    support_phone VARCHAR(20) DEFAULT '+256700000000',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT single_row CHECK (id = 1)
);

-- Insert default settings
INSERT INTO system_settings (id) VALUES (1) ON CONFLICT DO NOTHING;

-- ============================================
-- 18. FARMER PAYOUTS
-- ============================================
CREATE TABLE IF NOT EXISTS farmer_payouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    amount DECIMAL(12, 2) NOT NULL,
    commission_amount DECIMAL(10, 2) DEFAULT 0,
    net_amount DECIMAL(12, 2) NOT NULL,
    
    payment_method VARCHAR(50) NOT NULL,
    phone_number VARCHAR(20),
    
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'completed', 'failed'
    )),
    
    provider_reference VARCHAR(255),
    failure_reason TEXT,
    
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_farmer_payouts_farmer_id ON farmer_payouts(farmer_id);
CREATE INDEX IF NOT EXISTS idx_farmer_payouts_status ON farmer_payouts(status);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to tables
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_orders_updated_at ON orders;
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_payments_updated_at ON payments;
CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_notification_preferences_updated_at ON notification_preferences;
CREATE TRIGGER update_notification_preferences_updated_at
    BEFORE UPDATE ON notification_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_product_reviews_updated_at ON product_reviews;
CREATE TRIGGER update_product_reviews_updated_at
    BEFORE UPDATE ON product_reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_cart_items_updated_at ON cart_items;
CREATE TRIGGER update_cart_items_updated_at
    BEFORE UPDATE ON cart_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_ai_chat_sessions_updated_at ON ai_chat_sessions;
CREATE TRIGGER update_ai_chat_sessions_updated_at
    BEFORE UPDATE ON ai_chat_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_system_settings_updated_at ON system_settings;
CREATE TRIGGER update_system_settings_updated_at
    BEFORE UPDATE ON system_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update product rating
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE products SET
        rating = (
            SELECT COALESCE(AVG(rating), 0)
            FROM product_reviews
            WHERE product_id = COALESCE(NEW.product_id, OLD.product_id)
            AND is_visible = TRUE
        ),
        total_reviews = (
            SELECT COUNT(*)
DROP TRIGGER IF EXISTS update_product_rating_on_review ON product_reviews;
            FROM product_reviews
            WHERE product_id = COALESCE(NEW.product_id, OLD.product_id)
            AND is_visible = TRUE
        )
    WHERE id = COALESCE(NEW.product_id, OLD.product_id);
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

CREATE TRIGGER update_product_rating_on_review
    AFTER INSERT OR UPDATE OR DELETE ON product_reviews
    FOR EACH ROW EXECUTE FUNCTION update_product_rating();

-- Function to update farmer followers count
CREATE OR REPLACE FUNCTION update_followers_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
DROP TRIGGER IF EXISTS update_followers_count_trigger ON farmer_followers;
        UPDATE users SET followers_count = followers_count + 1 WHERE id = NEW.farmer_id;
        UPDATE users SET following_count = following_count + 1 WHERE id = NEW.follower_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE users SET followers_count = followers_count - 1 WHERE id = OLD.farmer_id;
        UPDATE users SET following_count = following_count - 1 WHERE id = OLD.follower_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

CREATE TRIGGER update_followers_count_trigger
    AFTER INSERT OR DELETE ON farmer_followers
    FOR EACH ROW EXECUTE FUNCTION update_followers_count();

-- Function to handle new user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, auth
LANGUAGE plpgsql
AS $$
BEGIN
    -- Log the trigger execution for debugging
    RAISE LOG 'Creating user profile for user_id: %, email: %', NEW.id, NEW.email;
    
    -- Insert a row into public.users
    INSERT INTO public.users (
        id,
        email,
        full_name,
        phone,
        role,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
        COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone'),
        COALESCE(NEW.raw_user_meta_data->>'role', 'buyer'),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, users.full_name),
        phone = COALESCE(EXCLUDED.phone, users.phone),
        role = COALESCE(EXCLUDED.role, users.role),
        updated_at = NOW();
    
    RAISE LOG 'User profile created successfully for user_id: %', NEW.id;
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the auth creation
        RAISE LOG 'Error in handle_new_user for user_id %, error: %', NEW.id, SQLERRM;
        RAISE WARNING 'Failed to create user profile: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Trigger to automatically create user profile on auth.users insert
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view public profiles" ON users;
CREATE POLICY "Users can view public profiles"
    ON users FOR SELECT
    USING (is_deleted = FALSE AND is_suspended = FALSE);

DROP POLICY IF EXISTS "Users can insert own profile during signup" ON users;
CREATE POLICY "Users can insert own profile during signup"
    ON users FOR INSERT
    WITH CHECK (
        auth.uid() = id OR
        auth.role() = 'service_role'
    );

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);

-- Products policies
DROP POLICY IF EXISTS "Anyone can view active products" ON products;
CREATE POLICY "Anyone can view active products"
    ON products FOR SELECT
    USING (status = 'active');

DROP POLICY IF EXISTS "Farmers can manage own products" ON products;
CREATE POLICY "Farmers can manage own products"
    ON products FOR ALL
    USING (auth.uid() = farmer_id);

-- Orders policies
DROP POLICY IF EXISTS "Users can view own orders" ON orders;
CREATE POLICY "Users can view own orders"
    ON orders FOR SELECT
    USING (auth.uid() = buyer_id);

DROP POLICY IF EXISTS "Farmers can view orders with their products" ON order_items;
CREATE POLICY "Farmers can view orders with their products"
    ON order_items FOR SELECT
    USING (auth.uid() = farmer_id);

-- Notifications policies
DROP POLICY IF EXISTS "Users can manage own notifications" ON notifications;
CREATE POLICY "Users can manage own notifications"
    ON notifications FOR ALL
    USING (auth.uid() = user_id);

-- Cart policies
DROP POLICY IF EXISTS "Users can manage own cart" ON cart_items;
CREATE POLICY "Users can manage own cart"
    ON cart_items FOR ALL
    USING (auth.uid() = user_id);

-- AI Chat policies
DROP POLICY IF EXISTS "Users can manage own AI sessions" ON ai_chat_sessions;
-- Notifications policies
CREATE POLICY "Users can manage own notifications"
    ON notifications FOR ALL
    USING (auth.uid() = user_id);

-- Cart policies
CREATE POLICY "Users can manage own cart"
    ON cart_items FOR ALL
    USING (auth.uid() = user_id);

-- AI Chat policies
CREATE POLICY "Users can manage own AI sessions"
    ON ai_chat_sessions FOR ALL
    USING (auth.uid() = user_id);

-- ============================================
-- STORAGE BUCKETS (Run in Supabase Dashboard)
-- ============================================
/*
-- Create storage buckets (execute these in Supabase SQL Editor or Dashboard)

INSERT INTO storage.buckets (id, name, public) VALUES 
    ('profile-photos', 'profile-photos', true),
    ('product-images', 'product-images', true),
    ('review-images', 'review-images', true),
    ('ai-images', 'ai-images', false),
    ('documents', 'documents', false);

-- Storage policies
CREATE POLICY "Anyone can view public images"
    ON storage.objects FOR SELECT
    USING (bucket_id IN ('profile-photos', 'product-images', 'review-images'));

CREATE POLICY "Authenticated users can upload"
    ON storage.objects FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update own files"
    ON storage.objects FOR UPDATE
    USING (auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own files"
    ON storage.objects FOR DELETE
    USING (auth.uid()::text = (storage.foldername(name))[1]);
*/

-- ============================================
-- SEED DATA (Optional)
-- ============================================

-- Insert product categories as reference
-- This is informational only, categories are stored in the application

/*
Product Categories:
- Vegetables
- Fruits
- Grains
- Legumes
- Tubers
- Dairy
- Poultry
- Livestock
- Fish
- Coffee
- Tea
- Spices
- Herbs
- Honey
- Seeds
- Fertilizers
- Equipment
- Other

Uganda Regions:
- Central
- Eastern
- Northern
- Western

Sample Districts by Region:
Central: Kampala, Wakiso, Mukono, Jinja, Masaka
Eastern: Mbale, Soroti, Tororo, Iganga, Busia
Northern: Gulu, Lira, Arua, Kitgum, Moroto
Western: Mbarara, Fort Portal, Kabale, Kasese, Hoima
*/

-- Success message
SELECT 'AgriSupply database schema created successfully!' AS message;
