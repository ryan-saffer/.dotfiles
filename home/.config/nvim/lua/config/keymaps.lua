-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Ctrl + Shift + Click to find references
vim.keymap.set("n", "<C-M-LeftMouse>", vim.lsp.buf.references, { desc = "LSP: Find references" })
-- When scrolling half page up/down, center the line vertically.
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true })
-- keep registers intact when deleting
vim.keymap.set("n", "<leader>d", '"_dd', { desc = "Delete line (no yank)" })
vim.keymap.set("v", "<leader>d", '"_d', { desc = "Delete (no yank)" })
vim.keymap.set("x", "<leader>d", '"_dd', { desc = "Delete line (no yank)" })
vim.keymap.set("n", "<leader>x", '"_x', { desc = "Delete char (no yank)" })
vim.keymap.set("n", "<leader>p", '"_p', { desc = "Paste (no yank)" })
vim.keymap.set("v", "<leader>p", '"_p', { desc = "Paste (no yank)" })
vim.keymap.set("x", "<leader>p", '"_p', { desc = "Paste (no yank)" })

-- Markdown preview
vim.keymap.set("n", "<leader>m", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Markdown Preview" })
