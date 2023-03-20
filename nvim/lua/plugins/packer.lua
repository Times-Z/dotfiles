local packer = require('packer')

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
        'VonHeikemen/fine-cmdline.nvim',
        requires = {
                {'MunifTanjim/nui.nvim'}
        }
    }

    use {
        'gelguy/wilder.nvim',
        config = function()
          -- config goes here
        end,
      }

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
        tag = "v3.*"
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

    use 'giusgad/hologram.nvim'

    use 'MunifTanjim/nui.nvim'

    use 'giusgad/pets.nvim'

    use 'nvim-tree/nvim-tree.lua'

end)
