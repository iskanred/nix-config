# Neovim Config Structure

This config follows a minimal, modular layout that works well with Home Manager.
`init.lua` is the entry point and only wires modules together. All logic lives
in `lua/` so it can be required as standard Lua modules.

## Structure

- `init.lua`: Entry point. Loads the config modules.
- `lua/config/options.lua`: Core editor options (UI, tabs, search, behavior).
- `lua/config/keymaps.lua`: Global keybindings (user-facing actions).
- `lua/config/diagnostics.lua`: Global diagnostics UI (signs, virtual text, floats).
- `lua/config/cmp.lua`: Completion engine configuration (nvim-cmp).
- `lua/config/lsp.lua`: Shared LSP wiring (capabilities, on_attach) + auto-load.
- `lua/lsp/*.lua`: Per-language LSP modules.

## Comparisons (what goes where)

- **options vs keymaps**
  - `options` are editor settings (how Neovim behaves by default).
  - `keymaps` are user actions (what happens when you press keys).

- **cmp vs diagnostics**
  - `cmp` is completion UI: suggestions, selection, confirm behavior.
  - `diagnostics` is the error/warning UI: virtual text, signs, floating windows.

## Auto-loading LSP modules

Any file under `lua/lsp/*.lua` that exports a `setup(base)` function is loaded
automatically. This keeps language-specific config isolated and lets you drop in
new servers without touching shared LSP code.

Example pattern for a language module:

```lua
-- lua/lsp/<lang>.lua
local M = {}

function M.setup(base)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "<filetype>",
    callback = function(ev)
      vim.lsp.start({
        name = "<server>",
        cmd = { "<server-cmd>" },
        root_dir = "<root>",
        capabilities = base.capabilities,
        on_attach = base.on_attach,
      })
    end,
  })
end

return M
```

## Keybindings (LSP)

- `gd` — go to definition
- `gD` — go to declaration
- `gi` — go to implementation
- `gr` — list references
- `K` — hover documentation
- `<leader>rn` — rename symbol
- `<leader>ca` — code action
- `<leader>e` — show diagnostics float
- `<leader>f` — format buffer (manual)
- `<leader>td` — toggle diagnostics

## Formatting

- On save (`BufWritePre`), format via LSP for any buffer that attaches to an LSP.
- Manual formatting remains available on `<leader>f`.

## Home Manager integration

The whole `files/nvim/` directory is linked into `~/.config/nvim` by Home Manager.
This makes the config declarative and reproducible across machines.

## Themes (extensible)

Themes are selected via the `NVIM_THEME` environment variable. The loader
expects a module in `lua/themes/<name>.lua` that exposes `load()`.

Current themes:
- `one-dark`
- `one-light`

To add a new theme:
1. Add a plugin (if needed) in `$HOME/.config/home-manager/modules/home/programs.nix`.
2. Create `lua/themes/<name>.lua` with a `load()` function.
3. Set `NVIM_THEME=<name>` (or use the theme helper in Zsh).
