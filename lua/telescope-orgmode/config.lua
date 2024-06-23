local M = {}

M.opts = {
  max_depth = nil,
}

function M.setup(ext_opts)
  M.opts = vim.tbl_extend('force', M.opts, ext_opts or {})
end

return M
