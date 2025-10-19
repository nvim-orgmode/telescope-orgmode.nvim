---@class TagInfo
---@field tag string Tag name
---@field count number Number of occurrences
---@field files string[] Files containing this tag

local M = {}

--- Collect all tags with occurrence counts from orgmode files
--- Excludes archived files
---@return TagInfo[]
function M.collect_tags_with_counts()
  local tag_info = {} -- { [tag] = { count, files_set } }
  local orgmode = require('orgmode')

  for _, orgfile in ipairs(orgmode.files:all()) do
    if not orgfile:is_archive_file() then
      local filename = orgfile.filename

      -- Count tags from headlines (includes inherited tags if enabled)
      for _, headline in ipairs(orgfile:get_headlines()) do
        for _, tag in ipairs(headline:get_tags()) do
          if not tag_info[tag] then
            tag_info[tag] = { count = 0, files = {} }
          end
          tag_info[tag].count = tag_info[tag].count + 1
          tag_info[tag].files[filename] = true
        end
      end
    end
  end

  -- Convert to array and add file lists
  local result = {}
  for tag, info in pairs(tag_info) do
    table.insert(result, {
      tag = tag,
      count = info.count,
      files = vim.tbl_keys(info.files),
    })
  end

  return result
end

--- Sort tags by frequency or alphabetically
---@param tags TagInfo[]
---@param sort_by 'frequency' | 'alphabetical'
---@return TagInfo[]
function M.sort_tags(tags, sort_by)
  if sort_by == 'frequency' then
    table.sort(tags, function(a, b)
      if a.count == b.count then
        return a.tag < b.tag -- Alphabetical tiebreaker
      end
      return a.count > b.count -- Descending frequency
    end)
  else -- alphabetical
    table.sort(tags, function(a, b)
      return a.tag < b.tag
    end)
  end
  return tags
end

--- Benchmark a function execution
---@param name string Operation name
---@param fn function Function to benchmark
---@return any result Result from function
function M.benchmark(name, fn)
  local start = vim.loop.hrtime()
  local result = fn()
  local duration = (vim.loop.hrtime() - start) / 1e6 -- Convert to ms
  vim.notify(string.format('%s: %.2fms', name, duration), vim.log.levels.DEBUG)
  return result
end

return M
