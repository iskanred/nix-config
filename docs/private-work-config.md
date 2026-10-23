# Shared baseline and private work configuration

The public flake is the complete personal baseline. A separate private flake
imports a pinned version and adds work configuration:

```text
public nix-config ──> personal machine
        │
        └──> private work flake ──> work machine
```

There is no private input in the public flake, and no work configuration needs
to be fetched on a personal machine. Private URLs, settings and dotfiles belong
only in the private repository. Credentials remain in external storage.

## Create the private repository

Create an empty directory outside this checkout and initialize the starter:

```sh
mkdir -p "$HOME/.config/nix-config-work"
cd "$HOME/.config/nix-config-work"
nix flake init -t "path:$HOME/.config/nix-config#work"
git init
cp local.nix.example local.nix
```

Edit `local.nix`, especially `configDirectory`, to match the private checkout.
Follow the generated README to lock, build and activate it. Only connect this
checkout to a private remote. The public repository contains only the generic
starter, never actual work values.

The baseline revision must expose `lib.mkHome` and `lib.mkDarwin` before the
starter can build from GitHub. To test unpublished baseline changes, use
`--override-input baseline "path:$HOME/.config/nix-config"` on a build command
with `--no-write-lock-file`; do not commit a lock pointing at a local checkout.

Existing configuration remains shared. Move entries into the private repository
only after identifying them as work-only. Moving previously published contents
does not remove them from Git history.

## Builder interface

Both builders always import the shared Home Manager baseline:

```nix
baseline.lib.mkHome {
  local = {
    username = "user";
    homeDirectory = "/home/user";
    system = "x86_64-linux";
    configDirectory = "/home/user/.config/nix-config-work";
  };
  homeModules = [ ./home.nix ]; # Optional; defaults to [].
  extraUnfreePackages = [ ]; # Package names; obsidian remains allowed.
}
```

`baseline.lib.mkDarwin` accepts the same arguments, plus:

```nix
{
  darwinModules = [ ./modules/darwin ]; # Optional; defaults to [].
  upgradeHomebrew = false; # Set true only for the update output.
}
```

`local` is passed to all supplied modules. `configDirectory` defaults to
`${homeDirectory}/.config/nix-config` when omitted, preserving the personal
setup. Private consumers should set it explicitly.

Home modules receive the usual Home Manager arguments; Darwin modules receive
the usual nix-darwin arguments. Use the provided `pkgs` so additions share the
baseline's package set and unfree allowlist. Module list options accumulate;
scalar conflicts are errors unless explicitly overridden. Use `lib.mkForce`
only for deliberate exceptions, since forcing a list can remove shared entries.

The private root has just one input, `baseline`. Its lock records the baseline
revision and transitive dependencies. Update that pin to adopt public changes;
the work system stays on the previous revision until rebuilt and activated.
No manual copying or merging of baseline files is needed.

## Custom update steps

`nixConfig.update.steps` is a custom Home Manager option supplied by this
baseline. Private modules add Zsh snippets using Home Manager's ordering helpers.
`dr update` updates flake inputs, runs these steps as the user, copies generated
snapshots into the checkout, then builds and activates `#update`.

`dr build` and `dr switch` only use saved snapshots. `nix flake update` alone
only updates dependency pins. No custom runner runs unless steps are configured.

### Example

```nix
{ lib, ... }:

{
  nixConfig.update.steps = {
    prepare = lib.hm.dag.entryAnywhere ''
      mkdir -p "$UPDATE_DIR/files/example"
    '';

    generateExample = lib.hm.dag.entryAfter [ "prepare" ] ''
      # Replace this demonstration with the generator's output-file command.
      print -r -- 'enabled = true' > "$UPDATE_DIR/files/example/config"
      update_header "$UPDATE_DIR/files/example/config" 'Example CLI'
    '';
  };
}
```

Each integration can keep its update step and static `home.file` declaration in
one module. Put shared CLI update/login steps in the parent module and order
configuration steps after login. Missing dependencies and cycles are errors;
unrelated steps run sequentially without a guaranteed relative order.

### Runner interface

- `$CONFIG_DIR` is `local.configDirectory` and the working directory.
- `$UPDATE_DIR` is temporary staging, cleaned up on success or failure. Write
  regular files under `$UPDATE_DIR/files/`; they are copied to the corresponding
  paths in `$CONFIG_DIR/files/` after every step succeeds.
- `update_header FILE GENERATOR` prepends these comments to fresh output:

  ```text
  # This file is generated automatically by Example CLI in /path/to/private-checkout.
  # Do not edit manually. Change the generating module and run dr update.
  ```

JSON cannot contain comments: generate an adjacent README instead. Use the
external tool's output-path option or supported environment variable to write
into staging, not the managed home file. Start cumulative generators with an
empty staged configuration so removed entries do not linger.

Steps share a Zsh process with startup files disabled, error/pipeline-failure
propagation, and coreutils on PATH. Use absolute paths or an explicit PATH for
other tools. These are ordinary shell snippets: there is no activation `run`
helper. Do not change `CONFIG_DIR`, `UPDATE_DIR`, or the runner's error handling,
and do not call `exit` from a step.

### First setup and maintenance

Commit initial credential-free snapshots before enabling their file declarations.
A fresh laptop can clone, create `local.nix`, install external CLIs, and use
explicit `darwin-rebuild` commands for the first build/switch. Manage small
credential-helper scripts as executable `home.file` entries. Tokens and private
keys must remain outside snapshots, since managed sources enter the Nix store.

After changing update steps, run `dr switch` and open a new shell. The next
`dr update` uses the newly installed runner; updating the baseline pin does not
replace the runner already loaded by the current shell. Linux Home Manager
consumers can evaluate the option, but no Linux update command is provided.

Failed generation leaves saved snapshots untouched and prevents build/activation.
Flake-lock changes and external CLI/login effects are not rolled back. Copying
successful outputs is not transactional; unrelated or absent files are retained.
A later build failure leaves the generated snapshots available for inspection.
Review `git status` and `git diff -- files flake.lock` (including untracked files)
and commit the snapshots and lock file yourself.

## Validate builder changes

From the public checkout, evaluate the harmless fixtures:

```sh
nix eval --impure --json --expr \
  'import ./tests/builders.nix { baseline = builtins.getFlake ("path:" + toString ./.); }'
```

This checks Darwin and Linux module composition, package inheritance, scoped
unfree permissions, scalar conflicts and overrides, Homebrew update flags, and
rebuild targets. Fixtures are evaluated only; never activate them.

Run update-runner regression tests on macOS with:

```sh
python3 tests/update.py
```

They build harmless runners in temporary directories and stub Nix/sudo commands
when testing `dr`; they never update real inputs or activate a system.
