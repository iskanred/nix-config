{ local, upgradeHomebrew, ... }:

{
  # nix-homebrew owns the Homebrew installation. autoMigrate lets an existing
  # installation be adopted when this configuration is first activated.
  nix-homebrew = {
    enable = true;
    user = local.username;
    autoMigrate = true;
  };

  # nix-darwin generates and applies the Brewfile during system activation.
  # Add GUI applications to casks; keep command-line tools in Nix.
  homebrew = {
    enable = true;
    casks = [ ];

    global.autoUpdate = false;

    onActivation = {
      autoUpdate = upgradeHomebrew;
      upgrade = upgradeHomebrew;

      # TODO: Change to "zap" after the complete cask application list is declared.
      cleanup = "uninstall";
    };
  };
}
