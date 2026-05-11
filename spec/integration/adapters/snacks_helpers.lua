-- Mock harness for Snacks adapter tests. Captures the picker_opts
-- the adapter passes to `require('snacks').picker(opts)`.

local M = {}

---Install a fake `snacks` module. Returns the capture array (one
---entry per picker call).
---@return table captured
function M.setup_snacks_mock()
  local captured = {}
  package.preload['snacks'] = function()
    return {
      picker = function(opts)
        table.insert(captured, opts)
        return {
          close = function() end,
          current = function() end,
        }
      end,
    }
  end
  package.loaded['snacks'] = nil
  return captured
end

function M.teardown()
  package.loaded['snacks'] = nil
  package.preload['snacks'] = nil
end

---Deep-snapshot the mutable config state. `setup()` mutates both
---`picker_defaults` and `defaults`, so both must be restored.
---@param config table
---@return table snapshot
function M.snapshot_config(config)
  return {
    picker_defaults = vim.deepcopy(config.picker_defaults),
    defaults = vim.deepcopy(config.defaults),
  }
end

---@param config table
---@param snapshot table
function M.restore_config(config, snapshot)
  config.picker_defaults = snapshot.picker_defaults
  config.defaults = snapshot.defaults
end

return M
