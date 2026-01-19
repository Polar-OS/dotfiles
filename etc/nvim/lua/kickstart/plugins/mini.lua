return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Simple and easy statusline.
      local statusline = require 'mini.statusline'
      statusline.setup {
        use_icons = vim.g.have_nerd_font,
        content = {
          active = function()
            local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
            local git = MiniStatusline.section_git({ trunc_width = 40 })
            local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
            local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
            local filename = MiniStatusline.section_filename({ trunc_width = 140 })
            local filetype = vim.bo.filetype ~= '' and vim.bo.filetype or 'no ft'
            local search = MiniStatusline.section_searchcount({ trunc_width = 75 })
            local macro = vim.fn.reg_recording() ~= '' and ('● REC @' .. vim.fn.reg_recording()) or ''

            return MiniStatusline.combine_groups({
              { hl = mode_hl, strings = { mode, macro } },
              { hl = 'MiniStatuslineDevinfo', strings = { git, diagnostics, lsp } },
              '%<',
              { hl = 'MiniStatuslineFilename', strings = { filename } },
              '%=',
              { hl = 'MiniStatuslineFileinfo', strings = { filetype, search } },
            })
          end,
        },
      }

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim

      require('mini.move').setup() -- No need to copy this inside `setup()`. Will be used automatically.

      local gen_loader = require('mini.snippets').gen_loader
      require('mini.snippets').setup {
        snippets = {
          -- Load custom file with global snippets first (adjust for Windows)
          gen_loader.from_file '~/.config/nvim/snippets/global.json',

          -- Load snippets based on current language by reading files from
          -- "snippets/" subdirectories from 'runtimepath' directories.
          gen_loader.from_lang(),
        },
      }

      require('mini.bracketed').setup()
      require('mini.animate').setup()
      -- require('mini.indentscope').setup()
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
