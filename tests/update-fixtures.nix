{ baseline, configDirectory }:

let
  lib = baseline.inputs.nixpkgs.lib;
  hmLib = import "${baseline.inputs.home-manager}/modules/lib/stdlib-extended.nix" lib;
  inherit (hmLib.hm) dag;
  mkHome = steps: baseline.lib.mkHome {
    local = {
      username = "fixture";
      homeDirectory = "/Users/fixture";
      system = builtins.currentSystem;
      inherit configDirectory;
    };
    homeModules = [ { nixConfig.update.steps = steps; } ];
  };
  runner = steps: (mkHome steps).config.nixConfig.update.runner;
  first = dag.entryAnywhere ''
    print -r -- "$UPDATE_DIR" > "$CONFIG_DIR/staging-path"
    mkdir -p "$UPDATE_DIR/files/git"
    print -r -- 'new snapshot' > "$UPDATE_DIR/files/git/config"
    print -r -- 'first' > "$CONFIG_DIR/order"
  '';
in
{
  success = runner {
    zFirst = first;
    aSecond = dag.entryAfter [ "zFirst" ] ''
      print -r -- 'second' >> "$CONFIG_DIR/order"
      update_header "$UPDATE_DIR/files/git/config" 'Fixture CLI'
      mkdir -p "$UPDATE_DIR/files/docker"
      print -r -- '{"credsStore":"fixture"}' > "$UPDATE_DIR/files/docker/config.json"
      print -r -- 'Generated fixture; do not edit manually.' > "$UPDATE_DIR/files/docker/README.md"
    '';
  };

  failure = runner {
    first = first;
    second = dag.entryAfter [ "first" ] "false";
    third = dag.entryAfter [ "second" ] ''
      print -r -- 'unexpected' > "$CONFIG_DIR/unexpected"
    '';
  };

  pipelineFailure = runner {
    first = first;
    second = dag.entryAfter [ "first" ] "false | cat";
  };

  evaluation = {
    emptyRunner = (runner { }) == null;
    cycleRejected = !(builtins.tryEval (runner {
      one = dag.entryAfter [ "two" ] "true";
      two = dag.entryAfter [ "one" ] "true";
    }).drvPath).success;
    missingRejected = !(builtins.tryEval (runner {
      one = dag.entryAfter [ "missingLogin" ] "true";
    }).drvPath).success;
    hookNotInActivation = !(builtins.hasAttr "fixture" (mkHome {
      fixture = dag.entryAnywhere "true";
    }).config.home.activation);
  };
}
