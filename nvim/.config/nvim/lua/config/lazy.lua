require("lazy").setup {
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
    { import = "plugins.ui" },
    { import = "plugins.tools" },
    { import = "plugins.lang" },
  },

  defaults = {
    lazy = true,
    version = false,
  },

  install = { colorscheme = { "kanagawa" } },

  checker = {
    enabled = false,
    notify = false,
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "2html_plugin", "tohtml", "getscript", "getscriptplugin",
        "gzip", "logipat", "netrw", "netrwplugin", "netrwsettings",
        "netrwfilehandlers", "matchit", "tar", "tarplugin", "rrhelper",
        "spellfile_plugin", "vimball", "vimballplugin", "zip", "zipplugin",
        "tutor", "rplugin", "syntax", "synmenu", "optwin", "compiler",
        "bugreport", "ftplugin",
      },
    },
  },
}
