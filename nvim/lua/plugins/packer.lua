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

    if install_plugins then
        require('packer').sync()
    end
end)
