local operations = require('telescope-orgmode.lib.operations')

describe('[Unit: lib/operations]', function()
  describe('get_current_headline', function()
    it('returns nil or table', function()
      local result = operations.get_current_headline()
      -- Should return nil or a table without crashing
      assert.is_true(result == nil or type(result) == 'table')
    end)
  end)

  describe('navigate_to', function()
    it('returns true for valid entry', function()
      -- Create a temporary file for testing
      local tmpfile = vim.fn.tempname() .. '.org'
      vim.fn.writefile({ '* Test Headline' }, tmpfile)

      local entry = { filename = tmpfile, lnum = 1 }
      local result = operations.navigate_to(entry)
      assert.is_true(result)

      -- Clean up
      vim.fn.delete(tmpfile)
    end)

    it('handles entry without lnum', function()
      local tmpfile = vim.fn.tempname() .. '.org'
      vim.fn.writefile({ '* Test Headline' }, tmpfile)

      local entry = { filename = tmpfile }
      local result = operations.navigate_to(entry)
      assert.is_true(result)

      -- Clean up
      vim.fn.delete(tmpfile)
    end)
  end)

  describe('refile', function()
    it('returns nil when source headline is nil', function()
      -- Mock get_current_headline to return nil
      local original = operations.get_current_headline
      operations.get_current_headline = function()
        return nil
      end

      local result = operations.refile({}, {})
      assert.is_nil(result)

      -- Restore
      operations.get_current_headline = original
    end)
  end)

  describe('insert_link', function()
    it('returns nil when destination is nil', function()
      local result = operations.insert_link(nil)
      assert.is_nil(result)
    end)

    it('returns nil when destination has no get_link method', function()
      local invalid_destination = { filename = '/some/file.org' }
      local result = operations.insert_link(invalid_destination)
      assert.is_nil(result)
    end)
  end)
end)
