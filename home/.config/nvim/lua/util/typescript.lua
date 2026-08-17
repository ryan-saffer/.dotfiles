-- Helpers for detecting a TypeScript 7 (native) install.
--
-- TypeScript 7 ships a native binary that speaks LSP via `tsc --lsp --stdio`.
-- Note the binary is called `tsc`, not `tsgo` -- `tsgo` is the name used by the
-- separate `@typescript/native-preview` package. nvim-lspconfig's `tsgo` server
-- looks for a `tsgo` binary, so the command has to be pointed at `tsc` instead.

local M = {}

local function package_version(path)
  if vim.fn.filereadable(path) ~= 1 then
    return
  end

  local ok, package = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
  if ok then
    return package.version
  end
end

---Does `dir` contain a node_modules providing TypeScript 7?
---@param dir string
---@return boolean
local function provides_typescript7(dir)
  -- `@typescript/native` is the conventional alias for the native package.
  if package_version(vim.fs.joinpath(dir, "node_modules", "@typescript", "native", "package.json")) then
    return true
  end

  local version = package_version(vim.fs.joinpath(dir, "node_modules", "typescript", "package.json"))
  local major = version and tonumber(version:match("^(%d+)"))
  return major ~= nil and major >= 7
end

---Walk up from `start` looking for the directory that holds the TypeScript 7 install.
---In a monorepo the install is hoisted to the workspace root, which may be several
---levels above the nearest package.json or lockfile, so anchoring on those is not enough.
---@param start? string defaults to the current working directory
---@return string? dir
function M.root(start)
  local dir = start or vim.fn.getcwd()
  if dir == "" then
    return
  end

  if vim.fn.isdirectory(dir) ~= 1 then
    dir = vim.fs.dirname(dir)
  end

  while dir do
    if provides_typescript7(dir) then
      return dir
    end

    local parent = vim.fs.dirname(dir)
    if parent == dir then
      return
    end
    dir = parent
  end
end

---Absolute path to the TypeScript 7 `tsc` binary for the project containing `start`.
---@param start? string
---@return string? path
function M.tsc(start)
  local root = M.root(start)
  if not root then
    return
  end

  local tsc = vim.fs.joinpath(root, "node_modules", ".bin", "tsc")
  if vim.fn.executable(tsc) == 1 then
    return tsc
  end
end

return M
