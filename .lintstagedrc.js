/**
 * Lint-staged configuration
 * Runs linters and formatters on staged files before commit
 *
 * Can be skipped using: git commit --no-verify
 */
export default {
  // TypeScript and JavaScript files
  '**/*.{ts,tsx,js,jsx}': (filenames) => {
    const commands = [];

    // Route files to their app's own ESLint instance
    const apiFiles = filenames.filter((f) => f.includes('/apps/api/'));
    const webFiles = filenames.filter((f) => f.includes('/apps/web/'));

    if (apiFiles.length > 0) {
      const escaped = apiFiles.map((f) => `"${f}"`).join(' ');
      commands.push(`pnpm --filter api exec eslint --fix --no-warn-ignored ${escaped}`);
    }
    if (webFiles.length > 0) {
      const escaped = webFiles.map((f) => `"${f}"`).join(' ');
      commands.push(`pnpm --filter web exec eslint --fix --no-warn-ignored ${escaped}`);
    }

    // Prettier runs from root for all files
    const allEscaped = filenames.map((f) => `"${f}"`).join(' ');
    commands.push(`prettier --write ${allEscaped}`);

    return commands;
  },

  // JSON, Markdown, YAML files
  '**/*.{json,md,yml,yaml}': (filenames) => {
    const escapedFilenames = filenames.map((f) => `"${f}"`).join(' ');
    return [`prettier --write ${escapedFilenames}`];
  },

  // Run type-check on TypeScript changes (workspace-wide)
  '**/*.{ts,tsx}': () => ['pnpm check-types'],
};
