{ local, ... }:

{
  nixpkgs.hostPlatform = local.system;

  system.primaryUser = local.username;

  users.users.${local.username} = {
    name = local.username;
    home = local.homeDirectory;
  };

  system.defaults = {
    dock.show-recents = false;

    CustomUserPreferences = {
      # Use Caps Lock to switch between Latin and non-Latin input sources.
      NSGlobalDomain = {
        TISRomanSwitchState = 1;
      };

      "com.apple.HIToolbox" = {
        # Globe/Fn key -> Show Emoji & Symbols.
        AppleFnUsageType = 2;
      };
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Keep this value after installation unless deliberately migrating
  # according to the nix-darwin changelog.
  system.stateVersion = 6;
}
