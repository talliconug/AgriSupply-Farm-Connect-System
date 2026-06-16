# AgriSupply Deployment Guide (Current System)

## Overview
This project deploys as:
- Mobile app: Flutter client
- Backend API: Node.js/Express deployed on Render
- Database/Auth/Storage: Supabase (PostgreSQL + Auth + Storage)

Current API base in mobile config:
- https://agrisupply-farm-connect-system.onrender.com/api/v1

## Architecture and Connections
1. Flutter app sends HTTPS requests to Render backend.
2. Render backend handles auth, validation, business logic, and webhooks.
3. Backend reads/writes data in Supabase PostgreSQL.
4. Supabase Auth manages account/session tokens (email, Google, OTP).
5. Supabase Storage hosts user/product media.
6. Payment providers call backend webhook endpoints after payment events.

## What Was Required
- Supabase project with schema, auth providers, and storage buckets.
- Render web service with Node runtime.
- Backend environment variables set in Render.
- Mobile app configured with backend URL and Supabase URL/key.
- Payment callback URLs pointing to Render API.

## Supabase Setup

### 1. Create Supabase Project
- Create project in Supabase dashboard.
- Collect:
  - SUPABASE_URL
  - SUPABASE_ANON_KEY
  - SUPABASE_SERVICE_ROLE_KEY

### 2. Apply Database Schema
- Run SQL from:
  - backend/database/schema.sql
  - backend/database/setup_storage.sql (if used)
- Optional seed data:
  - backend/database/seed.sql

### 3. Configure Auth
- Enable Email/Password.
- Configure Google provider (if used).
- Configure Phone OTP provider for SMS login.
- Ensure user profile trigger/policy flow is aligned with users table.

### 4. Configure Storage
Create buckets used by app/media flows (for example):
- profile photos
- product images
- review images
Set proper public/private access policy based on your security needs.

## Render Setup

### 1. Create Service
- Use render.yaml in project root, or configure manually.
- Runtime: Node
- Build command: npm install
- Start command: npm start
- Health check path: /health

### 2. Important Environment Variables
Set these in Render (matching render.yaml/current backend usage):
- NODE_ENV=production
- PORT=3000
- API_VERSION=v1
- SUPABASE_URL
- SUPABASE_ANON_KEY
- SUPABASE_SERVICE_ROLE_KEY
- JWT_SECRET
- JWT_EXPIRES_IN
- JWT_REFRESH_SECRET
- JWT_REFRESH_EXPIRES_IN
- GROQ_API_KEY
- GROQ_MODEL
- GROQ_VISION_MODEL
- MARZPAY_API_KEY
- MARZPAY_API_SECRET
- MARZPAY_API_URL
- MARZPAY_CALLBACK_URL
- APP_URL
- MTN_API_KEY
- MTN_API_SECRET
- MTN_SUBSCRIPTION_KEY
- MTN_ENVIRONMENT
- AIRTEL_API_KEY
- AIRTEL_API_SECRET
- AIRTEL_ENVIRONMENT
- FLUTTERWAVE_PUBLIC_KEY
- FLUTTERWAVE_SECRET_KEY
- FLUTTERWAVE_ENCRYPTION_KEY
- GOOGLE_CLIENT_ID
- GOOGLE_CLIENT_SECRET
- FIREBASE_PROJECT_ID
- FIREBASE_PRIVATE_KEY
- FIREBASE_CLIENT_EMAIL
- RATE_LIMIT_WINDOW_MS
- RATE_LIMIT_MAX_REQUESTS

### 3. API Mounting and Route Groups
Mounted in backend/src/index.js:
- /api/v1/auth
- /api/v1/users
- /api/v1/products
- /api/v1/orders
- /api/v1/payments
- /api/v1/notifications
- /api/v1/ai
- /api/v1/admin

## Connecting Mobile to Backend and Supabase
In mobile/lib/config/app_config.dart:
- supabaseUrl points to Supabase project URL
- supabaseAnonKey points to Supabase anon key
- apiBaseUrl points to Render backend /api/v1

This is how the mobile app communicates with both backend and Supabase.

## Payment/Webhook Connection
Backend receives provider callbacks on:
- /api/v1/payments/marzpay/callback
- /api/v1/payments/mtn/callback
- /api/v1/payments/airtel/callback
- /api/v1/payments/card/callback

For this to work:
- Payment providers must be configured with the exact Render callback URLs.
- APP_URL/MARZPAY_CALLBACK_URL must match your deployed backend URL.

## Deployment Verification Checklist
- GET /health returns success.
- Auth register/login works.
- Protected endpoint rejects missing/invalid token.
- Product list and details load.
- Order creation writes orders and order_items.
- Payment initiation creates payment record.
- Webhook updates payment/order status.
- Notifications and AI endpoints respond.

## Common Issues
- Invalid token errors: check auth provider config and bearer token flow.
- Supabase permission errors: verify RLS/policies and service role key usage.
- Callback not firing: verify provider webhook URL and APP_URL.
- CORS errors: update allowed origins and frontend URL configuration.
