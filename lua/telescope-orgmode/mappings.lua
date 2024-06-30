local to_actions = require('telescope-orgmode.actions')

local M = {}

function M.attach_mappings(map, opts)
  map('i', '<C-Space>', to_actions.toggle_headlines_orgfiles(opts), { desc = 'Toggle headline/orgfile' })
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
