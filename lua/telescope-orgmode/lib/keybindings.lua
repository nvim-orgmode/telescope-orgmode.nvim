local M = {}

---Keybinding definitions (semantic, not implementation)
---Each binding defines what action does, not how it's implemented in specific framework
M.bindings = {
  toggle_mode = {
    description = 'Toggle between headlines and orgfiles mode',
    default_key = '<C-Space>',
  },
  toggle_current_file = {
    description = 'Toggle filter: current file only',
    default_key = '<C-f>',
  },
  open_tag_picker = {
    description = 'Open tag selection picker',
    default_key = '<C-t>',
  },
  confirm = {
    description = 'Select entry and execute default action',
    default_key = '<CR>',
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

    require('telescope-orgmode.picker.search_tags').search_tags({
      default_text = selected_tag,
      context = context.opts.context,
    })
  end
end

return M
