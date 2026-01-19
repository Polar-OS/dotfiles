vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.have_nerd_font = true

if vim.g.vscode then
  require 'custom/vscode-keymaps'
else
  require 'options'
  require 'keymaps'
end

require 'lazy-bootstrap'

require 'lazy-plugins'
--
-- vim: ts=2 sts=2 sw=2 et
