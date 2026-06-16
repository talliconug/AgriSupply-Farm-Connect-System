-- ============================================
-- AgriSupply Farm Connect System
-- Seed Data for Development/Testing
-- ============================================

-- ============================================
-- 1. SEED ADMIN USER
-- ============================================
-- Note: Password should be set via Supabase Auth, not here
INSERT INTO users (
    id,
    email,
    phone,
    full_name,
    role,
    region,
    district,
    is_verified,
    verified_at,
    email_verified,
    phone_verified,
    created_at
) VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'admin@agrisupply.ug',
    '+256700000001',
    'System Administrator',
    'admin',
    'Central',
    'Kampala',
    true,
    NOW(),
    true,
    true,
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- ============================================
-- 2. SEED SAMPLE FARMERS
-- ============================================
INSERT INTO users (
    id,
    email,
    phone,
    full_name,
    role,
    region,
    district,
    village,
    farm_name,
    farm_size,
    farming_experience,
    crops_grown,
    bio,
    is_verified,
    verified_at,
    rating,
    created_at
) VALUES 
(
    'f0000000-0000-0000-0000-000000000001',
    'mukasa.james@example.com',
    '+256701234567',
    'Mukasa James',
    'farmer',
    'Central',
    'Wakiso',
    'Nansana',
    'Mukasa Family Farm',
    5.5,
    10,
    ARRAY['Matooke', 'Coffee', 'Beans'],
    'Experienced farmer specializing in organic matooke and arabica coffee. Third generation farmer committed to sustainable practices.',
    true,
    NOW(),
    4.8,
    NOW() - INTERVAL '6 months'
),
(
    'f0000000-0000-0000-0000-000000000002',
    'nakato.sarah@example.com',
    '+256702345678',
    'Nakato Sarah',
    'farmer',
    'Eastern',
    'Mbale',
    'Bududa',
    'Green Hills Organic Farm',
    3.0,
    5,
    ARRAY['Coffee', 'Maize', 'Vegetables'],
    'Young farmer passionate about organic farming and helping communities access fresh produce.',
    true,
    NOW(),
    4.6,
    NOW() - INTERVAL '3 months'
),
(
    'f0000000-0000-0000-0000-000000000003',
    'okello.peter@example.com',
    '+256703456789',
    'Okello Peter',
    'farmer',
    'Northern',
    'Gulu',
    'Pece',
    'Northern Grains Farm',
    10.0,
    15,
    ARRAY['Maize', 'Millet', 'Groundnuts', 'Simsim'],
    'Large-scale grain farmer supplying to markets across Northern Uganda.',
    true,
    NOW(),
    4.5,
    NOW() - INTERVAL '1 year'
),
(
    'f0000000-0000-0000-0000-000000000004',
    'kabahinda.grace@example.com',
    '+256704567890',
    'Kabahinda Grace',
    'farmer',
    'Western',
    'Mbarara',
    'Kakoba',
    'Ankole Dairy & Poultry',
    8.0,
    12,
    ARRAY['Dairy', 'Poultry', 'Matooke'],
    'Premium dairy products from Ankole cattle and free-range eggs.',
    true,
    NOW(),
    4.9,
    NOW() - INTERVAL '8 months'
),
(
    'f0000000-0000-0000-0000-000000000005',
    'kyomugisha.mary@example.com',
    '+256705678901',
    'Kyomugisha Mary',
    'farmer',
    'Western',
    'Kabale',
    'Rubanda',
    'Highland Produce Farm',
    4.0,
    7,
    ARRAY['Irish Potatoes', 'Cabbage', 'Carrots', 'Onions'],
    'Highland vegetable specialist. Fresh produce from the cool Kigezi highlands.',
    true,
    NOW(),
    4.7,
    NOW() - INTERVAL '4 months'
)
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- 3. SEED SAMPLE BUYERS
-- ============================================
INSERT INTO users (
    id,
    email,
    phone,
    full_name,
    role,
    region,
    district,
    address_line,
    created_at
) VALUES 
(
    'b0000000-0000-0000-0000-000000000001',
    'namugera.david@example.com',
    '+256706789012',
    'Namugera David',
    'buyer',
    'Central',
    'Kampala',
    'Wandegeya, Kampala',
    NOW() - INTERVAL '2 months'
),
(
    'b0000000-0000-0000-0000-000000000002',
    'achieng.joyce@example.com',
    '+256707890123',
    'Achieng Joyce',
    'buyer',
    'Eastern',
    'Jinja',
    'Main Street, Jinja',
    NOW() - INTERVAL '1 month'
),
(
    'b0000000-0000-0000-0000-000000000003',
    'tumusiime.robert@example.com',
    '+256708901234',
    'Tumusiime Robert',
    'buyer',
    'Western',
    'Fort Portal',
    'Rwenzori Road, Fort Portal',
    NOW() - INTERVAL '3 weeks'
)
ON CONFLICT (email) DO NOTHING;

-- ============================================
-- 4. SEED SAMPLE PRODUCTS
-- ============================================
INSERT INTO products (
    id,
    farmer_id,
    name,
    description,
    category,
    price,
    unit,
    quantity_available,
    min_order_quantity,
    is_organic,
    origin_location,
    status,
    rating,
    is_featured,
    views_count,
    tags,
    created_at
) VALUES 
-- Mukasa James's products
(
    'p0000000-0000-0000-0000-000000000001',
    'f0000000-0000-0000-0000-000000000001',
    'Fresh Organic Matooke',
    'Premium organic matooke from Wakiso. Harvested fresh daily. Perfect for making delicious matooke dishes. No chemicals or pesticides used.',
    'Fruits',
    35000,
    'bunch',
    50,
    1,
    true,
    'Nansana, Wakiso',
    'active',
    4.8,
    true,
    245,
    ARRAY['organic', 'matooke', 'fresh', 'wakiso'],
    NOW() - INTERVAL '5 months'
),
(
    'p0000000-0000-0000-0000-000000000002',
    'f0000000-0000-0000-0000-000000000001',
    'Arabica Coffee Beans',
    'Premium Arabica coffee beans, sun-dried and hand-sorted. Rich aroma with chocolate and fruity notes.',
    'Coffee',
    45000,
    'kg',
    100,
    2,
    true,
    'Nansana, Wakiso',
    'active',
    4.9,
    true,
    189,
    ARRAY['coffee', 'arabica', 'premium', 'organic'],
    NOW() - INTERVAL '4 months'
),
-- Nakato Sarah's products
(
    'p0000000-0000-0000-0000-000000000003',
    'f0000000-0000-0000-0000-000000000002',
    'Mixed Vegetables Bundle',
    'Fresh bundle of mixed vegetables including tomatoes, onions, green peppers, and eggplants. Perfect for a week of healthy cooking.',
    'Vegetables',
    25000,
    'bundle',
    30,
    1,
    true,
    'Bududa, Mbale',
    'active',
    4.6,
    false,
    156,
    ARRAY['vegetables', 'fresh', 'mixed', 'organic'],
    NOW() - INTERVAL '2 months'
),
(
    'p0000000-0000-0000-0000-000000000004',
    'f0000000-0000-0000-0000-000000000002',
    'Fresh Maize (Green)',
    'Sweet fresh maize cobs, perfect for roasting or boiling. Harvested same day.',
    'Grains',
    15000,
    'dozen',
    80,
    2,
    false,
    'Bududa, Mbale',
    'active',
    4.5,
    false,
    98,
    ARRAY['maize', 'corn', 'fresh', 'green'],
    NOW() - INTERVAL '1 month'
),
-- Okello Peter's products
(
    'p0000000-0000-0000-0000-000000000005',
    'f0000000-0000-0000-0000-000000000003',
    'Dry Maize (White)',
    'High-quality white maize grain. Perfect for posho, flour, or animal feed. Properly dried and stored.',
    'Grains',
    2500,
    'kg',
    500,
    10,
    false,
    'Pece, Gulu',
    'active',
    4.4,
    false,
    312,
    ARRAY['maize', 'dry', 'white', 'grain'],
    NOW() - INTERVAL '10 months'
),
(
    'p0000000-0000-0000-0000-000000000006',
    'f0000000-0000-0000-0000-000000000003',
    'Simsim (Sesame Seeds)',
    'Pure Northern Uganda simsim. High oil content, perfect for cooking or paste. Clean and sorted.',
    'Grains',
    8000,
    'kg',
    200,
    5,
    false,
    'Pece, Gulu',
    'active',
    4.6,
    true,
    178,
    ARRAY['simsim', 'sesame', 'seeds', 'northern'],
    NOW() - INTERVAL '8 months'
),
(
    'p0000000-0000-0000-0000-000000000007',
    'f0000000-0000-0000-0000-000000000003',
    'Groundnuts (Roasted)',
    'Premium roasted groundnuts from Northern Uganda. Crunchy and delicious.',
    'Legumes',
    6000,
    'kg',
    150,
    3,
    false,
    'Pece, Gulu',
    'active',
    4.7,
    false,
    145,
    ARRAY['groundnuts', 'peanuts', 'roasted', 'snacks'],
    NOW() - INTERVAL '6 months'
),
-- Kabahinda Grace's products
(
    'p0000000-0000-0000-0000-000000000008',
    'f0000000-0000-0000-0000-000000000004',
    'Fresh Farm Milk',
    'Pure Ankole cow milk delivered fresh daily. Rich in nutrients and natural taste.',
    'Dairy',
    3500,
    'litre',
    100,
    5,
    true,
    'Kakoba, Mbarara',
    'active',
    4.9,
    true,
    423,
    ARRAY['milk', 'fresh', 'dairy', 'ankole'],
    NOW() - INTERVAL '7 months'
),
(
    'p0000000-0000-0000-0000-000000000009',
    'f0000000-0000-0000-0000-000000000004',
    'Free-Range Eggs',
    'Farm fresh eggs from free-range chickens. Rich yellow yolks, perfect for breakfast.',
    'Poultry',
    15000,
    'tray (30)',
    50,
    1,
    true,
    'Kakoba, Mbarara',
    'active',
    4.8,
    false,
    287,
    ARRAY['eggs', 'free-range', 'fresh', 'poultry'],
    NOW() - INTERVAL '6 months'
),
(
    'p0000000-0000-0000-0000-000000000010',
    'f0000000-0000-0000-0000-000000000004',
    'Local Chicken (Kienyeji)',
    'Healthy free-range local chickens. Great taste, no antibiotics.',
    'Poultry',
    45000,
    'chicken',
    20,
    1,
    true,
    'Kakoba, Mbarara',
    'active',
    4.9,
    false,
    198,
    ARRAY['chicken', 'kienyeji', 'local', 'organic'],
    NOW() - INTERVAL '4 months'
),
-- Kyomugisha Mary's products
(
    'p0000000-0000-0000-0000-000000000011',
    'f0000000-0000-0000-0000-000000000005',
    'Irish Potatoes',
    'Fresh highland Irish potatoes from Kabale. Great for chips, mashing, or roasting.',
    'Tubers',
    3000,
    'kg',
    300,
    10,
    false,
    'Rubanda, Kabale',
    'active',
    4.6,
    false,
    234,
    ARRAY['potatoes', 'irish', 'tubers', 'kabale'],
    NOW() - INTERVAL '3 months'
),
(
    'p0000000-0000-0000-0000-000000000012',
    'f0000000-0000-0000-0000-000000000005',
    'Fresh Cabbage',
    'Large, firm cabbage heads from the cool Kigezi highlands. Perfect for salads and cooking.',
    'Vegetables',
    5000,
    'head',
    100,
    3,
    false,
    'Rubanda, Kabale',
    'active',
    4.5,
    false,
    123,
    ARRAY['cabbage', 'vegetables', 'fresh', 'highlands'],
    NOW() - INTERVAL '2 months'
),
(
    'p0000000-0000-0000-0000-000000000013',
    'f0000000-0000-0000-0000-000000000005',
    'Fresh Carrots',
    'Sweet, crunchy carrots from Kabale. Rich in vitamins, great for juicing or cooking.',
    'Vegetables',
    4000,
    'kg',
    150,
    5,
    false,
    'Rubanda, Kabale',
    'active',
    4.7,
    false,
    167,
    ARRAY['carrots', 'vegetables', 'fresh', 'organic'],
    NOW() - INTERVAL '1 month'
),
(
    'p0000000-0000-0000-0000-000000000014',
    'f0000000-0000-0000-0000-000000000005',
    'Red Onions',
    'Quality red onions from highland farms. Strong flavor, long shelf life.',
    'Vegetables',
    4500,
    'kg',
    200,
    5,
    false,
    'Rubanda, Kabale',
    'active',
    4.4,
    false,
    189,
    ARRAY['onions', 'red', 'vegetables', 'cooking'],
    NOW() - INTERVAL '3 weeks'
)
ON CONFLICT DO NOTHING;

-- ============================================
-- 5. SEED SAMPLE REVIEWS
-- ============================================
INSERT INTO product_reviews (
    id,
    product_id,
    user_id,
    rating,
    comment,
    is_verified_purchase,
    is_visible,
    created_at
) VALUES 
(
    'r0000000-0000-0000-0000-000000000001',
    'p0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000001',
    5,
    'Excellent quality matooke! Very fresh and the bunch was big. Will definitely order again.',
    true,
    true,
    NOW() - INTERVAL '1 month'
),
(
    'r0000000-0000-0000-0000-000000000002',
    'p0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000002',
    4,
    'Good matooke, delivery was a bit delayed but quality was great.',
    true,
    true,
    NOW() - INTERVAL '2 weeks'
),
(
    'r0000000-0000-0000-0000-000000000003',
    'p0000000-0000-0000-0000-000000000008',
    'b0000000-0000-0000-0000-000000000001',
    5,
    'Best milk I have ever tasted! Pure and fresh, my children love it.',
    true,
    true,
    NOW() - INTERVAL '3 weeks'
),
(
    'r0000000-0000-0000-0000-000000000004',
    'p0000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000003',
    5,
    'Amazing coffee! The aroma is wonderful and taste is smooth. Premium quality.',
    true,
    true,
    NOW() - INTERVAL '1 week'
)
ON CONFLICT DO NOTHING;

-- ============================================
-- 6. SEED SAMPLE ORDERS
-- ============================================
INSERT INTO orders (
    id,
    order_number,
    buyer_id,
    subtotal,
    delivery_fee,
    total_amount,
    delivery_address,
    delivery_region,
    delivery_district,
    status,
    payment_status,
    created_at
) VALUES 
(
    'o0000000-0000-0000-0000-000000000001',
    'AGR-2024-00001',
    'b0000000-0000-0000-0000-000000000001',
    105000,
    10000,
    115000,
    'Wandegeya, Near Total Petrol Station, Kampala',
    'Central',
    'Kampala',
    'delivered',
    'paid',
    NOW() - INTERVAL '2 months'
),
(
    'o0000000-0000-0000-0000-000000000002',
    'AGR-2024-00002',
    'b0000000-0000-0000-0000-000000000002',
    70000,
    15000,
    85000,
    'Main Street, Near Clock Tower, Jinja',
    'Eastern',
    'Jinja',
    'delivered',
    'paid',
    NOW() - INTERVAL '1 month'
),
(
    'o0000000-0000-0000-0000-000000000003',
    'AGR-2024-00003',
    'b0000000-0000-0000-0000-000000000001',
    52500,
    10000,
    62500,
    'Wandegeya, Near Total Petrol Station, Kampala',
    'Central',
    'Kampala',
    'shipped',
    'paid',
    NOW() - INTERVAL '1 week'
)
ON CONFLICT DO NOTHING;

-- ============================================
-- 7. SEED SAMPLE ORDER ITEMS
-- ============================================
INSERT INTO order_items (
    id,
    order_id,
    product_id,
    farmer_id,
    product_name,
    unit_price,
    quantity,
    subtotal
) VALUES 
-- Order 1 items
(
    'oi000000-0000-0000-0000-000000000001',
    'o0000000-0000-0000-0000-000000000001',
    'p0000000-0000-0000-0000-000000000001',
    'f0000000-0000-0000-0000-000000000001',
    'Fresh Organic Matooke',
    35000,
    2,
    70000
),
(
    'oi000000-0000-0000-0000-000000000002',
    'o0000000-0000-0000-0000-000000000001',
    'p0000000-0000-0000-0000-000000000008',
    'f0000000-0000-0000-0000-000000000004',
    'Fresh Farm Milk',
    3500,
    10,
    35000
),
-- Order 2 items
(
    'oi000000-0000-0000-0000-000000000003',
    'o0000000-0000-0000-0000-000000000002',
    'p0000000-0000-0000-0000-000000000002',
    'f0000000-0000-0000-0000-000000000001',
    'Arabica Coffee Beans',
    45000,
    1,
    45000
),
(
    'oi000000-0000-0000-0000-000000000004',
    'o0000000-0000-0000-0000-000000000002',
    'p0000000-0000-0000-0000-000000000003',
    'f0000000-0000-0000-0000-000000000002',
    'Mixed Vegetables Bundle',
    25000,
    1,
    25000
),
-- Order 3 items
(
    'oi000000-0000-0000-0000-000000000005',
    'o0000000-0000-0000-0000-000000000003',
    'p0000000-0000-0000-0000-000000000008',
    'f0000000-0000-0000-0000-000000000004',
    'Fresh Farm Milk',
    3500,
    15,
    52500
)
ON CONFLICT DO NOTHING;

-- ============================================
-- 8. SEED NOTIFICATION PREFERENCES
-- ============================================
INSERT INTO notification_preferences (
    user_id,
    push_enabled,
    email_enabled,
    sms_enabled,
    order_updates,
    promotional,
    price_alerts,
    new_products,
    messages,
    tips_and_advice
)
SELECT 
    id,
    true,
    true,
    false,
    true,
    true,
    true,
    true,
    true,
    true
FROM users
ON CONFLICT (user_id) DO NOTHING;

-- ============================================
-- 9. SEED SAMPLE NOTIFICATIONS
-- ============================================
INSERT INTO notifications (
    id,
    user_id,
    type,
    title,
    message,
    is_read,
    created_at
) VALUES 
(
    'n0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000001',
    'order',
    'Order Delivered',
    'Your order #AGR-2024-00001 has been delivered. Thank you for shopping with AgriSupply!',
    true,
    NOW() - INTERVAL '2 months'
),
(
    'n0000000-0000-0000-0000-000000000002',
    'f0000000-0000-0000-0000-000000000001',
    'order',
    'New Order Received',
    'You have received a new order for Fresh Organic Matooke. Please confirm within 24 hours.',
    true,
    NOW() - INTERVAL '2 months'
),
(
    'n0000000-0000-0000-0000-000000000003',
    'b0000000-0000-0000-0000-000000000001',
    'promotion',
    'Weekend Special!',
    'Get 10% off on all dairy products this weekend. Use code DAIRY10 at checkout.',
    false,
    NOW() - INTERVAL '1 day'
)
ON CONFLICT DO NOTHING;

-- ============================================
-- 10. SEED FARMER FOLLOWERS
-- ============================================
INSERT INTO farmer_followers (
    farmer_id,
    follower_id
) VALUES 
(
    'f0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000001'
),
(
    'f0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000002'
),
(
    'f0000000-0000-0000-0000-000000000004',
    'b0000000-0000-0000-0000-000000000001'
),
(
    'f0000000-0000-0000-0000-000000000004',
    'b0000000-0000-0000-0000-000000000003'
)
ON CONFLICT DO NOTHING;

-- ============================================
-- 11. SEED PRODUCT FAVORITES
-- ============================================
INSERT INTO product_favorites (
    user_id,
    product_id
) VALUES 
(
    'b0000000-0000-0000-0000-000000000001',
    'p0000000-0000-0000-0000-000000000001'
),
(
    'b0000000-0000-0000-0000-000000000001',
    'p0000000-0000-0000-0000-000000000008'
),
(
    'b0000000-0000-0000-0000-000000000002',
    'p0000000-0000-0000-0000-000000000002'
),
(
    'b0000000-0000-0000-0000-000000000003',
    'p0000000-0000-0000-0000-000000000008'
)
ON CONFLICT DO NOTHING;

-- Update follower counts
UPDATE users SET followers_count = 2 WHERE id = 'f0000000-0000-0000-0000-000000000001';
UPDATE users SET followers_count = 2 WHERE id = 'f0000000-0000-0000-0000-000000000004';
UPDATE users SET following_count = 2 WHERE id = 'b0000000-0000-0000-0000-000000000001';
UPDATE users SET following_count = 1 WHERE id = 'b0000000-0000-0000-0000-000000000002';
UPDATE users SET following_count = 1 WHERE id = 'b0000000-0000-0000-0000-000000000003';

-- Success message
SELECT 'AgriSupply seed data inserted successfully!' AS message;
SELECT 
    (SELECT COUNT(*) FROM users) AS users_count,
    (SELECT COUNT(*) FROM products) AS products_count,
    (SELECT COUNT(*) FROM orders) AS orders_count,
    (SELECT COUNT(*) FROM product_reviews) AS reviews_count;
