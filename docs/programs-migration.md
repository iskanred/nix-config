# Program Migration Playbook

## Goal
Migrate tools from `home.packages` to `programs.<name>` in Home Manager while preserving behavior and improving reproducibility across macOS and Linux.

## Source of Truth
Migration progress is tracked in this same file below (`Program Replacements`) using the `(replaced)` marker.

## Migration Principles
1. Do not break existing behavior.
2. Keep changes minimal and scoped (one package at a time).
3. If manual config exists, migrate to Nix carefully without regressions.
4. Remove legacy/manual settings only after successful migration.
5. Remove explicitly set values only when they match Home Manager/program defaults.
6. Add short comments for non-obvious Nix options explaining why they are set.

## Required Workflow For Each Package
1. Pick the next package in line from `Program Replacements` (top to bottom).
2. Find related config in repo (`rg -n "<name>"`).
3. Inspect module options:
   - `nix eval --json "path:.#homeConfigurations.$USER.options.programs.<name>" | jq 'keys'`
4. Replace package install with `programs.<name>` while preserving behavior.
5. Remove duplicates and obsolete manual config only when safe.
6. Mark the item as `(replaced)` in `Program Replacements`.
7. Always validate before reporting:
   - `XDG_CACHE_HOME=/tmp home-manager --flake path:.#$USER switch && exec zsh -lc 'exit'`

## Reporting Format After Each Step
- What was found (duplicates/manual config)
- What changed (files and key options)
- Why these choices were made
- Validation result of `hm switch && exec zsh`

## Program Replacements
eza -> programs.eza (replaced)
direnv -> programs.direnv (replaced)
kitty -> programs.kitty (replaced)
git -> programs.git
tmux -> programs.tmux
bat -> programs.bat
fd -> programs.fd
yazi -> programs.yazi
jq -> programs.jq
htop -> programs.htop
btop -> programs.btop
ripgrep -> programs.ripgrep
codex -> programs.codex
