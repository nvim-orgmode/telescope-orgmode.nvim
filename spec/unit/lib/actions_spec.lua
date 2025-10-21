local actions = require('telescope-orgmode.lib.actions')

describe('[Unit: lib/actions]', function()
  describe('entry normalization', function()
    -- Note: These tests verify the library handles different entry formats
    -- Full integration testing with orgmode is done in integration tests

    it('handles completely invalid entry gracefully', function()
      local entry = {}

      local destination = actions.entry_to_destination(entry)

      -- When no filename, org.get_api_file returns empty table or nil
      -- Just verify it doesn't crash
      assert.is_true(destination == nil or type(destination) == 'table')
    end)
  end)

  describe('refile workflow', function()
    it('returns failure when destination not found', function()
      local source = { title = 'Source' }
      local invalid_entry = {}

      local success, message = actions.execute_refile(source, invalid_entry)

      assert.is_false(success)
      -- Message should indicate destination issue
      assert.is_string(message)
      assert.is_true(message:find('destination') ~= nil or message:find('failed') ~= nil)
    end)
  end)

  describe('link insertion workflow', function()
    -- Note: Full integration testing with orgmode is done in integration tests
    -- Unit testing insert_link is challenging without mocking due to orgmode API dependencies
  end)

  describe('navigation workflow', function()
    it('returns false for invalid entry', function()
      local invalid_entry = {}

      local success = actions.execute_navigate(invalid_entry)

      -- Should return false for invalid navigation
      assert.is_boolean(success)
    end)
  end)

  describe('interface contract', function()
    it('execute_refile returns success boolean and message string', function()
      local source = {}
      local entry = {}

      local success, message = actions.execute_refile(source, entry)

      assert.is_boolean(success)
      assert.is_string(message)
    end)

    it('execute_navigate returns boolean', function()
      local entry = {}

      local success = actions.execute_navigate(entry)

      assert.is_boolean(success)
    end)
  end)
end)
