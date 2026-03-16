local highlights = require('telescope-orgmode.lib.highlights')

describe('[Unit: lib/highlights]', function()
  describe('TODO keyword highlights', function()
    it('returns correct highlight for TODO', function()
      assert.equals('@org.keyword.todo', highlights.get_todo_highlight('TODO', 'TODO'))
    end)

    it('returns correct highlight for DONE', function()
      assert.equals('@org.keyword.done', highlights.get_todo_highlight('DONE', 'DONE'))
    end)

    it('returns default highlight for custom TODO keyword', function()
      -- Custom keywords without orgmode loaded fall back to type-based default
      assert.equals('@org.keyword.todo', highlights.get_todo_highlight('WAITING', 'TODO'))
    end)

    it('returns nil for nil input', function()
      assert.is_nil(highlights.get_todo_highlight(nil, nil))
    end)
  end)

  describe('headline level highlights', function()
    it('returns correct highlight for level 1', function()
      assert.equals('@org.headline.level1', highlights.get_level_highlight(1))
    end)

    it('cycles through levels 1-8', function()
      assert.equals('@org.headline.level1', highlights.get_level_highlight(9))
      assert.equals('@org.headline.level2', highlights.get_level_highlight(10))
    end)

    it('handles various levels correctly', function()
      for i = 1, 8 do
        local expected = '@org.headline.level' .. i
        assert.equals(expected, highlights.get_level_highlight(i))
      end
    end)
  end)

  describe('priority highlights', function()
    it('returns per-priority highlight groups', function()
      assert.equals('@org.priority.highest', highlights.get_priority_highlight('A'))
      assert.equals('@org.priority.default', highlights.get_priority_highlight('B'))
      assert.equals('@org.priority.lowest', highlights.get_priority_highlight('C'))
    end)

    it('returns default for unknown priority letter', function()
      assert.equals('@org.priority.default', highlights.get_priority_highlight('D'))
    end)

    it('returns nil for nil priority', function()
      assert.is_nil(highlights.get_priority_highlight(nil))
    end)
  end)

  describe('text padding utility', function()
    it('pads short strings with spaces', function()
      assert.equals('test    ', highlights.pad('test', 8))
    end)

    it('returns string unchanged if exact width', function()
      assert.equals('test', highlights.pad('test', 4))
    end)

    it('truncates long strings with ellipsis', function()
      local result = highlights.pad('verylongstring', 8)
      assert.equals(8, vim.fn.strdisplaywidth(result))
      assert.is_true(result:find('…') ~= nil)
    end)
  end)

  describe('headline segment generation', function()
    it('returns segments array and plain text', function()
      local headline = {
        title = 'Test Headline',
        level = 1,
        todo_value = nil,
        priority = nil,
        all_tags = {},
        line_number = 10,
      }

      local opts = {
        show_location = false,
        show_tags = false,
        show_todo_state = false,
        show_priority = false,
        widths = {},
      }

      local segments, text = highlights.get_headline_segments(headline, 'test.org', opts)

      assert.is_table(segments)
      assert.is_string(text)
      assert.is_true(#segments > 0)
    end)

    it('includes all requested components', function()
      local headline = {
        title = 'Test',
        level = 1,
        todo_value = 'TODO',
        todo_type = 'TODO',
        priority = 'A',
        all_tags = { 'tag1' },
        line_number = 10,
      }

      local opts = {
        show_location = true,
        show_tags = true,
        show_todo_state = true,
        show_priority = true,
        widths = { location = 15, tags = 10, todo = 6, priority = 5 },
      }

      local segments, text = highlights.get_headline_segments(headline, 'test.org', opts)

      -- Verify we have multiple segments for different components
      assert.is_true(#segments >= 4) -- location, tags, todo, priority, title
      assert.is_true(text:find('Test') ~= nil)
    end)
  end)

  describe('property segment generation', function()
    local function make_headline(overrides)
      return vim.tbl_extend('force', {
        title = 'Test',
        level = 1,
        todo_value = nil,
        priority = nil,
        all_tags = {},
        line_number = 1,
        properties = {},
      }, overrides or {})
    end

    local function base_opts(overrides)
      return vim.tbl_extend('force', {
        show_location = false,
        show_tags = false,
        show_todo_state = false,
        show_priority = false,
        widths = {},
      }, overrides or {})
    end

    it('generates property segments with correct values', function()
      local headline = make_headline({ properties = { ID = 'abc-123', EFFORT = '2h' } })
      local opts = base_opts({
        show_properties = {
          { name = 'ID', max_width = 10 },
          { name = 'EFFORT', max_width = 6 },
        },
        widths = { properties = { ID = 10, EFFORT = 6 } },
      })

      local segments, text = highlights.get_headline_segments(headline, 'test.org', opts)

      -- title segment + 2 property segments = 3
      assert.equals(3, #segments)
      -- Property values should be in segments
      assert.is_truthy(segments[1][1]:find('abc%-123'))
      assert.is_truthy(segments[2][1]:find('2h'))
      -- Property values should be in searchable text
      assert.is_truthy(text:find('abc%-123'))
      assert.is_truthy(text:find('2h'))
    end)

    it('uses custom highlight group when specified', function()
      local headline = make_headline({ properties = { EFFORT = '30min' } })
      local opts = base_opts({
        show_properties = { { name = 'EFFORT', highlight = 'Number' } },
        widths = { properties = { EFFORT = 8 } },
      })

      local segments, _ = highlights.get_headline_segments(headline, 'test.org', opts)

      -- segments[1] = property, segments[2] = title
      assert.equals('Number', segments[1][2])
    end)

    it('uses Comment as default highlight', function()
      local headline = make_headline({ properties = { ID = 'x' } })
      local opts = base_opts({
        show_properties = { { name = 'ID' } },
        widths = { properties = { ID = 5 } },
      })

      local segments, _ = highlights.get_headline_segments(headline, 'test.org', opts)
      assert.equals('Comment', segments[1][2])
    end)

    it('auto-hides property column when width is 0', function()
      local headline = make_headline({ properties = { ID = '' } })
      local opts = base_opts({
        show_properties = { { name = 'ID' } },
        widths = { properties = {} }, -- ID not in widths = auto-hidden
      })

      local segments, _ = highlights.get_headline_segments(headline, 'test.org', opts)

      -- Only title segment
      assert.equals(1, #segments)
    end)

    it('inserts blank space for empty property value when column is visible', function()
      local headline = make_headline({ properties = { ID = '' } })
      local opts = base_opts({
        show_properties = { { name = 'ID' } },
        widths = { properties = { ID = 8 } },
      })

      local segments, text = highlights.get_headline_segments(headline, 'test.org', opts)

      -- Blank spacer segment + title = 2
      assert.equals(2, #segments)
      -- Spacer has no highlight (single-element table)
      assert.is_nil(segments[1][2])
      -- Only title in search text (no property value added)
      assert.equals('* Test', text)
    end)

    it('truncates long property values with ellipsis', function()
      local headline = make_headline({ properties = { ID = 'very-long-identifier-value' } })
      local opts = base_opts({
        show_properties = { { name = 'ID', max_width = 8 } },
        widths = { properties = { ID = 8 } },
      })

      local segments, _ = highlights.get_headline_segments(headline, 'test.org', opts)

      -- Property segment text should be truncated to width + 1 space
      local prop_text = segments[1][1]
      -- The padded text (without trailing space) should be exactly 8 chars wide
      local trimmed = prop_text:sub(1, -2) -- remove trailing space
      assert.equals(8, vim.fn.strdisplaywidth(trimmed))
      assert.is_truthy(trimmed:find('…'))
    end)

    it('uses ordinal_fields order for plain text when configured', function()
      local headline = make_headline({
        todo_value = 'TODO',
        todo_type = 'TODO',
        all_tags = { 'work' },
        line_number = 5,
      })
      local opts = base_opts({
        show_location = true,
        show_tags = true,
        show_todo_state = true,
        show_priority = false,
        ordinal_fields = { 'state', 'headline', 'tags' },
        widths = { location = 10, tags = 6, todo = 6 },
      })

      local segments, text = highlights.get_headline_segments(headline, 'test.org', opts)

      -- Plain text should follow ordinal_fields order: state, headline, tags
      assert.equals('TODO * Test work', text)
      -- Segments (display) should still be in visual order (unchanged)
      assert.is_true(#segments >= 3)
    end)

    it('excludes fields from plain text not listed in ordinal_fields', function()
      local headline = make_headline({
        todo_value = 'TODO',
        todo_type = 'TODO',
        all_tags = { 'work' },
        line_number = 5,
      })
      local opts = base_opts({
        show_location = true,
        show_tags = true,
        show_todo_state = true,
        ordinal_fields = { 'headline' },
        widths = { location = 10, tags = 6, todo = 6 },
      })

      local _, text = highlights.get_headline_segments(headline, 'test.org', opts)

      -- Only headline in text
      assert.equals('* Test', text)
    end)

    it('uses default field order when ordinal_fields is nil', function()
      local headline = make_headline({
        todo_value = 'TODO',
        todo_type = 'TODO',
        all_tags = { 'work' },
        line_number = 5,
      })
      local opts = base_opts({
        show_location = true,
        show_tags = true,
        show_todo_state = true,
        widths = { location = 10, tags = 6, todo = 6 },
      })

      local _, text = highlights.get_headline_segments(headline, 'test.org', opts)

      -- Default: all visible fields in text (state, headline, location, tags)
      assert.is_truthy(text:find('TODO'))
      assert.is_truthy(text:find('Test'))
      assert.is_truthy(text:find('work'))
      assert.is_truthy(text:find('test%.org'))
    end)

    it('places properties between location and tags', function()
      local headline = make_headline({
        all_tags = { 'work' },
        properties = { ID = 'test-id' },
      })
      local opts = base_opts({
        show_location = true,
        show_tags = true,
        show_properties = { { name = 'ID' } },
        widths = { location = 10, tags = 6, properties = { ID = 8 } },
      })

      local segments, _ = highlights.get_headline_segments(headline, 'test.org', opts)

      -- Order: location, property, tags, title
      assert.equals(4, #segments)
      assert.equals('Comment', segments[1][2]) -- location
      assert.equals('Comment', segments[2][2]) -- property (default hl)
      assert.equals('@org.tag', segments[3][2]) -- tags
    end)
  end)
end)
