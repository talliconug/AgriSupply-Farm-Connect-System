// Jest configuration for backend testing
const reporters = ['default'];
const watchPlugins = [];

try {
  require.resolve('jest-junit');
  reporters.push([
    'jest-junit',
    {
      outputDirectory: 'test-results',
      outputName: 'junit.xml',
    },
  ]);
} catch (error) {
  // Keep default reporter when jest-junit is not available.
}

try {
  require.resolve('jest-watch-typeahead/filename');
  require.resolve('jest-watch-typeahead/testname');
  watchPlugins.push('jest-watch-typeahead/filename');
  watchPlugins.push('jest-watch-typeahead/testname');
} catch (error) {
  // Watch plugins are optional.
}

module.exports = {
  // Test environment
  testEnvironment: 'node',

  // Root directory for tests
  rootDir: '.',

  // Test file patterns
  testMatch: [
    '**/tests/**/*.test.js',
    '**/tests/**/*.spec.js',
  ],

  // Coverage collection
  collectCoverage: true,
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  
  // Files to collect coverage from
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/index.js',
    '!**/node_modules/**',
  ],

  // Coverage thresholds
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70,
    },
  },

  // Setup files
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],

  // Module paths
  moduleDirectories: ['node_modules', 'src'],

  // Transform files
  transform: {},

  // Timeout for tests
  testTimeout: 30000,

  // Verbose output
  verbose: true,

  // Clear mocks between tests
  clearMocks: true,

  // Restore mocks after each test
  restoreMocks: true,

  // Max workers for parallel tests
  maxWorkers: '50%',

  // Test path ignore patterns
  testPathIgnorePatterns: [
    '/node_modules/',
    '/dist/',
  ],

  // Module name mapper for aliases
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '^@config/(.*)$': '<rootDir>/src/config/$1',
    '^@controllers/(.*)$': '<rootDir>/src/controllers/$1',
    '^@middleware/(.*)$': '<rootDir>/src/middleware/$1',
    '^@routes/(.*)$': '<rootDir>/src/routes/$1',
    '^@utils/(.*)$': '<rootDir>/src/utils/$1',
  },

  // Global variables
  globals: {
    NODE_ENV: 'test',
  },

  // Reporters
  reporters,

  // Watch plugins
  watchPlugins,
};
