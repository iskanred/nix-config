{ config, lib, ... }:

{
  home.file."personal-git-config" = {
    target = lib.mkOverride 900 ".gitconfig";

    text = ''
      [user]
        name = Iskander Nafikov
        email = nafikov.iskander@mail.ru
      [init]
        defaultBranch = main
    '';
  };

  xdg.configFile."zsh/init.zsh".source = ../../files/zsh/init.zsh;
  xdg.configFile."zsh/environment.zsh".source = ../../files/zsh/environment.zsh;
  xdg.configFile."zsh/functions.zsh".source = ../../files/zsh/functions.zsh;
  xdg.configFile."zsh/interactive.zsh".source = ../../files/zsh/interactive.zsh;
  xdg.configFile."zsh/darwin-rebuild.zsh".source = ../../files/zsh/darwin-rebuild.zsh;

  xdg.configFile."nvim" = {
    source = ../../files/nvim;
    force = true;
  };
  xdg.configFile."yazi/yazi.toml".source = ../../files/yazi/yazi.toml;

  home.file.".p10k.zsh".source = ../../files/zsh/.p10k.zsh;
}
