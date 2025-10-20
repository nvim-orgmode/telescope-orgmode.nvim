-- E2E Tests: Snacks Adapter
-- Smoke tests for Snacks adapter - verify pickers don't crash
-- Skipped when snacks.nvim is not installed (e.g. CI / vendor-only setup)

local has_snacks = pcall(require, 'snacks')
if not has_snacks then
  return
end

local e2e_helpers = require('spec.helpers.e2e_helpers')

describe('[E2E: Snacks Adapter]', function()
  local telescope_orgmode = require('telescope-orgmode')

  before_each(function()
    e2e_helpers.create_test_org_files()
    e2e_helpers.setup_orgmode_with_test_files()
  end)

  after_each(function()
    e2e_helpers.cleanup_test_org_files()
    -- Clean up any open pickers
    pcall(function()
      local picker = e2e_helpers.get_current_picker_snacks()
      if picker then
        e2e_helpers.close_picker_snacks(picker)
      end
    end)
  end)

  describe('picker creation smoke tests', function()
    it('should create search_headings picker without crashing', function()
      local ok = pcall(telescope_orgmode.search_headings, { adapter = 'snacks' })
      assert.is_true(ok, 'search_headings should not crash')

      -- Clean up
      pcall(function()
        local picker = e2e_helpers.get_current_picker_snacks()
        if picker then
          e2e_helpers.close_picker_snacks(picker)
        end
      end)
    end)

    it('should create refile_heading picker without crashing', function()
      local ok = pcall(telescope_orgmode.refile_heading, { adapter = 'snacks' })
      assert.is_true(ok, 'refile_heading should not crash')

      pcall(function()
        local picker = e2e_helpers.get_current_picker_snacks()
        if picker then
          e2e_helpers.close_picker_snacks(picker)
        end
      end)
    end)

    it('should create insert_link picker without crashing', function()
      vim.cmd('new')

      local ok = pcall(telescope_orgmode.insert_link, { adapter = 'snacks' })
      assert.is_true(ok, 'insert_link should not crash')

      pcall(function()
        local picker = e2e_helpers.get_current_picker_snacks()
        if picker then
          e2e_helpers.close_picker_snacks(picker)
        end
      end)

      vim.cmd('bdelete!')
    end)
  end)

  describe('nil entry handling', function()
    local actions = require('telescope-orgmode.lib.actions')

    it('should not crash when navigate receives nil entry', function()
      local ok, err = pcall(actions.execute_navigate, nil)
      assert.is_true(ok, 'execute_navigate(nil) should not crash: ' .. tostring(err))
    end)

    it('should not crash when insert_link receives nil entry', function()
      local ok, err = pcall(actions.execute_insert_link, nil)
      assert.is_true(ok, 'execute_insert_link(nil) should not crash: ' .. tostring(err))
    end)

    it('should not crash when refile receives nil entries', function()
      local ok, err = pcall(actions.execute_refile, nil, nil)
      assert.is_true(ok, 'execute_refile(nil, nil) should not crash: ' .. tostring(err))
    end)

    it('should return false/nil for nil entries', function()
      assert.is_false(actions.execute_navigate(nil))
      assert.is_nil(actions.execute_insert_link(nil))
      local success, _ = actions.execute_refile(nil, nil)
      assert.is_false(success)
    end)
  end)

  describe('configuration options', function()
    it('should handle filtering options without crashing', function()
      local ok = pcall(telescope_orgmode.search_headings, {
        adapter = 'snacks',
        only_current_file = true,
      })
      assert.is_true(ok, 'Should handle filter options')

      pcall(function()
        local picker = e2e_helpers.get_current_picker_snacks()
        if picker then
          e2e_helpers.close_picker_snacks(picker)
        end
      end)
    end)

    it('should handle tag queries without crashing', function()
      local ok = pcall(telescope_orgmode.search_headings, {
        adapter = 'snacks',
        tag_query = 'tag1',
      })
      assert.is_true(ok, 'Should handle tag queries')

      pcall(function()
        local picker = e2e_helpers.get_current_picker_snacks()
        if picker then
          e2e_helpers.close_picker_snacks(picker)
        end
      end)
    end)

    it('should handle invalid options gracefully', function()
      local ok = pcall(telescope_orgmode.search_headings, {
        adapter = 'snacks',
        invalid_option = 'should_be_ignored',
      })
      assert.is_true(ok, 'Should ignore invalid options')

      pcall(function()
        local picker = e2e_helpers.get_current_picker_snacks()
        if picker then
          e2e_helpers.close_picker_snacks(picker)
        end
      end)
    end)
  end)
end)
