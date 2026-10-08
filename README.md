# Cross-Platform Nix Configuration

One flake for:

- macOS system settings through nix-darwin
- a shared Home Manager environment on macOS and Linux
- standalone Home Manager activation when a system rebuild is not needed

The Home Manager modules select platform-specific packages and settings from
`pkgs.stdenv.hostPlatform`, while the Darwin system configuration remains in
`modules/darwin/`.

## Local configuration

Create the private machine configuration:

```bash
cp local.nix.example local.nix
```

Then set the account and platform:

```nix
{
  username = "your-username";
  homeDirectory = "/Users/your-username"; # Use /home/... on Linux.
  system = "aarch64-darwin"; # Or x86_64-darwin, x86_64-linux, aarch64-linux.
}
```

`local.nix` is intentionally gitignored. Commands use a `path:` flake reference
so the untracked file is included during evaluation.

## Apply the configuration

On macOS, apply the complete nix-darwin system and the integrated Home Manager
configuration:

```bash
sudo darwin-rebuild switch --flake "path:$HOME/.config/home-manager#current"
```

On macOS or Linux, apply only the standalone Home Manager configuration:

```bash
home-manager switch --flake "path:$HOME/.config/home-manager#$USER"
```

After the first Home Manager activation, `hm switch` is a shortcut for the
standalone command. Use `darwin-rebuild` when changes under `modules/darwin/`
must also be applied.

## Flake outputs

- `homeModules.default` — reusable cross-platform Home Manager module
- `homeConfigurations.<username>` — standalone Home Manager configuration
- `darwinConfigurations.current` — macOS system plus integrated Home Manager
  configuration; exported only when `local.system` ends in `-darwin`

## Layout

- `flake.nix` — inputs and standalone/Darwin outputs
- `home.nix` — shared Home Manager entry point
- `modules/home/` — shared and platform-conditional user configuration
- `modules/darwin/` — macOS system configuration
- `files/` — managed dotfiles

## Documentation

- [Program migration playbook](docs/programs-migration.md)
- [Neovim configuration](docs/neovim.md)

## Storage cleanup

```bash
hm generations
hm expire-generations "-30 days"
nix-collect-garbage -d
nix-store --optimise
```

## Theme settings

- Kitty: `programs.kitty.themeFile` in `modules/home/programs.nix`
- Neovim: `NVIM_THEME` in `modules/home/base.nix`
- bat: `BAT_THEME` in `modules/home/base.nix`
