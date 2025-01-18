local config = require("grape.config")
local utils = require("grape.utils")
local todo = require("grape.todo")
local wiki = require("grape.wiki")
local graph = require("grape.graph")

local M = {}

M.todo = todo
M.utils = utils
M.VERSION = "0.5.0"

M.setup = function(opts)
  utils.setup(opts, config)
end

M.open_wiki_index = wiki.open_wiki_index
M.create_or_open_wiki_file = wiki.create_or_open_wiki_file
M.open_link = wiki.open_link
M.show_graph = graph.show_graph
M.refresh_graph = graph.create_graph_json
M.stop_server = graph.stop_server


-- Register the 'ShowGraph' command
vim.api.nvim_create_user_command(
  'ShowGraph',
  function()
    require('grape.graph').show_graph()
  end,
  { desc = 'Show the graph' }
)

vim.api.nvim_create_user_command(
  'RefreshGraph',
  function()
    require('grape.graph').create_graph_json()
  end,
  { desc = 'Regenerate the data.json for selected wiki' }
)

-- Register the 'StopServer' command
vim.api.nvim_create_user_command(
  'StopServer',
  function()
    require('grape.graph').stop_server()
  end,
  { desc = 'Stop the server' }
)

return M
