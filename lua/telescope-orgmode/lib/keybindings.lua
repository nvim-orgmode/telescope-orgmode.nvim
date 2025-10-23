local M = {}

---Keybinding definitions (semantic, not implementation)
---Each binding defines what action does, not how it's implemented in specific framework
---Modes: 'i' = insert mode, 'n' = normal mode
M.bindings = {
  toggle_mode = {
    description = 'Toggle between headlines and orgfiles mode',
    modes = { i = '<C-Space>', n = '<C-Space>' },
  },
  toggle_current_file = {
    description = 'Toggle filter: current file only',
    modes = { i = '<C-f>', n = '<C-f>' },
  },
  open_tag_picker = {
    description = 'Open tag selection picker',
    modes = { i = '<C-t>', n = '<C-t>' },
  },
  confirm = {
    description = 'Select entry and execute default action',
    modes = { i = '<CR>', n = '<CR>' },
  },
  toggle_tag_sort = {
    description = 'Toggle tag sort mode (frequency/alphabetical)',
    modes = { i = '<C-s>', n = '<C-s>' },
  },
  return_to_headlines = {
    description = 'Return to headlines picker from tags',
    modes = { i = '<C-t>', n = '<C-t>' },
  },
  filter_current_buffer = {
    description = 'Filter to current buffer',
    modes = { i = '<C-f><C-b>', n = '<C-f><C-b>' },
  },
  filter_all_buffers = {
    description = 'Filter to all open buffers',
    modes = { i = '<C-f><C-a>', n = '<C-f><C-a>' },
  },
  filter_headline_file = {
    description = 'Filter to selected headline file',
    modes = { i = '<C-f><C-h>', n = '<C-f><C-h>' },
  },
  drop_filters = {
    description = 'Clear all filters',
    modes = { i = '<C-f><C-d>', n = '<C-f><C-d>' },
  },
}

---Execute keybinding action (framework-agnostic logic)
---@param action_name string Name from M.bindings
---@param context table {state, opts, refresh_fn}
function M.execute_action(action_name, context)
  if action_name == 'toggle_mode' then
    context.state:toggle()
    context.refresh_fn(context.state)
  elseif action_name == 'toggle_current_file' then
    -- Only works in headlines mode
    if context.state:get_current() ~= 'headlines' then
      return
    end

    local current = context.state:get_filter('only_current_file')
    context.state:set_filter('only_current_file', not current)
    context.refresh_fn(context.state)
  elseif action_name == 'open_tag_picker' then
    -- Close current picker before opening tag picker
    if context.close_fn then
      context.close_fn()
    end

    -- Pre-fill search with previously selected tag
    local selected_tag = context.opts.context and context.opts.context.selected_tag or ''

    require('telescope-orgmode').search_tags({
      default_text = selected_tag,
      context = context.opts.context,
    })
  elseif action_name == 'filter_current_buffer' then
    local current_file = context.opts.current_file
    context.state:set_filter('current_files', { current_file })
    context.refresh_fn(context.state)
  elseif action_name == 'filter_all_buffers' then
    local filters = require('telescope-orgmode.lib.filters')
    local open_buffers = filters.get_open_buffers()
    context.state:set_filter('current_files', open_buffers)
    context.refresh_fn(context.state)
  elseif action_name == 'filter_headline_file' then
    if context.state:get_current() ~= 'headlines' then
      return
    end
    if not context.selected_entry then
      return
    end

    local headline_file = context.selected_entry.filename
    context.state:set_filter('current_files', { headline_file })
    context.refresh_fn(context.state)
  elseif action_name == 'drop_filters' then
    context.state:set_filter('tag_query', nil)
    context.state:set_filter('current_files', {})
    context.state:set_filter('only_current_file', nil)
    context.refresh_fn(context.state)
  end
end

return M
