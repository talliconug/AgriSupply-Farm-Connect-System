# Environment Variables (Currently Used)

This document only lists variables currently referenced in code.

Source scan coverage:
- `backend/src/**/*.js`
- `backend/scripts/**/*.js`
- `mobile/lib/config/app_config.dart`

## 1) Backend variables

### 1.1 Core app and API

| Variable | Required | Default in code | Purpose |
| --- | --- | --- | --- |
| NODE_ENV | No | development-style behavior | Environment mode (logging and runtime mode checks) |
| PORT | No | `3000` | HTTP server port |
| API_VERSION | No | `v1` | API prefix in routes (`/api/v1/...`) |
| API_URL | No | none | Used by admin/report/export paths (if configured) |
| FRONTEND_URL | No | none | Used in auth/redirect/email flows |
| ALLOWED_ORIGINS | No | `*` | CORS allow-list (comma-separated) |

### 1.2 Supabase and authentication

| Variable | Required | Default in code | Purpose |
| --- | --- | --- | --- |
| SUPABASE_URL | Yes | none | Supabase project URL |
| SUPABASE_ANON_KEY | Yes | none | Supabase anon/public key |
| SUPABASE_SERVICE_ROLE_KEY | Yes | none | Supabase server key for privileged DB operations |
| JWT_SECRET | Yes | none | Access token signing secret |
| JWT_EXPIRES_IN | No | `7d` | Access token duration |
| JWT_REFRESH_SECRET | Yes | none | Refresh token signing secret |
| JWT_REFRESH_EXPIRES_IN | No | `30d` | Refresh token duration |

### 1.3 Rate limiting, upload, and logs

| Variable | Required | Default in code | Purpose |
| --- | --- | --- | --- |
| RATE_LIMIT_WINDOW_MS | No | `900000` | Rate limit window in ms |
| RATE_LIMIT_MAX_REQUESTS | No | `100` | Max requests per window |
| MAX_FILE_SIZE | No | `5242880` | Upload size cap (bytes) |
| ALLOWED_FILE_TYPES | No | `image/jpeg,image/png,image/webp` | Allowed upload MIME types |
| LOG_LEVEL | No | `info` | App log level |

### 1.4 AI (Groq)

| Variable | Required | Default in code | Purpose |
| --- | --- | --- | --- |
| GROQ_API_KEY | Yes (for AI routes) | none | Groq API key |
| GROQ_MODEL | No | `llama-3.3-70b-versatile` | Chat model |
| GROQ_VISION_MODEL | No | `llama-3.2-90b-vision-preview` | Vision model |

### 1.5 Payments

| Variable | Required | Default in code | Purpose |
| --- | --- | --- | --- |
| MARZPAY_API_URL | No | `https://wallet.wearemarz.com/api/v1` | MarzPay API base URL |
| MARZPAY_API_KEY | Yes (MarzPay flows) | none | MarzPay auth key |
| MARZPAY_API_SECRET | Yes (MarzPay flows) | none | MarzPay auth secret |
| MTN_API_KEY | Yes (MTN flows) | none | MTN API key |
| MTN_API_SECRET | Yes (MTN flows) | none | MTN API secret |
| MTN_SUBSCRIPTION_KEY | Yes (MTN flows) | none | MTN subscription key |
| MTN_ENVIRONMENT | No | `sandbox` | MTN target env (`sandbox` or `production`) |
| AIRTEL_API_KEY | Yes (Airtel flows) | none | Airtel API key |
| AIRTEL_API_SECRET | Yes (Airtel flows) | none | Airtel API secret |
| AIRTEL_ENVIRONMENT | No | `sandbox` | Airtel target env |
| FLUTTERWAVE_SECRET_KEY | Yes (card verify/refund) | none | Flutterwave server key |

### 1.6 Notification integrations

| Variable | Required | Default in code | Purpose |
| --- | --- | --- | --- |
| EMAIL_SERVICE | No | none | Email provider selector (`sendgrid` or `mailgun`) |
| SENDGRID_API_KEY | If EMAIL_SERVICE=sendgrid | none | SendGrid API key |
| MAILGUN_API_KEY | If EMAIL_SERVICE=mailgun | none | Mailgun key |
| MAILGUN_DOMAIN | If EMAIL_SERVICE=mailgun | none | Mailgun domain |
| FROM_EMAIL | No | `noreply@agrisupply.com` | Sender identity |
| SMS_SERVICE | No | none | SMS provider selector (`egosms` or `twilio`) |
| TWILIO_ACCOUNT_SID | If SMS_SERVICE=twilio | none | Twilio account SID |
| TWILIO_AUTH_TOKEN | If SMS_SERVICE=twilio | none | Twilio auth token |
| TWILIO_PHONE_NUMBER | If SMS_SERVICE=twilio | none | Twilio sender number |
| EGOSMS_API_URL | If SMS_SERVICE=egosms | none | EgoSMS API endpoint |
| EGOSMS_USERNAME | If SMS_SERVICE=egosms | none | EgoSMS username |
| EGOSMS_PASSWORD | If SMS_SERVICE=egosms | none | EgoSMS password |
| EGOSMS_SENDER_ID | If SMS_SERVICE=egosms | none | EgoSMS sender name/ID |
| FIREBASE_SERVER_KEY | Optional fallback | none | FCM legacy REST key fallback |

## 2) Current backend `.env` template

Use this as a practical, current starting point:

```env
NODE_ENV=development
PORT=3000
API_VERSION=v1
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=your-refresh-token-secret
JWT_REFRESH_EXPIRES_IN=30d

RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
MAX_FILE_SIZE=5242880
ALLOWED_FILE_TYPES=image/jpeg,image/png,image/webp
LOG_LEVEL=info

GROQ_API_KEY=your-groq-api-key
GROQ_MODEL=llama-3.3-70b-versatile
GROQ_VISION_MODEL=llama-3.2-90b-vision-preview

MARZPAY_API_URL=https://wallet.wearemarz.com/api/v1
MARZPAY_API_KEY=your-marzpay-api-key
MARZPAY_API_SECRET=your-marzpay-api-secret

MTN_API_KEY=your-mtn-api-key
MTN_API_SECRET=your-mtn-api-secret
MTN_SUBSCRIPTION_KEY=your-mtn-subscription-key
MTN_ENVIRONMENT=sandbox

AIRTEL_API_KEY=your-airtel-api-key
AIRTEL_API_SECRET=your-airtel-api-secret
AIRTEL_ENVIRONMENT=sandbox

FLUTTERWAVE_SECRET_KEY=your-flutterwave-secret-key

EMAIL_SERVICE=sendgrid
SENDGRID_API_KEY=your-sendgrid-api-key
FROM_EMAIL=noreply@agrisupply.com

SMS_SERVICE=egosms
EGOSMS_API_URL=https://your-egosms-endpoint
EGOSMS_USERNAME=your-egosms-username
EGOSMS_PASSWORD=your-egosms-password
EGOSMS_SENDER_ID=AgriSupply

FIREBASE_SERVER_KEY=your-firebase-server-key
```

## 3) Mobile configuration variables

Current mobile app runtime values come from `mobile/lib/config/app_config.dart` constants, not from `.env` files.

### Hardcoded app config currently used
- Supabase URL and anon key are read from `AppConfig.supabaseUrl` and `AppConfig.supabaseAnonKey`.
- Backend API base URL is read from `AppConfig.apiBaseUrl`.

### Compile-time environment pattern (documented, not currently wired in `lib/`)

```dart
const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000');
const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
```

## 4) Important notes
- Use `SUPABASE_SERVICE_ROLE_KEY` (not `SUPABASE_SERVICE_KEY`) because that is what backend code reads.
- Use `ALLOWED_ORIGINS` (not `CORS_ORIGINS`) for CORS in `backend/src/index.js`.
- Keep secrets out of public repos and CI logs.
