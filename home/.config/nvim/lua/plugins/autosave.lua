return {
  "okuuva/auto-save.nvim",
  opts = {
    trigger_events = {
      -- Only save on these events
      immediate_save = { "BufLeave", "FocusLost" },
      -- defer_save = {}, -- disable change-based autosave
      -- cancel_deferred_save = {},
    },
    debounce_delay = 5000,
  },
}
