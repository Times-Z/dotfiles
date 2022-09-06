local M = {}

local userPlugins = require "custom.plugins"
-- local pluginConfs = require "custom.plugins.configs"

M.ui = {
    theme = "catppuccin"
}

M.plugins = {
    user = userPlugins
}

M.mappings = require "custom.mappings"

return M
