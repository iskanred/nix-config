{
  description = "Cross-platform Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      ...
    }:
    let
      hasLocal = builtins.pathExists ./local.nix;

      normalizeLocal = machine:
        machine // {
          configDirectory =
            machine.configDirectory
            or "${machine.homeDirectory}/.config/nix-config";
        };

      local = if hasLocal then normalizeLocal (import ./local.nix) else null;

      isDarwin = hasLocal && nixpkgs.lib.hasSuffix "-darwin" local.system;

      mkAllowUnfreePredicate = extraUnfreePackages: pkg:
        builtins.elem (nixpkgs.lib.getName pkg) ([
          "obsidian"
        ] ++ extraUnfreePackages);

      mkHome = { local, homeModules ? [ ], extraUnfreePackages ? [ ] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit (local) system;
            config.allowUnfreePredicate = mkAllowUnfreePredicate extraUnfreePackages;
          };

          modules = [
            self.homeModules.default
          ] ++ homeModules;

          extraSpecialArgs = {
            local = normalizeLocal local;
          };
        };

      mkDarwin =
        {
          local,
          homeModules ? [ ],
          darwinModules ? [ ],
          extraUnfreePackages ? [ ],
          upgradeHomebrew ? false,
        }:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            local = normalizeLocal local;
            inherit upgradeHomebrew;
            allowUnfreePredicate = mkAllowUnfreePredicate extraUnfreePackages;
          };

          modules = [
            ./modules/darwin

            nix-homebrew.darwinModules.nix-homebrew

            home-manager.darwinModules.home-manager

            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.extraSpecialArgs = {
                local = normalizeLocal local;
              };

              home-manager.users.${local.username}.imports = [
                self.homeModules.default
              ] ++ homeModules;
            }
          ] ++ darwinModules;
        };
    in
    {
      # Reusable on standalone Home Manager, nix-darwin, and NixOS.
      homeModules.default = ./home.nix;

      # Consumers supply machine identity; these builders retain our baseline
      # and pinned dependency graph without reading the consumer's local.nix.
      lib = {
        inherit mkHome mkDarwin;
      };

      templates.work = {
        path = ./templates/work;
        description = "Private work configuration extending the public baseline";
      };
    }
    // nixpkgs.lib.optionalAttrs hasLocal {
      # Keep a standalone output available on both macOS and Linux.
      homeConfigurations.${local.username} = mkHome { inherit local; };
    }
    // nixpkgs.lib.optionalAttrs isDarwin {
      # Full macOS system configuration with Home Manager integrated.
      darwinConfigurations.current = mkDarwin { inherit local; };

      # Explicit update target used by `dr update`.
      darwinConfigurations.update = mkDarwin {
        inherit local;
        upgradeHomebrew = true;
      };
    };
}
