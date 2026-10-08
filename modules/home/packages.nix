{ pkgs, ... }:

let
  lib = pkgs.lib;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  ubridgeDarwin = pkgs.ubridge.overrideAttrs (_old: rec {
    version = "1.1.1";

    src = pkgs.fetchFromGitHub {
      owner = "GNS3";
      repo = "ubridge";
      tag = "v${version}";
      hash = "sha256-2kt5naxMZwYX39sGyPqjiybFb8QtZuDbyBnMPeZS9U0=";
    };
  });

  brewGuard = pkgs.writeShellScriptBin "brew" ''
    echo "brew is managed declaratively by Nix." >&2
    echo "Add casks to modules/darwin/homebrew.nix, then run 'dr switch' or 'dr update'." >&2
    exit 1
  '';

  commonPackages = with pkgs; [
    # GNU userland (Linux-like)
    coreutils
    findutils
    gnused
    gnugrep
    gawk
    gnutar

    # Modern alternatives
    duf
    dust
    tldr
    # Daily CLI
    git
    tmux
    ncdu
    bat
    fd
    yazi
    jq

    # Network
    inetutils
    net-tools
    nmap

    # Virtualization
    docker
    qemu
    vpcs
    virt-viewer

    # Binary manipulations
    binwalk
    hyx

    # Processes
    htop
    btop
    ripgrep
    pstree

    # JS
    nodejs_22

    # Java
    jdk21
    jdt-language-server

    # Docs
    pandoc
    typst
  ];

  fontsPackages = with pkgs; [
    nerd-fonts.fira-code
  ];

  linuxPackages = with pkgs; [
    iproute2
    ubridge
  ];

  darwinPackages = with pkgs; [
    brewGuard
    iproute2mac
    ubridgeDarwin
  ];
in
{
  # lib.optionals keeps one package list portable across Darwin and Linux.
  home.packages =
    commonPackages
    ++ fontsPackages
    ++ lib.optionals isLinux linuxPackages
    ++ lib.optionals isDarwin darwinPackages;
}
