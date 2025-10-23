local keybindings = require('telescope-orgmode.lib.keybindings')
local PickerState = require('telescope-orgmode.lib.state')

describe('[Unit: lib/keybindings]', function()
  describe('bindings', function()
    it('should define toggle_mode binding', function()
      assert.is_not_nil(keybindings.bindings.toggle_mode)
      assert.are.equal('Toggle between headlines and orgfiles mode', keybindings.bindings.toggle_mode.description)
      assert.are.equal('<C-Space>', keybindings.bindings.toggle_mode.modes.i)
      assert.are.equal('<C-Space>', keybindings.bindings.toggle_mode.modes.n)
    end)

    it('should define toggle_current_file binding', function()
      assert.is_not_nil(keybindings.bindings.toggle_current_file)
      assert.are.equal('Toggle filter: current file only', keybindings.bindings.toggle_current_file.description)
      assert.are.equal('<C-f>', keybindings.bindings.toggle_current_file.modes.i)
      assert.are.equal('<C-f>', keybindings.bindings.toggle_current_file.modes.n)
    end)

    it('should define open_tag_picker binding', function()
      assert.is_not_nil(keybindings.bindings.open_tag_picker)
      assert.are.equal('Open tag selection picker', keybindings.bindings.open_tag_picker.description)
      assert.are.equal('<C-t>', keybindings.bindings.open_tag_picker.modes.i)
      assert.are.equal('<C-t>', keybindings.bindings.open_tag_picker.modes.n)
    end)

    it('should define confirm binding', function()
      assert.is_not_nil(keybindings.bindings.confirm)
      assert.are.equal('Select entry and execute default action', keybindings.bindings.confirm.description)
      assert.are.equal('<CR>', keybindings.bindings.confirm.modes.i)
      assert.are.equal('<CR>', keybindings.bindings.confirm.modes.n)
    end)
  end)

  describe('execute_action', function()
    describe('toggle_mode', function()
      it('should toggle state and call refresh function', function()
        local state = PickerState:new('headlines', {})
        local refresh_called = false
        local refresh_state = nil

        local context = {
          state = state,
          opts = {},
          refresh_fn = function(updated_state)
            refresh_called = true
            refresh_state = updated_state
          end,
        }

        keybindings.execute_action('toggle_mode', context)

        assert.is_true(refresh_called)
        assert.are.equal('orgfiles', state:get_current())
        assert.are.equal(state, refresh_state)
      end)
    end)

    describe('toggle_current_file', function()
      it('should toggle filter and call refresh in headlines mode', function()
        local state = PickerState:new('headlines')
        state:set_filter('only_current_file', false)
        local refresh_called = false
        local refresh_state = nil

        local context = {
          state = state,
          opts = {},
          refresh_fn = function(updated_state)
            refresh_called = true
            refresh_state = updated_state
          end,
        }

        keybindings.execute_action('toggle_current_file', context)

        assert.is_true(refresh_called)
        assert.is_true(state:get_filter('only_current_file'))
        assert.are.equal(state, refresh_state)
      end)

      it('should do nothing in orgfiles mode', function()
        local state = PickerState:new('orgfiles')
        state:set_filter('only_current_file', false)
        local refresh_called = false

        local context = {
          state = state,
          opts = {},
          refresh_fn = function()
            refresh_called = true
          end,
        }

        keybindings.execute_action('toggle_current_file', context)

        assert.is_false(refresh_called)
        -- Filter should remain unchanged
        assert.are.equal(false, state:get_filter('only_current_file'))
      end)
    end)

    describe('open_tag_picker', function()
      it('should call close function if provided', function()
        local close_called = false

        local context = {
          opts = {},
          close_fn = function()
            close_called = true
          end,
        }

        -- Mock the search_tags module to avoid actual picker creation
        package.loaded['telescope-orgmode.picker.search_tags'] = {
          search_tags = function() end,
        }

        keybindings.execute_action('open_tag_picker', context)

        assert.is_true(close_called)

        -- Cleanup mock
        package.loaded['telescope-orgmode.picker.search_tags'] = nil
      end)

      it('should work without close function', function()
        local context = {
          opts = {},
        }

        -- Mock the search_tags module
        package.loaded['telescope-orgmode.picker.search_tags'] = {
          search_tags = function() end,
        }

        -- Should not error
        keybindings.execute_action('open_tag_picker', context)

        -- Cleanup mock
        package.loaded['telescope-orgmode.picker.search_tags'] = nil
      end)

      it('should pass selected tag from context', function()
        local passed_opts = nil

        local context = {
          opts = {
            context = {
              selected_tag = 'work',
            },
          },
        }

        -- Mock the main module and capture arguments
        package.loaded['telescope-orgmode'] = {
          search_tags = function(opts)
            passed_opts = opts
          end,
        }

        keybindings.execute_action('open_tag_picker', context)

        assert.is_not_nil(passed_opts)
        assert.are.equal('work', passed_opts.default_text)

        -- Cleanup mock
        package.loaded['telescope-orgmode'] = nil
      end)
    end)

    describe('filter_current_buffer', function()
      it('should set current_files to current buffer file', function()
        local state = PickerState:new('headlines')
        local refresh_called = false

        local context = {
          state = state,
          opts = { current_file = '/path/to/current.org' },
          refresh_fn = function()
            refresh_called = true
          end,
        }

        keybindings.execute_action('filter_current_buffer', context)

        assert.is_true(refresh_called)
        assert.are.same({ '/path/to/current.org' }, state:get_filter('current_files'))
      end)

      it('should work in headlines mode', function()
        local state = PickerState:new('headlines')
        local context = {
          state = state,
          opts = { current_file = '/path/to/file.org' },
          refresh_fn = function() end,
        }

        keybindings.execute_action('filter_current_buffer', context)

        assert.are.same({ '/path/to/file.org' }, state:get_filter('current_files'))
      end)

      it('should work in orgfiles mode', function()
        local state = PickerState:new('orgfiles')
        local context = {
          state = state,
          opts = { current_file = '/path/to/file.org' },
          refresh_fn = function() end,
        }

        keybindings.execute_action('filter_current_buffer', context)

        assert.are.same({ '/path/to/file.org' }, state:get_filter('current_files'))
      end)
    end)

    describe('filter_all_buffers', function()
      it('should set current_files to all open org buffers', function()
        local state = PickerState:new('headlines')
        local refresh_called = false

        local context = {
          state = state,
          opts = {},
          refresh_fn = function()
            refresh_called = true
          end,
        }

        keybindings.execute_action('filter_all_buffers', context)

        assert.is_true(refresh_called)
        -- Should have called filters.get_open_buffers and set result
        local current_files = state:get_filter('current_files')
        assert.is_table(current_files)
        -- Can't test exact contents since it depends on actual open buffers
      end)

      it('should work in both modes', function()
        -- Test headlines mode
        local state_headlines = PickerState:new('headlines')
        keybindings.execute_action('filter_all_buffers', {
          state = state_headlines,
          opts = {},
          refresh_fn = function() end,
        })
        assert.is_table(state_headlines:get_filter('current_files'))

        -- Test orgfiles mode
        local state_orgfiles = PickerState:new('orgfiles')
        keybindings.execute_action('filter_all_buffers', {
          state = state_orgfiles,
          opts = {},
          refresh_fn = function() end,
        })
        assert.is_table(state_orgfiles:get_filter('current_files'))
      end)
    end)

    describe('filter_headline_file', function()
      it('should set current_files to selected headline file', function()
        local state = PickerState:new('headlines')
        local refresh_called = false

        local context = {
          state = state,
          opts = {},
          selected_entry = { filename = '/path/to/selected.org' },
          refresh_fn = function()
            refresh_called = true
          end,
        }

        keybindings.execute_action('filter_headline_file', context)

        assert.is_true(refresh_called)
        assert.are.same({ '/path/to/selected.org' }, state:get_filter('current_files'))
      end)

      it('should do nothing in orgfiles mode', function()
        local state = PickerState:new('orgfiles')
        local refresh_called = false

        local context = {
          state = state,
          opts = {},
          selected_entry = { filename = '/path/to/selected.org' },
          refresh_fn = function()
            refresh_called = true
          end,
        }

        keybindings.execute_action('filter_headline_file', context)

        assert.is_false(refresh_called)
        assert.is_nil(state:get_filter('current_files'))
      end)

      it('should do nothing without selected_entry', function()
        local state = PickerState:new('headlines')
        local refresh_called = false

        local context = {
          state = state,
          opts = {},
          selected_entry = nil,
          refresh_fn = function()
            refresh_called = true
          end,
        }

        keybindings.execute_action('filter_headline_file', context)

        assert.is_false(refresh_called)
        assert.is_nil(state:get_filter('current_files'))
      end)
    end)

    describe('drop_filters', function()
      it('should clear all filters', function()
        local state = PickerState:new('headlines')
        state:set_filter('tag_query', 'work')
        state:set_filter('current_files', { '/path/to/file.org' })
        state:set_filter('only_current_file', true)
        local refresh_called = false

        local context = {
          state = state,
          opts = {},
          refresh_fn = function()
            refresh_called = true
          end,
        }

        keybindings.execute_action('drop_filters', context)

        assert.is_true(refresh_called)
        assert.is_nil(state:get_filter('tag_query'))
        assert.are.same({}, state:get_filter('current_files'))
        assert.is_nil(state:get_filter('only_current_file'))
      end)

      it('should work when no filters are set', function()
        local state = PickerState:new('headlines')
        local refresh_called = false

        local context = {
          state = state,
          opts = {},
          refresh_fn = function()
            refresh_called = true
          end,
        }

        keybindings.execute_action('drop_filters', context)

        assert.is_true(refresh_called)
        -- Should still set empty table for current_files
        assert.are.same({}, state:get_filter('current_files'))
      end)

      it('should work in both modes', function()
        -- Test headlines mode
        local state_headlines = PickerState:new('headlines')
        state_headlines:set_filter('tag_query', 'test')
        keybindings.execute_action('drop_filters', {
          state = state_headlines,
          opts = {},
          refresh_fn = function() end,
        })
        assert.is_nil(state_headlines:get_filter('tag_query'))

        -- Test orgfiles mode
        local state_orgfiles = PickerState:new('orgfiles')
        state_orgfiles:set_filter('current_files', { '/path/to/file.org' })
        keybindings.execute_action('drop_filters', {
          state = state_orgfiles,
          opts = {},
          refresh_fn = function() end,
        })
        assert.are.same({}, state_orgfiles:get_filter('current_files'))
      end)
    end)
  end)
end)
