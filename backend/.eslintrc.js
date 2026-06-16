# ESLint Configuration for AgriSupply Backend
# Node.js / Express API

module.exports = {
  env: {
    node: true,
    es2021: true,
    jest: true,
  },
  extends: [
    'eslint:recommended',
    'plugin:node/recommended',
    'plugin:security/recommended',
    'prettier',
  ],
  plugins: ['node', 'security', 'prettier'],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  rules: {
    // Prettier integration
    'prettier/prettier': 'error',

    // Best Practices
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    'no-console': 'warn',
    'no-debugger': 'error',
    'no-alert': 'error',
    'no-eval': 'error',
    'no-implied-eval': 'error',
    'no-new-func': 'error',
    'no-return-await': 'error',
    'prefer-const': 'error',
    'no-var': 'error',
    'eqeqeq': ['error', 'always'],
    'curly': ['error', 'all'],

    // Node.js specific
    'node/no-unsupported-features/es-syntax': 'off',
    'node/no-missing-require': 'error',
    'node/no-extraneous-require': 'error',
    'node/no-deprecated-api': 'error',
    'node/no-unpublished-require': ['error', {
      allowModules: ['supertest', 'jest']
    }],

    // Security
    'security/detect-object-injection': 'off', // Too many false positives
    'security/detect-non-literal-regexp': 'warn',
    'security/detect-non-literal-require': 'warn',
    'security/detect-possible-timing-attacks': 'warn',

    // Error handling
    'no-throw-literal': 'error',
    'prefer-promise-reject-errors': 'error',
    'no-async-promise-executor': 'error',
    'require-atomic-updates': 'error',

    // Code style
    'camelcase': ['error', { properties: 'never' }],
    'new-cap': ['error', { newIsCap: true }],
    'no-array-constructor': 'error',
    'no-new-object': 'error',
    'object-shorthand': ['error', 'always'],
    'prefer-arrow-callback': 'error',
    'prefer-template': 'error',
    'prefer-rest-params': 'error',
    'prefer-spread': 'error',
    'arrow-spacing': ['error', { before: true, after: true }],
    'comma-dangle': ['error', 'always-multiline'],
    'quotes': ['error', 'single', { avoidEscape: true }],
    'semi': ['error', 'always'],

    // Import/Require ordering
    'sort-imports': ['error', {
      ignoreCase: true,
      ignoreDeclarationSort: true,
    }],

    // Async/Await best practices
    'no-await-in-loop': 'warn',
    'require-await': 'error',

    // Complexity limits
    'max-depth': ['warn', 4],
    'max-nested-callbacks': ['warn', 3],
    'max-params': ['warn', 5],
    'complexity': ['warn', 15],
  },
  overrides: [
    {
      files: ['**/*.test.js', '**/tests/**/*.js'],
      rules: {
        'no-console': 'off',
        'security/detect-non-literal-fs-filename': 'off',
        'node/no-unpublished-require': 'off',
      },
    },
  ],
  ignorePatterns: [
    'node_modules/',
    'coverage/',
    'dist/',
    'build/',
    '*.min.js',
  ],
};
