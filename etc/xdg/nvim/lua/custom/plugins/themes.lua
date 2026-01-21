-- All colorschemes matching quickshell themes
return {
  -- Tokyo Night (already in kickstart, but ensure all variants)
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
  },

  -- Catppuccin
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1000,
    opts = {
      flavour = 'mocha', -- latte, frappe, macchiato, mocha
    },
  },

  -- Dracula
  {
    'Mofiqul/dracula.nvim',
    lazy = false,
    priority = 1000,
  },

  -- Nord
  {
    'shaunsingh/nord.nvim',
    lazy = false,
    priority = 1000,
  },

  -- Gruvbox
  {
    'ellisonleao/gruvbox.nvim',
    lazy = false,
    priority = 1000,
    opts = {
      contrast = 'hard',
    },
  },

  -- OneDark
  {
    'navarasu/onedark.nvim',
    lazy = false,
    priority = 1000,
    opts = {
      style = 'dark', -- dark, darker, cool, deep, warm, warmer
    },
  },

  -- Rose Pine
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    lazy = false,
    priority = 1000,
  },

  -- Solarized
  {
    'maxmx03/solarized.nvim',
    lazy = false,
    priority = 1000,
  },

  -- Everforest
  {
    'sainnhe/everforest',
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.everforest_background = 'hard'
    end,
  },

  -- Ayu
  {
    'Shatur/neovim-ayu',
    lazy = false,
    priority = 1000,
  },

  -- Nightfox (includes dawnfox)
  {
    'EdenEast/nightfox.nvim',
    lazy = false,
    priority = 1000,
  },

  -- GitHub theme
  {
    'projekt0n/github-nvim-theme',
    lazy = false,
    priority = 1000,
  },

  -- Kanagawa
  {
    'rebelot/kanagawa.nvim',
    lazy = false,
    priority = 1000,
  },

  -- Material
  {
    'marko-cerovac/material.nvim',
    lazy = false,
    priority = 1000,
  },

  -- Monokai Pro
  {
    'loctvl842/monokai-pro.nvim',
    lazy = false,
    priority = 1000,
  },

  -- Oxocarbon
  {
    'nyoom-engineering/oxocarbon.nvim',
    lazy = false,
    priority = 1000,
  },

  -- Synthwave '84
  {
    'arturgoms/moonbow.nvim', -- synthwave-like
    lazy = false,
    priority = 1000,
  },

  -- Vesper
  {
    'datsfilipe/vesper.nvim',
    lazy = false,
    priority = 1000,
  },
}
