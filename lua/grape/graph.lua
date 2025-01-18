local graph = {}
local server_job_id = nil -- Variable to store the server job ID
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
  return vim.loop.fs_mkdir(path, 511) -- 511 is 0777 in octal
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
  local file_path = string.sub(source, 2) -- Remove the '@' prefix

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


graph.get_links_from_file = function(file_path)
  local links = {}

  -- Open the file for reading
  local file = io.open(file_path, "r")
  if not file then
    return nil, "Failed to open file: " .. file_path
  end

  -- Read each line of the file
  local line_number = 0
  for line in file:lines() do
    line_number = line_number + 1

    -- Search for links using the first pattern ([title](file))
    local pattern1 = "%[(.-)%]%(<?([^)>]+)>?%)"
    local start_pos = 1
    while true do
      local match_start, match_end, _, file_link = line:find(pattern1, start_pos)
      if not match_start then break end
      start_pos = match_end + 1
      table.insert(links, utils.resolve_path(file_link, config))
    end

    -- Search for links using the second pattern ([[file]])
    local pattern2 = "%[%[(.-)%]%]"
    start_pos = 1
    while true do
      local match_start, match_end, file_link = line:find(pattern2, start_pos)
      if not match_start then break end
      start_pos = match_end + 1
      table.insert(links, utils.resolve_path(file_link, config))
    end
  end

  file:close()
  return links
end

graph.create_graph_json = function()
  local paths = get_wiki_paths()
local files = vim.fn.glob(config.path .. "/**/*.md", true, true)
  local nodes = {}
  local links = {}
  local file_ids = {}

  -- Create nodes (unique files)
  for i, file in ipairs(files) do
    if not file_ids[file] then
      -- Assign a unique ID to each file (node)
      table.insert(nodes, { id = file, group = 1 })
      file_ids[file] = #nodes -- Store the node index
    end
  end

  -- Create links (file relationships)
  for i, file in ipairs(files) do
    local current_file = file
    local current_file_id = file_ids[current_file]

    -- Find links (you can customize how to match links here)
    local current_file_links = graph.get_links_from_file(current_file)
    for j, link_file in ipairs(current_file_links) do
      if current_file ~= link_file then
        local link_file_id = file_ids[link_file]

        -- If the linked file is not already in the nodes, add it
        if not link_file_id then
          -- Add the link_file as a node
          table.insert(nodes, { id = link_file, group = 2 })
          file_ids[link_file] = #nodes -- Store the node index
          link_file_id = #nodes      -- Now link_file has a valid ID
        end

        -- Add a link from current_file to link_file
        table.insert(links, { source = current_file, target = link_file, value = 1 })
      end
    end
  end

  -- Convert the table to a JSON-like string
  local function table_to_json(t)
    local result = "{\n"

    -- Convert nodes to JSON format
    result = result .. '"nodes": [\n'
    for i, node in ipairs(t.nodes) do
      result = result .. '  {"id": "' .. node.id .. '", "group": ' .. node.group .. '}'
      if i < #t.nodes then
        result = result .. ',\n'
      else
        result = result .. '\n'
      end
    end
    result = result .. '],\n'

    -- Convert links to JSON format
    result = result .. '"links": [\n'
    for i, link in ipairs(t.links) do
      result = result ..
      '  {"source": "' .. link.source .. '", "target": "' .. link.target .. '", "value": ' .. link.value .. '}'
      if i < #t.links then
        result = result .. ',\n'
      else
        result = result .. '\n'
      end
    end
    result = result .. ']\n'

    result = result .. "}"
    return result
  end

  -- Create the graph JSON structure
  local graph_json = {
    nodes = nodes,
    links = links
  }

  -- Convert to JSON-like string
  local json_string = table_to_json(graph_json)

  -- Save the JSON structure to a file
  local output_file = io.open(paths.wiki_dir .. "/data.json", "w")
  if not output_file then
    return "Failed to open file for writing."
  end

  output_file:write(json_string)
  output_file:close()

  return "Graph JSON saved successfully!"
end

-- Start a simple web server to serve the HTML file
graph.show_graph = function()
  local paths = graph.setup() -- Ensure everything is set up for current wiki
  if not paths then return end

  -- Check if the index.html exists before starting the server
  if not file_exists(paths.index_html) then
    vim.api.nvim_out_write("Error: " .. paths.index_html .. " does not exist. Cannot start the server.\n")
    return
  end

  graph.create_graph_json()

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

-- Stops the server by terminating the background job
graph.stop_server = function()
  if server_job_id then
    vim.fn.jobstop(server_job_id) -- Stop the server job
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
