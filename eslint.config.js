import js from '@eslint/js';
import eslintConfigPrettier from 'eslint-config-prettier';
import tseslint from 'typescript-eslint';
import unusedImports from 'eslint-plugin-unused-imports';
import importPlugin from 'eslint-plugin-import';

/**
 * Root ESLint configuration for the monorepo.
 * This configuration provides baseline rules that all workspaces can extend.
 *
 * @type {import("eslint").Linter.Config[]}
 */
export default tseslint.config(
  // Base JavaScript recommended rules
  js.configs.recommended,

  // TypeScript recommended rules
  ...tseslint.configs.recommended,

  // Prettier integration - disables conflicting rules
  eslintConfigPrettier,

  // Global configuration for all files
  {
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      parserOptions: {
        ecmaFeatures: {
          jsx: true,
        },
      },
    },
    plugins: {
      'unused-imports': unusedImports,
      import: importPlugin,
    },
    rules: {
      // Unused imports - auto-remove
      'unused-imports/no-unused-imports': 'error',
      'unused-imports/no-unused-vars': [
        'warn',
        {
          vars: 'all',
          varsIgnorePattern: '^_',
          args: 'after-used',
          argsIgnorePattern: '^_',
          caughtErrors: 'all',
          caughtErrorsIgnorePattern: '^_',
        },
      ],

      // Import organization
      'import/order': [
        'error',
        {
          groups: [
            'builtin',
            'external',
            'internal',
            ['parent', 'sibling'],
            'index',
            'object',
            'type',
          ],
          'newlines-between': 'always',
          alphabetize: {
            order: 'asc',
            caseInsensitive: true,
          },
        },
      ],
      'import/no-duplicates': 'error',
      'import/newline-after-import': 'error',

      // TypeScript specific
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-unused-vars': 'off', // Handled by unused-imports
      '@typescript-eslint/consistent-type-imports': [
        'error',
        {
          prefer: 'type-imports',
          fixStyle: 'separate-type-imports',
        },
      ],
      '@typescript-eslint/no-empty-object-type': 'off',

      // General best practices
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'prefer-const': 'error',
      'no-var': 'error',
    },
  },

  // AdonisJS controllers use @inject() which relies on emitDecoratorMetadata.
  // consistent-type-imports would convert service imports to `import type`,
  // breaking DI resolution at runtime.
  {
    files: ['apps/api/app/**/*.controller.ts'],
    rules: {
      '@typescript-eslint/consistent-type-imports': 'off',
    },
  },

  // Global ignores
  {
    ignores: [
      '**/node_modules/**',
      '**/dist/**',
      '**/build/**',
      '**/.next/**',
      '**/out/**',
      '**/.turbo/**',
      '**/coverage/**',
      '**/*.config.js',
      '**/*.config.mjs',
      '**/next-env.d.ts',
      '**/.nuxt/**',
      '**/.output/**',
      '**/.vercel/**',
      '**/pnpm-lock.yaml',
    ],
  }
);
