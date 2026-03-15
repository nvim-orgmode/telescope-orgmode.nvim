local OrgFile = require('orgmode.files.file')
local org = require('telescope-orgmode.org')
local highlights = require('telescope-orgmode.lib.highlights')
local headlines_entry_maker = require('telescope-orgmode.entry_maker.headlines')

-- Use [Section Name] format in describe() for grouped test output
-- See scripts/test-formatter.sh for formatting behavior
describe('[Entry Maker: Headlines]', function()
  ---@return OrgFile
  local load_file_sync = function(content, filename)
    content = content or {}
    filename = filename or vim.fn.tempname() .. '.org'
    vim.fn.writefile(content, filename)
    return OrgFile.load(filename):wait()
  end

  describe('width calculation', function()
    it('should calculate max widths from result set', function()
      local file = load_file_sync({
        '* TODO Short',
        '* PROGRESS LongerKeyword',
        '* [#A] Priority A',
        '* [#B] Priority B',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local results, widths = headlines_entry_maker.get_entries({})

      -- PROGRESS is 8 characters (longest TODO keyword in test)
      assert.are.same(8, widths.todo)

      -- [#A] and [#B] are both 4 characters
      assert.are.same(4, widths.priority)
    end)

    it('should handle empty result sets', function()
      local file = load_file_sync({
        '* Regular headline',
        '* Another regular headline',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local results, widths = headlines_entry_maker.get_entries({})

      -- No TODO keywords or priorities
      assert.are.same(0, widths.todo)
      assert.are.same(0, widths.priority)
    end)
  end)

  describe('highlight integration', function()
    it('should return correct highlight groups for TODO keywords', function()
      -- Test with orgmode not loaded (fallback behavior)
      local hl = highlights.get_todo_highlight('TODO', 'TODO')
      assert.are.same('@org.keyword.todo', hl)

      hl = highlights.get_todo_highlight('DONE', 'DONE')
      assert.are.same('@org.keyword.done', hl)

      hl = highlights.get_todo_highlight(nil, '')
      assert.is_nil(hl)
    end)

    it('should return correct highlight groups for priorities', function()
      -- Per-priority highlight groups
      local hl = highlights.get_priority_highlight('A')
      assert.are.same('@org.priority.highest', hl)

      hl = highlights.get_priority_highlight('B')
      assert.are.same('@org.priority.default', hl)

      hl = highlights.get_priority_highlight('C')
      assert.are.same('@org.priority.lowest', hl)

      hl = highlights.get_priority_highlight(nil)
      assert.is_nil(hl)
    end)
  end)

  describe('entry creation', function()
    it('should create entries with TODO and priority fields', function()
      local file = load_file_sync({
        '* TODO [#A] Important task',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local results, widths = headlines_entry_maker.get_entries({})
      local make_entry = headlines_entry_maker.make_entry({
        show_todo_state = true,
        show_priority = true,
        widths = widths,
      })

      local entry = make_entry(results[1])

      -- Entry should have TODO and priority data
      assert.are.same('TODO', entry.todo_value)
      assert.are.same('TODO', entry.todo_type)
      assert.are.same('A', entry.priority)

      -- Ordinal should include TODO and priority for searching
      assert.is_truthy(string.find(entry.ordinal, 'TODO'))
      assert.is_truthy(string.find(entry.ordinal, '%[#A%]'))
    end)

    it('should exclude TODO from ordinal when show_todo_state is false', function()
      local file = load_file_sync({
        '* TODO Important task',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local results, widths = headlines_entry_maker.get_entries({})
      local make_entry = headlines_entry_maker.make_entry({
        show_todo_state = false,
        show_priority = true,
        widths = widths,
      })

      local entry = make_entry(results[1])

      -- Ordinal should NOT include TODO when column is hidden
      assert.is_falsy(string.find(entry.ordinal, 'TODO'))
    end)

    it('should exclude priority from ordinal when show_priority is false', function()
      local file = load_file_sync({
        '* [#A] Important task',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local results, widths = headlines_entry_maker.get_entries({})
      local make_entry = headlines_entry_maker.make_entry({
        show_todo_state = true,
        show_priority = false,
        widths = widths,
      })

      local entry = make_entry(results[1])

      -- Ordinal should NOT include priority when column is hidden
      assert.is_falsy(string.find(entry.ordinal, '%[#A%]'))
    end)
  end)

  describe('column visibility', function()
    it('should default to showing all columns', function()
      local config = require('telescope-orgmode.lib.config')

      -- Defaults should be true for all columns
      assert.is_true(config.defaults.show_location)
      assert.is_true(config.defaults.show_tags)
      assert.is_true(config.defaults.show_todo_state)
      assert.is_true(config.defaults.show_priority)
    end)

    it('should respect user configuration overrides', function()
      local config = require('telescope-orgmode.lib.config')

      config.setup({
        show_location = false,
        show_tags = false,
        show_todo_state = false,
        show_priority = false,
      })

      assert.is_false(config.defaults.show_location)
      assert.is_false(config.defaults.show_tags)
      assert.is_false(config.defaults.show_todo_state)
      assert.is_false(config.defaults.show_priority)

      -- Restore defaults
      config.setup({
        show_location = true,
        show_tags = true,
        show_todo_state = true,
        show_priority = true,
      })
    end)

    it('should exclude location from ordinal when show_location is false', function()
      local file = load_file_sync({
        '* Test headline',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local results, widths = headlines_entry_maker.get_entries({})
      local make_entry = headlines_entry_maker.make_entry({
        show_location = false,
        show_tags = true,
        show_todo_state = true,
        show_priority = true,
        widths = widths,
      })

      local entry = make_entry(results[1])

      -- Ordinal should NOT include location pattern (filename:line) when column is hidden
      assert.is_falsy(string.find(entry.ordinal, '%.org:%d+'))
    end)

    it('should exclude tags from ordinal when show_tags is false', function()
      local file = load_file_sync({
        '* Test headline :work:urgent:',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local results, widths = headlines_entry_maker.get_entries({})
      local make_entry = headlines_entry_maker.make_entry({
        show_location = true,
        show_tags = false,
        show_todo_state = true,
        show_priority = true,
        widths = widths,
      })

      local entry = make_entry(results[1])

      -- Ordinal should NOT include tags when column is hidden
      assert.is_falsy(string.find(entry.ordinal, 'work'))
      assert.is_falsy(string.find(entry.ordinal, 'urgent'))
    end)
  end)

  describe('property width calculation', function()
    it('should calculate property widths from result set', function()
      local file = load_file_sync({
        '* Headline 1',
        ':PROPERTIES:',
        ':ID: abc-123',
        ':EFFORT: 2h',
        ':END:',
        '* Headline 2',
        ':PROPERTIES:',
        ':ID: xy',
        ':EFFORT: 30min',
        ':END:',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local show_properties = {
        { name = 'ID', max_width = 15 },
        { name = 'EFFORT', max_width = 10 },
      }

      local results, widths = headlines_entry_maker.get_entries({ show_properties = show_properties })

      -- ID: 'abc-123' (7 chars) > 'xy' (2 chars) → width = 7
      assert.equals(7, widths.properties.ID)
      -- EFFORT: '30min' (5 chars) > '2h' (2 chars) → width = 5
      assert.equals(5, widths.properties.EFFORT)
    end)

    it('should respect max_width cap', function()
      local file = load_file_sync({
        '* Headline',
        ':PROPERTIES:',
        ':ID: very-long-identifier-that-exceeds-cap',
        ':END:',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local show_properties = { { name = 'ID', max_width = 8 } }
      local _, widths = headlines_entry_maker.get_entries({ show_properties = show_properties })

      assert.equals(8, widths.properties.ID)
    end)

    it('should auto-hide property when all values are empty', function()
      local file = load_file_sync({
        '* Headline without properties',
        '* Another headline',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local show_properties = { { name = 'EFFORT' } }
      local _, widths = headlines_entry_maker.get_entries({ show_properties = show_properties })

      -- Empty properties → not in widths table
      assert.is_nil(widths.properties.EFFORT)
    end)

    it('should use default max_width of 15 when not specified', function()
      local file = load_file_sync({
        '* Headline',
        ':PROPERTIES:',
        ':ID: this-is-a-really-long-value-beyond-fifteen',
        ':END:',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local show_properties = { { name = 'ID' } } -- no max_width
      local _, widths = headlines_entry_maker.get_entries({ show_properties = show_properties })

      assert.equals(15, widths.properties.ID)
    end)
  end)

  describe('property in entry creation', function()
    it('should include property values in ordinal for fuzzy search', function()
      local file = load_file_sync({
        '* Task with properties',
        ':PROPERTIES:',
        ':ID: unique-abc',
        ':END:',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local show_properties = { { name = 'ID' } }
      local results, widths = headlines_entry_maker.get_entries({ show_properties = show_properties })
      local make_entry = headlines_entry_maker.make_entry({
        show_properties = show_properties,
        widths = widths,
      })

      local entry = make_entry(results[1])
      assert.is_truthy(string.find(entry.ordinal, 'unique%-abc'))
    end)

    it('should expose properties on entry object', function()
      local file = load_file_sync({
        '* Task',
        ':PROPERTIES:',
        ':EFFORT: 2h',
        ':END:',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local show_properties = { { name = 'EFFORT' } }
      local results, widths = headlines_entry_maker.get_entries({ show_properties = show_properties })
      local make_entry = headlines_entry_maker.make_entry({
        show_properties = show_properties,
        widths = widths,
      })

      local entry = make_entry(results[1])
      assert.equals('2h', entry.properties.EFFORT)
    end)

    it('should exclude property from ordinal when show_properties is nil', function()
      local file = load_file_sync({
        '* Task',
        ':PROPERTIES:',
        ':ID: secret-id',
        ':END:',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local results, widths = headlines_entry_maker.get_entries({})
      local make_entry = headlines_entry_maker.make_entry({ widths = widths })

      local entry = make_entry(results[1])
      assert.is_falsy(string.find(entry.ordinal, 'secret%-id'))
    end)
  end)

  describe('width calculation for location and tags', function()
    it('should calculate max width for location column', function()
      local file = load_file_sync({
        '* First headline',
        '* Second headline',
        '* Third headline',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local results, widths = headlines_entry_maker.get_entries({})

      -- Width should be calculated from actual location strings
      assert.is_truthy(widths.location > 0)
    end)

    it('should calculate max width for tags column', function()
      local file = load_file_sync({
        '* Short :tag:',
        '* Longer :tag:with:multiple:',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local results, widths = headlines_entry_maker.get_entries({})

      -- Width should be based on longest tag string
      assert.is_truthy(widths.tags > 0)
      assert.is_truthy(widths.tags >= vim.fn.strdisplaywidth('tag:with:multiple'))
    end)

    it('should handle headlines without tags', function()
      local file = load_file_sync({
        '* No tags here',
        '* Also no tags',
      })

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local results, widths = headlines_entry_maker.get_entries({})

      -- Tags width should be 0 when no tags present
      assert.are.same(0, widths.tags)
    end)
  end)

  describe('property performance', function()
    it('should process 500 headlines × 2 properties under 500ms', function()
      -- Generate 500 headlines with property drawers
      local lines = {}
      for i = 1, 500 do
        table.insert(lines, string.format('* Headline %d', i))
        table.insert(lines, ':PROPERTIES:')
        table.insert(lines, string.format(':ID: item-%04d', i))
        table.insert(lines, string.format(':EFFORT: %dh', (i % 8) + 1))
        table.insert(lines, ':END:')
      end

      local file = load_file_sync(lines)

      package.loaded['orgmode'] = {
        files = {
          all = function()
            return { file }
          end,
        },
      }

      local show_properties = {
        { name = 'ID', max_width = 12 },
        { name = 'EFFORT', max_width = 6 },
      }

      -- Measure: load + index with properties
      local start = vim.uv.hrtime()
      local results, widths = headlines_entry_maker.get_entries({ show_properties = show_properties })
      local elapsed_ms = (vim.uv.hrtime() - start) / 1e6

      -- Verify correctness
      assert.equals(500, #results)
      assert.is_truthy(widths.properties.ID)
      assert.is_truthy(widths.properties.EFFORT)

      -- Performance gate: must be under 500ms (includes orgmode file parsing overhead)
      assert.is_truthy(
        elapsed_ms < 500,
        string.format('500 headlines × 2 properties took %.1fms (limit: 500ms)', elapsed_ms)
      )

      -- Log actual timing for documentation
      print(string.format('\n  [perf] 500 headlines × 2 properties: %.1fms', elapsed_ms))
    end)
  end)
end)
