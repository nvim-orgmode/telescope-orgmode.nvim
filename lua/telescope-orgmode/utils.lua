require('telescope-orgmode.typehints')

local entry_display = require('telescope.pickers.entry_display')
local finders = require('telescope.finders')
local action_state = require('telescope.actions.state')
local state = require('telescope.state')

local orgmode = require('orgmode.api')

local utils = {}

---@class OrgEntry
---@field file OrgApiFile
---@field filename string
---@field headline? OrgApiHeadline

---Fetches entrys from OrgApi and extracts the relevant information
---@param opts any
---@return OrgEntry[]
utils.get_entries = function(opts)
  ---@type { file: OrgApiFile, filename: string }[]
  local file_results = vim.tbl_map(function(file)
    return { file = file, filename = file.filename }
  end, orgmode.load())

  if not opts.archived then
    file_results = vim.tbl_filter(function(entry)
      return not entry.file.is_archive_file
    end, file_results)
  end

  if opts.max_depth == 0 then
    return file_results
  end

  local results = {}
  for _, file_entry in ipairs(file_results) do
    for _, headline in ipairs(file_entry.file.headlines) do
      local allowed_depth = opts.max_depth == nil or headline.level <= opts.max_depth
      local allowed_archive = opts.archived or not headline.is_archived
      if allowed_depth and allowed_archive then
        local entry = {
          file = file_entry.file,
          filename = file_entry.filename,
          headline = headline,
        }
        table.insert(results, entry)
      end
    end
  end

  return results
end

---Entry-Maker for Telescope
---@param opts any
---@return fun(entry: OrgEntry):MatchEntry
utils.make_entry = function(opts)
  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = vim.F.if_nil(opts.location_width, 20) },
      { remaining = true },
      --{ width = vim.F.if_nil(opts.tag_width, 20) },
    },
  })

  ---@param entry MatchEntry
  local function make_display(entry)
    return displayer({ entry.location, entry.tags .. ' ' .. entry.line })
  end

  return function(entry)
    local headline = entry.headline

    local lnum = nil
    local location = vim.fn.fnamemodify(entry.filename, ':t')
    local line = ''
    local tags = ''

    if headline then
      lnum = headline.position.start_line
      location = string.format('%s:%i', location, lnum)
      line = string.format('%s %s', string.rep('*', headline.level), headline.title)
      tags = table.concat(headline.all_tags, ':')
    end

    return {
      value = entry,
      ordinal = location .. ' ' .. tags .. ' ' .. line,
      filename = entry.filename,
      lnum = lnum,
      display = make_display,
      location = location,
      line = line,
      tags = tags,
    }
  end
end

utils.gen_depth_toggle = function(opts)
  return function(prompt_bufnr)
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    local status = state.get_status(prompt_bufnr)

    if status._ot_current_depth == nil and status._ot_next_depth == nil then
      -- uninitialized state - initialize with "show files only"
      -- Because when this function is called the first time, it is triggered
      -- by the users and we search over headings by default, we set the state
      -- for the first toggle already here.
      status._ot_current_depth = 0
      status._ot_next_depth = opts.max_depth
    else
      -- initalized state - swap to next state
      status._ot_current_depth, status._ot_next_depth = status._ot_next_depth, status._ot_current_depth
    end

    -- opts is used as a channel to communicate the depth state to the get_entries function
    opts.max_depth = status._ot_current_depth
    local new_finder = finders.new_table({
      results = utils.get_entries(opts),
      entry_maker = opts.entry_maker or utils.make_entry(opts),
    })

    current_picker:refresh(new_finder, opts)
  end
end

return utils
