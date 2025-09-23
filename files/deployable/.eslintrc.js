module.exports = {
  env: {
    browser: false,
    es2021: true,
    node: true
  },
  extends: [
    'standard'
  ],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module'
  },
  rules: {
    // Security rules
    'no-eval': 'error',
    'no-implied-eval': 'error',
    'no-new-func': 'error',
    'no-script-url': 'error',
    
    // Lambda@Edge specific rules
    'no-console': 'warn', // CloudWatch logs are expensive
    'prefer-const': 'error',
    'no-var': 'error',
    
    // Performance rules for Lambda@Edge
    'no-unused-vars': 'error',
    'no-unreachable': 'error',
    'no-duplicate-imports': 'error',
    
    // Code quality
    'complexity': ['warn', 10],
    'max-depth': ['warn', 4],
    'max-lines-per-function': ['warn', 50],
    'max-params': ['warn', 4],
    
    // AWS Lambda@Edge constraints
    'no-process-env': 'warn', // Environment variables have limitations in Lambda@Edge
    'no-process-exit': 'error'
  },
  overrides: [
    {
      files: ['*.test.js', '*.spec.js'],
      env: {
        jest: true
      },
      rules: {
        'no-console': 'off'
      }
    }
  ],
  globals: {
    // AWS Lambda@Edge globals
    'exports': 'readonly',
    'module': 'readonly',
    'require': 'readonly',
    '__dirname': 'readonly',
    '__filename': 'readonly',
    'Buffer': 'readonly',
    'process': 'readonly'
  }
}
