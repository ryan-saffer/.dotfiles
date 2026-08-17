return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Define a teal winbar highlight
      vim.api.nvim_set_hl(0, "WinbarPath", {
        fg = "#0f172a", -- dark text
        bg = "#24a695", -- teal background
        bold = true,
      })

      -- Enable winbar if not already enabled
      opts.winbar = opts.winbar or {}
      opts.winbar.lualine_c = {
        {
          function()
            local path = vim.fn.expand("%:p")
            if path == "" then
              return ""
            end

            -- Make path relative to cwd for readability
            return vim.fn.fnamemodify(path, ":~:.")
          end,
          color = "WinbarPath",
        },
      }
    end,
  },
}
