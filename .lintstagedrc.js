/**
 * Lint-staged configuration
 * Runs linters and formatters on staged files before commit
 *
 * Can be skipped using: git commit --no-verify
 */
export default {
  // TypeScript and JavaScript files
  '**/*.{ts,tsx,js,jsx}': (filenames) => {
    const escapedFilenames = filenames.map((f) => `"${f}"`).join(' ');
    return [
      // Run ESLint with auto-fix
      `eslint --fix --max-warnings 0 --no-warn-ignored ${escapedFilenames}`,
      // Format with Prettier
      `prettier --write ${escapedFilenames}`,
    ];
  },

  // JSON, Markdown, YAML files
  '**/*.{json,md,yml,yaml}': (filenames) => {
    const escapedFilenames = filenames.map((f) => `"${f}"`).join(' ');
    return [
      // Format with Prettier
      `prettier --write ${escapedFilenames}`,
    ];
  },

  // Run type-check on TypeScript changes (workspace-wide)
  '**/*.{ts,tsx}': () => [
    // Type-check the entire workspace to catch cross-file errors
    'pnpm check-types',
  ],
};
