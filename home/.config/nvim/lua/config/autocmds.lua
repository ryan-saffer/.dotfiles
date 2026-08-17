-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function custom_highlights()
  vim.api.nvim_set_hl(0, "Comment", { fg = "#FF757F", italic = true })

  vim.api.nvim_set_hl(0, "LineNr", { fg = "#24A695" })
  vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#24A695" })
  vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#24A695" })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#FF966C", bold = true })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = custom_highlights,
})

custom_highlights()
