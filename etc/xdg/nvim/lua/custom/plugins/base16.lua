return {
  {
    'RRethy/nvim-base16',
    lazy = false,
    priority = 1000,
    config = function()
      local function load_theme()
        -- Limpiar cache de módulos para asegurar recarga
        package.loaded['custom.theme_state'] = nil
        package.loaded['custom.matugen_theme'] = nil

        -- Intentar leer el estado
        local state_ok, state = pcall(require, 'custom.theme_state')
        
        if state_ok and state and state.type == "matugen" then
          -- Cargar tema dinámico de matugen
          local matugen_ok, matugen = pcall(require, 'custom.matugen_theme')
          if matugen_ok then
             matugen.setup()
             return
          end
        end

        -- Fallback o modo tinty: Cargar tema base16
        local theme_file = vim.fn.expand('~/.vimrc_background')
        if vim.fn.filereadable(theme_file) == 1 then
          vim.cmd('source ' .. theme_file)
        else
          pcall(vim.cmd.colorscheme, 'base16-mocha') -- Fallback final
        end
      end

      -- 1. Cargar inmediatamente
      load_theme()

      -- 2. Cargar de nuevo al terminar inicio (VimEnter) para pisar otros plugins
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          load_theme()
        end,
      })

      -- 3. Exponer comando para debug
      vim.api.nvim_create_user_command('ReloadTheme', load_theme, {})
    end,
  },
}
