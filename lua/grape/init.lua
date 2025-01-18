local config = require("grape.config")
local utils = require("grape.utils")
local todo = require("grape.todo")
local wiki = require("grape.wiki")
local graph = require("grape.graph")

local M = {}

M.todo = todo
M.utils = utils
M.VERSION = "0.4.0"

M.setup = function(opts)
  utils.setup(opts, config)
end

M.open_wiki_index = wiki.open_wiki_index
M.create_or_open_wiki_file = wiki.create_or_open_wiki_file
M.open_link = wiki.open_link
M.show_graph = graph.show_graph
M.stop_server = graph.stop_server

return M
