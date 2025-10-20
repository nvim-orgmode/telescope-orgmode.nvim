local config = require('telescope-orgmode.lib.config')

describe('config', function()
  describe('defaults', function()
    it('has expected default values', function()
      assert.is_nil(config.defaults.max_depth)
      assert.is_false(config.defaults.archived)
      assert.is_false(config.defaults.only_current_file)
      assert.is_true(config.defaults.show_location)
      assert.is_true(config.defaults.show_tags)
      assert.is_true(config.defaults.show_todo_state)
      assert.is_true(config.defaults.show_priority)
      assert.equals(15, config.defaults.location_max_width)
      assert.equals(15, config.defaults.tags_max_width)
    end)
  end)

  describe('merge', function()
    it('returns defaults when no opts provided', function()
      local result = config.merge(nil)
      assert.equals(config.defaults.archived, result.archived)
      assert.equals(config.defaults.show_location, result.show_location)
    end)

    it('merges user options with defaults', function()
      local opts = { max_depth = 3, archived = true }
      local result = config.merge(opts)
      assert.equals(3, result.max_depth)
      assert.is_true(result.archived)
      assert.is_false(result.only_current_file) -- from defaults
    end)

    it('overrides defaults with user options', function()
      local opts = { show_location = false, location_max_width = 20 }
      local result = config.merge(opts)
      assert.is_false(result.show_location)
      assert.equals(20, result.location_max_width)
    end)
  end)

  describe('validate', function()
    it('accepts valid configuration', function()
      local valid_config = config.merge({ max_depth = 3 })
      local valid, err = config.validate(valid_config)
      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it('rejects negative max_depth', function()
      local invalid_config = { max_depth = -1 }
      local valid, err = config.validate(invalid_config)
      assert.is_false(valid)
      assert.is_not_nil(err)
    end)

    it('rejects zero max_depth', function()
      local invalid_config = { max_depth = 0 }
      local valid, err = config.validate(invalid_config)
      assert.is_false(valid)
      assert.is_not_nil(err)
    end)

    it('rejects invalid location_max_width', function()
      local invalid_config = { location_max_width = -5 }
      local valid, err = config.validate(invalid_config)
      assert.is_false(valid)
      assert.is_not_nil(err)
    end)

    it('rejects invalid tags_max_width', function()
      local invalid_config = { tags_max_width = 0 }
      local valid, err = config.validate(invalid_config)
      assert.is_false(valid)
      assert.is_not_nil(err)
    end)
  end)

  describe('get_original_file', function()
    it('returns a string', function()
      local filename = config.get_original_file()
      assert.equals('string', type(filename))
    end)
  end)
end)
