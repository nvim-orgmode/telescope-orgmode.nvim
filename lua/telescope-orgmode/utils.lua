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
---@field title? string

---@param file_results { file: OrgApiFile, filename: string }[]
---@return OrgEntry[]
local function index_headlines(file_results, opts)
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
          title = nil,
        }
        table.insert(results, entry)
      end
    end
  end

  return results
end

---@param file_results { file: OrgApiFile, filename: string }[]
---@return OrgEntry[]
local function index_orgfiles(file_results, opts)
  local results = {}
  for _, file_entry in ipairs(file_results) do
    local entry = {
      file = file_entry.file,
      filename = file_entry.filename,
      -- not beautiful to access a private property, but this is the only way to get the title
      ---@diagnostic disable-next-line: invisible, undefined-field
      title = file_entry.file._file:get_directive('TITLE') or nil,
      headline = nil,
    }
    table.insert(results, entry)
  end
  return results
end

---Fetches entrys from OrgApi and extracts the relevant information
---@param opts any
---@return OrgEntry[]
utils.get_entries = function(opts)
  ---@type { file: OrgApiFile, filename: string, last_used: number }[]
  local file_results = vim.tbl_map(function(file)
    local file_stat = vim.loop.fs_stat(file.filename) or 0
    return { file = file, filename = file.filename, last_used = file_stat.mtime.sec }
  end, orgmode.load())

  if not opts.archived then
    file_results = vim.tbl_filter(function(entry)
      return not entry.file.is_archive_file
    end, file_results)
  end

  -- sorting does not work with the fuzzy sorters
  table.sort(file_results, function(a, b)
    return a.last_used > b.last_used
  end)

  if opts.state and opts.state.current and opts.state.current.max_depth == 0 then
    return index_orgfiles(file_results, opts)
  end

  return index_headlines(file_results, opts)
end

---Entry-Maker for Telescope
---@param opts any
---@return fun(entry: OrgEntry):MatchEntry
utils.make_entry = function(opts)
  local orgfile_displayer = entry_display.create({
    separator = ' ',
    items = {
      { remaining = true },
    },
  })

  local headline_displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = vim.F.if_nil(opts.location_width, 20) },
      { remaining = true },
    },
  })

  ---@param entry MatchEntry
  local function make_display(entry)
    if opts.state and opts.state.current and opts.state.current.max_depth == 0 then
      return orgfile_displayer({ entry.line })
    else
      return headline_displayer({ entry.location, entry.tags .. ' ' .. entry.line })
    end
  end

  return function(entry)
    local lnum = nil
    local location = vim.fn.fnamemodify(entry.filename, ':t')
    local line = entry.title or location
    local tags = ''
    local ordinal = line

    local headline = entry.headline
    if headline then
      lnum = headline.position.start_line
      location = string.format('%s:%i', location, lnum)
      line = string.format('%s %s', string.rep('*', headline.level), headline.title)
      ordinal = tags .. ' ' .. line .. ' ' .. location
      tags = table.concat(headline.all_tags, ':')
    end

    return {
      value = entry,
      ordinal = ordinal,
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

    -- FIXME: the state get's sometimes nil when the initalization has already been run
    -- In this case, a toggle is "dropped" (keypress does not change the state).
    -- Can we avoid that by initializing the state in the higher order function?
    -- Idea: We can try to do it as before, but pass the prompt_bufnr with the opts.
    if status._ot_state == nil then
      -- uninitialized state - initialize with orgfiles
      -- Because when this function is called the first time, it is triggered
      -- by the users and we search over headlines by default, we set the state
      -- for the first toggle already here.
      -- _ot_ is used as our plugin-specific namespace in the action status
      -- (ot - orgmode telescope)
      status._ot_state = { current = opts.state.orgfiles, next = opts.state.headlines }
    else
      -- initalized state - swap to next state
      status._ot_state.current, status._ot_state.next = status._ot_state.next, status._ot_state.current
    end

    -- opts is used as a channel to communicate the depth state to the get_entries function
    opts.state.current = status._ot_state.current

    -- the caller may not have defined a prompt title - then we don't adjust it
    if opts.state.current.prompt_title then
      current_picker.layout.prompt.border:change_title(status._ot_state.current.prompt_title)
    end

    local new_finder = finders.new_table({
      results = utils.get_entries(opts),
      entry_maker = opts.entry_maker or utils.make_entry(opts),
    })

    current_picker:refresh(new_finder, opts)
  end
end

return utils
