# Makefile for AgriSupply
# Common development tasks

.PHONY: help install dev test build deploy clean

# Default target
help:
	@echo "AgriSupply Development Commands"
	@echo "================================"
	@echo ""
	@echo "Setup:"
	@echo "  make install          Install all dependencies"
	@echo "  make setup            Complete setup (install + configure)"
	@echo ""
	@echo "Development:"
	@echo "  make dev              Start development servers"
	@echo "  make dev-backend      Start backend server only"
	@echo "  make dev-mobile       Start Flutter in debug mode"
	@echo ""
	@echo "Testing:"
	@echo "  make test             Run all tests"
	@echo "  make test-backend     Run backend tests"
	@echo "  make test-mobile      Run Flutter tests"
	@echo "  make test-coverage    Run tests with coverage"
	@echo ""
	@echo "Building:"
	@echo "  make build            Build all artifacts"
	@echo "  make build-backend    Build backend Docker image"
	@echo "  make build-android    Build Android APK"
	@echo "  make build-ios        Build iOS app"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-up        Start all Docker services"
	@echo "  make docker-down      Stop all Docker services"
	@echo "  make docker-logs      View Docker logs"
	@echo "  make docker-build     Build Docker images"
	@echo ""
	@echo "Database:"
	@echo "  make db-seed          Seed database with sample data"
	@echo "  make db-migrate       Run database migrations"
	@echo "  make db-reset         Reset database (destructive!)"
	@echo ""
	@echo "Quality:"
	@echo "  make lint             Run linters"
	@echo "  make format           Format code"
	@echo "  make analyze          Run static analysis"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean            Clean build artifacts"
	@echo "  make health           Check service health"

# ============================================
# SETUP
# ============================================

install: install-backend install-mobile
	@echo "✅ All dependencies installed"

install-backend:
	@echo "📦 Installing backend dependencies..."
	cd backend && npm install

install-mobile:
	@echo "📦 Installing Flutter dependencies..."
	cd mobile && flutter pub get
	cd mobile && flutter gen-l10n

setup: install
	@echo "🔧 Setting up environment..."
	@if [ ! -f backend/.env ]; then \
		cp backend/.env.example backend/.env; \
		echo "Created backend/.env - please configure it"; \
	fi
	@echo "✅ Setup complete"

# ============================================
# DEVELOPMENT
# ============================================

dev: dev-backend

dev-backend:
	@echo "🚀 Starting backend server..."
	cd backend && npm run dev

dev-mobile:
	@echo "📱 Starting Flutter app..."
	cd mobile && flutter run

# ============================================
# TESTING
# ============================================

test: test-backend test-mobile
	@echo "✅ All tests complete"

test-backend:
	@echo "🧪 Running backend tests..."
	cd backend && npm test

test-mobile:
	@echo "🧪 Running Flutter tests..."
	cd mobile && flutter test

test-coverage:
	@echo "📊 Running tests with coverage..."
	cd backend && npm run test:coverage
	cd mobile && flutter test --coverage

# ============================================
# BUILDING
# ============================================

build: build-backend build-android
	@echo "✅ Build complete"

build-backend:
	@echo "🐳 Building backend Docker image..."
	docker build -t agrisupply-api:latest ./backend

build-android:
	@echo "🤖 Building Android APK..."
	cd mobile && flutter build apk --release

build-android-bundle:
	@echo "🤖 Building Android App Bundle..."
	cd mobile && flutter build appbundle --release

build-ios:
	@echo "🍎 Building iOS app..."
	cd mobile && flutter build ios --release --no-codesign

# ============================================
# DOCKER
# ============================================

docker-up:
	@echo "🐳 Starting Docker services..."
	docker-compose up -d

docker-down:
	@echo "🐳 Stopping Docker services..."
	docker-compose down

docker-logs:
	@echo "📋 Showing Docker logs..."
	docker-compose logs -f

docker-build:
	@echo "🐳 Building Docker images..."
	docker-compose build

docker-restart:
	@echo "🔄 Restarting Docker services..."
	docker-compose restart

docker-clean:
	@echo "🧹 Cleaning Docker resources..."
	docker-compose down -v --rmi local

# ============================================
# DATABASE
# ============================================

db-seed:
	@echo "🌱 Seeding database..."
	cd backend && node scripts/seed.js

db-migrate:
	@echo "🔄 Running migrations..."
	cd backend && node scripts/migrate.js up

db-migrate-status:
	@echo "📊 Migration status..."
	cd backend && node scripts/migrate.js status

db-migrate-down:
	@echo "⬇️ Rolling back migration..."
	cd backend && node scripts/migrate.js down

# ============================================
# QUALITY
# ============================================

lint: lint-backend lint-mobile
	@echo "✅ Linting complete"

lint-backend:
	@echo "🔍 Linting backend..."
	cd backend && npm run lint

lint-mobile:
	@echo "🔍 Analyzing Flutter code..."
	cd mobile && flutter analyze

format: format-backend format-mobile
	@echo "✅ Formatting complete"

format-backend:
	@echo "✨ Formatting backend..."
	cd backend && npm run format

format-mobile:
	@echo "✨ Formatting Flutter code..."
	cd mobile && dart format lib test

analyze:
	@echo "🔬 Running static analysis..."
	cd mobile && flutter analyze
	cd backend && npm run lint

# ============================================
# UTILITIES
# ============================================

clean:
	@echo "🧹 Cleaning build artifacts..."
	cd backend && rm -rf node_modules coverage dist
	cd mobile && flutter clean
	@echo "✅ Clean complete"

health:
	@echo "🏥 Checking service health..."
	cd backend && node scripts/healthcheck.js

logs-backend:
	@echo "📋 Backend logs..."
	docker-compose logs -f api

# ============================================
# RELEASE
# ============================================

release-patch:
	@echo "📦 Creating patch release..."
	npm version patch
	git push --follow-tags

release-minor:
	@echo "📦 Creating minor release..."
	npm version minor
	git push --follow-tags

release-major:
	@echo "📦 Creating major release..."
	npm version major
	git push --follow-tags
