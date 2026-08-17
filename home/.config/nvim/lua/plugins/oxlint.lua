local js_like_filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
}

return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters = opts.formatters or {}

      -- Oxfmt cannot sort JSON keys, so preserve the old Prettier behavior for translation files with the repo sorter.
      opts.formatters.sort_i18n_json = {
        command = require("conform.util").from_node_modules("tsx"),
        args = { "scripts/sort-i18n-json.ts", "$FILENAME" },
        cwd = require("conform.util").root_file({ ".oxfmtrc.json" }),
        require_cwd = true,
        stdin = false,
        condition = function(_, ctx)
          return vim.fs.normalize(ctx.filename):match("/src/i18n/languages/[^/]+%.json$") ~= nil
        end,
      }

      local json_formatters = opts.formatters_by_ft.json or {}
      if not vim.tbl_contains(json_formatters, "sort_i18n_json") then
        table.insert(json_formatters, 1, "sort_i18n_json")
      end
      opts.formatters_by_ft.json = json_formatters

      for _, ft in ipairs(js_like_filetypes) do
        local formatters = opts.formatters_by_ft[ft] or {}

        formatters = vim.tbl_filter(function(formatter)
          return formatter ~= "eslint_d" and formatter ~= "prettier" and formatter ~= "prettierd"
        end, formatters)

        if not vim.tbl_contains(formatters, "oxlint") then
          table.insert(formatters, 1, "oxlint")
        end

        opts.formatters_by_ft[ft] = formatters
      end
    end,
  },
}
