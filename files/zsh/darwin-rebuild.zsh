# nix-darwin build, switch, and explicit update workflow.
# The flake reference is supplied by the Home Manager module when sourced.
typeset -g _DR_FLAKE_REF="$1"

function dr() {
  if [[ "$1" == "update" ]]; then
    shift

    if (( $# != 0 )); then
      print -u2 "usage: dr update"
      return 2
    fi

    nix flake update --flake "$_DR_FLAKE_REF" || return
    sudo darwin-rebuild build --flake "$_DR_FLAKE_REF#update" || return
    sudo darwin-rebuild switch --flake "$_DR_FLAKE_REF#update"
    return
  fi

  sudo darwin-rebuild --flake "$_DR_FLAKE_REF#current" "$@"
}
