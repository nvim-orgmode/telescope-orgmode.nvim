local entry_display = require('telescope.pickers.entry_display')

local orgmode = require('orgmode.api')

local utils = {}

utils.get_entries = function(opts)
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

utils.make_entry = function(opts)
  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = vim.F.if_nil(opts.location_width, 20) },
      { remaining = true },
    },
  })

  local function make_display(entry)
    return displayer({ entry.location, entry.line })
  end

  return function(entry)
    local headline = entry.headline

    local lnum = nil
    local location = vim.fn.fnamemodify(entry.filename, ':t')
    local line = ''

    if headline then
      lnum = headline.position.start_line
      location = string.format('%s:%i', location, lnum)
      line = string.format('%s %s', string.rep('*', headline.level), headline.title)
    end

    return {
      value = entry,
      ordinal = location .. ' ' .. line,
      filename = entry.filename,
      lnum = lnum,
      display = make_display,
      location = location,
      line = line,
    }
  end
end

return utils
