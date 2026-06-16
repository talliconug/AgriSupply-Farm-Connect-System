#!/usr/bin/env node

/**
 * Database Seeder Script
 * Populates the database with sample data for development and testing
 * 
 * Usage: node scripts/seed.js
 */

const { createClient } = require('@supabase/supabase-js');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const defaultAdminPassword = process.env.DEFAULT_ADMIN_PASSWORD || 'admin1234';

// Sample data
const users = [
  {
    email: 'farmer1@agrisupply.ug',
    password: 'Password123!',
    full_name: 'Nakato Sarah',
    phone: '+256771234567',
    role: 'farmer',
    region: 'Central',
    is_verified: true,
  },
  {
    email: 'farmer2@agrisupply.ug',
    password: 'Password123!',
    full_name: 'Okello James',
    phone: '+256782345678',
    role: 'farmer',
    region: 'Northern',
    is_verified: true,
  },
  {
    email: 'buyer1@agrisupply.ug',
    password: 'Password123!',
    full_name: 'Namugga Grace',
    phone: '+256701234567',
    role: 'buyer',
    region: 'Central',
    is_verified: true,
  },
  {
    email: 'buyer2@agrisupply.ug',
    password: 'Password123!',
    full_name: 'Mugisha David',
    phone: '+256752345678',
    role: 'buyer',
    region: 'Western',
    is_verified: true,
  },
  {
    email: 'admin@agrisupply.ug',
    password: defaultAdminPassword,
    full_name: 'System Admin',
    phone: '+256700000000',
    role: 'admin',
    region: 'Central',
    is_verified: true,
  },
];

const products = [
  {
    name: 'Fresh Tomatoes',
    description: 'Organically grown fresh tomatoes from Kampala farms. Perfect for cooking and salads.',
    price: 5000,
    unit: 'kg',
    quantity_available: 500,
    category: 'fruits_vegetables',
    is_organic: true,
    images: ['https://images.unsplash.com/photo-1546470427-0d4db154ceb8?w=500'],
    farmer_index: 0,
  },
  {
    name: 'Matooke (Green Bananas)',
    description: 'Fresh matooke from the fertile soils of Western Uganda. Steamed or mashed.',
    price: 15000,
    unit: 'bunch',
    quantity_available: 200,
    category: 'fruits_vegetables',
    is_organic: true,
    images: ['https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500'],
    farmer_index: 0,
  },
  {
    name: 'Fresh Milk',
    description: 'Raw fresh milk from healthy Ankole cattle. Available daily.',
    price: 3000,
    unit: 'litre',
    quantity_available: 100,
    category: 'dairy_eggs',
    is_organic: true,
    images: ['https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500'],
    farmer_index: 1,
  },
  {
    name: 'Free-Range Eggs',
    description: 'Fresh eggs from free-range chickens. No antibiotics or hormones.',
    price: 15000,
    unit: 'tray',
    quantity_available: 50,
    category: 'dairy_eggs',
    is_organic: true,
    images: ['https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=500'],
    farmer_index: 1,
  },
  {
    name: 'Dried Beans',
    description: 'High quality dried beans, perfect for traditional Ugandan dishes.',
    price: 8000,
    unit: 'kg',
    quantity_available: 1000,
    category: 'grains_cereals',
    is_organic: false,
    images: ['https://images.unsplash.com/photo-1551462147-ff29053bfc14?w=500'],
    farmer_index: 0,
  },
  {
    name: 'Fresh Tilapia',
    description: 'Fresh tilapia from Lake Victoria. Cleaned and ready to cook.',
    price: 18000,
    unit: 'kg',
    quantity_available: 80,
    category: 'fish_seafood',
    is_organic: false,
    images: ['https://images.unsplash.com/photo-1544943910-4c1dc44aab44?w=500'],
    farmer_index: 1,
  },
  {
    name: 'Local Chicken',
    description: 'Free-range local chicken (kienyeji). Full of flavor.',
    price: 35000,
    unit: 'piece',
    quantity_available: 30,
    category: 'meat_poultry',
    is_organic: true,
    images: ['https://images.unsplash.com/photo-1587593810167-a84920ea0781?w=500'],
    farmer_index: 0,
  },
  {
    name: 'Groundnuts',
    description: 'Roasted groundnuts from Northern Uganda. Great for snacking or making sauce.',
    price: 12000,
    unit: 'kg',
    quantity_available: 200,
    category: 'grains_cereals',
    is_organic: false,
    images: ['https://images.unsplash.com/photo-1567892320421-1c657571ea4a?w=500'],
    farmer_index: 1,
  },
  {
    name: 'Fresh Ginger',
    description: 'Organic ginger root. Perfect for tea, cooking, and medicinal purposes.',
    price: 10000,
    unit: 'kg',
    quantity_available: 100,
    category: 'herbs_spices',
    is_organic: true,
    images: ['https://images.unsplash.com/photo-1615485500704-8e990f9900f7?w=500'],
    farmer_index: 0,
  },
  {
    name: 'Passion Fruit Juice',
    description: 'Fresh passion fruit juice concentrate. No preservatives.',
    price: 8000,
    unit: 'litre',
    quantity_available: 50,
    category: 'beverages',
    is_organic: true,
    images: ['https://images.unsplash.com/photo-1622597467836-f3285f2131b8?w=500'],
    farmer_index: 1,
  },
];

async function hashPassword(password) {
  const salt = await bcrypt.genSalt(12);
  return bcrypt.hash(password, salt);
}

async function seedUsers() {
  console.log('Seeding users...');
  const createdUsers = [];

  for (const user of users) {
    const hashedPassword = await hashPassword(user.password);

    const { data, error } = await supabase
      .from('users')
      .upsert({
        email: user.email,
        password: hashedPassword,
        full_name: user.full_name,
        phone: user.phone,
        role: user.role,
        region: user.region,
        is_verified: user.is_verified,
      }, {
        onConflict: 'email',
      })
      .select()
      .single();

    if (error) {
      console.error(`Error creating user ${user.email}:`, error);
    } else {
      console.log(`Created user: ${user.email}`);
      createdUsers.push(data);
    }
  }

  return createdUsers;
}

async function seedProducts(createdUsers) {
  console.log('\nSeeding products...');
  const farmers = createdUsers.filter(u => u.role === 'farmer');

  for (const product of products) {
    const farmer = farmers[product.farmer_index];
    if (!farmer) {
      console.error(`No farmer found for index ${product.farmer_index}`);
      continue;
    }

    const { data, error } = await supabase
      .from('products')
      .upsert({
        farmer_id: farmer.id,
        name: product.name,
        description: product.description,
        price: product.price,
        unit: product.unit,
        quantity_available: product.quantity_available,
        category: product.category,
        is_organic: product.is_organic,
        images: product.images,
        is_approved: true,
        is_active: true,
      }, {
        onConflict: 'farmer_id,name',
      })
      .select()
      .single();

    if (error) {
      console.error(`Error creating product ${product.name}:`, error);
    } else {
      console.log(`Created product: ${product.name}`);
    }
  }
}

async function seedReviews(createdUsers) {
  console.log('\nSeeding reviews...');
  const buyers = createdUsers.filter(u => u.role === 'buyer');

  const { data: products } = await supabase
    .from('products')
    .select('id')
    .limit(5);

  if (!products || products.length === 0) {
    console.log('No products to review');
    return;
  }

  const reviews = [
    { rating: 5, comment: 'Excellent quality! Fresh and exactly as described.' },
    { rating: 4, comment: 'Good product, fast delivery. Will buy again.' },
    { rating: 5, comment: 'Amazing! The farmer was very helpful.' },
    { rating: 4, comment: 'Great value for money. Highly recommended.' },
    { rating: 5, comment: 'Best I\'ve ever had. Supporting local farmers!' },
  ];

  for (let i = 0; i < products.length && i < reviews.length; i++) {
    const buyer = buyers[i % buyers.length];
    const { error } = await supabase
      .from('reviews')
      .upsert({
        product_id: products[i].id,
        user_id: buyer.id,
        rating: reviews[i].rating,
        comment: reviews[i].comment,
      }, {
        onConflict: 'product_id,user_id',
      });

    if (error) {
      console.error(`Error creating review:`, error);
    } else {
      console.log(`Created review for product ${products[i].id}`);
    }
  }
}

async function main() {
  console.log('🌱 Starting AgriSupply Database Seeder\n');
  console.log('='.repeat(50));

  try {
    const createdUsers = await seedUsers();
    await seedProducts(createdUsers);
    await seedReviews(createdUsers);

    console.log('\n' + '='.repeat(50));
    console.log('✅ Seeding completed successfully!\n');
    console.log('Test Accounts:');
    console.log('-'.repeat(50));
    console.log('Farmer: farmer1@agrisupply.ug / Password123!');
    console.log('Buyer:  buyer1@agrisupply.ug / Password123!');
    console.log('Admin:  admin@agrisupply.ug / AdminPass123!');
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  }
}

main();
