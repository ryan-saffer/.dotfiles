-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- set cwd to git root and apply for lsp as well
vim.opt.autochdir = false
vim.g.root_spec = { { ".git" }, "cwd" }

-- Pick the TypeScript language server once per session, based on the project we opened:
-- `tsgo` (the native TypeScript 7 server) when the project ships TypeScript 7, else `vtsls`.
-- LazyVim reads this at startup and hard-disables the other server, so it cannot vary
-- per project within one session -- which is fine, since each project gets its own instance.
vim.g.lazyvim_ts_lsp = require("util.typescript").root() and "tsgo" or "vtsls"
