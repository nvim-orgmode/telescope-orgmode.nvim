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

---Create picker state from opts
---Centralizes state initialization logic to avoid duplication
---@param opts table User options with mode, filters, etc.
---@return PickerState
local function create_state(opts)
  return PickerState:new(opts.mode or 'headlines', {
    only_current_file = opts.only_current_file or false,
    current_file = opts.original_file,
    archived = opts.archived or false,
    max_depth = opts.max_depth,
    tag_query = opts.tag_query,
  })
end

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
  local state = create_state(opts)

  -- Create initial finder
  local initial_finder = create_finder(state, opts)

  -- Build title with filter context
  local base_title = opts.prompt_titles[state:get_current()]
  local context = state:get_title_context()
  local full_title = context ~= '' and (base_title .. ' ' .. context) or base_title

  -- Create and launch picker
  pickers
    .new(opts, {
      prompt_title = full_title,
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
  local state = create_state(opts)

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

  -- Build title with filter context
  local base_title = opts.prompt_titles[state:get_current()]
  local context = state:get_title_context()
  local full_title = context ~= '' and (base_title .. ' ' .. context) or base_title

  -- Create and launch picker
  pickers
    .new(opts, {
      prompt_title = full_title,
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
  local state = create_state(opts)

  -- Create initial finder
  local initial_finder = create_finder(state, opts)

  -- Insert link action
  local function insert_action(prompt_bufnr)
    local entry = action_state.get_selected_entry()

    -- Use lib_actions for insert link workflow
    local success, message = lib_actions.execute_insert_link(entry.value)

    vim.notify(message, success and vim.log.levels.INFO or vim.log.levels.ERROR)

    if success then
      actions.close(prompt_bufnr)
    end
  end

  -- Build title with filter context
  local base_title = opts.prompt_titles[state:get_current()]
  local context = state:get_title_context()
  local full_title = context ~= '' and (base_title .. ' ' .. context) or base_title

  -- Create and launch picker
  pickers
    .new(opts, {
      prompt_title = full_title,
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

---Tags search picker
---@param user_opts table|nil
function M.search_tags(user_opts)
  local tags_lib = require('telescope-orgmode.lib.tags')

  -- Merge config
  local opts = config:new('search_tags', user_opts)

  -- Load and sort tags
  local tags, sort_mode = tags_lib.load_and_sort_tags(opts)

  if #tags == 0 then
    vim.notify('No tags found in org files', vim.log.levels.INFO)
    return
  end

  -- Create tag previewer
  local function create_tag_previewer()
    return require('telescope.previewers').new_buffer_previewer({
      title = 'Headlines with Tag',
      define_preview = function(self, entry)
        local tag = entry.value.tag
        local lines = tags_lib.get_tag_preview_lines(tag, { max_count = 50 })
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      end,
    })
  end

  -- Create entry maker for tag items
  local function make_tag_entry(tag_info)
    return {
      value = tag_info,
      display = tags_lib.format_tag_display(tag_info),
      ordinal = tag_info.tag,
    }
  end

  -- Create and launch picker
  pickers
    .new(opts, {
      prompt_title = opts.prompt_title,
      default_text = opts.default_text,
      finder = finders.new_table({
        results = tags,
        entry_maker = make_tag_entry,
      }),
      sorter = conf.generic_sorter(opts),
      previewer = create_tag_previewer(),
      layout_config = {
        width = 0.95,
        height = 0.95,
        preview_width = 0.4,
      },
      attach_mappings = function(prompt_bufnr, map)
        -- Toggle sort mode
        local toggle_sort_binding = keybindings.bindings.toggle_tag_sort
        local function toggle_sort()
          local current_picker = action_state.get_current_picker(prompt_bufnr)
          sort_mode = tags_lib.toggle_sort_mode(sort_mode)
          tags = tags_lib.sort_tags(tags, sort_mode)

          current_picker:refresh(
            finders.new_table({
              results = tags,
              entry_maker = make_tag_entry,
            }),
            { reset_prompt = false }
          )

          vim.notify(string.format('Sort: %s', sort_mode), vim.log.levels.INFO)
        end

        for mode, key in pairs(toggle_sort_binding.modes) do
          map(mode, key, toggle_sort, { desc = toggle_sort_binding.description })
        end

        -- Return to headlines picker
        local return_binding = keybindings.bindings.return_to_headlines
        local function return_to_headlines()
          actions.close(prompt_bufnr)
          M.search_headings({
            default_text = '',
            context = opts.context,
          })
        end

        for mode, key in pairs(return_binding.modes) do
          map(mode, key, return_to_headlines, { desc = return_binding.description })
        end

        -- Select tag -> filter headlines by tag
        action_set.select:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if not selection then
            vim.notify('No tag selected', vim.log.levels.WARN)
            return
          end

          local tag = selection.value.tag

          -- Navigate to headlines filtered by tag
          M.search_headings({
            tag_query = '+' .. tag,
            default_text = '',
            context = {
              selected_tag = tag,
            },
          })
        end)

        return true
      end,
    })
    :find()
end

return M
