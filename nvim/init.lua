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
    },
    display = {
        non_interactive = true
    }
})

packer.startup(function(use)

    use 'wbthomason/packer.nvim'

    use 'nvim-tree/nvim-web-devicons'

    use 'nathom/filetype.nvim'

    use 'neovim/nvim-lspconfig'

    use 'feline-nvim/feline.nvim'

    use 'nvim-lualine/lualine.nvim'

    use 'hrsh7th/nvim-cmp'

    use 'hrsh7th/cmp-nvim-lsp'

    use 'hrsh7th/cmp-nvim-lua'

    use 'hrsh7th/cmp-buffer'

    use 'octaltree/cmp-look'

    use 'hrsh7th/cmp-path'

    use 'hrsh7th/cmp-calc'

    use 'f3fora/cmp-spell'

    use 'hrsh7th/cmp-emoji'

    use 'quangnguyen30192/cmp-nvim-ultisnips'

    use 'onsails/lspkind-nvim'

    use {
        'kevinhwang91/rnvimr',
        config = function()
            require('plugins.config.rnvimr')
        end
    }

    use {
        'glepnir/dashboard-nvim',
        event = 'VimEnter',
        config = function()
          require('dashboard').setup {
            theme = require('plugins.config.dashboard').theme,
            config = require('plugins.config.dashboard').config;
            hide = require('plugins.config.dashboard').hide
          }
        end,
        requires = {'nvim-tree/nvim-web-devicons'}
      }

    use {
        'karb94/neoscroll.nvim',
        opt = true,
        config = function()
            require('neoscroll').setup()
        end
    }


    use {
        'terrortylor/nvim-comment',
        cmd = "CommentToggle",
        config = function()
            require('nvim_comment').setup()
        end
    }

    use {'nvim-lua/plenary.nvim'}

    use {
        'nvim-telescope/telescope.nvim',
        cmd = "Telescope",
        config = function()
            require('telescope').setup()
        end
    }

    use {
        'nvim-telescope/telescope-media-files.nvim',
        after = "telescope.nvim",
        config = function()
            require("telescope").setup {
                extensions = {
                    media_files = {
                        filetypes = {"png", "webp", "jpg", "jpeg", "png"},
                        find_cmd = "rg" -- find command (defaults to `fd`)
                    }
                }
            }
            require("telescope").load_extension "media_files"
        end

    }

    use {
        'lewis6991/gitsigns.nvim',
        opt = true,
        config = function()
            require('gitsigns').setup()
        end
    }

    use {
        'catppuccin/nvim',
        as = 'catppuccin'
    }

    use {
        'akinsho/bufferline.nvim',
        tag = "v2.*"
    }

    use {
        'weilbith/nvim-code-action-menu',
        cmd = 'CodeActionMenu'
    }


    use {
        'lukas-reineke/indent-blankline.nvim',
        event = 'BufRead',
        config = function()
            require('indent_blankline').setup {
                require('plugins.config.indent_blankline')
            }
        end
    }

    if packer_bootstrap then
        packer.sync()
    end
end)

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
end