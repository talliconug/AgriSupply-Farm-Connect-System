# Contributing to AgriSupply

First off, thank you for considering contributing to AgriSupply! It's people like you that make AgriSupply such a great tool for Ugandan farmers.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Style Guidelines](#style-guidelines)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to support@agrisupply.ug.

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

## Getting Started

### Prerequisites

- Flutter SDK 3.16+
- Node.js 18+
- Git
- A Supabase account
- VS Code or Android Studio

### Fork the Repository

1. Fork the repo on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/agrisupply.git
   cd agrisupply
   ```
3. Add the upstream remote:
   ```bash
   git remote add upstream https://github.com/agrisupply/agrisupply.git
   ```

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

When creating a bug report, include:

- **Clear title** describing the issue
- **Steps to reproduce** the behavior
- **Expected behavior** vs actual behavior
- **Screenshots** if applicable
- **Device/Environment info** (OS, Flutter version, etc.)

Use this template:

```markdown
## Bug Description
A clear description of the bug.

## Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. See error

## Expected Behavior
What you expected to happen.

## Screenshots
If applicable, add screenshots.

## Environment
- Device: [e.g., Samsung Galaxy S21]
- OS: [e.g., Android 13]
- App Version: [e.g., 1.2.0]
```

### Suggesting Features

Feature suggestions are tracked as GitHub issues. When creating a feature request:

- **Use a clear title** describing the feature
- **Provide detailed description** of the proposed feature
- **Explain the use case** - why is this feature needed?
- **Include mockups** if possible

### Code Contributions

#### Good First Issues

Look for issues labeled `good first issue` - these are great for newcomers!

#### Areas We Need Help

- 🌍 **Translations** - Help translate to Luganda, Runyankole, Luo
- 📱 **UI/UX** - Improve user interface and experience
- 🧪 **Testing** - Write unit and integration tests
- 📚 **Documentation** - Improve docs and code comments
- 🐛 **Bug Fixes** - Fix reported issues
- ✨ **Features** - Implement new features

## Development Setup

### Flutter App

```bash
# Navigate to project root
cd agrisupply

# Get dependencies
flutter pub get

# Create environment config
cp lib/config/env.example.dart lib/config/env.dart
# Edit env.dart with your API keys

# Run the app
flutter run
```

### Backend API

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Create environment config
cp .env.example .env
# Edit .env with your credentials

# Run development server
npm run dev
```

## Style Guidelines

### Flutter/Dart Style

We follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).

```dart
// DO: Use lowerCamelCase for variables and methods
final userName = 'John';

// DO: Use UpperCamelCase for classes
class UserProfile {}

// DO: Use snake_case for file names
// user_profile_screen.dart

// DO: Add const where possible
const EdgeInsets.all(16.0);

// DO: Use trailing commas for better formatting
Widget build(BuildContext context) {
  return Container(
    padding: EdgeInsets.all(16),
    child: Text('Hello'),
  );
}
```

### JavaScript/Node.js Style

We follow the [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript).

```javascript
// DO: Use const/let, never var
const userName = 'John';
let count = 0;

// DO: Use camelCase for variables and functions
const getUserProfile = async (userId) => {};

// DO: Use async/await over callbacks
const getUser = async (id) => {
  const user = await User.findById(id);
  return user;
};

// DO: Handle errors properly
try {
  const result = await someAsyncOperation();
} catch (error) {
  logger.error('Operation failed:', error);
  throw new ApiError(500, 'Operation failed');
}
```

### File Organization

```
# Flutter screens
lib/screens/
├── auth/           # Authentication screens
├── buyer/          # Buyer-specific screens
├── farmer/         # Farmer-specific screens
├── admin/          # Admin screens
└── common/         # Shared screens

# Backend controllers
backend/src/controllers/
├── authController.js
├── userController.js
├── productController.js
└── ...
```

## Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```bash
# Feature
git commit -m "feat(products): add product search functionality"

# Bug fix
git commit -m "fix(auth): resolve login redirect issue"

# Documentation
git commit -m "docs(readme): update installation instructions"

# Breaking change
git commit -m "feat(api)!: change response format for orders endpoint

BREAKING CHANGE: Order response now includes nested items array"
```

## Pull Request Process

### Before Submitting

1. **Update your fork**:
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes** following the style guidelines

4. **Run tests**:
   ```bash
   # Flutter
   flutter test
   flutter analyze
   
   # Backend
   npm test
   npm run lint
   ```

5. **Commit your changes** using conventional commits

### Submitting a PR

1. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

2. Open a Pull Request on GitHub

3. Fill out the PR template:
   ```markdown
   ## Description
   Brief description of changes.

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## Testing
   Describe the tests you ran.

   ## Screenshots
   If applicable, add screenshots.

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Tests pass locally
   - [ ] Documentation updated
   - [ ] No new warnings
   ```

4. Request review from maintainers

### After Submitting

- Respond to review comments promptly
- Make requested changes
- Keep your PR up to date with main branch
- Be patient - we review PRs as quickly as possible!

## Recognition

Contributors are recognized in:
- README.md Contributors section
- Release notes
- Annual contributor appreciation

## Questions?

Feel free to reach out:
- 📧 Email: dev@agrisupply.ug
- 💬 Discord: [AgriSupply Community](https://discord.gg/agrisupply)
- 🐦 Twitter: [@AgriSupplyUG](https://twitter.com/AgriSupplyUG)

Thank you for contributing! 🌾
