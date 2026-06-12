return {
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("kanagawa").setup({
        transparent = true,
        terminalColors = true,
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
        overrides = function(colors)
          local theme = colors.theme
          return {
            -- Transparencia en flotantes y terminal
            NormalFloat  = { bg = "NONE" },
            FloatBorder  = { bg = "NONE" },
            NormalNC     = { bg = "NONE" },
            Terminal     = { bg = "NONE" },

            -- Mantener colores en lualine y bordes
            StatusLine   = { bg = theme.ui.bg_p1, fg = theme.ui.fg },
            StatusLineNC = { bg = theme.ui.bg_p1, fg = theme.ui.fg_dim },
            WinSeparator = { fg = theme.ui.bg_p2, bg = "NONE" },

            -- Mantener color en neo-tree sidebar
            NeoTreeNormal   = { bg = theme.ui.bg_m3 },
            NeoTreeNormalNC = { bg = theme.ui.bg_m3 },
          }
        end,
      })
      vim.cmd.colorscheme("kanagawa")
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa",
    },
  },
}
