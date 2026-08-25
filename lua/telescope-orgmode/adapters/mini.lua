local mini_pick = require('mini.pick')

-- Are sideeffects or a require in Lua bad pratice?
-- Should i instead wrap the module with a table, and then have a register_pickers function?
require('telescope-orgmode.mini.register_pickers')

local M = {}

---@param user_opts table|nil
function M.search_headings(user_opts)
  mini_pick.registry.orgmode_headings(user_opts)
end

---@param user_opts table|nil
function M.refile_heading(user_opts)
  mini_pick.registry.orgmode_refile_header(user_opts)
end

---@param user_opts table|nil
function M.insert_link(user_opts)
  mini_pick.registry.orgmode_insert_link(user_opts)
end

---@param user_opts table|nil
function M.search_tags(user_opts)
  mini_pick.registry.orgmode_search_tags(user_opts)
end

return M
