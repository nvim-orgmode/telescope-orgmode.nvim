local OrgFile = require('orgmode.files.file')
local operations = require('telescope-orgmode.lib.operations')
local org_module = require('telescope-orgmode.org')

describe('[Integration: lib/operations]', function()
  -- Test helpers for cleaner, more maintainable tests
  local helpers = {}

  ---Load org file and return OrgFile object
  ---@param content string[] File lines
  ---@param filename? string Optional filename (generates temp if not provided)
  ---@return OrgFile
  function helpers.load_file_sync(content, filename)
    filename = filename or vim.fn.tempname() .. '.org'
    vim.fn.writefile(content, filename)
    return OrgFile.load(filename):wait()
  end

  ---Setup orgmode with test files
  ---@param files OrgFile[] Files to make available to orgmode
  function helpers.setup_orgmode_mock(files)
    package.loaded['orgmode'] = {
      files = {
        all = function()
          return files
        end,
      },
      api = {
        current = function()
          return {
            get_closest_headline = function()
              if #files > 0 and files[1].headlines and #files[1].headlines > 0 then
                return files[1].headlines[1]
              end
              return nil
            end,
          }
        end,
      },
    }
  end

  ---Create test files with source and destination headlines
  ---@return { source_file: OrgFile, dest_file: OrgFile, source_headline: table, dest_headline: table }
  function helpers.create_refile_scenario()
    local source_file = helpers.load_file_sync({
      '* Source Headline',
      '  Content to refile',
      '* Another Headline',
    })

    local dest_file = helpers.load_file_sync({
      '* Destination Parent',
      '** Existing Child',
    })

    helpers.setup_orgmode_mock({ source_file, dest_file })

    local source_headline = org_module.get_api_headline(source_file.filename, 1)
    local dest_headline = org_module.get_api_headline(dest_file.filename, 1)

    return {
      source_file = source_file,
      dest_file = dest_file,
      source_headline = source_headline,
      dest_headline = dest_headline,
    }
  end

  ---Assert that headline has proper OrgApiHeadline structure
  ---@param headline table The headline to validate
  function helpers.assert_api_headline_structure(headline)
    assert.is_table(headline, 'Should have headline')
    assert.is_table(headline._section, 'Should have _section (internal object)')
    assert.is_table(headline._section.file, 'Should have _section.file (OrgFile)')
    assert.is_function(headline._section.file.update, 'Should have file:update() method')
  end

  describe('refile', function()
    it('should work with real OrgApiHeadline objects', function()
      -- Setup: Create refile scenario with real orgmode objects
      local scenario = helpers.create_refile_scenario()

      -- Validate structure
      helpers.assert_api_headline_structure(scenario.source_headline)
      assert.is_not_nil(scenario.dest_headline, 'Should have destination headline')

      -- CRITICAL TEST: Exercise real refile flow with file:update() callback
      -- EXPECTED: This FAILS with buggy code (get_range() error in callback)
      -- EXPECTED: This PASSES after fix (proper internal object usage)
      local result = operations.refile(scenario.source_headline, scenario.dest_headline)

      -- If we get here without error, the fix worked!
      assert.is_not_nil(result, 'Refile should return result')
    end)

    it('should use internal object in callback for correct method access', function()
      -- Setup
      local source_file = helpers.load_file_sync({
        '* TODO Test Headline',
        '** Subheadline',
      })

      helpers.setup_orgmode_mock({ source_file })

      local source_headline = org_module.get_api_headline(source_file.filename, 1)
      helpers.assert_api_headline_structure(source_headline)

      -- THE FIX: Use internal object (_section) in callback
      -- Internal object has methods that work in file:update() context
      local internal_headline = source_headline._section
      assert.is_not_nil(internal_headline, 'Should have internal headline')
      assert.is_function(internal_headline.get_range, 'Internal object should have :get_range()')

      -- Verify internal object's get_range() works in callback context
      local callback_executed = false
      local callback_error = nil

      local success, err = pcall(function()
        internal_headline.file
          :update(function()
            callback_executed = true
            -- Internal object's methods work correctly in callback
            local range_in_callback = internal_headline:get_range()
            assert.is_not_nil(range_in_callback, 'get_range() should work in callback')
            assert.is_number(range_in_callback.start_line, 'Should have start_line')
          end)
          :wait()
      end)

      assert.is_true(callback_executed, 'Callback should have executed')
      assert.is_true(success, 'Should not have error with internal object: ' .. tostring(err))
      assert.is_nil(callback_error, 'Should not have error in callback')
    end)

    it('should return nil for invalid headline', function()
      -- Test error handling - doesn't need real orgmode setup
      local result = operations.refile(nil, nil)
      assert.is_nil(result, 'Should return nil for nil source')

      -- Test with object missing _section
      local invalid_headline = { filename = 'test.org' }
      result = operations.refile(invalid_headline, nil)
      assert.is_nil(result, 'Should return nil for headline missing _section')
    end)
  end)

  describe('insert_link', function()
    it('should call get_link() on OrgApiHeadline objects', function()
      -- Setup
      local file = helpers.load_file_sync({
        '* Headline One',
        '* Headline Two',
      })

      helpers.setup_orgmode_mock({ file })

      -- Get real API headline
      local headline = org_module.get_api_headline(file.filename, 1)
      assert.is_not_nil(headline, 'Failed to get headline')

      -- Verify get_link() returns a string (not nil or object)
      local link = headline:get_link()
      assert.is_string(link, 'get_link() should return a string')
      assert.is_not_nil(link:match('^file:'), 'Link should start with file: protocol')
    end)

    it('should call get_link() on OrgApiFile objects', function()
      local file = helpers.load_file_sync({ '* Content' })
      helpers.setup_orgmode_mock({ file })

      -- Get real API file
      local api_file = org_module.get_api_file(file.filename)
      assert.is_not_nil(api_file, 'Failed to get API file')

      -- Verify get_link() returns a string
      local link = api_file:get_link()
      assert.is_string(link, 'get_link() should return a string')
      assert.is_not_nil(link:match('^file:'), 'Link should start with file: protocol')
    end)
  end)

  describe('navigate_to', function()
    it('should navigate to real org file headline', function()
      local file = helpers.load_file_sync({
        '* Test Headline',
        '  Some content',
      })

      local entry = {
        filename = file.filename,
        lnum = 1,
      }

      -- Navigate
      local result = operations.navigate_to(entry)
      assert.is_true(result, 'Should successfully navigate')

      -- Verify location
      local current_file = vim.fn.expand('%:p')
      assert.are.equal(file.filename, current_file, 'Should be in correct file')

      local cursor = vim.api.nvim_win_get_cursor(0)
      assert.are.equal(1, cursor[1], 'Cursor should be at line 1')
    end)

    it('should work with OrgApiHeadline format', function()
      local file = helpers.load_file_sync({ '* Headline' })
      helpers.setup_orgmode_mock({ file })

      local headline = org_module.get_api_headline(file.filename, 1)
      assert.is_not_nil(headline)

      -- Navigate using API headline format
      local result = operations.navigate_to(headline)
      assert.is_true(result, 'Should navigate with OrgApiHeadline')

      local current_file = vim.fn.expand('%:p')
      assert.are.equal(file.filename, current_file)
    end)
  end)
end)
