local graph = {}
local server_job_id = nil  -- Variable to store the server job ID

-- Function to generate HTML file for the wiki graph
graph.generate_html = function()
  local html_content = [[
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Graph Visualization</title>
    <style>
      body { font-family: Arial, sans-serif; text-align: center; margin: 50px; }
      .graph { display: flex; justify-content: center; align-items: center; height: 100vh; }
      .node { border: 1px solid #333; padding: 10px; border-radius: 50%; }
    </style>
  </head>
  <body>
    <h1>Graph Visualization</h1>
    <div class="graph">
      <div class="node">Wiki Graph</div>
    </div>
  </body>
  </html>
  ]]
  
  -- Save the generated HTML to the desired path
  local home_dir = vim.loop.os_homedir()
  local file_path = home_dir .. "/wiki_graph.html"

  -- Write the content to the file
  local file = io.open(file_path, "w")
  if file then
    file:write(html_content)
    file:close()
    -- Output success message to the message area (no command line)
    vim.api.nvim_out_write("Graph HTML generated at: " .. file_path .. "\n")
    return file_path
  else
    -- Handle file writing error by outputting message to the message area
    vim.api.nvim_out_write("Error: Could not write HTML file\n")
    return nil
  end
end

-- Start a simple web server to serve the HTML file
graph.start_server = function(file_path)
  -- You can choose a port and a simple HTTP server command like python's built-in HTTP server
  local port = 8000
  local cmd = "python3 -m http.server " .. port .. " --directory " .. vim.loop.os_homedir()

  -- Execute the command to start the server in the background
  server_job_id = vim.fn.jobstart(cmd)
  vim.api.nvim_out_write("Server running at: http://localhost:" .. port .. "\n")
  
  -- Open the file in the browser after starting the server
  graph.open_in_browser("http://localhost:" .. port .. "/wiki_graph.html")
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

-- Main function to generate and start the server for the graph
graph.show_graph = function()
  local file_path = graph.generate_html()
  if file_path then
    graph.start_server(file_path)
  end
end

return graph
