# Changelog

## 1.6.2

**Fixes**

- `picker_defaults` passed to `setup()` now reaches the pickers. It was merged into the wrong config table, so the `snacks` sub-namespace added in 1.6.1 never took effect.

**Full Changelog**: https://github.com/nvim-orgmode/telescope-orgmode.nvim/compare/1.6.1...1.6.2

## 1.6.1

**New features**

- Snacks picker options are configurable per picker type through a `snacks` sub-namespace in `picker_defaults`: layout, window, previewers, matcher, sort and additional input keys. Per-call overrides deep-merge over the setup defaults.

**Notes**

- The reference manual now ships as a Vim help file — read it offline with `:help telescope-orgmode`.
- Adapter-owned snacks fields (`title`, `items`, `pattern`, `preview`, `frecency`, `format`, `confirm`) stay protected: user values for those are ignored to keep the adapter contract intact. User input keys merge additively, and adapter keys win on conflict.
- The `snacks` sub-namespace applies to the Snacks adapter only. The Telescope adapter keeps its existing pass-through opts, and `search_tags` is not routed through this pipeline yet.

**Full Changelog**: https://github.com/nvim-orgmode/telescope-orgmode.nvim/compare/1.6.0...1.6.1

## 1.6.0

**New features**

- Configurable property columns: show org property drawer values (e.g. `ID`) as picker columns via `show_properties`
- Configurable search field ordering via `ordinal_fields` (controls which fields the fuzzy matcher scores against)
- Snacks picker boosts recently and frequently used files; new toggle exposes per-item scoring for tuning

**Fixes**

- Telescope picker respects the user's `telescope.setup()` layout configuration (was hardcoded to 0.95 × 0.95)
- Folds are preserved when jumping to headlines

**Notes**

- Telescope picker no longer opens near-fullscreen by default. If you liked the old size, set `layout_config` in your `telescope.setup()`.
- Search-result ranking may shift slightly due to unified field ordering across Telescope and Snacks.

**Full Changelog**: https://github.com/nvim-orgmode/telescope-orgmode.nvim/compare/1.5.1...1.6.0

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
