return {
  "epwalsh/obsidian.nvim",
  version = "*",
  ft = "markdown",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    workspaces = {
      { name = "vault", path = "~/Documents/obsidian" },
    },
    ui = { enable = false },
  },
  keys = {
    { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "Obsidian: new note" },
    { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Obsidian: search" },
    { "<leader>od", "<cmd>ObsidianToday<cr>", desc = "Obsidian: daily note" },
    { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Obsidian: backlinks" },
  },
}
