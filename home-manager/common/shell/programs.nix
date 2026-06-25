{
  lib,
  pkgs,
  config,
  ...
}:

{
  xdg.configFile."starship.toml" = lib.mkIf config.programs.starship.enable {
    source = config.my.paths.local.xdgConfigLayeredSource "starship.toml";
  };

  xdg.configFile."atuin/config.toml" = lib.mkIf config.programs.atuin.enable {
    source = config.my.paths.local.xdgConfigLayeredSource "atuin/config.toml";
  };

  programs = {
    fzf = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.fzf;
      defaultCommand = "fd --type f";
      changeDirWidgetCommand = "fd --type d";
    };

    carapace = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.carapace;
    };

    tealdeer = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.tealdeer;
      settings.updates.auto_update = true;
    };

    navi = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.navi;
    };

    atuin = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.atuin;
    };

    starship = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.starship;
    };

    zoxide = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.zoxide;
      options = [ "--cmd cd" ];
    };
  };
}
