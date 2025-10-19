local to_actions = require('telescope-orgmode.actions')

local M = {}

function M.attach_mappings(map, opts)
  map('i', '<c-space>', to_actions.toggle_headlines_orgfiles(opts), { desc = 'Toggle headline/orgfile' })
  map('n', '<c-space>', to_actions.toggle_headlines_orgfiles(opts), { desc = 'Toggle headline/orgfile' })
  map('i', '<c-f>', to_actions.toggle_current_file_only(opts), { desc = 'Toggle current file only' })
  map('n', '<c-f>', to_actions.toggle_current_file_only(opts), { desc = 'Toggle current file only' })
  map('i', '<c-t>', to_actions.open_tag_picker(opts), { desc = 'Open tag picker' })
  map('n', '<c-t>', to_actions.open_tag_picker(opts), { desc = 'Open tag picker' })
  M.attach_custom(map, opts)
end

function M.attach_custom(map, opts)
  for mode, mappings in pairs(opts.mappings or {}) do
    for key, action in pairs(mappings) do
      map(mode, key, action)
    end
  end
end

return M
