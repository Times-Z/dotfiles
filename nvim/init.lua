local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
local install_plugins = false

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    print('Installing packer...')
    local packer_url = 'https://github.com/wbthomason/packer.nvim'
    vim.fn.system({'git', 'clone', '--depth', '1', packer_url, install_path})
    print('Done.')

    vim.cmd('packadd packer.nvim')
    install_plugins = true
end

require('packer').startup(function(use)

    use {
        'kevinhwang91/rnvimr',
        config = function()
            require('plugins.config.rnvimr')
        end
    }

    use {
        'glepnir/dashboard-nvim',
        config = function()
            require('plugins.config.dashboard')
        end
    }

    use {
        'karb94/neoscroll.nvim',
        opt = true,
        config = function()
            require('neoscroll').setup()
        end
    }

    use {'nathom/filetype.nvim'}

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
        'lukas-reineke/indent-blankline.nvim',
        event = 'BufRead',
        config = function()
            require('indent_blankline').setup {require('plugins.config.indent_blankline')}
        end
    }

    use 'wbthomason/packer.nvim'
    use 'neovim/nvim-lspconfig'

    use {
        'kyazdani42/nvim-web-devicons',
        config = function()
            require('nvim-web-devicons').setup()
        end
    }

    use {
        'catppuccin/nvim',
        as = 'catppuccin'
    }

    use {
        'akinsho/bufferline.nvim',
        tag = "v2.*",
        requires = 'kyazdani42/nvim-web-devicons'
    }

    use 'feline-nvim/feline.nvim'

    use {
        'nvim-lualine/lualine.nvim',
        requires = {
            'kyazdani42/nvim-web-devicons',
            opt = true
        }
    }

    use {
        'weilbith/nvim-code-action-menu',
        cmd = 'CodeActionMenu'
    }

    use {
        "hrsh7th/nvim-cmp",
        requires = {"hrsh7th/cmp-buffer", "hrsh7th/cmp-nvim-lsp", 'quangnguyen30192/cmp-nvim-ultisnips',
                    'hrsh7th/cmp-nvim-lua', 'octaltree/cmp-look', 'hrsh7th/cmp-path', 'hrsh7th/cmp-calc',
                    'f3fora/cmp-spell', 'hrsh7th/cmp-emoji'}
    }

    use {'onsails/lspkind-nvim'}

    if install_plugins then
        require('packer').sync()
    end
end)

vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.termguicolors = true

-- Config
require('plugins.config.theme')
require('mapping')
require('plugins.packer')
require('plugins.lsp')
require('plugins.cmp')

require('bufferline').setup {}
require('lualine').setup {
    options = {
        theme = "catppuccin"
    }
}
