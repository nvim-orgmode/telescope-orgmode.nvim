local M = {}

M.opts = {
  max_depth = nil,
  location_max_width = 15,
  tags_max_width = 15,
  show_location = true,
  show_tags = true,
  show_todo_state = true,
  show_priority = true,
}

function M.setup(ext_opts)
  M.opts = vim.tbl_extend('force', M.opts, ext_opts or {})
end

function M.init_opts(opts, prompt_titles, default_state)
  opts = vim.tbl_extend('force', M.opts, opts or {})
  opts.mode = opts.mode or default_state
  if not prompt_titles[opts.mode] then
    error("Invalid mode '" .. opts.mode .. "'. Valid modes are: " .. table.concat(vim.tbl_keys(prompt_titles), ', '))
  end
  opts.prompt_titles = prompt_titles
  opts.states = {}
  opts.state = { current = opts.mode, next = opts.mode }
  for state, _ in pairs(prompt_titles) do
    if state ~= opts.mode then
      opts.state.next = state
    end
    table.insert(opts.states, state)
  end

  -- Capture the current buffer before opening telescope
  opts.original_buffer = vim.api.nvim_get_current_buf()
  opts.original_file = vim.api.nvim_buf_get_name(opts.original_buffer)

  return opts
end

return M
