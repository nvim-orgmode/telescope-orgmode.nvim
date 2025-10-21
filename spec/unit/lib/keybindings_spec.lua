local keybindings = require('telescope-orgmode.lib.keybindings')
local PickerState = require('telescope-orgmode.lib.state')

describe('[Unit: lib/keybindings]', function()
  describe('bindings', function()
    it('should define toggle_mode binding', function()
      assert.is_not_nil(keybindings.bindings.toggle_mode)
      assert.are.equal('Toggle between headlines and orgfiles mode', keybindings.bindings.toggle_mode.description)
      assert.are.equal('<C-Space>', keybindings.bindings.toggle_mode.default_key)
    end)

    it('should define toggle_current_file binding', function()
      assert.is_not_nil(keybindings.bindings.toggle_current_file)
      assert.are.equal('Toggle filter: current file only', keybindings.bindings.toggle_current_file.description)
      assert.are.equal('<C-f>', keybindings.bindings.toggle_current_file.default_key)
    end)

    it('should define open_tag_picker binding', function()
      assert.is_not_nil(keybindings.bindings.open_tag_picker)
      assert.are.equal('Open tag selection picker', keybindings.bindings.open_tag_picker.description)
      assert.are.equal('<C-t>', keybindings.bindings.open_tag_picker.default_key)
    end)

    it('should define confirm binding', function()
      assert.is_not_nil(keybindings.bindings.confirm)
      assert.are.equal('Select entry and execute default action', keybindings.bindings.confirm.description)
      assert.are.equal('<CR>', keybindings.bindings.confirm.default_key)
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

        -- Mock the search_tags module and capture arguments
        package.loaded['telescope-orgmode.picker.search_tags'] = {
          search_tags = function(opts)
            passed_opts = opts
          end,
        }

        keybindings.execute_action('open_tag_picker', context)

        assert.is_not_nil(passed_opts)
        assert.are.equal('work', passed_opts.default_text)

        -- Cleanup mock
        package.loaded['telescope-orgmode.picker.search_tags'] = nil
      end)
    end)
  end)
end)
