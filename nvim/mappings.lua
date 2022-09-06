local M = {}

M.ranger = {
    n = {
        ["<leader>,"] = {"<cmd> RnvimrToggle <CR>", "toggle ranger"}
    }
}

M.tree = {
    n = {
        ["<leader>;"] = {"<cmd> NvimTreeToggle <CR>", "toggle tree"}
    }
}

M.global = {
    n = {
        ["<leader>q"] = {"<cmd> :q <CR>", "Quit"}
    }
}

return M
