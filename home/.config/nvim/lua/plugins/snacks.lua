return {
  "folke/snacks.nvim",
  opts = {
    scroll = {
      enabled = false,
    },
    picker = {
      sources = {
        git_log_file = {
          actions = {
            yank_commit = { action = "yank", field = "commit", reg = "+" },
          },
          win = {
            input = {
              keys = {
                ["<c-y>"] = { "yank_commit", mode = { "n", "i" } },
              },
            },
            list = {
              keys = {
                ["<c-y>"] = "yank_commit",
              },
            },
          },
        },
      },
    },
  },
}
