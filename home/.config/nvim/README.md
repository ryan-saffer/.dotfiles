# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## TypeScript Monorepos

The native TypeScript language server only searches projects it has already loaded. The
configuration in `lua/plugins/typescript.lua` loads one hidden source buffer from every
TypeScript workspace listed in the repository root `package.json`, making cross-workspace
references independent of the order in which files are opened.

New apps and packages are included automatically when they:

- match a root `workspaces` pattern;
- contain a `tsconfig.json`; and
- contain at least one TypeScript or JavaScript source file outside ignored dependency,
  generated-output, and build directories.

Neovim warns when a declared TypeScript workspace has no source file to load. Set
`vim.g.ts_warm_consumers = false` before the LSP configuration loads to disable warming
when startup time or memory usage matters more than complete monorepo references.
