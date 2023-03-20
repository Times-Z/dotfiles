vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
      fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
      vim.cmd [[packadd packer.nvim]]
      return true
    end
    return false
  end

local packer_bootstrap = ensure_packer()
local packer = require('packer')

packer.init({
    max_jobs = nil,
      git = {
        clone_timeout = 99999,
    }
})

require('plugins.packer')

if packer_bootstrap then
    packer.sync()
end

if packer_bootstrap == false then
    vim.opt.number = true
    vim.opt.mouse = 'a'
    vim.opt.termguicolors = true
    
    -- Config
    require('plugins.config.theme')
    require('mapping')
    require('plugins.lsp')
    require('plugins.cmp')
    
    require('bufferline').setup {}
    require('lualine').setup {
        options = {
            theme = "catppuccin"
        }
    }
    require("nvim-tree").setup({
	sort_by = "case_sensitive",
  	renderer = {
    		group_empty = true,
  	},
  	filters = {
		dotfiles = true,
  	},
})
end
