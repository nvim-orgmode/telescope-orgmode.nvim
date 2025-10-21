local highlights = require('telescope-orgmode.lib.highlights')

describe('[Unit: lib/highlights]', function()
  describe('TODO keyword highlights', function()
    it('returns correct highlight for TODO', function()
      assert.equals('@org.keyword.todo', highlights.get_todo_highlight('TODO'))
    end)

    it('returns correct highlight for DONE', function()
      assert.equals('@org.keyword.done', highlights.get_todo_highlight('DONE'))
    end)

    it('returns nil for unknown TODO type', function()
      assert.is_nil(highlights.get_todo_highlight('UNKNOWN'))
    end)

    it('returns nil for nil input', function()
      assert.is_nil(highlights.get_todo_highlight(nil))
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
    it('returns highlight group for any priority', function()
      assert.equals('@org.priority', highlights.get_priority_highlight('A'))
      assert.equals('@org.priority', highlights.get_priority_highlight('B'))
      assert.equals('@org.priority', highlights.get_priority_highlight('C'))
    end)

    it('returns Normal for nil priority', function()
      assert.equals('Normal', highlights.get_priority_highlight(nil))
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
end)
