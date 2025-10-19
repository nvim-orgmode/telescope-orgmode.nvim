local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local tag_collection = require('telescope-orgmode.tag_collection')

local M = {}

--- Previewer shows context of what headlines will be filtered when tag is selected
---@param opts { initial_sort?: 'frequency'|'alphabetical', context?: table }
---@return function
local function create_tag_previewer(opts)
  return require('telescope.previewers').new_buffer_previewer({
    title = 'Headlines with Tag',
    define_preview = function(self, entry)
      local tag = entry.value.tag
      local lines = {}

      local orgmode = require('orgmode')
      local Search = require('orgmode.files.elements.search')
      local search = Search:new('+' .. tag)

      local count = 0
      local MAX_PREVIEW = 50

      for _, file in ipairs(orgmode.files:all()) do
        if count >= MAX_PREVIEW then
          break
        end

        for _, headline in ipairs(file:apply_search(search, false)) do
          if count >= MAX_PREVIEW then
            break
          end

          local todo = headline:get_todo() or ''
          local priority = headline:get_priority() or ''
          local title = headline:get_title()
          local file_short = vim.fn.fnamemodify(file.filename, ':~:.')

          local line = string.format('%s %s %s', todo, priority, title)
          table.insert(lines, line)
          table.insert(lines, '  → ' .. file_short)
          table.insert(lines, '')

          count = count + 1
        end
      end

      if #lines == 0 then
        lines = { 'No headlines found with this tag' }
      elseif count >= MAX_PREVIEW then
        table.insert(lines, string.format('... (showing first %d headlines)', MAX_PREVIEW))
      end

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
    end,
  })
end

---@param opts? { initial_sort?: 'frequency'|'alphabetical', default_text?: string, context?: { selected_tag?: string } }
function M.search_tags(opts)
  opts = opts or {}
  local sort_mode = opts.initial_sort or 'frequency'

  local tags = tag_collection.benchmark('Tag collection', function()
    return tag_collection.collect_tags_with_counts()
  end)

  tags = tag_collection.sort_tags(tags, sort_mode)

  if #tags == 0 then
    vim.notify('No tags found in org files', vim.log.levels.INFO)
    return
  end

  pickers
    .new(opts, {
      prompt_title = 'Org Tags (Press <C-s> to toggle sort)',
      default_text = opts.default_text,
      finder = finders.new_table({
        results = tags,
        entry_maker = function(tag_info)
          return {
            value = tag_info,
            display = string.format('%s (%d)', tag_info.tag, tag_info.count),
            ordinal = tag_info.tag,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      previewer = create_tag_previewer(opts),
      attach_mappings = function(prompt_bufnr, map)
        local toggle_sort = function()
          local current_picker = action_state.get_current_picker(prompt_bufnr)
          sort_mode = (sort_mode == 'frequency') and 'alphabetical' or 'frequency'

          tags = tag_collection.sort_tags(tags, sort_mode)
          current_picker:refresh(
            finders.new_table({
              results = tags,
              entry_maker = function(tag_info)
                return {
                  value = tag_info,
                  display = string.format('%s (%d)', tag_info.tag, tag_info.count),
                  ordinal = tag_info.tag,
                }
              end,
            }),
            { reset_prompt = false }
          )

          vim.notify(string.format('Sort: %s', sort_mode), vim.log.levels.INFO)
        end

        map('i', '<C-s>', toggle_sort, { desc = 'Toggle sort mode' })
        map('n', '<C-s>', toggle_sort, { desc = 'Toggle sort mode' })

        --- Supports bidirectional navigation between tag and headline pickers
        local return_to_headlines = function()
          actions.close(prompt_bufnr)

          require('telescope-orgmode.picker.search_headings')({
            default_text = '',
            context = opts.context,
          })
        end

        map('i', '<C-t>', return_to_headlines, { desc = 'Return to headline search' })
        map('n', '<C-t>', return_to_headlines, { desc = 'Return to headline search' })

        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if not selection then
            vim.notify('No tag selected', vim.log.levels.WARN)
            return
          end

          local tag = selection.value.tag

          --- Pass tag as search query AND context to enable round-trip navigation
          require('telescope-orgmode.picker.search_headings')({
            tag_query = '+' .. tag,
            default_text = '',
            context = {
              selected_tag = tag,
            },
          })
        end)

        return true
      end,
    })
    :find()
end

return M
