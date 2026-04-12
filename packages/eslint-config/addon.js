import { sharedRules } from './shared-rules.js';

/**
 * Addon ESLint rules for frameworks that provide their own base config.
 * This config only adds import ordering and unused imports rules without
 * conflicting with existing TypeScript or base configs.
 *
 * Uses the same shared rules as base.js for consistency.
 *
 * @type {import("eslint").Linter.Config[]}
 * */
export const addonConfig = [sharedRules];
