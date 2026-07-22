-- No Node in this VM: prevent Mason from trying (and failing)
-- to install Node-based markdown tools. Removes installer noise.
return {
  "mason-org/mason.nvim",
  opts = function(_, opts)
    opts.ensure_installed = opts.ensure_installed or {}
    opts.ensure_installed = vim.tbl_filter(function(pkg)
      return pkg ~= "markdownlint-cli2" and pkg ~= "markdown-toc"
    end, opts.ensure_installed)
    return opts
  end,
}
