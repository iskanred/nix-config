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
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      hasLocal = builtins.pathExists ./local.nix;

      local =
        if hasLocal
        then import ./local.nix
        else null;

      isDarwin = hasLocal && nixpkgs.lib.hasSuffix "-darwin" local.system;

      mkHome = system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};

          modules = [
            self.homeModules.default
          ];

          extraSpecialArgs = {
            inherit local;
          };
        };

      mkDarwin = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit local;
        };

        modules = [
          ./modules/darwin

          home-manager.darwinModules.home-manager

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.extraSpecialArgs = {
              inherit local;
            };

            home-manager.users.${local.username}.imports = [
              self.homeModules.default
            ];
          }
        ];
      };
    in
    {
      # Reusable on standalone Home Manager, nix-darwin, and NixOS.
      homeModules.default = ./home.nix;
    }
    // nixpkgs.lib.optionalAttrs hasLocal {
      # Keep a standalone output available on both macOS and Linux.
      homeConfigurations.${local.username} = mkHome local.system;
    }
    // nixpkgs.lib.optionalAttrs isDarwin {
      # Full macOS system configuration with Home Manager integrated.
      darwinConfigurations.current = mkDarwin;
    };
}
