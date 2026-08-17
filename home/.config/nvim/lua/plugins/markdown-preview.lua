return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  build = "cd app && npm install",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
  end,
  config = function()
    -- Custom opener to avoid focusing the browser on macOS
    vim.cmd([[
        function! OpenMarkdownPreview(url)
          " -g: do not bring app to foreground
          silent call system('open -g ' . shellescape(a:url))
        endfunction
        let g:mkdp_browserfunc = 'OpenMarkdownPreview'
      ]])
  end,
  ft = { "markdown" },
}
