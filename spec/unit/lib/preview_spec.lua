local preview = require('telescope-orgmode.lib.preview')

describe('[Unit: lib/preview]', function()
  describe('get_preview_config', function()
    it('should return headline preview config with line number', function()
      local entry = {
        filename = '/path/to/file.org',
        headline = {
          line_number = 42,
        },
      }

      local config = preview.get_preview_config(entry)

      assert.are.equal('/path/to/file.org', config.file)
      assert.are.equal(42, config.line)
      assert.are.equal(0, config.col)
    end)

    it('should return headline preview config with lnum fallback', function()
      local entry = {
        filename = '/path/to/file.org',
        headline = {
          lnum = 15,
        },
      }

      local config = preview.get_preview_config(entry)

      assert.are.equal('/path/to/file.org', config.file)
      assert.are.equal(15, config.line)
      assert.are.equal(0, config.col)
    end)

    it('should return file preview config when no headline', function()
      local entry = {
        filename = '/path/to/file.org',
      }

      local config = preview.get_preview_config(entry)

      assert.are.equal('/path/to/file.org', config.file)
      assert.are.equal(1, config.line)
      assert.are.equal(0, config.col)
    end)

    it('should handle Telescope entry structure (entry.value)', function()
      local entry = {
        value = {
          filename = '/path/to/telescope.org',
          headline = {
            line_number = 100,
          },
        },
      }

      local config = preview.get_preview_config(entry)

      assert.are.equal('/path/to/telescope.org', config.file)
      assert.are.equal(100, config.line)
      assert.are.equal(0, config.col)
    end)

    it('should handle Snacks entry structure (entry.__entry)', function()
      local entry = {
        __entry = {
          filename = '/path/to/snacks.org',
          headline = {
            line_number = 200,
          },
        },
      }

      local config = preview.get_preview_config(entry)

      assert.are.equal('/path/to/snacks.org', config.file)
      assert.are.equal(200, config.line)
      assert.are.equal(0, config.col)
    end)

    it('should handle entry with value.headline structure', function()
      local entry = {
        value = {
          filename = '/value/file.org',
          headline = {
            line_number = 50,
          },
        },
      }

      local config = preview.get_preview_config(entry)

      -- Should use entry.value data structure
      assert.are.equal('/value/file.org', config.file)
      assert.are.equal(50, config.line)
      assert.are.equal(0, config.col)
    end)
  end)
end)
