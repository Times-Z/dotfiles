local g = vim.g

g.rnvimr_enable_ex = 1
g.rnvimr_enable_picker = 1
g.rnvimr_enable_bw = 1
g.rnvimr_ranger_cmd = {
    'ranger'
}
vim.cmd("highlight link RnvimrNormal CursorLine")

-- Override default actions
vim.g.rnvimr_action = {
['<CR>'] = 'NvimEdit tabedit',
['o'] = 'NvimEdit tabedit'
}
