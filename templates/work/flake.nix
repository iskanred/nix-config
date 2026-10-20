{
  description = "Private work configuration";

  # This is the only dependency: the baseline owns the entire Nix input graph.
  inputs.baseline.url = "github:iskanred/nix-config";

  outputs = { baseline, ... }:
    let
      hasLocal = builtins.pathExists ./local.nix;
      local = if hasLocal then import ./local.nix else null;
      isDarwin = hasLocal && baseline.inputs.nixpkgs.lib.hasSuffix "-darwin" local.system;

      common = {
        inherit local;
        homeModules = [ ./home.nix ];
        extraUnfreePackages = [ ];
      };

      darwin = common // {
        darwinModules = [ ./modules/darwin ];
      };
    in
    { }
    // baseline.inputs.nixpkgs.lib.optionalAttrs hasLocal {
      homeConfigurations.${local.username} = baseline.lib.mkHome common;
    }
    // baseline.inputs.nixpkgs.lib.optionalAttrs isDarwin {
      darwinConfigurations.current = baseline.lib.mkDarwin darwin;
      darwinConfigurations.update = baseline.lib.mkDarwin (darwin // {
        upgradeHomebrew = true;
      });
    };
}
