{ config, lib, local, pkgs, ... }:

let
  cfg = config.nixConfig.update;
  dependencies = lib.concatMap (step: step.after ++ step.before)
    (builtins.attrValues cfg.steps);
  missing = lib.unique (builtins.filter
    (name: !(builtins.hasAttr name cfg.steps)) dependencies);
  sorted = lib.hm.dag.topoSort cfg.steps;
  ordered =
    if missing != [ ] then
      throw "nixConfig.update.steps: unknown dependencies: ${lib.concatStringsSep ", " missing}"
    else if sorted ? result then sorted.result
    else throw "nixConfig.update.steps: dependency cycle";
in
{
  options.nixConfig.update = {
    steps = lib.mkOption {
      type = lib.hm.types.dagOf lib.types.lines;
      default = { };
      description = ''
        Ordered Zsh snippets run only by dr update, after updating flake inputs
        and before building. Write snapshots under $UPDATE_DIR/files/; they are
        copied into $CONFIG_DIR/files/ only after all steps succeed.
      '';
    };

    runner = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      readOnly = true;
      internal = true;
      description = "Generated update runner, or null when no steps are configured.";
    };
  };

  config.nixConfig.update.runner =
    if cfg.steps == { } then null else
    pkgs.writeScriptBin "nix-config-update" ''
      #!${pkgs.zsh}/bin/zsh -f
      set -eu
      set -o pipefail
      umask 077
      export PATH=${lib.makeBinPath [ pkgs.coreutils ]}:"$PATH"

      readonly CONFIG_DIR=${lib.escapeShellArg local.configDirectory}
      UPDATE_DIR=$(mktemp -d)
      readonly UPDATE_DIR
      export CONFIG_DIR UPDATE_DIR
      trap 'rm -rf -- "$UPDATE_DIR"' EXIT
      cd -- "$CONFIG_DIR"
      mkdir -p -- "$UPDATE_DIR/files"

      # For formats supporting # comments. JSON notices belong in a README.
      update_header() {
        local generated_file="$1"
        local generator="$2"
        {
          print -r -- "# This file is generated automatically by $generator in $CONFIG_DIR."
          print -r -- "# Do not edit manually. Change the generating module and run dr update."
          cat -- "$generated_file"
        } > "$generated_file.header"
        mv -- "$generated_file.header" "$generated_file"
      }

      ${lib.concatMapStringsSep "\n" (step: ''
        print -r -- ${lib.escapeShellArg "Updating ${step.name}"}
        ${step.data}
      '') ordered}

      # Publish regular files only, after every generation step succeeds.
      # Replace destination symlinks rather than writing through them.
      for staged_file in "$UPDATE_DIR"/files/**/*(.DN); do
        destination="$CONFIG_DIR/''${staged_file#"$UPDATE_DIR/"}"
        mkdir -p -- "$(dirname -- "$destination")"
        cp --remove-destination -- "$staged_file" "$destination"
      done
    '';
}
