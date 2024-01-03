local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local action_set = require("telescope.actions.set")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local state = require("telescope.state")

local utils = require('telescope-orgmode.utils')

local orgmode = require('orgmode')
local Files = require('orgmode.parser.files')
local Capture = require('orgmode.capture')
local Range = require('orgmode.parser.range')

return function(opts)
  opts = opts or {}

  -- TODO: this should be included in return from Files.get_current_file
  local is_capture = vim.F.npcall(vim.api.nvim_buf_get_var, 0, 'org_capture')

  local src_file = Files.get_current_file()
  -- In capture, refile top level heading even if cursor closer to a subheading
  local src_item = is_capture and src_file:get_headlines()[1] or src_file:get_closest_headline()
  local src_lines = src_file:get_headline_lines(src_item)

  local function refile(prompt_bufnr)
    local entry = action_state.get_selected_entry()
    actions.close(prompt_bufnr)

    local dst_file = entry.value.file
    local dst_headline = entry.value.headline
    if dst_headline then
      -- NOTE: adapted from Capture:refile_to_headline
      if src_item and src_item.level <= dst_headline.level then
        -- Refiling in same file just moves the lines from one position
        -- to another,so we need to apply demote instantly
        local is_same_file = dst_file.filename == src_item.root.filename
        src_lines = src_item:demote(dst_headline.level - src_item.level + 1, true, not is_same_file)
      end
      refile_opts = {
        file = dst_file.filename,
        lines = src_lines,
        item = src_item,
        range = Range.from_line(dst_headline.position.end_line),
        headline = dst_headline.title,
      }
      local refiled = Capture:_refile_to(refile_opts)
      if not refiled then
        return false
      end
    else
      Capture:_refile_to_end(dst_file.filename, src_lines, src_item)
    end

    if is_capture then
      orgmode.action('capture.kill')
    end
  end

  local function gen_depth_toggle(opts, prompt_bufnr)

    local status = state.get_status(prompt_bufnr)
    status._ot_current_depth = opts.max_depth
    status._ot_next_depth = nil
    if status._ot_current_depth ~= 0 then
      status._ot_next_depth = 0
    end

    return function()
      local current_picker = action_state.get_current_picker(prompt_bufnr)

      local aux = status._ot_current_depth
      status._ot_current_depth = status._ot_next_depth
      status._ot_next_depth = aux

      opts.max_depth = status._ot_current_depth
      local new_finder = finders.new_table {
        results = utils.get_entries(opts),
        entry_maker = opts.entry_maker or utils.make_entry(opts),
      }

      current_picker:refresh(new_finder, opts)
    end
  end

  pickers.new(opts, {
     -- TODO: alter prompt title when depth is 0: Refile under file, Refile
     -- under Headline
    prompt_title = "Refile Destination",
    finder = finders.new_table {
      results = utils.get_entries(opts),
      entry_maker = opts.entry_maker or utils.make_entry(opts),
    },
    sorter = conf.generic_sorter(opts),
    previewer = conf.grep_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      action_set.select:replace(refile)
      map("i", "<c-space>", gen_depth_toggle(opts, prompt_bufnr))
      return true
    end,
  }):find()
end
