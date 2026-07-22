-- Disable autocomplete on markdown
return {
  "saghen/blink.cmp",
  opts = {
    enabled = function()
      return not vim.tbl_contains({ "markdown", "text", "gitcommit" }, vim.bo.filetype)
    end,
  },
}
