local graph = {}
local server_job_id = nil  -- Variable to store the server job ID
local config = require("grape.config")
local utils = require("grape.utils")

-- Helper function to check if a file exists
local function file_exists(filepath)
  local file = io.open(filepath, "r")
  if file then
    file:close()
    return true
  else
    return false
  end
end

-- Helper function to create directory if it doesn't exist
local function create_directory(path)
  return vim.loop.fs_mkdir(path, 511)  -- 511 is 0777 in octal
end

-- Helper function to copy files
local function copy_file(source, destination)
  local source_file = io.open(source, "r")
  if source_file then
    local content = source_file:read("*all")
    source_file:close()
    
    -- Create the destination directory if it doesn't exist
    local dest_dir = vim.fn.fnamemodify(destination, ":h")
    create_directory(dest_dir)
    
    local dest_file = io.open(destination, "w")
    if dest_file then
      dest_file:write(content)
      dest_file:close()
      vim.api.nvim_out_write("Copied: " .. source .. " to " .. destination .. "\n")
    else
      vim.api.nvim_out_write("Error: Could not write to " .. destination .. "\n")
    end
  else
    vim.api.nvim_out_write("Error: Could not read " .. source .. "\n")
  end
end

-- Get current paths for the active wiki
local function get_wiki_paths()
  if not config.wiki_name or config.wiki_name == "" or not config.path or config.path == "" then
    vim.api.nvim_out_write("Error: No wiki is currently active. Please open a wiki first.\n")
    return nil
  end

  local cache_dir = vim.fn.stdpath("cache")
  return {
    base_dir = cache_dir .. "/grape.nvim",
    wiki_dir = cache_dir .. "/grape.nvim/" .. config.wiki_name,
    force_graph_js = cache_dir .. "/grape.nvim/force-graph.min.js",
    index_html = cache_dir .. "/grape.nvim/" .. config.wiki_name .. "/index.html"
  }
end

-- Get the plugin root directory
local function get_plugin_root()
  -- Get the directory of the current file (graph.lua)
  local source = debug.getinfo(1, "S").source
  local file_path = string.sub(source, 2)  -- Remove the '@' prefix
  
  -- Navigate up to the plugin root (two levels up from lua/grape/graph.lua)
  return vim.fn.fnamemodify(file_path, ":h:h:h")
end

-- Setup function to configure the graph module
graph.setup = function()
  local paths = get_wiki_paths()
  if not paths then return end
  
  -- Create the necessary directories
  create_directory(paths.base_dir)
  create_directory(paths.wiki_dir)
  
  -- Get the plugin root directory and construct assets path
  local plugin_root = get_plugin_root()
  local assets_dir = plugin_root .. "/assets"
  
  -- Copy force-graph.min.js if it doesn't exist
  local force_graph_src = assets_dir .. "/force-graph.min.js"
  if not file_exists(paths.force_graph_js) then
    copy_file(force_graph_src, paths.force_graph_js)
  end
  
  -- Copy index.html to the wiki directory if it doesn't exist
  local index_html_src = assets_dir .. "/index.html"
  if not file_exists(paths.index_html) then
    copy_file(index_html_src, paths.index_html)
  end
  
  return paths
end

-- Start a simple web server to serve the HTML file
graph.show_graph = function()
  local paths = graph.setup()  -- Ensure everything is set up for current wiki
  if not paths then return end
  
  -- Check if the index.html exists before starting the server
  if not file_exists(paths.index_html) then
    vim.api.nvim_out_write("Error: " .. paths.index_html .. " does not exist. Cannot start the server.\n")
    return
  end

  graph.refresh_graph_data(paths.wiki_dir)

  -- Set the port for the server and create the command to start it
  local port = 8000
  local cmd = "python3 -m http.server " .. port .. " --directory " .. paths.base_dir
  
  -- Execute the command to start the server in the background
  server_job_id = vim.fn.jobstart(cmd)
  vim.api.nvim_out_write("Server running at: http://localhost:" .. port .. "\n")
  
  -- Construct URL using the current wiki name
  local url = string.format("http://localhost:%d/%s/index.html", port, config.wiki_name)
  graph.open_in_browser(url)
end

graph.refresh_graph_data = function(wiki_dir)
  utils.create_data_json(wiki_dir)
end

-- Stops the server by terminating the background job
graph.stop_server = function()
  if server_job_id then
    vim.fn.jobstop(server_job_id)  -- Stop the server job
    vim.api.nvim_out_write("Server stopped.\n")
  else
    vim.api.nvim_out_write("No server running to stop.\n")
  end
end

-- Opens the generated HTML file in the default web browser
graph.open_in_browser = function(url)
  local cmd
  if vim.fn.has("mac") == 1 then
    cmd = "open " .. url
  elseif vim.fn.has("unix") == 1 then
    cmd = "xdg-open " .. url
  elseif vim.fn.has("win32") == 1 then
    cmd = "start " .. url
  else
    error("Unsupported OS for opening the browser")
  end
  os.execute(cmd)
end

return graph
