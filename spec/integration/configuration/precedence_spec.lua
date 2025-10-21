-- Configuration precedence and validation tests
-- Tests cross-cutting configuration concerns that don't belong to specific features

describe('[Config: Precedence & Validation]', function()
  -- TODO: Add configuration precedence tests
  -- - defaults vs setup() vs per-call opts
  -- - validation enforcement at setup() and call time
  -- - picker-specific defaults

  describe('configuration precedence', function()
    -- it('defaults used when no config provided')
    -- it('setup() overrides defaults globally')
    -- it('per-call opts override setup()')
    -- it('per-call opts override defaults without setup()')
  end)

  describe('validation enforcement', function()
    -- it('rejects invalid config at setup() time')
    -- it('rejects invalid config at call time')
  end)

  describe('picker-specific defaults', function()
    -- it('search_headings uses correct prompt titles')
    -- it('refile_heading uses correct prompt titles')
    -- it('insert_link uses correct prompt titles')
  end)
end)
