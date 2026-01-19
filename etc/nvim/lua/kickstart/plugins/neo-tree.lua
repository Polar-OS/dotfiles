-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal float<CR>', desc = 'NeoTree reveal float', silent = true },
  },
  opts = {
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        use_libuv_file_watcher = true,
      },
      sources = {
        winbar = true,
        content_layout = 'center',
        { source = 'filesystem', display_name = ' 󰈔 File' },
        { source = 'buffers', display_name = '  Bufs' },
        { source = 'git_status', display_name = '  Git' },
      },
    },
  },
}
