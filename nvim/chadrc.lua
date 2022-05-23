local M = {}

local userPlugins = require "custom.plugins"
local userMapping = require "custom.mappings"

M.ui = {
   theme = "catppuccin",
}

M.plugins = {
   user = userPlugins
}

M.mappings = {
   userMapping.rnvimr,
   userMapping.treetoggle,
   userMapping.global,
}

return M
