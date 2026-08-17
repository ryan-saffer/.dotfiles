local function ignore_dir(name)
  local escaped = vim.pesc(name)
  return {
    "^" .. escaped .. "/",
    "%f[^/]" .. escaped .. "/",
  }
end

local file_ignore_patterns = {}

for _, name in ipairs({
  "node_modules",
  ".git",
  "dist",
  "build",
  "Pods",
  ".expo",
  ".vscode",
  "Kick.app",
  ".gradle",
  ".idea",
  ".kotlin",
  ".cxx",
  ".maestro",
  "coverage",
}) do
  vim.list_extend(file_ignore_patterns, ignore_dir(name))
end

return {
  "ibhagwan/fzf-lua",
  opts = {
    files = {
      hidden = true,
      no_ignore = true,
      -- fzf-lua matches Lua patterns against paths relative to the picker cwd.
      file_ignore_patterns = file_ignore_patterns,
    },
    grep = {
      hidden = true,
      no_ignore = true,
      rg_opts = "--column --line-number --no-heading --color=always --smart-case "
        .. "--hidden --no-ignore "
        .. "-g '!**/.git/**' "
        .. "-g '!**/node_modules/**' "
        .. "-g '!**/dist/**' "
        .. "-g '!**/build/**' "
        .. "-g '!**/Pods/**' "
        .. "-g '!**/.expo/**' "
        .. "-g '!**/.vscode/**' "
        .. "-g '!**/Kick.app/**' "
        .. "-g '!**/.gradle/**' "
        .. "-g '!**/.idea/**' "
        .. "-g '!**/.kotlin/**' "
        .. "-g '!**/.cxx/**' "
        .. "-g '!**/.maestro/**' "
        .. "-g '!**/coverage/**' "
        .. "-g '!**firebase-debug**' "
        .. "-e",
    },
  },
}
