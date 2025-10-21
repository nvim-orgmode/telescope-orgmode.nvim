local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local action_set = require('telescope.actions.set')

local PickerState = require('telescope-orgmode.lib.state')
local operations = require('telescope-orgmode.lib.operations')
local config = require('telescope-orgmode.lib.config')
local org = require('telescope-orgmode.org')
local headlines_entry = require('telescope-orgmode.entry_maker.headlines')
local orgfiles_entry = require('telescope-orgmode.entry_maker.orgfiles')
local lib_actions = require('telescope-orgmode.lib.actions')
local keybindings = require('telescope-orgmode.lib.keybindings')

local M = {}

---Create telescope finder for current state
---@param state PickerState
---@param opts table
---@return table telescope finder
local function create_finder(state, opts)
  local mode = state:get_current()

  if mode == 'headlines' then
    -- Get all filters from state
    local filters = state:get_all_filters()
    local headline_opts = vim.tbl_extend('force', opts, filters)

    -- Load headlines with filters
    local results, widths = headlines_entry.get_entries(headline_opts)
    headline_opts.widths = widths

    return finders.new_table({
      results = results,
      entry_maker = opts.entry_maker or headlines_entry.make_entry(headline_opts),
    })
  else -- orgfiles
    return finders.new_table({
      results = orgfiles_entry.get_entries(opts),
      entry_maker = opts.entry_maker or orgfiles_entry.make_entry(),
    })
  end
end

---Update picker with new finder and title
---@param prompt_bufnr number
---@param finder table
---@param title string
local function update_picker(prompt_bufnr, finder, title)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker.prompt_border:change_title(title)
  current_picker:refresh(finder)
end

---Toggle between headlines and orgfiles mode
---@param state PickerState
---@param opts table
---@return function telescope action
local function toggle_mode_action(state, opts)
  return function(prompt_bufnr)
    -- Refresh function for keybindings library
    local function refresh(updated_state)
      local new_mode = updated_state:get_current()
      local new_finder = create_finder(updated_state, opts)
      local new_title = opts.prompt_titles[new_mode]
      update_picker(prompt_bufnr, new_finder, new_title)
    end

    -- Execute action using keybindings library
    keybindings.execute_action('toggle_mode', {
      state = state,
      opts = opts,
      refresh_fn = refresh,
    })
  end
end

---Toggle current file filter (headlines mode only)
---@param state PickerState
---@param opts table
---@return function telescope action
local function toggle_current_file_action(state, opts)
  return function(prompt_bufnr)
    -- Refresh function for keybindings library
    local function refresh(updated_state)
      local new_finder = create_finder(updated_state, opts)
      local title = opts.prompt_titles.headlines
      update_picker(prompt_bufnr, new_finder, title)
    end

    -- Execute action using keybindings library
    keybindings.execute_action('toggle_current_file', {
      state = state,
      opts = opts,
      refresh_fn = refresh,
    })
  end
end

---Open tag picker action
---@param opts table
---@return function telescope action
local function open_tag_picker_action(opts)
  return function(prompt_bufnr)
    -- Close function for keybindings library
    local function close_fn()
      actions.close(prompt_bufnr)
    end

    -- Execute action using keybindings library
    keybindings.execute_action('open_tag_picker', {
      opts = opts,
      close_fn = close_fn,
    })
  end
end

---Attach custom user mappings
---@param map function telescope map function
---@param opts table
local function attach_custom_mappings(map, opts)
  for mode, mappings in pairs(opts.mappings or {}) do
    for key, action in pairs(mappings) do
      map(mode, key, action)
    end
  end
end

---Attach common mappings for all pickers
---@param map function telescope map function
---@param state PickerState
---@param opts table
local function attach_common_mappings(map, state, opts)
  map('i', '<c-space>', toggle_mode_action(state, opts), { desc = 'Toggle headline/orgfile' })
  map('n', '<c-space>', toggle_mode_action(state, opts), { desc = 'Toggle headline/orgfile' })
  map('i', '<c-f>', toggle_current_file_action(state, opts), { desc = 'Toggle current file only' })
  map('n', '<c-f>', toggle_current_file_action(state, opts), { desc = 'Toggle current file only' })
  map('i', '<c-t>', open_tag_picker_action(opts), { desc = 'Open tag picker' })
  map('n', '<c-t>', open_tag_picker_action(opts), { desc = 'Open tag picker' })
  attach_custom_mappings(map, opts)
end

---Search headings picker
---@param user_opts table|nil
function M.search_headings(user_opts)
  -- Merge config
  local opts = config:new('search_headings', user_opts)

  -- Capture original buffer for current file filtering
  opts.original_buffer = vim.api.nvim_get_current_buf()
  opts.original_file = vim.api.nvim_buf_get_name(opts.original_buffer)

  -- Create state manager
  local state = PickerState:new(opts.mode or 'headlines', {
    only_current_file = opts.only_current_file or false,
    archived = opts.archived or false,
    max_depth = opts.max_depth,
  })

  -- Create initial finder
  local initial_finder = create_finder(state, opts)

  -- Create and launch picker
  pickers
    .new(opts, {
      prompt_title = opts.prompt_titles[state:get_current()],
      default_text = opts.default_text or '',
      finder = initial_finder,
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      layout_config = {
        width = 0.95,
        height = 0.95,
        preview_width = 0.4,
      },
      attach_mappings = function(_, map)
        attach_common_mappings(map, state, opts)
        return true
      end,
    })
    :find()
end

---Refile heading picker
---@param user_opts table|nil
function M.refile_heading(user_opts)
  -- Merge config
  local opts = config:new('refile_heading', user_opts)

  -- Capture original buffer
  opts.original_buffer = vim.api.nvim_get_current_buf()
  opts.original_file = vim.api.nvim_buf_get_name(opts.original_buffer)

  -- Get source headline
  local source_headline = org.get_closest_headline()

  if not source_headline then
    local filetype = vim.bo.filetype
    if filetype == 'org' then
      vim.notify('No headline found at cursor position in org file', vim.log.levels.WARN)
    else
      vim.notify(
        'No headline found at cursor position. Make sure cursor is on a valid agenda item or org headline.',
        vim.log.levels.WARN
      )
    end
    return
  end

  -- Create state manager
  local state = PickerState:new(opts.mode or 'headlines', {
    only_current_file = opts.only_current_file or false,
    archived = opts.archived or false,
    max_depth = opts.max_depth,
  })

  -- Create initial finder
  local initial_finder = create_finder(state, opts)

  -- Refile action
  local function refile_action(prompt_bufnr)
    local entry = action_state.get_selected_entry()

    -- Use lib_actions for refile workflow
    local success, message = lib_actions.execute_refile(source_headline, entry.value)

    vim.notify(message, success and vim.log.levels.INFO or vim.log.levels.WARN)

    if success then
      actions.close(prompt_bufnr)
    end
  end

  -- Create and launch picker
  pickers
    .new(opts, {
      prompt_title = opts.prompt_titles[state:get_current()],
      finder = initial_finder,
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      layout_config = {
        width = 0.95,
        height = 0.95,
        preview_width = 0.4,
      },
      attach_mappings = function(_, map)
        action_set.select:replace(refile_action)
        attach_common_mappings(map, state, opts)
        return true
      end,
    })
    :find()
end

---Insert link picker
---@param user_opts table|nil
function M.insert_link(user_opts)
  -- Merge config
  local opts = config:new('insert_link', user_opts)

  -- Capture original buffer
  opts.original_buffer = vim.api.nvim_get_current_buf()
  opts.original_file = vim.api.nvim_buf_get_name(opts.original_buffer)

  -- Create state manager
  local state = PickerState:new(opts.mode or 'headlines', {
    only_current_file = opts.only_current_file or false,
    archived = opts.archived or false,
    max_depth = opts.max_depth,
  })

  -- Create initial finder
  local initial_finder = create_finder(state, opts)

  -- Insert link action
  local function insert_action(prompt_bufnr)
    local entry = action_state.get_selected_entry()
    local entry_value = entry.value

    -- Close picker FIRST, then execute insert_link after focus returns to original buffer
    actions.close(prompt_bufnr)
    vim.schedule(function()
      local promise = lib_actions.execute_insert_link(entry_value)
      if not promise then
        vim.notify('Could not find link target', vim.log.levels.ERROR)
        return
      end

      -- Handle async result
      promise
        :next(function(result)
          if result then
            vim.notify('Link inserted successfully', vim.log.levels.INFO)
          else
            vim.notify('Link insertion cancelled', vim.log.levels.INFO)
          end
        end)
        :catch(function(err)
          vim.notify('Failed to insert link: ' .. tostring(err), vim.log.levels.ERROR)
        end)
    end)
  end

  -- Create and launch picker
  pickers
    .new(opts, {
      prompt_title = opts.prompt_titles[state:get_current()],
      finder = initial_finder,
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      layout_config = {
        width = 0.95,
        height = 0.95,
        preview_width = 0.4,
      },
      attach_mappings = function(_, map)
        action_set.select:replace(insert_action)
        attach_common_mappings(map, state, opts)
        return true
      end,
    })
    :find()
end

return M
