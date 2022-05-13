return {

    ["neovim/nvim-lspconfig"] = {
        after = "nvim-lsp-installer",
        module = "lspconfig",
        config = function()
            local lsp_module = require "lspconfig"
            require "plugins.configs.lsp_installer"
            require "plugins.configs.lspconfig"
            -- Enable (broadcasting) snippet capability for completion
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities.textDocument.completion.completionItem.snippetSupport = true
            lsp_module.pyright.setup {}
            lsp_module.bashls.setup {}
            lsp_module.cssmodules_ls.setup {}
            lsp_module.dockerls.setup {}
            lsp_module.dotls.setup {}
            lsp_module.emmet_ls.setup {}
            lsp_module.eslint.setup {}
            lsp_module.gopls.setup {}
            lsp_module.golangci_lint_ls.setup {}
            lsp_module.html.setup {
                capabilities = capabilities
            }
            lsp_module.jsonls.setup {
                capabilities = capabilities
            }
            lsp_module.intelephense.setup {}
        end
    },

    ["karb94/neoscroll.nvim"] = {
        opt = true,
        config = function()
            require("neoscroll").setup()
        end,

        -- lazy loading
        setup = function()
            require("core.utils").packer_lazy_load "neoscroll.nvim"
        end
    },

    ["nathom/filetype.nvim"] = {},

    ["kevinhwang91/rnvimr"] = {
        config = function()
            require("custom.plugins.configs.rnvimr")
        end
    },

    ["sindrets/diffview.nvim"] = {
        requires = 'nvim-lua/plenary.nvim'
    },

    ["glepnir/dashboard-nvim"] = {
        config = function()
            require("custom.plugins.configs.dash")
        end
    },

    ["terrortylor/nvim-comment"] = {
        cmd = "CommentToggle",
        config = function()
            require("plugins.configs.others")
        end,
        setup = function()
            require("core.mappings").comment()
        end
    },

    ["nvim-telescope/telescope.nvim"] = {
        cmd = "Telescope",

        setup = function()
            require("core.mappings").telescope()
        end,

        config = function()
            require "plugins.configs.telescope"
        end
    },

    ["nvim-telescope/telescope-media-files.nvim"] = {
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
    },

    ["lewis6991/gitsigns.nvim"] = {
        opt = true,
        config = function()
            require("plugins.configs.others").gitsigns()
        end,
        setup = function()
            require("core.utils").packer_lazy_load "gitsigns.nvim"
        end
    },

    ["lukas-reineke/indent-blankline.nvim"] = {
        event = "BufRead",
        config = function()
            require("indent_blankline").setup {
                indentLine_enabled = 1,
                char = "▏",
                space_char_blankline = " ",
                show_current_context = true,
                filetype_exclude = {"help", "terminal", "dashboard", "packer", "lspinfo", "TelescopePrompt",
                                    "TelescopeResults"},
                char_highlight_list = {"IndentBlanklineIndent1", "IndentBlanklineIndent2", "IndentBlanklineIndent3",
                                       "IndentBlanklineIndent4", "IndentBlanklineIndent5", "IndentBlanklineIndent6"},
                buftype_exclude = {"terminal", "dashboard"},
                show_trailing_blankline_indent = false,
                show_first_indent_level = false
            }
        end
    }
}
