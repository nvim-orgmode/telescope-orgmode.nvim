-- E2E Tests: Telescope Adapter
-- Smoke tests for Telescope adapter - verify pickers don't crash

local e2e_helpers = require('spec.helpers.e2e_helpers')

describe('[E2E: Telescope Adapter]', function()
  local telescope_orgmode = require('telescope-orgmode')

  before_each(function()
    e2e_helpers.create_test_org_files()
    e2e_helpers.setup_orgmode_with_test_files()
  end)

  after_each(function()
    e2e_helpers.cleanup_test_org_files()
    -- Clean up any open pickers
    pcall(function()
      local picker = e2e_helpers.get_current_picker_telescope()
      if picker then
        e2e_helpers.close_picker_telescope(picker)
      end
    end)
  end)

  describe('picker creation smoke tests', function()
    it('should create search_headings picker without crashing', function()
      local ok = pcall(telescope_orgmode.search_headings, { adapter = 'telescope' })
      assert.is_true(ok, 'search_headings should not crash')

      -- Clean up
      pcall(function()
        local picker = e2e_helpers.get_current_picker_telescope()
        if picker then
          e2e_helpers.close_picker_telescope(picker)
        end
      end)
    end)

    it('should create refile_heading picker without crashing', function()
      local ok = pcall(telescope_orgmode.refile_heading, { adapter = 'telescope' })
      assert.is_true(ok, 'refile_heading should not crash')

      pcall(function()
        local picker = e2e_helpers.get_current_picker_telescope()
        if picker then
          e2e_helpers.close_picker_telescope(picker)
        end
      end)
    end)

    it('should create insert_link picker without crashing', function()
      vim.cmd('new')

      local ok = pcall(telescope_orgmode.insert_link, { adapter = 'telescope' })
      assert.is_true(ok, 'insert_link should not crash')

      pcall(function()
        local picker = e2e_helpers.get_current_picker_telescope()
        if picker then
          e2e_helpers.close_picker_telescope(picker)
        end
      end)

      vim.cmd('bdelete!')
    end)
  end)

  describe('configuration options', function()
    it('should handle filtering options without crashing', function()
      local ok = pcall(telescope_orgmode.search_headings, {
        adapter = 'telescope',
        only_current_file = true,
      })
      assert.is_true(ok, 'Should handle filter options')

      pcall(function()
        local picker = e2e_helpers.get_current_picker_telescope()
        if picker then
          e2e_helpers.close_picker_telescope(picker)
        end
      end)
    end)

    it('should handle tag queries without crashing', function()
      local ok = pcall(telescope_orgmode.search_headings, {
        adapter = 'telescope',
        tag_query = 'tag1',
      })
      assert.is_true(ok, 'Should handle tag queries')

      pcall(function()
        local picker = e2e_helpers.get_current_picker_telescope()
        if picker then
          e2e_helpers.close_picker_telescope(picker)
        end
      end)
    end)

    it('should handle invalid options gracefully', function()
      local ok = pcall(telescope_orgmode.search_headings, {
        adapter = 'telescope',
        invalid_option = 'should_be_ignored',
      })
      assert.is_true(ok, 'Should ignore invalid options')

      pcall(function()
        local picker = e2e_helpers.get_current_picker_telescope()
        if picker then
          e2e_helpers.close_picker_telescope(picker)
        end
      end)
    end)
  end)
end)
