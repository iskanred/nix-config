# nix-darwin build, switch, and explicit update workflow.
# The flake reference and optional runner are supplied by Home Manager.
typeset -g _DR_FLAKE_REF="$1"
typeset -g _DR_UPDATE_RUNNER="${2-}"

function dr() {
  if [[ "$1" == "update" ]]; then
    shift

    if (( $# != 0 )); then
      print -u2 "usage: dr update"
      return 2
    fi

    nix flake update --flake "$_DR_FLAKE_REF" || return
    if [[ -n "$_DR_UPDATE_RUNNER" ]]; then
      "$_DR_UPDATE_RUNNER" || return
    fi
    sudo darwin-rebuild build --flake "$_DR_FLAKE_REF#update" || return
    sudo darwin-rebuild switch --flake "$_DR_FLAKE_REF#update"
    return
  fi

  sudo darwin-rebuild --flake "$_DR_FLAKE_REF#current" "$@"
}
