return {
  'andrew-george/telescope-themes',
  config = function()
    require('telescope').load_extension 'themes'
  end,
  init = function()
    vim.keymap.set('n', '<leader>st', ':Telescope themes<CR>', { noremap = true, silent = true, desc = 'Theme Switcher' })
  end,
}
