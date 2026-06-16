## Admin Setup Instructions

### 1. Create Admin Account via Supabase

Since there's no admin registration endpoint (for security), you need to create an admin account directly in Supabase:

#### Option A: Via Supabase Dashboard (Recommended)
1. Go to https://app.supabase.com/project/ugrraxmjvbujpdzfsvzt
2. Navigate to **Authentication** → **Users**
3. Click **"Add user"** → **"Create new user"**
4. Fill in:
   - Email: `admin@agrisupply.com`
   - Password: Choose a strong password
   - Auto Confirm User: **Yes** (checked)
5. Click **"Create user"**

6. Go to **Table Editor** → **users** table
7. Find the user you just created (by email)
8. Edit the user record:
   - Change `role` from `buyer` to `admin`
   - Set `is_verified` to `true`
   - Set `full_name` to `"Admin User"` (or your preferred name)
9. Click **Save**

#### Option B: Via SQL Editor
1. Go to **SQL Editor** in Supabase
2. Run this SQL:

```sql
-- First, create the auth user
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at
)
VALUES (
  gen_random_uuid(),
  'admin@agrisupply.com',
  crypt('YourStrongPassword123!', gen_salt('bf')),
  now(),
  now(),
  now()
);

-- Then, update their profile to admin
UPDATE public.users
SET
  role = 'admin',
  is_verified = true,
  full_name = 'Admin User'
WHERE email = 'admin@agrisupply.com';
```

### 2. Login to Admin Dashboard

#### Mobile App:
1. Open the AgriSupply app
2. Click **Login**
3. Enter one of the following:
  - Your manually created admin credentials, or
  - Development default credentials from seed script:
    - Email: `admin@agrisupply.ug`
    - Password: `admin1234` (or `DEFAULT_ADMIN_PASSWORD` env override)
4. You'll be redirected to the Admin Dashboard
5. If you used the development default credentials, change the password immediately after first login

### 3. Admin Features Available

Once logged in as admin, you have access to:

#### Dashboard Tab
- Platform statistics (users, products, orders, revenue)
- Growth metrics
- Recent activity

#### Users Tab
- View all users (farmers, buyers, admins)
- Filter by role, region, verification status
- Search users
- Actions:
  - View user details
  - Verify farmers
  - Suspend/unsuspend accounts
  - Delete users
  - Manage premium memberships

#### Products Tab (Product Management)
- View all products (pending, active, rejected)
- Filter by category, status
- Sort by various criteria
- Actions:
  - Approve pending products
  - Reject inappropriate products
  - Delete products
  - View product details

#### Orders Tab (Order Management)
- View all platform orders
- Filter by status (pending, processing, shipped, delivered, cancelled)
- Sort by date, amount
- Actions:
  - View order details
  - Update order status
  - Track payments
  - Handle disputes

### 4. Admin Routes

The admin screens are accessible via these routes in the app:
- `/admin/dashboard` - Main dashboard
- `/admin/users` - User management
- `/admin/products` - Product management
- `/admin/orders` - Order management
- `/admin/analytics` - Analytics & reports

### 5. Admin API Endpoints

Backend admin endpoints (require admin authentication):

```
GET    /api/v1/admin/dashboard        - Dashboard statistics
GET    /api/v1/admin/users            - List all users
GET    /api/v1/admin/users/:id        - Get user details
PUT    /api/v1/admin/users/:id        - Update user
POST   /api/v1/admin/users/:id/verify - Verify user
POST   /api/v1/admin/users/:id/suspend - Suspend user
DELETE /api/v1/admin/users/:id        - Delete user

GET    /api/v1/admin/products         - List all products
PUT    /api/v1/admin/products/:id     - Update product
DELETE /api/v1/admin/products/:id     - Delete product

GET    /api/v1/admin/orders           - List all orders
PUT    /api/v1/admin/orders/:id       - Update order
```

### 6. Security Notes

⚠️ **Important Security Practices:**

1. **Never expose admin credentials** in code or public repositories
2. **Use strong passwords** for admin accounts
3. **Do not use `admin1234` in production**
3. **Enable 2FA** if available
4. **Limit admin accounts** - only create what's necessary
5. **Monitor admin actions** via logs
6. **Regular security audits** of admin activities

### 7. Testing Admin Features

For testing purposes, you can:

1. Create test farmers and buyers via the regular registration flow
2. Create test products as a farmer
3. Test product approval/rejection workflow
4. Create test orders
5. Test order management features

### 8. Troubleshooting

**Issue: Can't login with admin account**
- Verify the user exists in `auth.users` table
- Check `users` table has matching record with `role = 'admin'`
- Ensure `is_verified = true`
- Check password is correct

**Issue: Admin dashboard not showing**
- Clear app cache
- Logout and login again
- Check user role in database

**Issue: Admin actions failing**
- Check backend logs
- Verify Supabase RLS policies allow admin actions
- Ensure proper authentication token is being sent

### 9. Production Recommendations

For production deployment:

1. **Change default admin credentials immediately**
2. **Set up proper logging** for all admin actions
3. **Implement audit trails** for sensitive operations
4. **Add IP whitelisting** for admin panel access if needed
5. **Set up alerts** for suspicious admin activity
6. **Regular backups** before bulk admin operations
7. **Use environment-specific admin accounts** (dev, staging, prod)
