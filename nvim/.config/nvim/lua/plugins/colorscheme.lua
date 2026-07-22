-- Tokyonight base
return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night", -- darkest tokyonight variant
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "dark",
      },
      on_colors = function(colors)
        colors.bg = "#303446"
        colors.bg_dark = "#303446"
        colors.bg_float = "#292c3c"
        colors.bg_popup = "#292c3c"
        colors.bg_sidebar = "#292c3c"
        colors.bg_statusline = "#292c3c"
        colors.bg_visual = "#414559"
        colors.fg = "#c6d0f5"
        colors.fg_dark = "#a5adce"
        colors.fg_gutter = "#414559"
        colors.comment = "#a5adce"
        colors.cyan = "#5eead4"
        colors.teal = "#5eead4"
        colors.green = "#5eead4"
        colors.blue = "#818cf8"
        colors.purple = "#818cf8"
        colors.magenta = "#818cf8"
        colors.yellow = "#818cf8"
        colors.orange = "#818cf8"
        colors.red = "#f87171"
        colors.error = "#f87171"
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
