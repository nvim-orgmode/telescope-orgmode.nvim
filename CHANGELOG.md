# Changelog

## 1.5.0

**Snacks.nvim support**

[snacks.nvim](https://github.com/folke/snacks.nvim) can now be used as picker backend alongside Telescope.

**New features**

- Tag search: `search_tags()` lets you browse and filter by org tags
- Filter headlines by current file, open buffers, or specific files
- Picker title shows active filters
- Location column can show category instead of filename (`location_preference`)
- Jumping to a headline now sets a jumplist mark (`<C-o>` to go back)

**Fixes**

- Per-call `adapter` option was ignored after first call
- `get_api_file()` could crash on invalid filenames
- Pressing `<CR>` on an empty result no longer errors

**Under the hood**

- Restructured codebase for multi-adapter support
- Added test suite and GitHub Actions CI

**Full Changelog**: https://github.com/nvim-orgmode/telescope-orgmode.nvim/compare/1.4.3...1.5.0
