{ config, local, pkgs, ... }:

let
  # Use path-based flakes so local.nix can stay gitignored and untracked.
  flakeRef = "path:${local.configDirectory}";
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  kittyPrimaryMod = if isDarwin then "cmd" else "ctrl";
in
{
  programs.zsh = {
    enable = true;

    # Autocompletion
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    dotDir = "${config.xdg.configHome}/zsh";

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "fzf"
        "vi-mode"
      ];
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    # More Linux-like behavior
    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    # Base aliases
    shellAliases = {
      # eza defaults: icons + grouped directories for a richer ls replacement
      ls  = "eza --group-directories-first";
      lsa = "eza --group-directories-first --all";

      l   = "eza --group-directories-first --tree --level=1";
      la  = "eza --group-directories-first --tree --level=1 --all";

      lt  = "eza --group-directories-first --tree --level=2";
      lta = "eza --group-directories-first --tree --level=2 --all";

      # '--git' and '--binary' options only have sense when using with '--long' option
      ll  = "eza --group-directories-first --long --binary --git";
      lla = "eza --group-directories-first --long --binary --git --all";

      cat = "bat";
      top = "htop";
    }
    // pkgs.lib.optionalAttrs (!isDarwin) {
      hm = "home-manager --flake '${flakeRef}#${config.home.username}'";
    };

    initContent = ''
      ${pkgs.lib.optionalString isDarwin ''
        source "$HOME/.config/zsh/darwin-rebuild.zsh" '${flakeRef}'
      ''}

      source "$HOME/.config/zsh/init.zsh"
    '';
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    # Use `z` as the command and auto-add directories on `cd`.
    options = [ "--cmd" "z" ];
  };

  programs.eza = {
    enable = true;
    # Disable built-in aliases; we provide custom eza aliases in programs.zsh.shellAliases.
    enableZshIntegration = false;
    icons = "always";
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    # Use nix-direnv for fast, cached nix shells on directory change.
    nix-direnv.enable = true;
  };

  programs.kitty = {
    enable = true;
    # Use a built-in kitty-themes entry so theme is reproducible across systems.
    themeFile = "OneDark";
    # Configure Git difftool to use `kitten diff` for side-by-side terminal diffs.
    enableGitIntegration = true;

    font = {
      # Explicit font choice for consistent rendering across macOS/Linux.
      name = "FiraCode Nerd Font";
      size = 16.0;
    };

    settings = {
      # Faster cursor blink than Kitty default for clearer focus.
      cursor_blink_interval = 0.2;

      # Slight terminal transparency and blur for visual comfort.
      # Note: blur is only effective on compositors/platforms that support it.
      background_opacity = 0.9;
      background_blur = 5;

      # Keep powerline tab style with stable tab titles.
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_title_template = "{index}: {title}";

      # Always ask confirmation before closing a tab/OS window (threshold = 1).
      confirm_os_window_close = 1;
      enable_audio_bell = false;
    };

    keybindings = {
      # Use Cmd on macOS and Ctrl on Linux for consistent ergonomics.
      "${kittyPrimaryMod}+t" = "new_tab";
      "${kittyPrimaryMod}+w" = "close_tab";
      "${kittyPrimaryMod}+shift+]" = "next_tab";
      "${kittyPrimaryMod}+shift+[" = "previous_tab";
      "${kittyPrimaryMod}+1" = "goto_tab 1";
      "${kittyPrimaryMod}+2" = "goto_tab 2";
      "${kittyPrimaryMod}+3" = "goto_tab 3";
      "${kittyPrimaryMod}+4" = "goto_tab 4";
      "${kittyPrimaryMod}+5" = "goto_tab 5";
      "${kittyPrimaryMod}+6" = "goto_tab 6";
      "${kittyPrimaryMod}+7" = "goto_tab 7";
      "${kittyPrimaryMod}+8" = "goto_tab 8";
      "${kittyPrimaryMod}+9" = "goto_tab 9";
    };
  };

  programs.obsidian = {
    enable = pkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.obsidian;
    cli.enable = true;
  };

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;

    # Preserve the pre-26.05 defaults across Home Manager upgrades.
    withRuby = true;
    withPython3 = true;

    plugins = with pkgs.vimPlugins; [
      onedark-nvim
      nvim-cmp
      cmp-nvim-lsp
    ];
  };

  programs.fzf.enable = true;
}
