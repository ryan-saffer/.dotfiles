local root_markers = {
  "settings.gradle",
  "settings.gradle.kts",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "workspace.json",
}

local function root_dir(bufnr, on_dir)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local app_root = vim.fs.root(filename, "app.config.ts")

  if app_root then
    local android_root = vim.fs.joinpath(app_root, "android")
    if vim.fn.filereadable(vim.fs.joinpath(android_root, "settings.gradle")) == 1 then
      -- Expo modules live outside android/, but the generated Gradle project includes them.
      on_dir(android_root)
      return
    end
  end

  local root = vim.fs.root(filename, root_markers)
  if root then
    on_dir(root)
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_lsp = {
          root_dir = root_dir,
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "kotlin" } },
  },
}
