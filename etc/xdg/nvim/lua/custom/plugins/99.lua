return {
  'ThePrimeagen/99',
  config = function()
    local _99 = require '99'
    _99.setup {
      logger = {
        level = _99.DEBUG,
        path = '/tmp/' .. vim.fs.basename(vim.uv.cwd()) .. '.99.debug',
        print_on_error = true,
      },
      md_files = {
        'AGENT.md',
      },
      model = 'opencode/glm-4.7-free',
    }

    vim.keymap.set('n', '<leader>9f', _99.fill_in_function, { desc = '[9]9 Fill in function' })
    vim.keymap.set('v', '<leader>9v', _99.visual, { desc = '[9]9 Visual selection' })
    vim.keymap.set('n', '<leader>9s', _99.stop_all_requests, { desc = '[9]9 Stop all requests' })
    vim.keymap.set('n', '<leader>9p', _99.fill_in_function_prompt, { desc = '[9]9 Fill in function w/ prompt' })
  end,
}
