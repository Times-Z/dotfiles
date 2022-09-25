-- Key mapping
-- Define space as leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set('n', '<leader>w', '<cmd>write<cr>', {
    desc = 'Save'
})

vim.keymap.set('n', '<leader>q', '<cmd>quit<cr>', {
    desc = 'Quit'
})

vim.keymap.set('n', '<leader>a', ':keepjumps normal! ggVG<cr>', {
    desc = 'Select all in buffer'
})

vim.keymap.set('n', '<leader>,', '<cmd>RnvimrToggle<cr>', {
    desc = 'Toogle ranger'
})

vim.keymap.set('n', '<leader>c', '<cmd>CommentToggle<cr>', {
    desc = 'Toogle comment'
})

vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>', {
    desc = 'Telecope find file'
})

vim.keymap.set('n', '<leader>fn', '<cmd>DashboardNewFile<cr>', {
    desc = 'New file'
})
vim.keymap.set('n', '<leader>m', '<cmd>CodeActionMenu<cr>', {
    desc = 'code action menu'
})

