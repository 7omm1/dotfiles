-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup "global_indent",
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup "autoformat",
  pattern = { "lua", "scss" },
  callback = function()
    vim.b.autoformat = true
  end,
})
-- Restaurar lualine después de kanagawa
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "kanagawa",
  callback = function()
    vim.api.nvim_set_hl(0, "StatusLine", { bg = "#1f1f28", fg = "#dcd7ba" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "#1f1f28", fg = "#727169" })
    vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#363646", bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { bg = "NONE" })
  end,
})
