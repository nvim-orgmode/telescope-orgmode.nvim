-- E2E Test Helpers
-- Utilities for programmatic E2E testing with real picker APIs

local M = {}

-- Test org file paths (created in temp directory)
M.TEST_ORG_DIR = vim.fn.tempname()
M.TEST_FILE_1 = M.TEST_ORG_DIR .. '/test1.org'
M.TEST_FILE_2 = M.TEST_ORG_DIR .. '/test2.org'
M.TEST_ARCHIVE = M.TEST_ORG_DIR .. '/archive.org'

function M.create_test_org_files()
  vim.fn.mkdir(M.TEST_ORG_DIR, 'p')

  local content1 = [[
* TODO Headline 1 :tag1:tag2:
** DONE Subheadline 1.1
** TODO Subheadline 1.2 :tag3:
* Headline 2
* DONE Archive Test
]]

  local content2 = [[
* TODO Headline 3 :tag1:
* DONE Headline 4
** Subheadline 4.1
]]

  local archive_content = [[
* DONE Archived Headline
* TODO Old Task
]]

  vim.fn.writefile(vim.split(content1, '\n'), M.TEST_FILE_1)
  vim.fn.writefile(vim.split(content2, '\n'), M.TEST_FILE_2)
  vim.fn.writefile(vim.split(archive_content, '\n'), M.TEST_ARCHIVE)
end

function M.cleanup_test_org_files()
  vim.fn.delete(M.TEST_ORG_DIR, 'rf')
end

function M.setup_orgmode_with_test_files()
  local OrgFile = require('orgmode.files.file')

  -- Load test files synchronously
  local file1 = OrgFile.load(M.TEST_FILE_1):wait()
  local file2 = OrgFile.load(M.TEST_FILE_2):wait()
  local archive = OrgFile.load(M.TEST_ARCHIVE):wait()

  -- Mock orgmode.files:all() to return our test files
  package.loaded['orgmode'] = {
    files = {
      all = function()
        return { file1, file2, archive }
      end,
    },
  }

  return { file1, file2, archive }
end

function M.create_real_headline_entry(filename, line_number)
  local org = require('telescope-orgmode.org')
  local api_headline = org.get_api_headline(filename, line_number)

  return {
    filename = filename,
    headline = api_headline and api_headline._section or nil,
  }
end

function M.create_real_orgfile_entry(filename)
  local title = vim.fn.fnamemodify(filename, ':t:r')
  return {
    filename = filename,
    title = title,
    headline = nil,
  }
end

-- Telescope-specific helpers
function M.get_current_picker_telescope()
  local action_state = require('telescope.actions.state')
  local prompt_bufnr = vim.api.nvim_get_current_buf()
  return action_state.get_current_picker(prompt_bufnr)
end

function M.close_picker_telescope(picker)
  if picker then
    local actions = require('telescope.actions')
    actions.close(picker.prompt_bufnr)
  end
end

function M.get_picker_entries_telescope(picker)
  if not picker then
    return {}
  end

  local manager = picker.manager
  if manager then
    return manager:get_entries()
  end

  return {}
end

-- Snacks-specific helpers
function M.get_current_picker_snacks()
  local ok, snacks = pcall(require, 'snacks')
  if ok and snacks.picker then
    return snacks.picker.active
  end
  return nil
end

function M.close_picker_snacks(picker)
  if picker and picker.close then
    picker:close()
  end
end

function M.wait_for_picker(timeout_ms)
  timeout_ms = timeout_ms or 300
  vim.wait(timeout_ms, function()
    -- Wait for picker to initialize
    return false
  end)
end

function M.create_real_state()
  local state = require('telescope-orgmode.lib.state')
  local refresh_callback = function() end
  return state.create_state('headlines', {}, refresh_callback)
end

-- Verify headline was moved for refile tests
function M.verify_headline_exists(filename, headline_title)
  local lines = vim.fn.readfile(filename)
  for _, line in ipairs(lines) do
    if line:match(vim.pesc(headline_title)) then
      return true
    end
  end
  return false
end

-- Get first headline from test file
function M.get_first_headline_from_file(filename)
  local lines = vim.fn.readfile(filename)
  for i, line in ipairs(lines) do
    if line:match('^%*+%s+') then
      return i
    end
  end
  return nil
end

return M
