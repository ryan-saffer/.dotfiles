-- When `vim.g.lazyvim_ts_lsp` is "tsgo" (see config/options.lua), LazyVim enables the
-- `tsgo` server from nvim-lspconfig. Two things need adjusting for a monorepo:
--
--  1. Its default command looks for a `tsgo` binary, but TypeScript 7 installs its native
--     binary as `tsc`, so the command has to be redirected.
--  2. Its default root is the nearest lockfile, which spawns one server per package.
--     Pinning the root to the TypeScript install gives a single server for the whole repo.
--
-- Everything else (settings, inlay hints) comes from LazyVim's tsgo extra.

local ts = require("util.typescript")

local default_inlay_hint_handler = vim.lsp.handlers["textDocument/inlayHint"]

local function inlay_hint_text(label)
  if type(label) == "string" then
    return label
  end

  local parts = {}
  for _, part in ipairs(label) do
    parts[#parts + 1] = part.value
  end
  return table.concat(parts)
end

-- Long inlay hints push code off screen, so truncate them.
local function limit_inlay_hint_length(err, result, ctx, config)
  for _, hint in ipairs(result or {}) do
    local label = inlay_hint_text(hint.label)
    if vim.fn.strdisplaywidth(label) > 30 then
      hint.label = vim.fn.strcharpart(label, 0, 30) .. "…"
    end
  end

  return default_inlay_hint_handler(err, result, ctx, config)
end

--- The TypeScript server only searches projects it has loaded. In a monorepo this makes
--- cross-workspace references depend on which files happened to be opened first. Load one
--- representative file from every TypeScript workspace declared in the root package.json
--- so references are complete regardless of the initial file. See `vim.g.ts_warm_consumers`.
local warmed_roots = {}

local ignored_directories = {
  [".astro"] = true,
  [".git"] = true,
  [".sanity"] = true,
  build = true,
  dist = true,
  node_modules = true,
}

local function is_source_file(name)
  return name:match("%.tsx?$") ~= nil or name:match("%.jsx?$") ~= nil
end

local function representative_file(dir)
  for _, candidate in ipairs({
    "src/index.ts",
    "src/main.ts",
    "src/main.tsx",
    "src/app.tsx",
    "src/index.tsx",
    "index.ts",
    "index.tsx",
    "main.ts",
    "main.tsx",
  }) do
    local path = vim.fs.joinpath(dir, candidate)
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end

  -- Some workspaces, such as Sanity Studio, keep source outside src/. Search the
  -- workspace while avoiding generated output and dependency trees.
  local directories = { dir }
  local declaration
  local index = 1
  while directories[index] do
    local current = directories[index]
    index = index + 1
    for name, kind in vim.fs.dir(current) do
      local path = vim.fs.joinpath(current, name)
      if kind == "file" and is_source_file(name) then
        if not name:match("%.d%.ts$") then
          return path
        end
        declaration = declaration or path
      elseif kind == "directory" and not ignored_directories[name] then
        directories[#directories + 1] = path
      end
    end
  end
  return declaration
end

local function workspace_directories(root)
  local package_path = vim.fs.joinpath(root, "package.json")
  if vim.fn.filereadable(package_path) ~= 1 then
    return {}
  end

  local ok, package = pcall(vim.json.decode, table.concat(vim.fn.readfile(package_path), "\n"))
  if not ok or type(package) ~= "table" then
    vim.notify("Cannot read workspace configuration from " .. package_path, vim.log.levels.WARN)
    return {}
  end

  local patterns = package.workspaces
  if type(patterns) == "table" and type(patterns.packages) == "table" then
    patterns = patterns.packages
  end
  if type(patterns) ~= "table" then
    return {}
  end

  local directories = {}
  local seen = {}
  for _, pattern in ipairs(patterns) do
    if type(pattern) == "string" then
      for _, path in ipairs(vim.fn.glob(vim.fs.joinpath(root, pattern), false, true)) do
        path = vim.fs.normalize(path)
        if not seen[path] and vim.fn.isdirectory(path) == 1 then
          seen[path] = true
          directories[#directories + 1] = path
        end
      end
    end
  end
  table.sort(directories)
  return directories
end

local function warm_workspace_projects(root)
  if warmed_roots[root] or vim.g.ts_warm_consumers == false then
    return
  end
  warmed_roots[root] = true

  for _, dir in ipairs(workspace_directories(root)) do
    if vim.fn.filereadable(vim.fs.joinpath(dir, "tsconfig.json")) == 1 then
      local file = representative_file(dir)
      if file then
        -- Loading the buffer triggers an LSP didOpen, which makes the server load that
        -- project. The buffer stays hidden and unlisted.
        local bufnr = vim.fn.bufadd(file)
        vim.fn.setbufvar(bufnr, "&buflisted", 0)
        vim.fn.bufload(bufnr)
      else
        vim.notify("Cannot warm TypeScript workspace without a source file: " .. dir, vim.log.levels.WARN)
      end
    end
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tsgo = {
          -- The binary comes from the project's node_modules, not Mason.
          mason = false,
          -- LazyVim's extra omits these dotted variants.
          filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
          },
          handlers = {
            ["textDocument/inlayHint"] = limit_inlay_hint_length,
          },
          -- One server for the whole repo, rather than one per nearest lockfile.
          root_dir = function(bufnr, on_dir)
            local root = ts.root(vim.api.nvim_buf_get_name(bufnr))
            if root then
              on_dir(root)
            end
          end,
          cmd = function(dispatchers, config)
            -- Resolve independently of root_dir, since the install may sit above it.
            local tsc = ts.tsc((config or {}).root_dir) or ts.tsc()
            if not tsc then
              vim.notify("TypeScript 7 `tsc` not found; cannot start tsgo", vim.log.levels.ERROR)
              return
            end

            return vim.lsp.rpc.start({ tsc, "--lsp", "--stdio" }, dispatchers)
          end,
        },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    optional = true,
    init = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("ts_warm_consumers", { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client or client.name ~= "tsgo" then
            return
          end

          local root = client.config.root_dir
          if root then
            vim.schedule(function()
              warm_workspace_projects(root)
            end)
          end
        end,
      })
    end,
  },
}
