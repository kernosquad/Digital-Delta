# ESLint, Prettier & TypeScript Configuration

This monorepo uses a unified configuration for ESLint, Prettier, and TypeScript across all workspaces.

## 🎯 Overview

- **ESLint**: Modern flat config with TypeScript support, unused imports auto-removal, and import ordering
- **Prettier**: Single source of formatting with 2-space indentation
- **TypeScript**: Shared configs with strict type checking
- **EditorConfig**: Consistent editor behavior across the team

## 📦 Configuration Files

### Root Level

- `.prettierrc` - Prettier configuration
- `.prettierignore` - Files to exclude from formatting
- `.editorconfig` - Editor configuration for consistent behavior
- `.eslintignore` - Files to exclude from linting
- `eslint.config.js` - Root ESLint configuration
- `.vscode/settings.json` - VS Code integration

### Shared Packages

- `packages/eslint-config/base.js` - Base ESLint config with TypeScript, import ordering, and unused imports
- `packages/eslint-config/next.js` - Next.js specific config with React rules
- `packages/eslint-config/react-internal.js` - React library config
- `packages/typescript-config/` - Shared TypeScript configurations

## 🚀 Scripts

### Root Level

```bash
# Lint all workspaces
pnpm lint

# Format all files
pnpm format

# Check formatting without modifying files
pnpm format:check

# Format and write changes
pnpm format:write

# Type check all workspaces
pnpm check-types
```

### Workspace Level

Each workspace has its own scripts:

```bash
# In apps/web, apps/api, or packages/ui
pnpm lint         # Run ESLint
pnpm format       # Format files
pnpm check-types  # TypeScript check
```

## 🎨 Prettier Configuration

- **Tab Width**: 2 spaces
- **Semicolons**: Yes
- **Quotes**: Single quotes
- **Trailing Commas**: ES5 compatible
- **Print Width**: 100 characters
- **Arrow Parens**: Always
- **End of Line**: LF (Unix style)

## 🔍 ESLint Rules

### Key Features

1. **Unused Imports Auto-Removal**: Automatically removes unused imports
2. **Import Ordering**: Organizes imports by type (builtin → external → internal → local)
3. **TypeScript Strict**: Consistent type imports with `import type`
4. **Prettier Integration**: No rule conflicts with Prettier
5. **Monorepo Aware**: Proper path resolution for workspace packages

### Rule Highlights

- `unused-imports/no-unused-imports`: Error (auto-fixable)
- `import/order`: Alphabetically sorted with group separation
- `@typescript-eslint/consistent-type-imports`: Enforces `import type` for types
- `no-console`: Warn (allows `console.warn` and `console.error`)
- `prefer-const`: Error
- `no-var`: Error

## 🏗️ Workspace-Specific Configs

### apps/web (Next.js)

Uses `@repo/eslint-config/next-js` which includes:

- React and React Hooks rules
- Next.js specific rules
- Browser globals
- Service worker support

### apps/api (AdonisJS)

Uses `@adonisjs/eslint-config` with custom extensions:

- Import ordering consistent with monorepo
- Unused imports removal
- Type import enforcement

### packages/ui (React Library)

Uses `@repo/eslint-config/react-internal` which includes:

- React and React Hooks rules
- JSX transform support (no React import needed)
- Browser globals

## 🛠️ VS Code Integration

The `.vscode/settings.json` enables:

- Format on save with Prettier
- Auto-fix ESLint issues on save
- TypeScript workspace version
- Working directories for monorepo support

### Recommended VS Code Extensions

- [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint)
- [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
- [EditorConfig](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig)

## 🔧 Maintenance

### Adding a New Workspace

1. Add `eslint` and `prettier` to devDependencies
2. Create `eslint.config.js` extending from `@repo/eslint-config`
3. Add lint and format scripts to `package.json`
4. Run `pnpm install`

### Updating Rules

- **Shared rules**: Edit `packages/eslint-config/base.js`
- **Next.js specific**: Edit `packages/eslint-config/next.js`
- **React specific**: Edit `packages/eslint-config/react-internal.js`
- **Workspace overrides**: Add to workspace's `eslint.config.js`

## 📚 Dependencies

### Root

- `eslint` - Linter
- `prettier` - Code formatter
- `typescript-eslint` - TypeScript ESLint integration
- `eslint-plugin-unused-imports` - Auto-remove unused imports
- `eslint-plugin-import` - Import/export validation and ordering
- `eslint-config-prettier` - Disable conflicting ESLint rules

### Shared Config Package

All shared configurations and their dependencies are in `packages/eslint-config`.

## 🎯 Best Practices

1. **Always run lint and format before committing**
2. **Use `--fix` flag for auto-fixable issues**: `pnpm lint --fix`
3. **Check formatting**: `pnpm format:check` in CI/CD
4. **Enable editor integration** for real-time feedback
5. **Keep shared configs minimal** - add workspace-specific overrides locally

## 🐛 Troubleshooting

### ESLint not working in VS Code

1. Reload VS Code window
2. Check Output → ESLint for errors
3. Ensure working directories are set in `.vscode/settings.json`

### Prettier conflicts with ESLint

The setup uses `eslint-config-prettier` to disable conflicting rules. If you see conflicts:

1. Check if you have other Prettier plugins installed
2. Ensure `eslint-config-prettier` is last in the config array

### Import ordering issues

Run `pnpm lint --fix` to auto-fix import ordering issues.

### Type imports

Use `import type { Type } from 'module'` for type-only imports. ESLint will enforce this and can auto-fix.

## 📖 Resources

- [ESLint Flat Config](https://eslint.org/docs/latest/use/configure/configuration-files-new)
- [Prettier Options](https://prettier.io/docs/en/options.html)
- [TypeScript ESLint](https://typescript-eslint.io/)
- [Turborepo](https://turbo.build/repo/docs)
