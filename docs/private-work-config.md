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

## Validate builder changes

From the public checkout, evaluate the harmless fixtures:

```sh
nix eval --impure --json --expr \
  'import ./tests/builders.nix { baseline = builtins.getFlake ("path:" + toString ./.); }'
```

This checks Darwin and Linux module composition, package inheritance, scoped
unfree permissions, scalar conflicts and overrides, Homebrew update flags, and
rebuild targets. Fixtures are evaluated only; never activate them.
