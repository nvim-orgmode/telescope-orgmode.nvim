-- Unit tests for tags_lib.get_tag_preview_lines. Verifies rendering of
-- the headline schema (todo_value / priority may be nil and must not
-- break the line layout).

local tags_lib = require('telescope-orgmode.lib.tags')
local org = require('telescope-orgmode.org')

describe('[Unit: lib/tags get_tag_preview_lines]', function()
  local original_get_headlines_for_tag

  before_each(function()
    original_get_headlines_for_tag = org.get_headlines_for_tag
  end)

  after_each(function()
    org.get_headlines_for_tag = original_get_headlines_for_tag
  end)

  it('renders new Headline-Schema entries (todo_value + priority)', function()
    org.get_headlines_for_tag = function()
      return {
        {
          filename = '/tmp/work.org',
          title = 'Important task',
          level = 1,
          line_number = 3,
          all_tags = { 'work' },
          is_archived = false,
          todo_value = 'TODO',
          todo_type = 'TODO',
          priority = 'A',
          properties = {},
        },
        {
          filename = '/tmp/work.org',
          title = 'Plain headline',
          level = 1,
          line_number = 7,
          all_tags = { 'work' },
          is_archived = false,
          todo_value = nil,
          todo_type = '',
          priority = nil,
          properties = {},
        },
      }
    end

    local lines = tags_lib.get_tag_preview_lines('work', {})

    -- First headline: TODO + [#A] priority + title
    assert.equals('TODO A Important task', lines[1])
    assert.equals('  → ' .. vim.fn.fnamemodify('/tmp/work.org', ':~:.'), lines[2])
    assert.equals('', lines[3])

    -- Second headline: no TODO or priority, so empty fields before the title
    assert.equals('  Plain headline', lines[4])
    assert.equals('  → ' .. vim.fn.fnamemodify('/tmp/work.org', ':~:.'), lines[5])
    assert.equals('', lines[6])
  end)

  it('returns placeholder when no headlines match', function()
    org.get_headlines_for_tag = function()
      return {}
    end

    local lines = tags_lib.get_tag_preview_lines('missing', {})
    assert.same({ 'No headlines found with this tag' }, lines)
  end)
end)
