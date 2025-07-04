local finders = require('telescope-orgmode.finders')
local org = require('telescope-orgmode.org')

local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local M = {}

function M.toggle_headlines_orgfiles(opts)
  return function(prompt_bufnr)
    opts.state.current, opts.state.next = opts.state.next, opts.state.current

    if opts.state.current == 'headlines' then
      M._find_headlines(opts, prompt_bufnr)
    elseif opts.state.current == 'orgfiles' then
      M._find_orgfiles(opts, prompt_bufnr)
    else
      -- this should not happen
      error(string.format('Invalid state %s', opts.state.current))
    end
  end
end

function M.search_headlines(opts)
  return function(prompt_bufnr)
    M._find_headlines(opts, prompt_bufnr)
  end
end

function M.search_orgfiles(opts)
  return function(prompt_bufnr)
    M._find_orgfiles(opts, prompt_bufnr)
  end
end

function M.toggle_current_file_only(opts)
  return function(prompt_bufnr)
    -- Only toggle if we're in headlines mode
    if opts.state.current ~= 'headlines' then
      return
    end

    opts.only_current_file = not opts.only_current_file
    M._find_headlines(opts, prompt_bufnr)
  end
end

function M.refile(closest_headline)
  return function(prompt_bufnr)
    local entry = action_state.get_selected_entry()
    actions.close(prompt_bufnr)

    local destination = entry.value.headline
      and org.get_api_headline(entry.filename, entry.value.headline.line_number)
      or org.get_api_file(entry.filename)

    if not destination then
      error('Could not find destination headline or file')
    end

    return org.refile({
      source = closest_headline,
      destination = destination,
    })
  end
end

function M.insert(_)
  return function(prompt_bufnr)
    actions.close(prompt_bufnr)

    ---@type MatchEntry
    local entry = action_state.get_selected_entry()

    local api_object = entry.value.headline
      and org.get_api_headline(entry.filename, entry.value.headline.line_number)
      or org.get_api_file(entry.filename)
    
    if not api_object then
      error('Could not find ' .. (entry.value.headline and 'headline' or 'file') .. ' for link')
    end
    
    local destination = api_object:get_link()

    org.insert_link(destination)
    return true
  end
end

function M._find_headlines(opts, prompt_bufnr)
  local headlines = finders.headlines(opts)
  M._update_picker(headlines, opts.prompt_titles.headlines, prompt_bufnr)
end

function M._find_orgfiles(opts, prompt_bufnr)
  local orgfiles = finders.orgfiles(opts)
  M._update_picker(orgfiles, opts.prompt_titles.orgfiles, prompt_bufnr)
end

function M._update_picker(finder, title, prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)

  current_picker.layout.prompt.border:change_title(title)
  current_picker:refresh(finder)
end

return M
