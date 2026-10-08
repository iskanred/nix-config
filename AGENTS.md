# AGENTS

Concise guidelines for automated changes in this repository.

## Structure
- `home.nix` only contains `imports`.
- Modules live in `modules/home/` and are grouped by concern.
- macOS system modules live in `modules/darwin/`.
- Dotfiles live in `files/` and are linked via Home Manager.

## Local-only config
- `local.nix` must remain gitignored.
- Use `local.nix.example` as a template.
- Flake commands should use `path:` so untracked `local.nix` is visible:
  - macOS: `darwin-rebuild build --flake "path:$HOME/.config/nix-config#current"`
  - non-NixOS Linux: `home-manager --flake "path:$HOME/.config/nix-config#$USER" switch`
- Use `darwin-switch` on macOS and `hm switch` on non-NixOS Linux.

## Editing rules
- Keep changes minimal and focused.
- Avoid new modules unless a new concern appears.
- Update `modules/home/files.nix` when adding files under `files/`.

## Validation
- On macOS, build the full Darwin output and activate it with `darwin-switch`
  when system authorization is available.
- On non-NixOS Linux, run `hm switch`.
- If shell configs change, ensure shell startup is clean.

## Commit hygiene
- Never stage or commit `local.nix`.
- Use short, descriptive commit messages (imperative mood).
- Always include a short description of a commit with listing what has been changed in each scope.
