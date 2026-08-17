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

--- The TypeScript server only searches projects it has loaded, and it loads the project
--- owning the file you open. Opening a file in a shared package therefore finds no
--- references from the apps that consume it, because those projects were never loaded.
--- Loading one representative file per app fixes that. See `vim.g.ts_warm_consumers`.
local warmed = false

local function representative_file(dir)
  for _, candidate in ipairs({ "src/index.ts", "src/main.ts", "src/main.tsx", "src/app.tsx", "src/index.tsx" }) do
    local path = vim.fs.joinpath(dir, candidate)
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end

  local found = vim.fs.find(function(name)
    return name:match("%.tsx?$") ~= nil
  end, { path = vim.fs.joinpath(dir, "src"), type = "file", limit = 1 })
  return found[1]
end

local function warm_consumer_projects(root)
  if warmed or vim.g.ts_warm_consumers == false then
    return
  end
  warmed = true

  local apps = vim.fs.joinpath(root, "apps")
  if vim.fn.isdirectory(apps) ~= 1 then
    return
  end

  for name, kind in vim.fs.dir(apps) do
    if kind == "directory" then
      local dir = vim.fs.joinpath(apps, name)
      if vim.fn.filereadable(vim.fs.joinpath(dir, "tsconfig.json")) == 1 then
        local file = representative_file(dir)
        if file then
          -- Loading the buffer triggers an LSP didOpen, which makes the server load that
          -- project. The buffer stays hidden and unlisted.
          local bufnr = vim.fn.bufadd(file)
          vim.fn.setbufvar(bufnr, "&buflisted", 0)
          vim.fn.bufload(bufnr)
        end
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
          local file = vim.api.nvim_buf_get_name(event.buf)
          -- Only needed when starting inside a shared package; opening an app file
          -- already loads that app's project.
          if root and file:find(vim.fs.joinpath(root, "packages"), 1, true) == 1 then
            vim.schedule(function()
              warm_consumer_projects(root)
            end)
          end
        end,
      })
    end,
  },
}
