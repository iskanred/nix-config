# Private work configuration

This repository extends the public baseline with private work modules.
Keep this repository private. Store credentials outside the Nix configuration.

The public baseline must publish `lib.mkHome` and `lib.mkDarwin` before this
checkout can build using its GitHub input. Until then, validate local changes
without writing a local-path lock:

```sh
nix build --no-link "path:$PWD#darwinConfigurations.current.system" \
  --override-input baseline "path:$HOME/.config/nix-config" \
  --no-write-lock-file
```

On Linux, use `"path:$PWD#homeConfigurations.$USER.activationPackage"` instead.
After publication, follow the bootstrap steps below to create the remote pin.

## Bootstrap

1. Copy `local.nix.example` to `local.nix` and set your account, platform and
   the absolute `configDirectory` of this checkout.
2. Run `nix flake lock 'path:.'` and commit `flake.lock` with the configuration.
3. On macOS, build before switching:

   ```sh
   darwin-rebuild build --flake "path:$PWD#current"
   sudo darwin-rebuild switch --flake "path:$PWD#current"
   ```

   After activation, `dr build`, `dr switch` and `dr update` target this checkout.
   Audit `brew list --cask` using the real Homebrew binary before switching:
   the baseline uninstalls casks absent from the combined declaration.

   On non-NixOS Linux, use:

   ```sh
   home-manager switch --flake "path:$PWD#$USER"
   ```

   After activation, `hm switch` targets this checkout.

## Maintain

- Add work packages and settings under `modules/home/`, importing additional
  modules from `home.nix`.
- Add work macOS settings and Homebrew casks under `modules/darwin/`.
- Store private dotfiles under `files/` and link them in `modules/home/files.nix`.
- Add unfree package names to `common.extraUnfreePackages` in `flake.nix`.
- Leave `local.nix` ignored. Commit the work modules and lock file only to your
  private remote.

The shared baseline is mandatory and cannot silently disappear if an input is
unavailable. Lists merge through the Nix module system; scalar conflicts require
an intentional override, such as `lib.mkForce`, in the work module.

To adopt a published baseline change without switching immediately:

```sh
nix flake update baseline --flake "path:$PWD"
```

Build, review and commit the lock change, then switch. The baseline owns
Nixpkgs, Home Manager, nix-darwin and nix-homebrew; do not add duplicate inputs.
`dr update` retains its existing behavior: update inputs, build, then activate
with Homebrew upgrades enabled. Use the separate steps above for review first.

For another work machine, reuse these modules with that machine's ignored
`local.nix`. Keep hardware- or host-specific modules separate if needed.
