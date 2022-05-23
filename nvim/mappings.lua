local M = {}

M.rnvimr = {
    mode_opts = { silent = false }, 
    n = {
       ["<leader>,"] = { "<cmd> RnvimrToggle <CR>", "toggle ranger" }
    },
 }

M.treetoggle = {
    mode_opts = { silent = false },
    n = {
       ["<leader>;"] = { "<cmd> NvimTreeToggle <CR>", "toggle tree" }
    },
}

M.global = {
    mode_opts = { silent = false },
    n = {
       ["<leader>q"] = { "<cmd> :q <CR>", "Quit" }
    },
}

return M