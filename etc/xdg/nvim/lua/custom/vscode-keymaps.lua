local keymap = vim.keymap.set
local opts = {
  noremap = true,
  silent = true,
}

-- vscode keymaps
keymap({ '' }, '<leader>ot', "<cmd>lua require('vscode').action('workbench.action.terminal.toggleTerminal')<CR>", opts)
keymap({ 'n', 'v' }, '<leader>os', "<cmd>lua require('vscode').action('workbench.action.toggleSidebarVisibility')<CR>", opts)
keymap({ 'n', 'v' }, '<leader>oc', "<cmd>lua require('vscode').action('workbench.action.chat.newChat')<CR>", opts)

keymap({ 'n', 'v' }, '<leader>q', "<cmd>lua require('vscode').action('workbench.actions.view.problems')<CR>", opts)

keymap({ 'n', 'v' }, '<leader>fs', "<cmd>lua require('vscode').action('workbench.action.focusSideBar')<CR>", opts)
keymap({ 'n', 'v', 't' }, 'fe', "<cmd>lua require('vscode').action('workbench.action.focusActiveEditorGroup')<CR>", opts)

keymap({ 'n', 'v' }, '<leader>cn', "<cmd>lua require('vscode').action('notifications.clearAll')<CR>", opts)

-- general keymaps
keymap({ 'n', 'v' }, '<leader>qf', "<cmd>lua require('vscode').action('editor.action.quickFix')<CR>", opts)
keymap({ 'n', 'v' }, '<leader>ff', "<cmd>lua require('vscode').action('workbench.action.quickOpen')<CR>", opts)
keymap({ 'n', 'v' }, '<leader>cp', "<cmd>lua require('vscode').action('workbench.action.showCommands')<CR>", opts)
keymap({ 'n', 'v' }, '<leader>pr', "<cmd>lua require('vscode').action('code-runner.run')<CR>", opts)

-- editor keymaps
keymap({ 'n', 'v' }, '<leader>fd', "<cmd>lua require('vscode').action('editor.action.formatDocument')<CR>", opts)
keymap({ 'n', 'v' }, '<leader>d', "<cmd>lua require('vscode').action('editor.action.showHover')<CR>", opts)

-- lsp keymaps
keymap({ 'n', 'v' }, '<leader>gr', "<cmd>lua require('vscode').action('editor.action.goToReferences')<CR>", opts)
keymap({ 'n', 'v' }, '<leader>gI', "<cmd>lua require('vscode').action('editor.action.goToImplementation')<CR>", opts)
keymap({ 'n', 'v' }, '<leader>rn', "<cmd>lua require('vscode').action('editor.action.rename')<CR>", opts)

keymap({ 'n', 'v' }, 'gmn', "<cmd>lua require('vscode').action('gotoNextPreviousMember.nextMember')<CR>", opts)
keymap({ 'n', 'v' }, 'gmp', "<cmd>lua require('vscode').action('gotoNextPreviousMember.previousMember')<CR>", opts)
