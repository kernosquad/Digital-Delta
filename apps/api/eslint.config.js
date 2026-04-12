import { configApp } from '@adonisjs/eslint-config';
import { addonConfig } from '@repo/eslint-config/addon';

export default [
  ...configApp(),
  ...addonConfig,
  {
    // Controllers use @inject() which requires value imports for emitDecoratorMetadata.
    // The consistent-type-imports rule incorrectly flags service class imports as type-only.
    files: ['app/**/*.controller.ts'],
    rules: {
      '@typescript-eslint/consistent-type-imports': 'off',
    },
  },
];
