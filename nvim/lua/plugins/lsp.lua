local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

lsp_server = {
    'pyre',
    'pylsp',
    'pyright',
    'ansiblels',
    'angularls',
    'bashls',
    'awk_ls',
    'cssls',
    'cssmodules_ls',
    'cucumber_language_server',
    'dockerls',
    'emmet_ls',
    'eslint',
    'html',
    'intelephense',
    'phpactor',
    'phan',
    'yamlls',
}

for key,value in ipairs(lsp_server) 
do
    require('lspconfig')[value].setup {
        capabilities = capabilities
    }
end
