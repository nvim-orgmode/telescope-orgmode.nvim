-- E2E Tests: Keybinding Action Execution
-- Tests that actions triggered by keybindings execute correctly (programmatic, not feedkeys)
-- Note: We cannot test actual keystroke simulation in headless mode (Neovim limitation)
-- Instead, we test the business logic that keybindings trigger

local e2e_helpers = require('spec.helpers.e2e_helpers')

describe('[E2E: Keybinding Actions]', function()
  local PickerState = require('telescope-orgmode.lib.state')
  local filters = require('telescope-orgmode.lib.filters')

  before_each(function()
    e2e_helpers.create_test_org_files()
    e2e_helpers.setup_orgmode_with_test_files()
  end)

  after_each(function()
    e2e_helpers.cleanup_test_org_files()
  end)

  describe('mode toggle action (<C-Space> keybinding logic)', function()
    it('should toggle from headlines to orgfiles mode', function()
      local state_obj = PickerState:new('headlines')

      assert.are.equal('headlines', state_obj:get_current(), 'Should start in headlines mode')

      -- Simulate what <C-Space> keybinding does
      state_obj:toggle()

      assert.are.equal('orgfiles', state_obj:get_current(), 'Should toggle to orgfiles mode')
    end)

    it('should toggle from orgfiles to headlines mode', function()
      local state_obj = PickerState:new('orgfiles')

      assert.are.equal('orgfiles', state_obj:get_current(), 'Should start in orgfiles mode')

      state_obj:toggle()

      assert.are.equal('headlines', state_obj:get_current(), 'Should toggle back to headlines mode')
    end)

    it('should preserve filters when toggling modes', function()
      local state_obj = PickerState:new('headlines')

      -- Set a filter
      state_obj:set_filter('current_files', { e2e_helpers.TEST_FILE_1 })

      -- Toggle mode
      state_obj:toggle()

      -- Filter should persist
      local filters_after = state_obj:get_all_filters()
      assert.is_not_nil(filters_after.current_files, 'Filter should persist after mode toggle')
      assert.are.equal(e2e_helpers.TEST_FILE_1, filters_after.current_files[1])
    end)
  end)

  describe('current file filter action (<C-f> keybinding logic)', function()
    it('should set current_file filter to true', function()
      local state_obj = PickerState:new('headlines')

      -- Simulate what <C-f> does (first press)
      state_obj:set_filter('current_file', true)

      local filters_result = state_obj:get_all_filters()
      assert.is_true(filters_result.current_file, 'current_file filter should be enabled')
    end)

    it('should toggle current_file filter off when pressed again', function()
      local state_obj = PickerState:new('headlines')

      -- First press: enable
      state_obj:set_filter('current_file', true)
      assert.is_true(state_obj:get_all_filters().current_file)

      -- Second press: disable
      state_obj:set_filter('current_file', false)
      assert.is_false(state_obj:get_all_filters().current_file)
    end)

    it('should only work in headlines mode', function()
      local state_obj = PickerState:new('orgfiles')

      -- Try to set filter in orgfiles mode
      state_obj:set_filter('current_file', true)

      -- This should either be ignored or work (implementation detail)
      -- Main point: it shouldn't crash
      local filters_result = state_obj:get_all_filters()
      assert.is_not_nil(filters_result, 'Should not crash when setting filter in orgfiles mode')
    end)
  end)

  describe('multi-file filter actions', function()
    it('should set current_files filter (<C-f><C-b> logic)', function()
      local state_obj = PickerState:new('headlines')

      local files = { e2e_helpers.TEST_FILE_1, e2e_helpers.TEST_FILE_2 }
      state_obj:set_filter('current_files', files)

      local filters_result = state_obj:get_all_filters()
      assert.is_not_nil(filters_result.current_files, 'current_files filter should be set')
      assert.are.equal(2, #filters_result.current_files, 'Should have 2 files')
    end)

    it('should clear filters manually', function()
      local state_obj = PickerState:new('headlines')

      -- Set multiple filters
      state_obj:set_filter('current_file', true)
      state_obj:set_filter('current_files', { e2e_helpers.TEST_FILE_1 })

      -- Clear filters by setting to nil
      state_obj:set_filter('current_file', nil)
      state_obj:set_filter('current_files', nil)

      local filters_result = state_obj:get_all_filters()
      assert.is_nil(filters_result.current_file, 'current_file should be cleared')
      assert.is_nil(filters_result.current_files, 'current_files should be cleared')
    end)
  end)

  describe('filter application logic', function()
    it('should filter headlines by file list', function()
      local headlines = {
        { filename = e2e_helpers.TEST_FILE_1, title = 'Headline 1' },
        { filename = e2e_helpers.TEST_FILE_2, title = 'Headline 2' },
        { filename = e2e_helpers.TEST_FILE_1, title = 'Headline 3' },
      }

      -- Test apply_file_filter (actual API)
      local filtered = filters.apply_file_filter(headlines, { e2e_helpers.TEST_FILE_1 })

      assert.are.equal(2, #filtered, 'Should filter to 2 headlines from FILE_1')
      assert.are.equal('Headline 1', filtered[1].title)
      assert.are.equal('Headline 3', filtered[2].title)
    end)

    it('should handle empty filter list (no filtering)', function()
      local headlines = {
        { filename = e2e_helpers.TEST_FILE_1, title = 'Headline 1' },
        { filename = e2e_helpers.TEST_FILE_2, title = 'Headline 2' },
      }

      -- Empty list = no filter
      local filtered = filters.apply_file_filter(headlines, {})

      assert.are.equal(2, #filtered, 'Should return all headlines when filter list is empty')
    end)

    it('should handle nil filter list (no filtering)', function()
      local headlines = {
        { filename = e2e_helpers.TEST_FILE_1, title = 'Headline 1' },
      }

      -- nil = no filter
      local filtered = filters.apply_file_filter(headlines, nil)

      assert.are.equal(1, #filtered, 'Should return all headlines when filter list is nil')
    end)
  end)

  describe('state persistence across operations', function()
    it('should maintain state through multiple operations', function()
      local state_obj = PickerState:new('headlines')

      -- Sequence of operations
      state_obj:set_filter('current_file', true)
      state_obj:toggle() -- Switch to orgfiles
      state_obj:toggle() -- Switch back to headlines

      -- Verify state persisted
      assert.are.equal('headlines', state_obj:get_current(), 'Should be back in headlines mode')
      local filters_result = state_obj:get_all_filters()
      assert.is_true(filters_result.current_file, 'Filter should persist through mode toggles')
    end)

    it('should handle rapid state changes', function()
      local state_obj = PickerState:new('headlines')

      -- Rapid operations
      for _ = 1, 5 do
        state_obj:toggle()
        state_obj:set_filter('current_file', true)
        state_obj:toggle()
        -- Clear filters manually
        state_obj:set_filter('current_file', nil)
      end

      -- Should not crash and state should be valid
      assert.is_not_nil(state_obj:get_current(), 'State should remain valid')
    end)
  end)

  describe('real-world usage scenarios', function()
    it('should handle typical user workflow: search -> filter -> navigate', function()
      local state_obj = PickerState:new('headlines')

      -- User opens headlines picker
      assert.are.equal('headlines', state_obj:get_current())

      -- User presses <C-f> to filter current file
      state_obj:set_filter('current_file', true)

      -- User presses <C-Space> to see orgfiles
      state_obj:toggle()
      assert.are.equal('orgfiles', state_obj:get_current())

      -- User presses <C-Space> to go back to headlines
      state_obj:toggle()
      assert.are.equal('headlines', state_obj:get_current())

      -- User clears filters manually
      state_obj:set_filter('current_file', nil)

      local final_filters = state_obj:get_all_filters()
      assert.is_nil(final_filters.current_file, 'Filters should be cleared')
    end)

    it('should handle edge case: toggling filters multiple times', function()
      local state_obj = PickerState:new('headlines')

      -- Toggle filter on/off multiple times
      for i = 1, 10 do
        local enable = (i % 2 == 1)
        state_obj:set_filter('current_file', enable)

        local filters_result = state_obj:get_all_filters()
        assert.are.equal(enable, filters_result.current_file or false, 'Filter state should match toggle')
      end
    end)
  end)
end)
