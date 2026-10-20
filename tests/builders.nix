# Evaluate with the command documented in docs/private-work-config.md.
{ baseline }:

let
  lib = baseline.inputs.nixpkgs.lib;
  local = {
    username = "fixture";
    homeDirectory = "/Users/fixture";
    system = "aarch64-darwin";
    configDirectory = "/Users/fixture/private-config";
  };
  workHome = { pkgs, ... }: {
    home.packages = [ pkgs.hello ];
    home.sessionVariables.WORK_FIXTURE = "present";
  };
  workDarwin = { ... }: {
    environment.variables.WORK_SYSTEM_FIXTURE = "present";
    homebrew.casks = [ "fixture-app" ];
  };
  common = {
    inherit local;
    homeModules = [ workHome ];
    extraUnfreePackages = [ "fixture-unfree" ];
  };
  home = baseline.lib.mkHome common;
  darwinArgs = common // { darwinModules = [ workDarwin ]; };
  current = baseline.lib.mkDarwin darwinArgs;
  update = baseline.lib.mkDarwin (darwinArgs // { upgradeHomebrew = true; });
  linux = baseline.lib.mkHome (common // {
    local = local // {
      system = "x86_64-linux";
      homeDirectory = "/home/fixture";
      configDirectory = "/home/fixture/private-config";
    };
  });
  defaultHome = baseline.lib.mkHome {
    local = builtins.removeAttrs local [ "configDirectory" ];
  };
  scalarConflict = baseline.lib.mkHome (common // {
    homeModules = [ workHome { home.sessionVariables.WORK_FIXTURE = "conflict"; } ];
  });
  scalarOverride = baseline.lib.mkHome (common // {
    homeModules = [
      workHome
      ({ lib, ... }: { home.sessionVariables.WORK_FIXTURE = lib.mkForce "override"; })
    ];
  });

  hasPackage = name: packages:
    builtins.elem name (map lib.getName packages);
  hasHome = config:
    config.home.sessionVariables.WORK_FIXTURE == "present"
    && hasPackage "hello" config.home.packages
    && hasPackage "ripgrep" config.home.packages
    && config.programs.zsh.enable;
  allowed = predicate:
    predicate { name = "obsidian-1"; }
    && predicate { name = "fixture-unfree-1"; }
    && !(predicate { name = "other-unfree-1"; });
  hasDarwin = system:
    hasHome system.config.home-manager.users.fixture
    && system.config.environment.variables.WORK_SYSTEM_FIXTURE == "present"
    && builtins.any (cask: cask.name == "fixture-app") system.config.homebrew.casks
    && system.config.system.defaults.dock.show-recents == false
    && allowed system.config.nixpkgs.config.allowUnfreePredicate;

  results = {
    standaloneHome = hasHome home.config;
    linuxHome = hasHome linux.config;
    darwinCurrent = hasDarwin current;
    darwinUpdate = hasDarwin update;
    homebrewUpdateFlag =
      !current.config.homebrew.onActivation.upgrade
      && !current.config.homebrew.onActivation.autoUpdate
      && update.config.homebrew.onActivation.upgrade
      && update.config.homebrew.onActivation.autoUpdate;
    standaloneUnfree = allowed home.pkgs.config.allowUnfreePredicate;
    defaultUnfree =
      defaultHome.pkgs.config.allowUnfreePredicate { name = "obsidian-1"; }
      && !(defaultHome.pkgs.config.allowUnfreePredicate { name = "fixture-unfree-1"; });
    darwinRebuildTarget =
      lib.hasInfix "'path:/Users/fixture/private-config'"
        current.config.home-manager.users.fixture.programs.zsh.initContent
      && !(current.config.home-manager.users.fixture.programs.zsh.shellAliases ? hm);
    linuxRebuildTarget =
      linux.config.programs.zsh.shellAliases.hm
      == "home-manager --flake 'path:/home/fixture/private-config#fixture'";
    defaultConfigDirectory =
      lib.hasInfix "'path:/Users/fixture/.config/nix-config'"
        defaultHome.config.programs.zsh.initContent;
    scalarConflictRejected =
      !(builtins.tryEval scalarConflict.config.home.sessionVariables.WORK_FIXTURE).success;
    scalarOverrideAccepted =
      scalarOverride.config.home.sessionVariables.WORK_FIXTURE == "override";
  };
in
assert lib.assertMsg (lib.all (value: value) (builtins.attrValues results))
  "Builder regression: ${builtins.toJSON results}";
results
